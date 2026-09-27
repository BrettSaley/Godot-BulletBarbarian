extends Enemy
## One of the Great Olm's hands, reaching out of the wall beside its head.
##   Left claw  - crystal bursts under your feet and crystal shockwaves
##   Right hand - lightning strips across the room and falling crystals
## Both hands must die before the head can be hurt.

const CRYSTAL := Color(0.6, 0.85, 0.75)
const LIGHTNING := Color(0.6, 0.8, 1.0)

## "left" or "right". Set by the raid, along with the room rectangle.
var side := "left"
var room: Rect2
var clench := 0.0


func _init() -> void:
	radius = 34.0
	move_speed = 0.0
	max_hp = 1000.0
	xp = 300
	bullet_damage = 26.0
	contact_damage = 45.0
	drops_loot = false
	size_scale = 1.1
	aggro_range = 2000.0
	projectile_style = Projectiles.Style.ORB


func set_side(new_side: String) -> void:
	side = new_side
	display_name = "Great Olm (left claw)" if side == "left" else "Great Olm (right hand)"


func _attacks() -> Array:
	return ["crystal_burst", "shockwave"] if side == "left" else ["lightning", "falling_crystals"]


func _move(delta: float) -> void:
	clench = maxf(clench - delta * 2.0, 0.0)


func _fire(attack_name: String) -> float:
	match attack_name:
		"crystal_burst":
			clench = 1.0
			hazards().blast(player.position, 45.0, 1.0, bullet_damage * 2.0, "Great Olm's crystals", CRYSTAL)
			for i in 2:
				hazards().blast(player.position + Vector2.from_angle(randf() * TAU) * 90.0, 45.0, 1.0,
						bullet_damage * 2.0, "Great Olm's crystals", CRYSTAL)
			return 1.2
		"shockwave":
			clench = 1.0
			ring(position, 14, 120.0, 7.0, CRYSTAL)
			return 1.4
		"lightning":
			# Two horizontal strips of lightning; stand between them.
			for i in 2:
				var y := randf_range(room.position.y + 140, room.end.y - 40)
				hazards().rect_blast(Rect2(room.position.x, y - 25, room.size.x, 50), 1.3,
						bullet_damage * 2.5, "Great Olm's lightning", LIGHTNING)
			return 1.8
		"falling_crystals":
			hazards().blast(player.position, 40.0, 1.2, bullet_damage * 2.0, "Great Olm's falling crystals", CRYSTAL)
			for i in 5:
				var at := Vector2(randf_range(room.position.x + 40, room.end.x - 40), randf_range(room.position.y + 140, room.end.y - 40))
				hazards().blast(at, 40.0, 1.2, bullet_damage * 2.0, "Great Olm's falling crystals", CRYSTAL)
			return 1.2
	return 1.0


func _draw() -> void:
	var skin := Color(0.35, 0.42, 0.38)
	var tip := CRYSTAL if side == "left" else LIGHTNING
	var mirror := -1.0 if side == "left" else 1.0
	draw_set_transform(Vector2.ZERO, 0.0, Vector2(mirror, 1.0))
	# Forearm coming out of the wall above
	draw_rect(Rect2(Vector2(-14, -60), Vector2(28, 44)), skin.darkened(0.2))
	draw_circle(Vector2.ZERO, 26.0, skin)
	# Four fingers, curled in when clenching
	for f in 4:
		var base := Vector2(-18 + f * 12, 14)
		var length := 20.0 * (1.0 - clench * 0.6)
		draw_line(base, base + Vector2(f * 2 - 3, length), skin.darkened(0.1), 7.0)
		draw_circle(base + Vector2(f * 2 - 3, length), 4.0, tip)
	# Crystal growths on the back of the hand
	draw_colored_polygon(PackedVector2Array([Vector2(-8, -10), Vector2(-2, -30), Vector2(4, -8)]), tip)
	draw_colored_polygon(PackedVector2Array([Vector2(6, -6), Vector2(14, -22), Vector2(16, -2)]), tip.darkened(0.2))
	draw_set_transform(Vector2.ZERO)
	draw_health_bar(46.0)
