class_name Dungeon
extends Node2D
## A RotMG-style dungeon: a winding path of rooms joined by corridors, each
## room holding packs of the dungeon's monsters, and a boss in a big room at
## the end. Nothing seals; fight your way through. The boss drops loot on the
## ground (and sometimes the dungeon's unique in a white bag), then an exit
## opens. Shares its interface with Raid so the main scene can treat both
## the same. All positions are in world coordinates.

signal enemy_died(enemy: Enemy)
signal walkable_changed(rects: Array[Rect2])
signal announce(text: String)
signal boss_defeated(pos: Vector2, drop: Dictionary)

## Built well south of the raids, past the realm's east edge.
const ORIGIN := Vector2(World.SIZE.x + 1500, 3200)
const PATH_ROOMS := 5
const START_ROOM := Vector2(460, 380)
const BOSS_ROOM := Vector2(1000, 680)
const CORRIDOR_WIDTH := 130.0
const CORRIDOR_LENGTH := 220.0
const DOORWAY_OVERLAP := 30.0
## Monsters and boss scale like the realm's outermost zone.
const DUNGEON_TIER := 6
const MOB_AGGRO := 420.0

var dungeon_id := ""
var data: Dictionary
var realm := 0
var player: Node2D
var shots: Node2D
var enemy_parent: Node2D

var rooms: Array[Rect2] = []
var corridors: Array[Rect2] = []
var boss: Enemy
var boss_down := false
var time := 0.0


func build(id: String, target_player: Node2D, shot_layer: Node2D, enemy_layer: Node2D) -> void:
	dungeon_id = id
	data = Dungeons.info(id)
	realm = data.realm
	player = target_player
	shots = shot_layer
	enemy_parent = enemy_layer
	_lay_out()
	for i in range(1, rooms.size() - 1):
		for pack in 2:
			_spawn_pack(rooms[i])
	_spawn_boss()
	queue_redraw()


## Rooms march east, drifting up and down, joined by L-shaped corridors.
func _lay_out() -> void:
	var y := ORIGIN.y
	var x := ORIGIN.x
	for i in PATH_ROOMS + 2:
		var size := START_ROOM
		if i == PATH_ROOMS + 1:
			size = BOSS_ROOM
		elif i > 0:
			size = Vector2(randf_range(520, 720), randf_range(380, 520))
		if i > 0:
			y = clampf(y + randf_range(-260, 260), ORIGIN.y - 500, ORIGIN.y + 500)
		var room := Rect2(Vector2(x, y - size.y / 2.0), size)
		if not rooms.is_empty():
			_connect(rooms[-1], room)
		rooms.append(room)
		x += size.x + CORRIDOR_LENGTH


func _connect(a: Rect2, b: Rect2) -> void:
	var ya := a.get_center().y
	var yb := b.get_center().y
	var half := CORRIDOR_WIDTH / 2.0
	var mid := (a.end.x + b.position.x) / 2.0
	corridors.append(Rect2(a.end.x - DOORWAY_OVERLAP, ya - half, mid - a.end.x + DOORWAY_OVERLAP + half, CORRIDOR_WIDTH))
	corridors.append(Rect2(mid - half, minf(ya, yb) - half, CORRIDOR_WIDTH, absf(ya - yb) + CORRIDOR_WIDTH))
	corridors.append(Rect2(mid - half, yb - half, b.position.x - mid + half + DOORWAY_OVERLAP, CORRIDOR_WIDTH))


func _spawn_pack(room: Rect2) -> void:
	var center := Vector2(randf_range(room.position.x + 80, room.end.x - 80), randf_range(room.position.y + 80, room.end.y - 80))
	var kind = data.monsters.pick_random()
	for i in randi_range(2, 4):
		var mob: Enemy = Minion.make(kind) if kind is String else kind.new()
		mob.drops_loot = true
		_add(mob, center + Vector2.from_angle(randf() * TAU) * randf_range(20, 60), room)
		mob.aggro_range = MOB_AGGRO


func _spawn_boss() -> void:
	var room: Rect2 = rooms[-1]
	boss = data.boss.new()
	boss.room = room
	_add(boss, room.get_center() + Vector2(150, 0), room)
	boss.aggro_range = 600.0
	boss.died.connect(_on_boss_died)


func _add(enemy: Enemy, pos: Vector2, room: Rect2) -> Enemy:
	enemy.position = pos
	enemy.setup(DUNGEON_TIER, shots, player, realm)
	enemy.leash_range = INF
	enemy.bounds = room.grow(-14)
	enemy.position = enemy.position.clamp(enemy.bounds.position + Vector2.ONE * enemy.radius, enemy.bounds.end - Vector2.ONE * enemy.radius)
	enemy.add_to_group("dungeon_enemies")
	enemy.died.connect(func(e: Enemy): enemy_died.emit(e))
	enemy_parent.add_child(enemy)
	return enemy


func _on_boss_died(dead: Enemy) -> void:
	boss_down = true
	var drop := Items.roll_dungeon_drop(data.unique, realm)
	announce.emit("%s defeated!%s" % [dead.display_name, " A unique drop!" if drop.unique != null else ""])
	boss_defeated.emit(dead.position, drop)


# --- Shared interface with Raid ---

func raid_name() -> String:
	return data.name


func room_name_at(pos: Vector2) -> String:
	if rooms[-1].has_point(pos):
		return boss.display_name if is_instance_valid(boss) else "Boss chamber"
	return data.name


func entrance() -> Vector2:
	return rooms[0].get_center()


func bounds() -> Rect2:
	var total := rooms[0]
	for room in rooms:
		total = total.merge(room)
	for corridor in corridors:
		total = total.merge(corridor)
	return total.grow(120)


## The whole dungeon is open from the start.
func walkable() -> Array[Rect2]:
	var rects: Array[Rect2] = []
	for room in rooms:
		rects.append(room.grow(-14))
	rects.append_array(corridors)
	return rects


func tear_down() -> void:
	for enemy in get_tree().get_nodes_in_group("dungeon_enemies"):
		enemy.queue_free()
	queue_free()


func _process(delta: float) -> void:
	time += delta
	queue_redraw()


func _draw() -> void:
	var floor_color: Color = data.floor
	var wall_color: Color = data.wall
	for corridor in corridors:
		draw_rect(corridor.grow(10), wall_color)
	for room in rooms:
		draw_rect(room.grow(14), wall_color)
	for corridor in corridors:
		draw_rect(corridor, floor_color)
	for i in rooms.size():
		var room: Rect2 = rooms[i]
		draw_rect(room, floor_color)
		# Rubble and cracks for texture
		var rng := RandomNumberGenerator.new()
		rng.seed = i * 97 + dungeon_id.hash()
		for k in 18:
			var p := room.position + Vector2(rng.randf() * room.size.x, rng.randf() * room.size.y)
			draw_circle(p, rng.randf_range(2, 6), floor_color.darkened(0.25))
		for corner in [room.position + Vector2(20, 20), Vector2(room.end.x - 20, room.position.y + 20)]:
			draw_circle(corner, 6.0, Color(0.35, 0.22, 0.1))
			draw_circle(corner + Vector2(0, -6), 5.0 + sin(time * 9.0 + corner.x) * 1.5, Color(1, 0.6, 0.15, 0.9))
	var start: Rect2 = rooms[0]
	draw_string(ThemeDB.fallback_font, start.position + Vector2(0, 60), data.name, HORIZONTAL_ALIGNMENT_CENTER, start.size.x, 26,
			Color(1, 0.9, 0.7))
	draw_string(ThemeDB.fallback_font, start.position + Vector2(0, 88), "Fight through to the boss at the end.",
			HORIZONTAL_ALIGNMENT_CENTER, start.size.x, 13, Color(0.8, 0.8, 0.8))
	if not boss_down:
		draw_rect(rooms[-1], Color(0.8, 0.15, 0.1, 0.5), false, 3.0)
