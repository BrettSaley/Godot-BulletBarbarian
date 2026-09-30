extends Node2D
## Wires the game together: player, enemies, projectiles, hazards, loot and
## HUD. Handles XP and loot from kills, moving items between bags, inventory
## and equipment, travelling between realms and raids, unlocking realms, and
## permadeath (a new Barbarian starts from scratch, in Lumbridge).
##
## Realm progression: killing a world boss opens a portal to one of its
## realm's dungeons; after DUNGEONS_PER_RAID dungeons are cleared, the next
## world boss opens the realm's raid instead. Completing the Chambers of Xeric
## unlocks God Wars, the Theatre of Blood unlocks the Wilderness, and the
## Tombs of Amascut are the last raid. Every realm's hub has portals to the
## others; unlocked realms can always be revisited.

const DUNGEON_PORTAL_LIFETIME := 60.0
const DUNGEONS_PER_RAID := 2
const AUTOSAVE_INTERVAL := 30.0
## Screen pixels per world pixel. Fixed, so a bigger window shows more of the
## world instead of zooming in (1600x900 shows a 960x540 view).
const VIEW_SCALE := 1600.0 / 960.0
const MIN_WINDOW := Vector2i(1280, 720)
## Where the realm portals stand around each hub's campfire.
const REALM_PORTAL_OFFSETS := [Vector2(-170, -40), Vector2(170, -40)]
## Raid portals sit in an arc below the campfire, CoX to ToA from left to right.
const RAID_PORTAL_OFFSETS := [Vector2(-150, 140), Vector2(0, 205), Vector2(150, 140)]
const HUB_PORTAL_COLORS := [Color(0.45, 0.85, 0.4), Color(0.6, 0.85, 1.0), Color(0.9, 0.3, 0.25)]

@onready var world: World = $World
@onready var bags: Node2D = $Bags
@onready var portals: Node2D = $Portals
@onready var enemies: Node2D = $Enemies
@onready var player: Node2D = $Player
@onready var player_shots: Node2D = $PlayerShots
@onready var enemy_shots: Node2D = $EnemyShots
@onready var hazards: Node2D = $Hazards
@onready var spawner: Node = $Spawner
@onready var hud: CanvasLayer = $HUD

var camera: Camera2D
## The raid or dungeon the player is in (null in the overworld).
var instance: Node2D
var realm := Realms.LUMBRIDGE
## Dungeons cleared per realm toward its raid portal, which opens for good at
## DUNGEONS_PER_RAID.
var dungeons_done := [0, 0, 0]
## Per realm: dungeons left in the current rotation, and the last one opened.
var dungeon_queues := [[], [], []]
var last_dungeon := ["", "", ""]
## How many realms this Barbarian has unlocked (1 = only Lumbridge).
var unlocked_realms := 1
var current_bag: LootBag
var shown_bag_size := -1
var locked_notice_timer := 0.0
var saving := false
var choosing := false  # on the select or design screen
var slot := 0
var autosave_timer := AUTOSAVE_INTERVAL


func _ready() -> void:
	RenderingServer.set_default_clear_color(Color(0.05, 0.05, 0.06))
	Input.set_default_cursor_shape(Input.CURSOR_CROSS)
	get_window().min_size = MIN_WINDOW
	get_window().size_changed.connect(_fit_view_to_window)
	_fit_view_to_window()

	player.shots = player_shots
	player.died.connect(_on_player_died)
	player.leveled_up.connect(_on_player_leveled_up)
	player_shots.enemy_hit.connect(player.on_hit_enemy)
	camera = Camera2D.new()
	camera.position_smoothing_enabled = true
	camera.position_smoothing_speed = 8.0
	player.add_child(camera)

	enemy_shots.player = player
	enemy_shots.player_hit.connect(player.take_damage)
	hazards.player = player

	spawner.enemy_parent = enemies
	spawner.shots = enemy_shots
	spawner.player = player
	spawner.enemy_died.connect(_on_enemy_died)
	spawner.boss_spawned.connect(_on_boss_spawned)

	hud.bind_player(player)
	hud.slot_clicked.connect(_on_slot_clicked)
	hud.character_select_requested.connect(_to_character_select)

	# Only the real game saves; test scripts that add Main by hand don't touch the saves.
	saving = get_tree().current_scene == self
	# Nothing may save until a character is picked, or the blank starting
	# Barbarian would overwrite slot 1.
	choosing = saving
	_travel_to_realm(Realms.LUMBRIDGE)
	if saving:
		SaveGame.migrate_old_save()
		_show_character_select()


## The select screen, with the game paused behind it until a character is picked.
func _show_character_select() -> void:
	choosing = true
	get_tree().paused = true
	var select := CharacterSelect.new()
	add_child(select)
	select.chosen.connect(_on_slot_chosen)


## Play the character in `chosen_slot`, or design a new one if it's empty.
func _on_slot_chosen(chosen_slot: int) -> void:
	slot = chosen_slot
	var save := SaveGame.read(slot)
	if save.is_empty():
		_design_character()
		return
	player.load_save(save.player)
	unlocked_realms = save.unlocked_realms
	dungeons_done = save.dungeons_done
	# Older saves reset progress after a raid; a raid that unlocked the next
	# realm was clearly opened, so keep its portal open.
	for r in unlocked_realms - 1:
		dungeons_done[r] = maxi(dungeons_done[r], DUNGEONS_PER_RAID)
	last_dungeon = save.get("last_dungeon", last_dungeon)
	dungeon_queues = save.get("dungeon_queues", dungeon_queues)
	spawner.boss_queues = save.get("boss_queues", spawner.boss_queues)
	spawner.last_bosses = save.get("last_bosses", spawner.last_bosses)
	get_tree().paused = false
	choosing = false
	_travel_to_realm(save.realm)
	hud.show_message("Welcome back, %s." % player.character_name, 4.0)


## A new Barbarian starts on the design screen; Back returns to the select screen.
func _design_character() -> void:
	var creator := CharacterCreator.new()
	add_child(creator)
	creator.cancelled.connect(_show_character_select)
	creator.finished.connect(func(chosen_name: String, look: Dictionary) -> void:
		get_tree().paused = false
		choosing = false
		player.set_look(chosen_name, look)
		_save()
		hud.show_message("Welcome to Lumbridge, %s. Danger grows the farther you go." % chosen_name, 5.0))


## Back to the character select screen (after death, or from the pause menu).
func _to_character_select() -> void:
	_save()
	get_tree().paused = false
	get_tree().reload_current_scene()


# --- Saving (RotMG style: automatic, and deleted when you die) ---

func _save() -> void:
	if not saving or choosing or not player.is_alive():
		return
	SaveGame.write(slot, {"player": player.to_save(), "realm": realm, "unlocked_realms": unlocked_realms,
			"dungeons_done": dungeons_done.duplicate(), "last_dungeon": last_dungeon.duplicate(),
			"dungeon_queues": dungeon_queues.duplicate(true), "boss_queues": spawner.boss_queues.duplicate(true),
			"last_bosses": spawner.last_bosses.duplicate()})


## Also covers quitting from the pause menu or closing the window.
func _exit_tree() -> void:
	_save()


func _process(delta: float) -> void:
	var bag := _bag_under_player()
	var bag_size := bag.items.size() if bag else -1
	if bag != current_bag or bag_size != shown_bag_size:
		current_bag = bag
		shown_bag_size = bag_size
		hud.show_bag(bag)

	locked_notice_timer -= delta
	autosave_timer -= delta
	if autosave_timer <= 0.0:
		autosave_timer = AUTOSAVE_INTERVAL
		_save()
	if player.is_alive():
		for portal: Portal in get_tree().get_nodes_in_group("portals"):
			if not portal.is_queued_for_deletion() and portal.position.distance_to(player.position) < Portal.RADIUS:
				_take_portal(portal)
				break

	if instance is Dungeon:
		hud.area_name = instance.raid_name()
	elif instance:
		hud.area_name = "%s: %s" % [instance.raid_name(), instance.room_name_at(player.position)]
	else:
		var zone := World.zone_name(player.position, realm)
		var hub: bool = World.zone_tier(player.position) < 0
		hud.area_name = zone if hub else "%s: %s" % [Realms.info(realm).name, zone]


## R escapes to the hub; F11 switches between full screen and a window;
## 9 cycles the dev modes; 8 drops every UT and GIGA item nearby.
func _unhandled_input(event: InputEvent) -> void:
	if not (event is InputEventKey and event.pressed and not event.echo):
		return
	match event.keycode:
		KEY_R:
			_escape_to_hub()
		KEY_F11:
			var fullscreen := DisplayServer.window_get_mode() == DisplayServer.WINDOW_MODE_FULLSCREEN
			DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED if fullscreen else DisplayServer.WINDOW_MODE_FULLSCREEN)
		KEY_9, KEY_KP_9:
			var mode_name: String = player.cycle_dev_mode()
			hud.set_dev_mode(player.dev_mode, mode_name)
			hud.show_message(mode_name, 1.5)
		KEY_8, KEY_KP_8:
			_drop_all_uniques()


## Like RotMG's escape to Nexus: straight back to the current realm's hub at full HP and MP,
## from the overworld or out of a dungeon or raid.
func _escape_to_hub() -> void:
	if not player.is_alive() or choosing:
		return
	_travel_to_realm(realm)
	# Escaping fully restores you.
	player.hp = player.max_hp()
	player.mp = player.max_mp()
	player.changed.emit()
	hud.show_message("You escape to %s." % Realms.info(realm).hub, 2.0)


## Dev tool: one bag per raid and per realm's dungeons, in a row by the player.
func _drop_all_uniques() -> void:
	var groups: Array = []
	for raid_id in Items.RAID_UNIQUES:
		groups.append(Items.RAID_UNIQUES[raid_id].map(func(id): return Items.unique(id)))
	for r in Realms.count():
		groups.append(Dungeons.for_realm(r).map(func(id): return Items.dungeon_unique(Dungeons.info(id).unique)))
	for i in groups.size():
		_spawn_bag(player.position + Vector2((i - (groups.size() - 1) / 2.0) * 50.0, 70), groups[i])
	hud.show_message("Dropped every UT and GIGA item.", 2.0)


# --- Travelling ---

func _take_portal(portal: Portal) -> void:
	if portal.locked:
		if locked_notice_timer <= 0.0:
			locked_notice_timer = 2.0
			hud.show_message(portal.lock_hint, 2.0)
		return
	var parts := portal.destination.split(":")
	match parts[0]:
		"raid":
			portal.queue_free()
			# Raid portals stay open once unlocked; leaving or finishing the
			# raid never closes its hub portal.
			_enter_instance(Raid.new(), parts[1])
		"dungeon":
			portal.queue_free()
			_enter_instance(Dungeon.new(), parts[1])
		_:
			var target := int(parts[1])
			var from_instance := instance != null
			_travel_to_realm(target)
			hud.show_message("You return to %s." % Realms.info(target).hub if from_instance
					else "You travel to %s." % Realms.info(target).name, 3.0)


## Go to a realm's hub. Switching to a different realm clears the old realm's
## monsters, bags and portals; returning from a raid or dungeon keeps them.
func _travel_to_realm(target: int) -> void:
	if instance:
		instance.tear_down()
		instance = null
		# Any loot and portals left behind in the raid or dungeon are gone.
		for leftover in get_tree().get_nodes_in_group("loot_bags") + get_tree().get_nodes_in_group("portals"):
			if not World.bounds().has_point(leftover.position):
				leftover.queue_free()
	_clear_combat()
	if target != realm or spawner.spawned.is_empty():
		realm = target
		world.set_realm(realm)
		spawner.set_realm(realm)
		hud.boss = null
		for bag in get_tree().get_nodes_in_group("loot_bags"):
			bag.queue_free()
		for portal in get_tree().get_nodes_in_group("portals"):
			portal.queue_free()
	spawner.paused = false
	player.position = World.CENTER + Vector2(0, 60)
	var area: Array[Rect2] = [World.bounds()]
	player.walkable = area
	_set_camera_limits(Rect2(Vector2.ZERO, World.SIZE))
	_build_hub_portals()
	_update_raid_progress()
	_save()


## Portals around the hub campfire to every other realm, locked until unlocked.
func _build_hub_portals() -> void:
	for portal in get_tree().get_nodes_in_group("hub_portals"):
		portal.queue_free()
	var slot := 0
	for target in Realms.count():
		if target == realm:
			continue
		var portal := Portal.new()
		portal.add_to_group("hub_portals")
		portal.label = "To %s" % Realms.info(target).name
		portal.destination = "realm:%d" % target
		portal.color = HUB_PORTAL_COLORS[target]
		portal.locked = target >= unlocked_realms
		portal.lock_hint = "Complete the %s to unlock" % Realms.info(target - 1).raid_name if target > 0 else ""
		portal.position = World.CENTER + REALM_PORTAL_OFFSETS[slot]
		portals.add_child(portal)
		slot += 1
	# One portal per raid; each opens once its realm has enough dungeons done
	# and then stays open for good.
	for raid_realm in Realms.count():
		var data := Realms.info(raid_realm)
		var portal := Portal.new()
		portal.add_to_group("hub_portals")
		portal.label = data.raid_name
		portal.destination = "raid:%s" % data.raid
		portal.color = data.portal_color
		if raid_realm >= unlocked_realms:
			portal.locked = true
			portal.lock_hint = "Unlock %s first" % data.name
		elif dungeons_done[raid_realm] < DUNGEONS_PER_RAID:
			portal.locked = true
			portal.lock_hint = "%s dungeons cleared: %d/%d" % [data.name, dungeons_done[raid_realm], DUNGEONS_PER_RAID]
		portal.position = World.CENTER + RAID_PORTAL_OFFSETS[raid_realm]
		portals.add_child(portal)


## Enter a raid or dungeon (both share the same interface).
func _enter_instance(new_instance: Node2D, id: String) -> void:
	_clear_combat()
	spawner.paused = true
	hud.boss = null
	instance = new_instance
	add_child(instance)
	move_child(instance, world.get_index() + 1)
	instance.build(id, player, enemy_shots, enemies)
	instance.enemy_died.connect(_on_enemy_died)
	instance.walkable_changed.connect(func(rects: Array[Rect2]): player.walkable = rects)
	instance.announce.connect(func(text: String): hud.show_message(text, 3.0))
	if instance is Raid:
		instance.chest_opened.connect(_on_raid_chest_opened)
	else:
		instance.boss_defeated.connect(_on_dungeon_boss_defeated)
	player.position = instance.entrance()
	player.walkable = instance.walkable()
	_set_camera_limits(instance.bounds())
	hud.show_message("You enter %s..." % instance.raid_name(), 3.0)


## A dungeon boss drops its loot (and maybe the unique, in its own white
## bag), counts toward the next raid, and opens the way home.
func _on_dungeon_boss_defeated(pos: Vector2, drop: Dictionary) -> void:
	_spawn_bag(pos, drop.loot)
	if drop.unique != null:
		_spawn_bag(pos + Vector2(50, 0), [drop.unique])
	var was_open: bool = dungeons_done[realm] >= DUNGEONS_PER_RAID
	dungeons_done[realm] = mini(dungeons_done[realm] + 1, DUNGEONS_PER_RAID)
	_update_raid_progress()
	if not was_open and dungeons_done[realm] >= DUNGEONS_PER_RAID:
		hud.show_message("The %s portal is open at %s!" % [Realms.info(realm).raid_name, Realms.info(realm).hub], 4.0)
	_spawn_exit(pos, instance.realm, Vector2(0, 110))


## The exit goes `offset` away from `near` (flipped if that side is the closer
## wall), then is pulled back inside the room so it never lands past a wall.
func _spawn_exit(near: Vector2, home: int, offset: Vector2) -> void:
	var exit := Portal.new()
	exit.label = "Exit to %s" % Realms.info(home).hub
	exit.destination = "realm:%d" % home
	exit.color = Color(0.4, 0.8, 1.0)
	exit.position = near + offset
	var room := _instance_rect_at(near)
	if room.has_area():
		if not room.has_point(near + offset):
			offset = -offset
		var inside := room.grow(-Portal.RADIUS - 6)
		exit.position = (near + offset).clamp(inside.position, inside.end)
	portals.add_child(exit)


## The biggest walkable area of the raid or dungeon containing `pos`.
func _instance_rect_at(pos: Vector2) -> Rect2:
	var best := Rect2()
	for rect: Rect2 in instance.walkable():
		if rect.has_point(pos) and rect.get_area() > best.get_area():
			best = rect
	return best


func _update_raid_progress() -> void:
	hud.set_raid_progress(dungeons_done[realm], DUNGEONS_PER_RAID, Realms.info(realm).raid_name)


func _clear_combat() -> void:
	enemy_shots.clear_all()
	player_shots.clear_all()
	hazards.clear_all()


func _set_camera_limits(rect: Rect2) -> void:
	camera.limit_left = int(rect.position.x)
	camera.limit_top = int(rect.position.y)
	camera.limit_right = int(rect.end.x)
	camera.limit_bottom = int(rect.end.y)
	camera.reset_smoothing()


## Completing a raid opens the exit, and unlocks the next realm the first time.
func _on_raid_chest_opened(pos: Vector2, loot: Array) -> void:
	_spawn_bag(pos, loot)
	var purple := loot.any(func(item): return item.tier == Items.GIGA)
	var raid_realm: int = instance.realm
	# Completing a raid raises the level cap: CoX to 40, ToB to 60.
	player.raise_level_cap(40 + 20 * raid_realm)
	var message := "A purple! %s" % loot[0].name if purple else "The chest holds the finest gear of %s." % Realms.info(raid_realm).name
	var next_realm := raid_realm + 1
	if next_realm < Realms.count() and next_realm >= unlocked_realms:
		unlocked_realms = next_realm + 1
		message += "\n%s unlocked! Its portal waits at %s." % [Realms.info(next_realm).name, Realms.info(raid_realm).hub]
	elif next_realm >= Realms.count():
		message += "\nYou have conquered every raid in the land!"
	hud.show_message(message, 6.0)
	_spawn_exit(pos, raid_realm, Vector2(120, 0))


# --- Combat results ---

func _on_enemy_died(enemy: Enemy) -> void:
	player.add_xp(enemy.xp)
	DamageText.spawn(enemies, enemy.position + Vector2(0, -enemy.radius - 22), "+%d XP" % enemy.xp, Color(0.5, 1, 0.5), 12)
	if not enemy.drops_loot:
		return
	var drops := Items.roll_boss_drop(enemy.realm) if enemy.is_boss else Items.roll_monster_drop(enemy.tier, enemy.realm)
	if not drops.is_empty():
		_spawn_bag(enemy.position, drops)
	if enemy.is_boss:
		# World bosses always open a dungeon, cycling through all four before
		# any repeats; the raid portals wait in the hub.
		var portal := Portal.new()
		var dungeon_id: String = ShuffleBag.next(dungeon_queues[realm], Dungeons.for_realm(realm), last_dungeon[realm])
		last_dungeon[realm] = dungeon_id
		portal.label = Dungeons.info(dungeon_id).name
		portal.destination = "dungeon:%s" % dungeon_id
		portal.color = Color(0.9, 0.9, 0.95)
		hud.show_message("%s has been slain! A portal to %s opens." % [enemy.display_name, portal.label], 4.0)
		portal.lifetime = DUNGEON_PORTAL_LIFETIME
		portal.position = enemy.position + Vector2(0, -70)
		portals.add_child(portal)


func _on_boss_spawned(boss: Enemy) -> void:
	hud.boss = boss
	hud.show_message("%s has appeared in %s!" % [boss.display_name, World.zone_name(boss.position, realm)], 4.0)


func _on_player_leveled_up(new_level: int) -> void:
	DamageText.spawn(self, player.position + Vector2(0, -44), "LEVEL UP!", Color(1, 0.9, 0.3), 18)
	if new_level >= player.level_cap:
		hud.show_message("Level %d! Now your score counts up." % new_level if player.at_final_level()
				else "Level %d - the cap! Complete a raid to raise it." % new_level, 3.0)


func _on_player_died(killer: String) -> void:
	# Permadeath: the character's save goes with them.
	if saving:
		SaveGame.erase(slot)
	player.hide()
	hud.show_death(player.character_name, killer, player.level)


# --- Items ---

func _bag_under_player() -> LootBag:
	var nearest: LootBag = null
	var nearest_distance := LootBag.PICKUP_RADIUS
	for bag: LootBag in get_tree().get_nodes_in_group("loot_bags"):
		if bag.is_queued_for_deletion():
			continue
		var d := bag.position.distance_to(player.position)
		if d < nearest_distance:
			nearest = bag
			nearest_distance = d
	return nearest


func _on_slot_clicked(slot: ItemSlot, button: int) -> void:
	if not player.is_alive() or slot.item == null:
		return
	var right := button == MOUSE_BUTTON_RIGHT
	match slot.group:
		"inventory":
			if right:
				_drop(player.take_from_inventory(slot.key))
			else:
				player.equip_from_inventory(slot.key)
		"equip":
			if right:
				var item: Dictionary = player.equipment[slot.key]
				player.equipment[slot.key] = null
				player.hp = minf(player.hp, player.max_hp())
				player.changed.emit()
				_drop(item)
			elif not player.unequip(slot.key):
				hud.show_message("Inventory full", 1.2)
		"bag":
			if current_bag == null:
				return
			if player.first_free_slot() == -1:
				hud.show_message("Inventory full", 1.2)
				return
			player.add_to_inventory(current_bag.take(slot.key))
	shown_bag_size = -2  # force the bag panel to refresh


## Put an item on the ground: into the bag underfoot if it has room, else a new bag.
func _drop(item: Dictionary) -> void:
	if current_bag and current_bag.items.size() < LootBag.CAPACITY:
		current_bag.items.append(item)
		current_bag.time_left = LootBag.LIFETIME
		current_bag.queue_redraw()
	else:
		_spawn_bag(player.position, [item])


func _spawn_bag(pos: Vector2, items: Array) -> void:
	var bag := LootBag.new()
	bag.position = pos
	bag.items = items
	bags.add_child(bag)


## Grow or shrink the visible world with the window, keeping things the same size.
func _fit_view_to_window() -> void:
	var window := get_window()
	window.content_scale_size = Vector2i((Vector2(window.size) / VIEW_SCALE).round())
