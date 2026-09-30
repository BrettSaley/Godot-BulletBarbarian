extends Enemy
## The Great Olm's head, the final boss of the Chambers of Xeric. It sits in
## the north wall firing alternating ranged and magic orbs, spraying acid
## pools, and trapping you between walls of fire. The fight has three phases:
## in phases 1 and 2 only the hands can be hurt, and when both fall the Olm
## rises again with fresh hands (the raid respawns them). In phase 3 the head
## becomes vulnerable once the hands are dead.

const ACID := Color(0.45, 0.8, 0.2)
const FIRE := Color(1.0, 0.45, 0.1)
const RANGED := Color(0.4, 0.85, 0.35)
const MAGIC := Color(0.4, 0.55, 1.0)
const FINAL_PHASE := 3
## Fire walls come at most this often.
const FIRE_WALL_COOLDOWN := 25.0

## Set by the raid.
var hands: Array = []
var room: Rect2
var phase := 1
var magic_next := false
var enraged := false
var fire_wall_timer := FIRE_WALL_COOLDOWN


func _init() -> void:
	display_name = "Great Olm"
	radius = 50.0
	move_speed = 0.0
	max_hp = 1500.0
	xp = 800
	bullet_damage = 28.0
	contact_damage = 50.0
	is_boss = true
	drops_loot = false
	aggro_range = 2000.0
	projectile_style = Projectiles.Style.ORB


func hands_alive() -> bool:
	return hands.any(func(h): return is_instance_valid(h) and h.hp > 0.0)


func _attacks() -> Array:
	# Fire walls are the Olm's big move: only once the cooldown has passed.
	return ["orbs", "orbs", "acid"] if fire_wall_timer > 0.0 else ["orbs", "orbs", "acid", "fire_wall"]


func _move(delta: float) -> void:
	fire_wall_timer -= delta
	var protected := phase < FINAL_PHASE or hands_alive()
	if untargetable and not protected:
		enraged = true
		difficulty = 1.0
		DamageText.spawn(get_parent(), position + Vector2(0, 70), "The Great Olm is vulnerable!", Color(1, 0.8, 0.3), 18)
	untargetable = protected


func _fire(attack_name: String) -> float:
	# Each phase attacks a little faster, and faster again once enraged.
	var pace := (1.0 - 0.12 * (phase - 1)) * (0.75 if enraged else 1.0)
	match attack_name:
		"orbs":
			magic_next = not magic_next
			fan(position, dir_to_player(position), 2, 0.18, 190.0, 8.0, MAGIC if magic_next else RANGED)
			return 0.6 * pace
		"acid":
			for i in 6:
				var at := Vector2(randf_range(room.position.x + 40, room.end.x - 40), randf_range(room.position.y + 150, room.end.y - 40))
				hazards().pool(at, 34.0, 8.0, bullet_damage * 1.4, "Great Olm's acid", ACID)
			return 2.0 * pace
		"fire_wall":
			# Walls of fire on both sides of the player: don't touch them.
			fire_wall_timer = FIRE_WALL_COOLDOWN
			for offset in [-90.0, 90.0]:
				var x: float = player.position.x + offset
				hazards().rect_pool(Rect2(x - 12, room.position.y + 120, 24, room.size.y - 120), 5.0,
						bullet_damage * 3.0, "Great Olm's fire wall", FIRE)
			return 3.0 * pace
	return 1.0


## A giant pale salamander head bursting from the crystal wall.
func _draw() -> void:
	var skin := Color(0.5, 0.58, 0.48)
	var skin_dark := Color(0.33, 0.4, 0.33)
	var belly := Color(0.7, 0.72, 0.58)
	var crystal := Color(0.45, 0.85, 0.8)
	var dark := Color(0.08, 0.1, 0.08)
	var breathe := 1.0 + sin(time * 1.6) * 0.02
	draw_set_transform(Vector2.ZERO, 0.0, Vector2(1.0, breathe))

	# Crystal crown behind the head
	for k in 7:
		var x := -54.0 + k * 18.0
		var h := 26.0 + (k % 3) * 12.0
		draw_colored_polygon(PackedVector2Array([Vector2(x - 9, -44), Vector2(x - 2, -44 - h), Vector2(x + 9, -44)]), crystal.darkened(0.15))
		draw_colored_polygon(PackedVector2Array([Vector2(x - 2, -44 - h), Vector2(x + 9, -44), Vector2(x + 1, -44)]), crystal.lightened(0.35))

	# Broad, rounded head
	var head := PackedVector2Array([Vector2(-78, -8), Vector2(-70, -34), Vector2(-46, -52), Vector2(0, -58), Vector2(46, -52),
			Vector2(70, -34), Vector2(78, -8), Vector2(66, 20), Vector2(38, 42), Vector2(0, 50), Vector2(-38, 42), Vector2(-66, 20)])
	var outline := PackedVector2Array()
	for p in head:
		outline.append(p * 1.04)
	draw_colored_polygon(outline, dark)
	draw_colored_polygon(head, skin)
	# Pale lower jaw and throat
	draw_colored_polygon(PackedVector2Array([Vector2(-50, 14), Vector2(50, 14), Vector2(34, 40), Vector2(0, 47), Vector2(-34, 40)]), belly)
	# Mottled speckles
	for s in [Vector2(-52, -30), Vector2(-40, -42), Vector2(44, -38), Vector2(56, -22), Vector2(-60, 4), Vector2(62, 6), Vector2(0, -44), Vector2(-14, -36), Vector2(18, -46)]:
		draw_circle(s, 3.5, skin_dark)
	# Cheek crystals
	for side in [-1.0, 1.0]:
		draw_colored_polygon(PackedVector2Array([Vector2(side * 70, 0), Vector2(side * 90, -14), Vector2(side * 78, 12)]), crystal)

	# Heavy brow ridges
	for side in [-1.0, 1.0]:
		draw_colored_polygon(PackedVector2Array([Vector2(side * 12, -24), Vector2(side * 52, -30), Vector2(side * 50, -20), Vector2(side * 14, -16)]), skin_dark)

	# Eyes: slit pupils, glowing once vulnerable, heavy-lidded while shielded
	var vulnerable := not untargetable
	var iris := Color(0.95, 0.85, 0.2) if vulnerable else Color(0.7, 0.75, 0.35)
	for side in [-1.0, 1.0]:
		var eye := Vector2(side * 32, -8)
		if vulnerable:
			draw_circle(eye, 17.0, Color(1, 0.85, 0.2, 0.25 + 0.1 * sin(time * 6.0)))
		draw_set_transform(eye * Vector2(1, breathe), 0.0, Vector2(1.0, 0.72 * breathe))
		draw_circle(Vector2.ZERO, 14.0, dark)
		draw_circle(Vector2.ZERO, 11.5, iris)
		draw_set_transform(eye * Vector2(1, breathe), 0.0, Vector2(0.25, 0.72 * breathe))
		draw_circle(Vector2.ZERO, 10.0, dark)
		draw_set_transform(Vector2.ZERO, 0.0, Vector2(1.0, breathe))
		draw_circle(eye + Vector2(-4, -4), 2.5, Color(1, 1, 1, 0.85))
		if not vulnerable:
			# Drooping lid over the top of the eye
			draw_colored_polygon(PackedVector2Array([eye + Vector2(-15, -12), eye + Vector2(15, -12), eye + Vector2(15, 1), eye + Vector2(-15, 1)]), skin_dark)

	# Nostrils
	draw_circle(Vector2(-9, 6), 3.0, dark)
	draw_circle(Vector2(9, 6), 3.0, dark)
	# Wide mouth with jagged teeth
	var mouth := PackedVector2Array([Vector2(-46, 16), Vector2(-24, 23), Vector2(0, 25), Vector2(24, 23), Vector2(46, 16)])
	draw_polyline(mouth, dark, 3.0)
	for t in 8:
		var x := -35.0 + t * 10.0
		var y := 22.0 + (1.5 if absf(x) < 20 else 0.0)
		draw_colored_polygon(PackedVector2Array([Vector2(x - 3, y), Vector2(x + 3, y), Vector2(x, y + 6)]), Color(0.95, 0.93, 0.85))
	draw_set_transform(Vector2.ZERO)

	# Crystal barrier while shielded
	if untargetable:
		draw_arc(Vector2.ZERO, 92.0, 0.0, TAU, 48, Color(0.6, 0.9, 1.0, 0.3 + 0.15 * sin(time * 4.0)), 4.0)
	draw_string(ThemeDB.fallback_font, Vector2(-60, 72), "Phase %d / %d" % [phase, FINAL_PHASE],
			HORIZONTAL_ALIGNMENT_CENTER, 120, 13, Color(1, 0.9, 0.7))
	draw_health_bar(60.0)
