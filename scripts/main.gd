extends Node2D
## Wires the game together: player, enemies, projectiles, hazards, loot and
## HUD. Handles XP and loot from kills, moving items between bags, inventory
## and equipment, travelling between the realm and the Chambers of Xeric,
## and permadeath (a new Barbarian starts from scratch).

const RAID_PORTAL_LIFETIME := 60.0

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
var current_bag: LootBag
var shown_bag_size := -1


func _ready() -> void:
	RenderingServer.set_default_clear_color(Color(0.05, 0.05, 0.06))
	Input.set_default_cursor_shape(Input.CURSOR_CROSS)

	player.shots = player_shots
	player.died.connect(_on_player_died)
	player.leveled_up.connect(_on_player_leveled_up)
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

	_enter_realm()
	hud.show_message("Welcome to Lumbridge. Danger grows the farther you go.", 5.0)


func _process(_delta: float) -> void:
	var bag := _bag_under_player()
	var bag_size := bag.items.size() if bag else -1
	if bag != current_bag or bag_size != shown_bag_size:
		current_bag = bag
		shown_bag_size = bag_size
		hud.show_bag(bag)

	if player.is_alive():
		for portal: Portal in get_tree().get_nodes_in_group("portals"):
			if not portal.is_queued_for_deletion() and portal.position.distance_to(player.position) < Portal.RADIUS:
				_take_portal(portal)
				break

	hud.area_name = raid.room_name_at(player.position) if raid else World.zone_name(player.position)


## F11 switches between full screen and a window.
func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo and event.keycode == KEY_F11:
		var fullscreen := DisplayServer.window_get_mode() == DisplayServer.WINDOW_MODE_FULLSCREEN
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED if fullscreen else DisplayServer.WINDOW_MODE_FULLSCREEN)


# --- Travelling ---

func _take_portal(portal: Portal) -> void:
	var destination := portal.destination
	portal.queue_free()
	if destination == "raid":
		_enter_raid()
	else:
		_enter_realm()
		hud.show_message("You return to Lumbridge.", 3.0)


func _enter_realm() -> void:
	if raid:
		raid.tear_down()
		raid = null
	_clear_combat()
	spawner.paused = false
	player.position = World.CENTER + Vector2(0, 60)
	var realm: Array[Rect2] = [World.bounds()]
	player.walkable = realm
	_set_camera_limits(Rect2(Vector2.ZERO, World.SIZE))


func _enter_raid() -> void:
	_clear_combat()
	spawner.paused = true
	hud.boss = null
	raid = Raid.new()
	add_child(raid)
	move_child(raid, $World.get_index() + 1)
	raid.build(player, enemy_shots, enemies)
	raid.enemy_died.connect(_on_enemy_died)
	raid.walkable_changed.connect(func(rects: Array[Rect2]): player.walkable = rects)
	raid.announce.connect(func(text: String): hud.show_message(text, 3.0))
	raid.chest_opened.connect(_on_raid_chest_opened)
	player.position = raid.entrance()
	player.walkable = raid.walkable()
	_set_camera_limits(raid.bounds())
	hud.show_message("You enter the Chambers of Xeric...", 3.0)


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


func _on_raid_chest_opened(pos: Vector2, loot: Array) -> void:
	_spawn_bag(pos, loot)
	var purple := loot.any(func(item): return item.tier == Items.UT)
	hud.show_message("A purple! %s" % loot[0].name if purple else "The chest holds Rune and Dragon gear.", 4.0)
	var exit := Portal.new()
	exit.label = "Exit to Lumbridge"
	exit.destination = "realm"
	exit.color = Color(0.4, 0.8, 1.0)
	exit.position = pos + Vector2(120, 0)
	portals.add_child(exit)


# --- Combat results ---

func _on_enemy_died(enemy: Enemy) -> void:
	player.add_xp(enemy.xp)
	DamageText.spawn(enemies, enemy.position + Vector2(0, -enemy.radius - 22), "+%d XP" % enemy.xp, Color(0.5, 1, 0.5), 12)
	if not enemy.drops_loot:
		return
	var drops := Items.roll_boss_drop(enemy.display_name) if enemy.is_boss else Items.roll_monster_drop(enemy.tier)
	if not drops.is_empty():
		_spawn_bag(enemy.position, drops)
	if enemy.is_boss:
		hud.show_message("%s has been slain! A portal to the Chambers of Xeric opens." % enemy.display_name, 4.0)
		var portal := Portal.new()
		portal.label = "Chambers of Xeric"
		portal.lifetime = RAID_PORTAL_LIFETIME
		portal.position = enemy.position + Vector2(0, -70)
		portals.add_child(portal)


func _on_boss_spawned(boss: Enemy) -> void:
	hud.boss = boss
	hud.show_message("%s has appeared in %s!" % [boss.display_name, World.zone_name(boss.position)], 4.0)


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
