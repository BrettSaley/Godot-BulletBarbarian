extends Node2D
## Wires the game together: player, enemies, projectiles, hazards, loot and
## HUD. Handles XP and loot from kills, moving items between bags, inventory
## and equipment, travelling between realms and raids, unlocking realms, and
## permadeath (a new Barbarian starts from scratch, in Lumbridge).
##
## Realm progression: Lumbridge's world bosses open portals to the Chambers of
## Xeric; completing it unlocks God Wars. God Wars bosses lead to the Theatre
## of Blood, which unlocks the Wilderness, whose bosses lead to the Tombs of
## Amascut. Every realm's hub has portals to the others; unlocked realms can
## always be revisited.

const RAID_PORTAL_LIFETIME := 60.0
## Screen pixels per world pixel. Fixed, so a bigger window shows more of the
## world instead of zooming in (1600x900 shows a 960x540 view).
const VIEW_SCALE := 1600.0 / 960.0
const MIN_WINDOW := Vector2i(1280, 720)
## Where the realm portals stand around each hub's campfire.
const HUB_PORTAL_OFFSETS := [Vector2(-170, -40), Vector2(170, -40), Vector2(0, -190)]
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
var raid: Raid
var realm := Realms.LUMBRIDGE
## How many realms this Barbarian has unlocked (1 = only Lumbridge).
var unlocked_realms := 1
var current_bag: LootBag
var shown_bag_size := -1
var locked_notice_timer := 0.0


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
	hud.restart_requested.connect(get_tree().reload_current_scene)

	_travel_to_realm(Realms.LUMBRIDGE)
	hud.show_message("Welcome to Lumbridge. Danger grows the farther you go.", 5.0)


func _process(delta: float) -> void:
	var bag := _bag_under_player()
	var bag_size := bag.items.size() if bag else -1
	if bag != current_bag or bag_size != shown_bag_size:
		current_bag = bag
		shown_bag_size = bag_size
		hud.show_bag(bag)

	locked_notice_timer -= delta
	if player.is_alive():
		for portal: Portal in get_tree().get_nodes_in_group("portals"):
			if not portal.is_queued_for_deletion() and portal.position.distance_to(player.position) < Portal.RADIUS:
				_take_portal(portal)
				break

	if raid:
		hud.area_name = "%s: %s" % [raid.raid_name(), raid.room_name_at(player.position)]
	else:
		var zone := World.zone_name(player.position, realm)
		var hub: bool = World.zone_tier(player.position) < 0
		hud.area_name = zone if hub else "%s: %s" % [Realms.info(realm).name, zone]


## F11 switches between full screen and a window; 9 cycles the dev modes.
func _unhandled_input(event: InputEvent) -> void:
	if not (event is InputEventKey and event.pressed and not event.echo):
		return
	match event.keycode:
		KEY_F11:
			var fullscreen := DisplayServer.window_get_mode() == DisplayServer.WINDOW_MODE_FULLSCREEN
			DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED if fullscreen else DisplayServer.WINDOW_MODE_FULLSCREEN)
		KEY_9, KEY_KP_9:
			var mode_name: String = player.cycle_dev_mode()
			hud.set_dev_mode(player.dev_mode, mode_name)
			hud.show_message(mode_name, 1.5)


# --- Travelling ---

func _take_portal(portal: Portal) -> void:
	if portal.locked:
		if locked_notice_timer <= 0.0:
			locked_notice_timer = 2.0
			hud.show_message(portal.lock_hint, 2.0)
		return
	var parts := portal.destination.split(":")
	if parts[0] == "raid":
		portal.queue_free()
		_enter_raid(parts[1])
	else:
		var target := int(parts[1])
		var from_raid := raid != null
		_travel_to_realm(target)
		hud.show_message("You return to %s." % Realms.info(target).hub if from_raid
				else "You travel to %s." % Realms.info(target).name, 3.0)


## Go to a realm's hub. Switching to a different realm clears the old realm's
## monsters, bags and portals; returning from a raid keeps them.
func _travel_to_realm(target: int) -> void:
	if raid:
		raid.tear_down()
		raid = null
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
		portal.position = World.CENTER + HUB_PORTAL_OFFSETS[slot]
		portals.add_child(portal)
		slot += 1


func _enter_raid(raid_id: String) -> void:
	_clear_combat()
	spawner.paused = true
	hud.boss = null
	raid = Raid.new()
	add_child(raid)
	move_child(raid, world.get_index() + 1)
	raid.build(raid_id, player, enemy_shots, enemies)
	raid.enemy_died.connect(_on_enemy_died)
	raid.walkable_changed.connect(func(rects: Array[Rect2]): player.walkable = rects)
	raid.announce.connect(func(text: String): hud.show_message(text, 3.0))
	raid.chest_opened.connect(_on_raid_chest_opened)
	player.position = raid.entrance()
	player.walkable = raid.walkable()
	_set_camera_limits(raid.bounds())
	hud.show_message("You enter the %s..." % raid.raid_name(), 3.0)


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
	var purple := loot.any(func(item): return item.tier == Items.UT)
	var message := "A purple! %s" % loot[0].name if purple else "The chest holds the finest gear of %s." % Realms.info(raid.realm).name
	var next_realm := raid.realm + 1
	if next_realm < Realms.count() and next_realm >= unlocked_realms:
		unlocked_realms = next_realm + 1
		message += "\n%s unlocked! Its portal waits at %s." % [Realms.info(next_realm).name, Realms.info(raid.realm).hub]
	elif next_realm >= Realms.count():
		message += "\nYou have conquered every raid in the land!"
	hud.show_message(message, 6.0)
	var exit := Portal.new()
	exit.label = "Exit to %s" % Realms.info(raid.realm).hub
	exit.destination = "realm:%d" % raid.realm
	exit.color = Color(0.4, 0.8, 1.0)
	exit.position = pos + Vector2(120, 0)
	portals.add_child(exit)


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
		var data := Realms.info(realm)
		hud.show_message("%s has been slain! A portal to the %s opens." % [enemy.display_name, data.raid_name], 4.0)
		var portal := Portal.new()
		portal.label = data.raid_name
		portal.destination = "raid:%s" % data.raid
		portal.color = data.portal_color
		portal.lifetime = RAID_PORTAL_LIFETIME
		portal.position = enemy.position + Vector2(0, -70)
		portals.add_child(portal)


func _on_boss_spawned(boss: Enemy) -> void:
	hud.boss = boss
	hud.show_message("%s has appeared in %s!" % [boss.display_name, World.zone_name(boss.position, realm)], 4.0)


func _on_player_leveled_up(new_level: int) -> void:
	DamageText.spawn(self, player.position + Vector2(0, -44), "LEVEL UP!", Color(1, 0.9, 0.3), 18)
	if new_level >= 20:
		hud.show_message("Level 20! Now find better gear.", 3.0)


func _on_player_died(killer: String) -> void:
	player.hide()
	hud.show_death(killer, player.level)


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
