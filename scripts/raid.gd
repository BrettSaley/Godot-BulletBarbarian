class_name Raid
extends Node2D
## A raid dungeon: a chain of rooms joined by corridors, built off to the side
## of the realm. Walking into a room seals it until its boss is dead; the last
## room holds the reward chest. Three raids share this code:
##   Chambers of Xeric (Lumbridge) - lobby, three random rooms from Tekton,
##     Vanguards, Vasa Nistirio and Lizardman Shamans, then the Great Olm
##     (three phases). The Vanguards shield whichever one falls behind.
##   Theatre of Blood (God Wars) - Maiden, Bloat, Nylocas (waves, then the
##     Vasilias), Sotetseg, Xarpus, then Verzik Vitur.
##   Tombs of Amascut (Wilderness) - Akkha, Ba-Ba, Kephri and Zebak in a random
##     order, then both Wardens: the Obelisk, one Warden fighting while the
##     other casts from the dais, then the survivor on its throne.
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
const Maiden := preload("res://scripts/enemies/tob/maiden.gd")
const Bloat := preload("res://scripts/enemies/tob/bloat.gd")
const NylocasVasilias := preload("res://scripts/enemies/tob/nylocas_vasilias.gd")
const Sotetseg := preload("res://scripts/enemies/tob/sotetseg.gd")
const Xarpus := preload("res://scripts/enemies/tob/xarpus.gd")
const Verzik := preload("res://scripts/enemies/tob/verzik.gd")
const Akkha := preload("res://scripts/enemies/toa/akkha.gd")
const BaBa := preload("res://scripts/enemies/toa/baba.gd")
const Kephri := preload("res://scripts/enemies/toa/kephri.gd")
const Zebak := preload("res://scripts/enemies/toa/zebak.gd")
const Wardens := preload("res://scripts/enemies/toa/wardens.gd")
const Obelisk := preload("res://scripts/enemies/toa/obelisk.gd")

## Built well past the realm's east edge.
const ORIGIN := Vector2(World.SIZE.x + 1500, 600)
const ROOM_SIZE := Vector2(900, 560)
const SMALL_ROOM := Vector2(560, 440)
const BIG_ROOM := Vector2(1100, 680)
const CORRIDOR := Vector2(220, 140)
## The top of the Olm room is the wall its head and hands sit in.
const OLM_WALL := 130.0
## The Wardens stand on a raised dais along the top of their room.
const WARDEN_DAIS := 130.0
const WARDEN_PEDESTAL_X := 330.0
## How far each corridor's walkable strip extends into the rooms it joins.
const DOORWAY_OVERLAP := 30.0
const RAIDS := {
	"cox": {"name": "Chambers of Xeric", "floor": Color(0.2, 0.19, 0.22), "accent": Color(0.85, 0.75, 0.55)},
	"tob": {"name": "Theatre of Blood", "floor": Color(0.22, 0.14, 0.15), "accent": Color(0.9, 0.3, 0.3)},
	"toa": {"name": "Tombs of Amascut", "floor": Color(0.42, 0.35, 0.24), "accent": Color(0.95, 0.8, 0.4)},
}
const ROOM_NAMES := {
	"tekton": "Tekton", "vanguards": "Vanguards", "vasa": "Vasa Nistirio",
	"shamans": "Lizardman Shamans", "olm": "The Great Olm",
	"maiden": "The Maiden of Sugadinti", "bloat": "The Pestilent Bloat", "nylocas": "The Nylocas",
	"sotetseg": "Sotetseg", "xarpus": "Xarpus", "verzik": "Verzik Vitur",
	"akkha": "Path of Het: Akkha", "baba": "Path of Apmeken: Ba-Ba", "kephri": "Path of Scabaras: Kephri",
	"zebak": "Path of Crondis: Zebak", "wardens": "The Wardens", "chest": "Reward Chamber",
}
## A Vanguard this far (in health %) below the healthiest one becomes immune.
const VANGUARD_SPREAD := 0.3
## Pause before the Olm rises with new hands between phases.
const OLM_RISE_DELAY := 3.0
const NYLOCAS_WAVES := 4
const NYLOCAS_WAVE_EVERY := 7.0
## Raid monsters use this zone tier for their stat scaling (plus the realm's).
const RAID_TIER := 4
const WALL := Color(0.09, 0.08, 0.1)

## Set by build().
var raid_id := "cox"
var realm := Realms.LUMBRIDGE
var player: Node2D
var shots: Node2D
var enemy_parent: Node2D

## Each room: {kind, rect, state ("waiting" | "fighting" | "cleared"), required: [Enemy], ...}
var rooms: Array[Dictionary] = []
var corridors: Array[Rect2] = []
var chest_opened_already := false
var chest_had_purple := false
## Rolled the moment the final boss dies, so a purple shows before opening.
var chest_loot: Array = []
var time := 0.0
## Room the next spawned enemies are confined to.
var spawn_bounds := Rect2()


func build(id: String, target_player: Node2D, shot_layer: Node2D, enemy_layer: Node2D) -> void:
	raid_id = id
	realm = Realms.realm_of_raid(id)
	player = target_player
	shots = shot_layer
	enemy_parent = enemy_layer
	var kinds := ["lobby"]
	match raid_id:
		"cox":
			var picks := ["tekton", "vanguards", "vasa", "shamans"]
			picks.shuffle()
			kinds += picks.slice(0, 3) + ["olm"]
		"tob":
			kinds += ["maiden", "bloat", "nylocas", "sotetseg", "xarpus", "verzik"]
		"toa":
			var paths := ["akkha", "baba", "kephri", "zebak"]
			paths.shuffle()
			kinds += paths + ["wardens"]
	kinds.append("chest")
	var x := ORIGIN.x
	for kind in kinds:
		var size := ROOM_SIZE
		if kind in ["lobby", "chest"]:
			size = SMALL_ROOM
		elif kind in ["olm", "verzik", "wardens"]:
			size = BIG_ROOM
		var rect := Rect2(Vector2(x, ORIGIN.y - size.y / 2.0), size)
		if not rooms.is_empty():
			corridors.append(Rect2(Vector2(x - CORRIDOR.x, ORIGIN.y - CORRIDOR.y / 2.0), CORRIDOR))
		rooms.append({"kind": kind, "rect": rect, "state": "waiting", "required": []})
		x += size.x + CORRIDOR.x
	rooms[0].state = "cleared"
	rooms[-1].state = "cleared"
	queue_redraw()


func raid_name() -> String:
	return RAIDS[raid_id].name


func entrance() -> Vector2:
	return rooms[0].rect.get_center() + Vector2(-150, 0)


func bounds() -> Rect2:
	var total: Rect2 = rooms[0].rect
	for room in rooms:
		total = total.merge(room.rect)
	return total.grow(120)


func room_name_at(pos: Vector2) -> String:
	for room in rooms:
		if room.rect.has_point(pos) and ROOM_NAMES.has(room.kind):
			return ROOM_NAMES[room.kind]
	return raid_name()


func chest_position() -> Vector2:
	return rooms[-1].rect.get_center()


## Where the player may walk: sealed inside a room during a fight, otherwise
## every room up to and including the next unfinished one.
## Everywhere inside the walls, including the Olm's wall and the Wardens' dais
## (so shots can reach them): shots that leave these hit a wall.
func open_areas() -> Array[Rect2]:
	var rects: Array[Rect2] = []
	for room in rooms:
		rects.append(room.rect)
	for corridor in corridors:
		# Corridors only touch the rooms' edges; overlap a little so shots pass.
		rects.append(corridor.grow_individual(4, 0, 4, 0))
	return rects


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
	elif room.kind == "wardens":
		rect = Rect2(rect.position + Vector2(0, WARDEN_DAIS), rect.size - Vector2(0, WARDEN_DAIS))
	return rect.grow(-14)


func _physics_process(delta: float) -> void:
	time += delta
	for room in rooms:
		match room.state:
			"waiting":
				if room.rect.grow(-40).has_point(player.position):
					_start(room)
			"fighting":
				match room.kind:
					"vanguards":
						_balance_vanguards(room)
					"olm":
						_update_olm_phases(room, delta)
					"nylocas":
						_update_nylocas(room, delta)
				room.required = room.required.filter(func(e): return is_instance_valid(e) and e.hp > 0.0)
				if room.required.is_empty() and not room.get("busy", false):
					_clear(room)
	if not chest_opened_already and player.position.distance_to(chest_position()) < 45.0:
		_open_chest()
	queue_redraw()


func _start(room: Dictionary) -> void:
	room.state = "fighting"
	spawn_bounds = room.rect.grow(-14) if room.kind in ["olm", "wardens"] else _floor(room)
	var rect: Rect2 = room.rect
	var c := rect.get_center()
	match room.kind:
		# --- Chambers of Xeric ---
		"tekton":
			var tekton: Enemy = Tekton.new()
			tekton.anvil = rect.position + Vector2(rect.size.x - 90, 80)
			room.required = [_add(tekton, c + Vector2(150, 0))]
		"vanguards":
			for i in 3:
				var vanguard: Enemy = Vanguard.new()
				vanguard.set_kind(["melee", "ranged", "magic"][i])
				room.required.append(_add(vanguard, c + Vector2.from_angle(TAU * i / 3.0 - PI / 2.0) * 150.0))
		"vasa":
			var vasa: Enemy = Vasa.new()
			vasa.room_center = c
			_add(vasa, c)
			for corner in [Vector2(-1, -1), Vector2(1, -1), Vector2(-1, 1), Vector2(1, 1)]:
				vasa.crystals.append(_add(GlowingCrystal.new(), c + corner * (rect.size / 2.0 - Vector2(80, 70))))
			room.required = [vasa]
		"shamans":
			for i in 3:
				room.required.append(_add(LizardmanShaman.new(), c + Vector2(100 + i * 60, (i - 1) * 120)))
		"olm":
			var head: Enemy = OlmHead.new()
			head.room = rect
			_add(head, Vector2(c.x, rect.position.y + OLM_WALL * 0.5))
			_spawn_olm_hands(head)
			room.required = [head]
			room.respawn_timer = 0.0
		# --- Theatre of Blood ---
		"maiden":
			var maiden: Enemy = Maiden.new()
			maiden.room = rect
			room.required = [_add(maiden, rect.position + Vector2(160, rect.size.y / 2.0))]
		"bloat":
			var bloat: Enemy = Bloat.new()
			bloat.room = rect
			room.required = [_add(bloat, rect.position + Vector2(110, 110))]
		"nylocas":
			room.busy = true
			room.waves_left = NYLOCAS_WAVES
			room.wave_timer = 1.0
			room.wave_enemies = []
		"sotetseg":
			var sotetseg: Enemy = Sotetseg.new()
			sotetseg.room = rect
			room.required = [_add(sotetseg, Vector2(c.x, rect.position.y + 60))]
		"xarpus":
			room.required = [_add(Xarpus.new(), c)]
		"verzik":
			var verzik: Enemy = Verzik.new()
			verzik.room = rect
			room.required = [_add(verzik, Vector2(c.x, rect.position.y + 90))]
		# --- Tombs of Amascut ---
		"akkha", "baba", "kephri", "zebak":
			var boss: Enemy = {"akkha": Akkha, "baba": BaBa, "kephri": Kephri, "zebak": Zebak}[room.kind].new()
			boss.room = rect
			var spot := Vector2(c.x + 180, c.y) if room.kind != "kephri" else Vector2(c.x + 200, rect.position.y + 100)
			room.required = [_add(boss, spot)]
		"wardens":
			# Both Wardens wait on the dais; the Obelisk shields them from the floor.
			var floor_rect := _floor(room)
			var obelisk := _add(Obelisk.new(), Vector2(c.x, floor_rect.position.y + 110))
			var wardens: Array = []
			var leader := randi() % 2
			for i in 2:
				var warden: Enemy = Wardens.new()
				warden.set_kind(["elidinis", "tumeken"][i])
				warden.room = rect
				warden.floor_rect = floor_rect
				warden.obelisk = obelisk
				warden.leads = i == leader
				warden.pedestal = Vector2(c.x + (i * 2 - 1) * WARDEN_PEDESTAL_X, rect.position.y + WARDEN_DAIS * 0.5)
				warden.throne = Vector2(c.x, rect.position.y + WARDEN_DAIS * 0.5)
				wardens.append(_add(warden, warden.pedestal))
			wardens[0].partner = wardens[1]
			wardens[1].partner = wardens[0]
			room.required = wardens
	walkable_changed.emit(walkable())
	announce.emit(ROOM_NAMES[room.kind])


func _clear(room: Dictionary) -> void:
	room.state = "cleared"
	# Leftover adds (crystals, spawn, obelisks) vanish with their boss.
	for enemy in get_tree().get_nodes_in_group("raid_enemies"):
		if room.rect.grow(40).has_point(enemy.position):
			enemy.queue_free()
	shots.clear_all()
	get_tree().get_first_node_in_group("hazards").clear_all()
	walkable_changed.emit(walkable())
	var final_room: bool = room == rooms[-2]
	if final_room:
		_roll_chest()
	announce.emit("%s defeated!" % ROOM_NAMES[room.kind] if not final_room
			else "%s is conquered! %s" % [raid_name(), "A purple light shines above the chest!" if chest_had_purple else "Claim your reward."])


# --- Chambers of Xeric mechanics ---

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


# --- Theatre of Blood mechanics ---

## Waves of Nylocas pour in from three doorways; after the last wave is dead,
## the Nylocas Vasilias arrives.
func _update_nylocas(room: Dictionary, delta: float) -> void:
	var rect: Rect2 = room.rect
	room.wave_enemies = room.wave_enemies.filter(func(e): return is_instance_valid(e) and e.hp > 0.0)
	if room.waves_left > 0:
		room.wave_timer -= delta
		if room.wave_timer <= 0.0 or room.wave_enemies.is_empty() and room.wave_timer < NYLOCAS_WAVE_EVERY - 2.0:
			var wave: int = NYLOCAS_WAVES - room.waves_left
			room.waves_left -= 1
			room.wave_timer = NYLOCAS_WAVE_EVERY
			var doors := [Vector2(rect.position.x + 30, rect.get_center().y), Vector2(rect.get_center().x, rect.position.y + 30),
					Vector2(rect.get_center().x, rect.end.y - 30)]
			var colors := [Color(0.8, 0.8, 0.78), Color(0.35, 0.75, 0.3), Color(0.35, 0.5, 0.95)]
			for i in 5 + wave * 2:
				var nylo := Minion.make("nylocas", colors.pick_random())
				var door: Vector2 = doors[i % doors.size()]
				room.wave_enemies.append(_add(nylo, door + Vector2(randf_range(-30, 30), randf_range(-30, 30))))
			announce.emit("Nylocas wave %d of %d!" % [wave + 1, NYLOCAS_WAVES])
	elif room.busy and room.wave_enemies.is_empty():
		room.busy = false
		room.required = [_add(NylocasVasilias.new(), rect.get_center() + Vector2(150, 0))]
		announce.emit("The Nylocas Vasilias emerges!")


# --- Spawning and rewards ---

func _add(enemy: Enemy, pos: Vector2) -> Enemy:
	enemy.position = pos
	enemy.setup(RAID_TIER, shots, player, realm, true)
	enemy.leash_range = INF  # sealed in the room anyway
	enemy.bounds = spawn_bounds
	if spawn_bounds.has_area():
		enemy.position = enemy.position.clamp(spawn_bounds.position + Vector2.ONE * enemy.radius, spawn_bounds.end - Vector2.ONE * enemy.radius)
	enemy.add_to_group("raid_enemies")
	enemy.died.connect(func(e: Enemy): enemy_died.emit(e))
	enemy_parent.add_child(enemy)
	return enemy


func _open_chest() -> void:
	chest_opened_already = true
	if chest_loot.is_empty():
		_roll_chest()
	var loot := chest_loot
	chest_opened.emit(chest_position() + Vector2(0, 50), loot)


## Remove everything this raid spawned (used when leaving).
func tear_down() -> void:
	for enemy in get_tree().get_nodes_in_group("raid_enemies"):
		enemy.queue_free()
	queue_free()


# --- Drawing ---

func _draw() -> void:
	var floor_color: Color = RAIDS[raid_id].floor
	for corridor in corridors:
		draw_rect(corridor.grow(10), WALL)
		draw_rect(corridor, floor_color)
	for room in rooms:
		_draw_room(room, floor_color)


func _draw_room(room: Dictionary, floor_color: Color) -> void:
	var rect: Rect2 = room.rect
	var accent: Color = RAIDS[raid_id].accent
	draw_rect(rect.grow(14), WALL)
	draw_rect(rect, floor_color)
	# Flagstone grid
	var tile := 48.0
	var x := rect.position.x + tile
	while x < rect.end.x:
		draw_line(Vector2(x, rect.position.y), Vector2(x, rect.end.y), floor_color.darkened(0.25), 1.0)
		x += tile
	var y := rect.position.y + tile
	while y < rect.end.y:
		draw_line(Vector2(rect.position.x, y), Vector2(rect.end.x, y), floor_color.darkened(0.25), 1.0)
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
			draw_string(ThemeDB.fallback_font, rect.position + Vector2(0, 70), raid_name(),
					HORIZONTAL_ALIGNMENT_CENTER, rect.size.x, 30, accent)
			draw_string(ThemeDB.fallback_font, rect.position + Vector2(0, 100), "Head east. Each room seals until its boss falls.",
					HORIZONTAL_ALIGNMENT_CENTER, rect.size.x, 14, Color(0.75, 0.75, 0.75))
		"olm":
			var wall := Rect2(rect.position, Vector2(rect.size.x, OLM_WALL))
			draw_rect(wall, Color(0.16, 0.2, 0.18))
			for k in 14:
				var cx := rect.position.x + 40 + k * 78.0
				draw_colored_polygon(PackedVector2Array([Vector2(cx - 10, wall.end.y), Vector2(cx, wall.end.y - 30 - (k % 3) * 12),
						Vector2(cx + 10, wall.end.y)]), Color(0.45, 0.65, 0.58))
		"wardens":
			# Raised sandstone dais with a pedestal for each Warden and a throne between.
			var dais := Rect2(rect.position, Vector2(rect.size.x, WARDEN_DAIS))
			draw_rect(dais, accent.darkened(0.45))
			draw_rect(Rect2(dais.position.x, dais.end.y - 10, dais.size.x, 10), accent.darkened(0.6))
			var mid := rect.get_center().x
			for px in [mid - WARDEN_PEDESTAL_X, mid + WARDEN_PEDESTAL_X]:
				draw_rect(Rect2(px - 50, dais.position.y + 25, 100, 80), accent.darkened(0.3))
			draw_rect(Rect2(mid - 60, dais.position.y + 12, 120, 100), accent.darkened(0.2))
			draw_colored_polygon(PackedVector2Array([Vector2(mid - 60, dais.position.y + 12), Vector2(mid, dais.position.y - 10),
					Vector2(mid + 60, dais.position.y + 12)]), accent)
		"chest":
			_draw_chest(rect.get_center())


func _draw_chest(c: Vector2) -> void:
	if chest_had_purple:
		# The famous purple light, visible as soon as the final boss falls.
		var pulse := 0.1 * sin(time * 5.0)
		draw_rect(Rect2(c + Vector2(-34, -420), Vector2(68, 420)), Color(0.8, 0.3, 1.0, 0.18 + pulse * 0.5))
		draw_rect(Rect2(c + Vector2(-14, -420), Vector2(28, 420)), Color(0.85, 0.4, 1.0, 0.45 + pulse))
		draw_rect(Rect2(c + Vector2(-4, -420), Vector2(8, 420)), Color(1, 0.85, 1.0, 0.7 + pulse))
		draw_circle(c + Vector2(0, -6), 40.0, Color(0.8, 0.3, 1.0, 0.25 + pulse))
	var wood := Color(0.45, 0.28, 0.12)
	draw_rect(Rect2(c + Vector2(-26, -8), Vector2(52, 28)), wood)
	draw_rect(Rect2(c + Vector2(-26, -8), Vector2(52, 28)), Color(0.85, 0.7, 0.3), false, 2.0)
	var lid_y := -30.0 if chest_opened_already else -20.0
	draw_rect(Rect2(c + Vector2(-26, lid_y), Vector2(52, 12)), wood.lightened(0.1))
	draw_rect(Rect2(c + Vector2(-5, -6), Vector2(10, 10)), Color(0.85, 0.7, 0.3))
	if not chest_opened_already:
		draw_string(ThemeDB.fallback_font, c + Vector2(-80, -40), "Walk here to claim",
				HORIZONTAL_ALIGNMENT_CENTER, 160, 13, Color(1, 0.9, 0.6))


func _roll_chest() -> void:
	chest_loot = Items.raid_chest_loot(raid_id, realm)
	chest_had_purple = chest_loot.any(func(item): return item.tier == Items.GIGA)
