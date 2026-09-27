class_name Raid
extends Node2D
## The Chambers of Xeric: a chain of rooms joined by corridors, built off to
## the side of the realm. A lobby, three combat rooms picked at random
## (Tekton, Vanguards, Vasa Nistirio, Lizardman Shamans), the Great Olm, then
## the reward chest. Walking into a room seals it until its boss is dead.
## The Olm fights in three phases (hands, hands, then hands and head), and
## the Vanguards shield whichever one falls too far behind the others.
## All positions are in world coordinates (the node itself sits at 0,0).

signal enemy_died(enemy: Enemy)
signal walkable_changed(rects: Array[Rect2])
signal announce(text: String)
signal chest_opened(pos: Vector2, loot: Array)

const Tekton := preload("res://scripts/enemies/raid/tekton.gd")
const Vanguard := preload("res://scripts/enemies/raid/vanguard.gd")
const Vasa := preload("res://scripts/enemies/raid/vasa.gd")
const GlowingCrystal := preload("res://scripts/enemies/raid/glowing_crystal.gd")
const LizardmanShaman := preload("res://scripts/enemies/raid/lizardman_shaman.gd")
const OlmHead := preload("res://scripts/enemies/raid/olm_head.gd")
const OlmHand := preload("res://scripts/enemies/raid/olm_hand.gd")

## Built well past the realm's east edge.
const ORIGIN := Vector2(World.SIZE.x + 1500, 600)
const ROOM_SIZE := Vector2(900, 560)
const SMALL_ROOM := Vector2(560, 440)
const OLM_ROOM := Vector2(1100, 680)
const CORRIDOR := Vector2(220, 140)
## The top of the Olm room is the wall its head and hands sit in.
const OLM_WALL := 130.0
## How far each corridor's walkable strip extends into the rooms it joins.
const DOORWAY_OVERLAP := 30.0
const COMBAT_ROOMS := ["tekton", "vanguards", "vasa", "shamans"]
const ROOM_NAMES := {
	"lobby": "Chambers of Xeric", "tekton": "Tekton", "vanguards": "Vanguards", "vasa": "Vasa Nistirio",
	"shamans": "Lizardman Shamans", "olm": "The Great Olm", "chest": "Reward Chamber",
}
## A Vanguard this far (in health %) below the healthiest one becomes immune.
const VANGUARD_SPREAD := 0.3
## Pause before the Olm rises with new hands between phases.
const OLM_RISE_DELAY := 3.0
## Raid monsters use this zone tier for their stat scaling.
const RAID_TIER := 4
const FLOOR := Color(0.2, 0.19, 0.22)
const WALL := Color(0.09, 0.08, 0.1)

## Set by build().
var player: Node2D
var shots: Node2D
var enemy_parent: Node2D

## Each room: {kind, rect, state ("waiting" | "fighting" | "cleared"), required: [Enemy]}
var rooms: Array[Dictionary] = []
var corridors: Array[Rect2] = []
var chest_opened_already := false
var chest_had_purple := false
var time := 0.0


func build(target_player: Node2D, shot_layer: Node2D, enemy_layer: Node2D) -> void:
	player = target_player
	shots = shot_layer
	enemy_parent = enemy_layer
	var picks := COMBAT_ROOMS.duplicate()
	picks.shuffle()
	var kinds := ["lobby"] + picks.slice(0, 3) + ["olm", "chest"]
	var x := ORIGIN.x
	for kind in kinds:
		var size := ROOM_SIZE
		if kind in ["lobby", "chest"]:
			size = SMALL_ROOM
		elif kind == "olm":
			size = OLM_ROOM
		var rect := Rect2(Vector2(x, ORIGIN.y - size.y / 2.0), size)
		if not rooms.is_empty():
			corridors.append(Rect2(Vector2(x - CORRIDOR.x, ORIGIN.y - CORRIDOR.y / 2.0), CORRIDOR))
		rooms.append({"kind": kind, "rect": rect, "state": "waiting", "required": []})
		x += size.x + CORRIDOR.x
	rooms[0].state = "cleared"
	rooms[-1].state = "cleared"
	queue_redraw()


func entrance() -> Vector2:
	return rooms[0].rect.get_center() + Vector2(-150, 0)


func bounds() -> Rect2:
	var total: Rect2 = rooms[0].rect
	for room in rooms:
		total = total.merge(room.rect)
	return total.grow(120)


func room_name_at(pos: Vector2) -> String:
	for room in rooms:
		if room.rect.has_point(pos):
			return ROOM_NAMES[room.kind]
	return "Chambers of Xeric"


func chest_position() -> Vector2:
	return rooms[-1].rect.get_center()


## Where the player may walk: sealed inside a room during a fight, otherwise
## every room up to and including the next unfinished one.
func walkable() -> Array[Rect2]:
	var rects: Array[Rect2] = []
	for room in rooms:
		if room.state == "fighting":
			rects.append(_floor(room))
			return rects
	for i in rooms.size():
		rects.append(_floor(rooms[i]))
		if rooms[i].state != "cleared":
			break
		if i < corridors.size():
			# Reach past the doorways into both rooms: room floors are inset from
			# their walls, so a wall-to-wall corridor would leave a gap at each door.
			rects.append(corridors[i].grow_individual(DOORWAY_OVERLAP, 0, DOORWAY_OVERLAP, 0))
	return rects


func _floor(room: Dictionary) -> Rect2:
	var rect: Rect2 = room.rect
	if room.kind == "olm":
		rect = Rect2(rect.position + Vector2(0, OLM_WALL), rect.size - Vector2(0, OLM_WALL))
	return rect.grow(-14)


func _physics_process(delta: float) -> void:
	time += delta
	for room in rooms:
		match room.state:
			"waiting":
				if room.rect.grow(-40).has_point(player.position):
					_start(room)
			"fighting":
				if room.kind == "vanguards":
					_balance_vanguards(room)
				elif room.kind == "olm":
					_update_olm_phases(room, delta)
				room.required = room.required.filter(func(e): return is_instance_valid(e) and e.hp > 0.0)
				if room.required.is_empty():
					_clear(room)
	if not chest_opened_already and player.position.distance_to(chest_position()) < 45.0:
		_open_chest()
	queue_redraw()


func _start(room: Dictionary) -> void:
	room.state = "fighting"
	var rect: Rect2 = room.rect
	var c := rect.get_center()
	match room.kind:
		"tekton":
			var tekton: Enemy = _spawn(Tekton, c + Vector2(150, 0))
			tekton.anvil = rect.position + Vector2(rect.size.x - 90, 80)
			room.required = [tekton]
		"vanguards":
			for i in 3:
				var kind: String = ["melee", "ranged", "magic"][i]
				var vanguard: Enemy = Vanguard.new()
				vanguard.set_kind(kind)
				_add(vanguard, c + Vector2.from_angle(TAU * i / 3.0 - PI / 2.0) * 150.0)
				room.required.append(vanguard)
		"vasa":
			var vasa: Enemy = _spawn(Vasa, c)
			vasa.room_center = c
			for corner in [Vector2(-1, -1), Vector2(1, -1), Vector2(-1, 1), Vector2(1, 1)]:
				vasa.crystals.append(_spawn(GlowingCrystal, c + corner * (rect.size / 2.0 - Vector2(80, 70))))
			room.required = [vasa]
		"shamans":
			for i in 3:
				room.required.append(_spawn(LizardmanShaman, c + Vector2(100 + i * 60, (i - 1) * 120)))
		"olm":
			var head: Enemy = _spawn(OlmHead, Vector2(c.x, rect.position.y + OLM_WALL * 0.5))
			head.room = rect
			_spawn_olm_hands(head)
			room.required = [head]
			room.respawn_timer = 0.0
	walkable_changed.emit(walkable())
	announce.emit(ROOM_NAMES[room.kind])


func _clear(room: Dictionary) -> void:
	room.state = "cleared"
	# Leftover adds (crystals, spawn) vanish with their boss.
	for enemy in get_tree().get_nodes_in_group("raid_enemies"):
		if room.rect.grow(40).has_point(enemy.position):
			enemy.queue_free()
	shots.clear_all()
	get_tree().get_first_node_in_group("hazards").clear_all()
	walkable_changed.emit(walkable())
	announce.emit("%s defeated!" % ROOM_NAMES[room.kind] if room.kind != "olm" else "The Great Olm is slain! Claim your reward.")


func _spawn_olm_hands(head: Enemy) -> void:
	var hands: Array = []
	for side in ["left", "right"]:
		var hand: Enemy = OlmHand.new()
		hand.set_side(side)
		hand.room = head.room
		_add(hand, head.position + Vector2(-200.0 if side == "left" else 200.0, 20))
		hands.append(hand)
	head.hands = hands


## Phases 1 and 2 end when both hands die: after a pause the Olm rises again
## with fresh hands. In the final phase the head opens up instead (olm_head.gd).
func _update_olm_phases(room: Dictionary, delta: float) -> void:
	var head = room.required[0] if not room.required.is_empty() else null
	if not is_instance_valid(head) or head.hands_alive() or head.phase >= OlmHead.FINAL_PHASE:
		return
	if room.respawn_timer <= 0.0:
		room.respawn_timer = OLM_RISE_DELAY
		announce.emit("The Great Olm's hands fall... it rises again!")
		return
	room.respawn_timer -= delta
	if room.respawn_timer <= 0.0:
		head.phase += 1
		_spawn_olm_hands(head)
		var last: bool = head.phase == OlmHead.FINAL_PHASE
		announce.emit("Phase %d of %d%s" % [head.phase, OlmHead.FINAL_PHASE, ": kill the hands, then the head!" if last else ""])


## Vanguards must be worn down together: any Vanguard whose health falls too
## far below the healthiest one is shielded (immune) until the others catch up.
func _balance_vanguards(room: Dictionary) -> void:
	var alive: Array = room.required.filter(func(e): return is_instance_valid(e) and e.hp > 0.0)
	if alive.size() < 2:
		for vanguard in alive:
			vanguard.invulnerable = false
		return
	var highest: float = alive.map(func(e): return e.hp / e.max_hp).max()
	for vanguard in alive:
		var fraction: float = vanguard.hp / vanguard.max_hp
		if not vanguard.invulnerable and fraction < highest - VANGUARD_SPREAD:
			vanguard.invulnerable = true
			announce.emit("The %s is shielded! Damage the others." % vanguard.display_name)
		elif vanguard.invulnerable and fraction >= highest - VANGUARD_SPREAD * 0.5:
			vanguard.invulnerable = false


func _spawn(kind: GDScript, pos: Vector2) -> Enemy:
	return _add(kind.new(), pos)


func _add(enemy: Enemy, pos: Vector2) -> Enemy:
	enemy.position = pos
	enemy.setup(RAID_TIER, shots, player)
	enemy.leash_range = INF  # sealed in the room anyway
	enemy.add_to_group("raid_enemies")
	enemy.died.connect(func(e: Enemy): enemy_died.emit(e))
	enemy_parent.add_child(enemy)
	return enemy


func _open_chest() -> void:
	chest_opened_already = true
	var loot := Items.raid_chest_loot()
	chest_had_purple = loot.any(func(item): return item.tier == Items.UT)
	chest_opened.emit(chest_position() + Vector2(0, 50), loot)


## Remove everything this raid spawned (used when leaving).
func tear_down() -> void:
	for enemy in get_tree().get_nodes_in_group("raid_enemies"):
		enemy.queue_free()
	queue_free()


func _draw() -> void:
	for corridor in corridors:
		draw_rect(corridor.grow(10), WALL)
		draw_rect(corridor, FLOOR)
	for room in rooms:
		_draw_room(room)


func _draw_room(room: Dictionary) -> void:
	var rect: Rect2 = room.rect
	draw_rect(rect.grow(14), WALL)
	draw_rect(rect, FLOOR)
	# Flagstone grid
	var tile := 48.0
	var x := rect.position.x + tile
	while x < rect.end.x:
		draw_line(Vector2(x, rect.position.y), Vector2(x, rect.end.y), FLOOR.darkened(0.25), 1.0)
		x += tile
	var y := rect.position.y + tile
	while y < rect.end.y:
		draw_line(Vector2(rect.position.x, y), Vector2(rect.end.x, y), FLOOR.darkened(0.25), 1.0)
		y += tile
	# Torches in the corners
	for corner in [rect.position + Vector2(20, 20), Vector2(rect.end.x - 20, rect.position.y + 20)]:
		draw_circle(corner, 6.0, Color(0.35, 0.22, 0.1))
		draw_circle(corner + Vector2(0, -6), 5.0 + sin(time * 9.0 + corner.x) * 1.5, Color(1, 0.6, 0.15, 0.9))
	# Sealed doorways glow red while a fight is on
	if room.state == "fighting":
		draw_rect(rect, Color(0.8, 0.15, 0.1, 0.8), false, 4.0)

	match room.kind:
		"lobby":
			draw_string(ThemeDB.fallback_font, rect.position + Vector2(0, 70), "Chambers of Xeric",
					HORIZONTAL_ALIGNMENT_CENTER, rect.size.x, 30, Color(0.85, 0.75, 0.55))
			draw_string(ThemeDB.fallback_font, rect.position + Vector2(0, 100), "Head east. Each room seals until its boss falls.",
					HORIZONTAL_ALIGNMENT_CENTER, rect.size.x, 14, Color(0.75, 0.75, 0.75))
		"olm":
			var wall := Rect2(rect.position, Vector2(rect.size.x, OLM_WALL))
			draw_rect(wall, Color(0.16, 0.2, 0.18))
			for k in 14:
				var cx := rect.position.x + 40 + k * 78.0
				draw_colored_polygon(PackedVector2Array([Vector2(cx - 10, wall.end.y), Vector2(cx, wall.end.y - 30 - (k % 3) * 12),
						Vector2(cx + 10, wall.end.y)]), Color(0.45, 0.65, 0.58))
		"chest":
			_draw_chest(rect.get_center())


func _draw_chest(c: Vector2) -> void:
	if chest_opened_already and chest_had_purple:
		# The famous purple light.
		draw_rect(Rect2(c + Vector2(-18, -400), Vector2(36, 400)), Color(0.8, 0.3, 1.0, 0.25 + 0.1 * sin(time * 5.0)))
	var wood := Color(0.45, 0.28, 0.12)
	draw_rect(Rect2(c + Vector2(-26, -8), Vector2(52, 28)), wood)
	draw_rect(Rect2(c + Vector2(-26, -8), Vector2(52, 28)), Color(0.85, 0.7, 0.3), false, 2.0)
	var lid_y := -30.0 if chest_opened_already else -20.0
	draw_rect(Rect2(c + Vector2(-26, lid_y), Vector2(52, 12)), wood.lightened(0.1))
	draw_rect(Rect2(c + Vector2(-5, -6), Vector2(10, 10)), Color(0.85, 0.7, 0.3))
	if not chest_opened_already:
		draw_string(ThemeDB.fallback_font, c + Vector2(-80, -40), "Walk here to claim",
				HORIZONTAL_ALIGNMENT_CENTER, 160, 13, Color(1, 0.9, 0.6))
