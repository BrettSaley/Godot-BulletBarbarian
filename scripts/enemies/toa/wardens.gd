extends Enemy
## The Wardens (Tombs of Amascut), the final boss. Two Wardens - Elidinis'
## (blue) and Tumeken's (gold) - stand on the dais along the north wall:
##   1 Obelisk: both Wardens lie dormant while the Obelisk shields them.
##   2 One Warden leaps down and fights you on the floor. Its partner stays on
##     the dais, immune, casting specials: exploding floor tiles, lightning
##     lanes and skull rain.
##   3 When the first falls, the survivor takes the throne at the top centre
##     (like the Great Olm) and fights from there, lighting up the floor in
##     tile patterns - faster once it's below 35% health.

const DIVINE := Color(1.0, 0.85, 0.35)
const ELIDINIS := Color(0.4, 0.7, 1.0)
const CELL := 90.0
const TILE_DELAY := 1.4
const ENRAGE_BELOW := 0.35
const ACTIVE_SPEED := 95.0
const THRONE_SPEED := 260.0

## Set by the raid.
var room: Rect2
## The walkable floor below the dais.
var floor_rect: Rect2
var obelisk: Enemy
var partner: Enemy
## This Warden is the one that comes down to fight first.
var leads := false
var pedestal: Vector2
var throne: Vector2
var kind := "tumeken"

var role := "dormant"
var tile_timer := 2.0


func _init() -> void:
	radius = 30.0
	move_speed = 0.0
	max_hp = 2000.0
	xp = 900
	bullet_damage = 34.0
	contact_damage = 55.0
	is_boss = true
	drops_loot = false
	aggro_range = 2000.0
	preferred_range = 220.0
	projectile_style = Projectiles.Style.ORB
	invulnerable = true


func set_kind(new_kind: String) -> void:
	kind = new_kind
	display_name = "Elidinis' Warden" if kind == "elidinis" else "Tumeken's Warden"


func color() -> Color:
	return ELIDINIS if kind == "elidinis" else DIVINE


func _current_role() -> String:
	if is_instance_valid(obelisk) and obelisk.hp > 0.0:
		return "dormant"
	if is_instance_valid(partner) and partner.hp > 0.0:
		return "active" if leads else "casting"
	return "final"


func _move(delta: float) -> void:
	var next := _current_role()
	if next != role:
		_enter_role(next)
	match role:
		"active":
			super._move(delta)
		"final":
			if position.distance_to(throne) > 2.0:
				position = position.move_toward(throne, THRONE_SPEED * delta)
			elif invulnerable:
				invulnerable = false
				DamageText.spawn(get_parent(), position + Vector2(0, 70), "The Warden takes the throne!", color(), 18)
			tile_timer -= delta
			if tile_timer <= 0.0 and not invulnerable:
				tile_timer = 1.9 if enraged() else 2.7
				_tiles(0.5 if enraged() else 0.42)


func _enter_role(next: String) -> void:
	role = next
	attack = ""
	rest_timer = 1.0
	match role:
		"active":
			# Leap down off the dais onto the floor.
			invulnerable = false
			move_speed = ACTIVE_SPEED
			position = Vector2(position.x, floor_rect.position.y + 90.0)
			bounds = floor_rect
			DamageText.spawn(get_parent(), position + Vector2(0, -70), "%s awakens!" % display_name, color(), 18)
		"casting":
			invulnerable = true
			move_speed = 0.0
		"final":
			# Walk to the throne, immune until it arrives.
			invulnerable = true
			move_speed = 0.0
			bounds = Rect2()
			tile_timer = 2.0
			DamageText.spawn(get_parent(), position + Vector2(0, -70), "%s rises to the throne!" % display_name, color(), 18)


func enraged() -> bool:
	return role == "final" and hp / max_hp < ENRAGE_BELOW


func _attacks() -> Array:
	match role:
		"active":
			return ["slam", "skulls", "ring"]
		"casting":
			return ["tiles", "lightning", "skull_rain"]
		"final":
			return ["lightning", "skulls", "ring", "slam", "skull_rain"]
	return ["wait"]


func _fire(attack_name: String) -> float:
	var pace := 0.75 if enraged() else 1.0
	match attack_name:
		"slam":
			hazards().blast(player.position, 70.0, 1.1, bullet_damage * 2.5, "%s's slam" % display_name, color())
			return 1.1 * pace
		"skulls":
			fan(position, dir_to_player(position), 3, 0.15, 210.0, 8.0, color().lightened(0.2))
			return 0.55 * pace
		"ring":
			ring(position, 16, 150.0, 7.0, color())
			return 1.0 * pace
		"tiles":
			_tiles(0.35)
			return 3.2
		"lightning":
			_lightning()
			return 2.2 * pace
		"skull_rain":
			for i in 6:
				var at := player.position + Vector2.from_angle(randf() * TAU) * randf_range(0.0, 170.0)
				hazards().blast(_on_floor(at), 42.0, 1.2, bullet_damage * 2.0, "Skull rain", color().lightened(0.3))
			return 3.0 * pace
	return 3.0


## A pattern of floor tiles lights up, then explodes: random tiles, a
## checkerboard, or every other column. There's always a safe tile to step to.
func _tiles(density: float) -> void:
	var cols := int(floor_rect.size.x / CELL)
	var rows := int(floor_rect.size.y / CELL)
	var origin := floor_rect.position + (floor_rect.size - Vector2(cols, rows) * CELL) / 2.0
	var player_cell := Vector2i(((player.position - origin) / CELL).floor())
	var step: Vector2i = [Vector2i(1, 0), Vector2i(-1, 0), Vector2i(0, 1), Vector2i(0, -1)].pick_random()
	var safe := player_cell + step
	var pattern := randi() % 3
	var parity := randi() % 2
	for c in cols:
		for r in rows:
			var lit := false
			match pattern:
				0:
					lit = randf() < density and Vector2i(c, r) != safe
				1:
					lit = (c + r) % 2 == parity
				2:
					lit = c % 2 == parity
			if lit:
				hazards().rect_blast(Rect2(origin + Vector2(c, r) * CELL, Vector2(CELL, CELL)), TILE_DELAY,
						bullet_damage * 2.0, "The Wardens' floor", color())


## Two strips of divine lightning through the player: one across, one down.
func _lightning() -> void:
	var at := _on_floor(player.position)
	hazards().rect_blast(Rect2(floor_rect.position.x, at.y - 30, floor_rect.size.x, 60), 1.2,
			bullet_damage * 2.5, "Divine lightning", ELIDINIS if kind == "tumeken" else DIVINE)
	hazards().rect_blast(Rect2(at.x - 30, floor_rect.position.y, 60, floor_rect.size.y), 1.6,
			bullet_damage * 2.5, "Divine lightning", ELIDINIS if kind == "tumeken" else DIVINE)


func _on_floor(point: Vector2) -> Vector2:
	return point.clamp(floor_rect.position + Vector2(30, 30), floor_rect.end - Vector2(30, 30))


func _draw() -> void:
	var stone := Color(0.55, 0.5, 0.42) if kind == "tumeken" else Color(0.45, 0.48, 0.52)
	var glow := color()
	var awake := role != "dormant"
	var core := glow if awake else stone.darkened(0.2)
	var s := 1.25 if role == "final" else 1.0
	draw_set_transform(Vector2(0, 36 * s), 0.0, Vector2(1.3 * s, 0.3 * s))
	draw_circle(Vector2.ZERO, 30.0, Color(0, 0, 0, 0.3))
	draw_set_transform(Vector2(0, sin(time * 2.0) * 2.0), 0.0, Vector2(s, s))
	if role == "casting":
		# Channelling: a slow ring of light while it casts from the dais.
		draw_arc(Vector2.ZERO, 50.0, time * 1.5, time * 1.5 + TAU * 0.75, 32, Color(glow, 0.7), 3.0)
	elif invulnerable:
		draw_arc(Vector2.ZERO, 46.0, 0.0, TAU, 40, Color(ELIDINIS, 0.5 + 0.2 * sin(time * 5.0)), 3.0)
	# Towering statue body with a glowing core
	draw_colored_polygon(PackedVector2Array([Vector2(-22, 34), Vector2(-26, -6), Vector2(-14, -18), Vector2(14, -18),
			Vector2(26, -6), Vector2(22, 34)]), stone)
	draw_circle(Vector2(0, 4), 10.0 + (sin(time * 6.0) * 2.0 if enraged() else 0.0), core)
	for side in [-1.0, 1.0]:
		# Arms raised while casting from the dais
		var arm_y := -26.0 if role == "casting" else -10.0
		draw_rect(Rect2(Vector2(side * 26 - 6, arm_y), Vector2(12, 34)), stone.darkened(0.15))
		if role == "casting":
			draw_circle(Vector2(side * 26, arm_y - 4), 6.0 + sin(time * 8.0), glow)
	# Head with a crest: a sun disc for Tumeken, a crescent for Elidinis
	draw_colored_polygon(PackedVector2Array([Vector2(-12, -18), Vector2(-10, -40), Vector2(10, -40), Vector2(12, -18)]), stone.lightened(0.1))
	if kind == "tumeken":
		draw_circle(Vector2(0, -50), 9.0, core)
	else:
		draw_arc(Vector2(0, -48), 10.0, PI * 0.15, PI * 0.85, 12, core, 4.0)
	draw_circle(Vector2(-4, -30), 2.5, core)
	draw_circle(Vector2(4, -30), 2.5, core)
	draw_set_transform(Vector2.ZERO)
	var status := ""
	match role:
		"dormant":
			status = "Dormant"
		"casting":
			status = "IMMUNE - casting"
		"final":
			status = "ENRAGED" if enraged() else ("" if not invulnerable else "Rising...")
	if status != "":
		draw_string(ThemeDB.fallback_font, Vector2(-70, -66 * s), status, HORIZONTAL_ALIGNMENT_CENTER, 140, 11, glow)
	draw_health_bar(46.0 * s)
