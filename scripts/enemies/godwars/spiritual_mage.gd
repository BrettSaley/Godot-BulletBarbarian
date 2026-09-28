extends Enemy
## Spiritual Mage (OSRS, God Wars): a Saradominist priest casting spirals of
## holy light and calling down smites where you stand.

const HOLY := Color(1.0, 0.95, 0.6)

var spiral_angle := 0.0


func _init() -> void:
	display_name = "Spiritual Mage"
	radius = 13.0
	move_speed = 70.0
	max_hp = 140.0
	xp = 26
	bullet_damage = 18.0
	contact_damage = 15.0
	preferred_range = 300.0
	projectile_style = Projectiles.Style.ORB


func _attacks() -> Array:
	return ["holy_spiral", "smite"]


func _fire(attack_name: String) -> float:
	match attack_name:
		"holy_spiral":
			spiral_angle += 0.45
			for i in 3:
				shoot(position, Vector2.from_angle(spiral_angle + TAU * i / 3.0) * 130.0, 5.0, HOLY)
			return 0.16
		"smite":
			hazards().blast(player.position, 50.0, 1.0, bullet_damage * 2.0, display_name, HOLY)
			return 1.2
	return 1.0


func _draw() -> void:
	var robe := Color(0.92, 0.92, 0.95)
	var trim := Color(0.3, 0.45, 0.9)
	draw_set_transform(Vector2(0, 13), 0.0, Vector2(1.0, 0.35))
	draw_circle(Vector2.ZERO, 10.0, Color(0, 0, 0, 0.3))
	draw_set_transform(Vector2(0, sin(time * 3.0) * 1.5))
	# Staff topped with a holy star
	draw_line(Vector2(10, 12), Vector2(10, -14), Color(0.8, 0.7, 0.35), 2.0)
	draw_circle(Vector2(10, -16), 4.5 if is_attacking() else 3.0, HOLY)
	# White robe with blue trim, hooded head
	draw_colored_polygon(PackedVector2Array([Vector2(-8, 12), Vector2(-5, -2), Vector2(5, -2), Vector2(8, 12)]), robe)
	draw_line(Vector2(0, -2), Vector2(0, 12), trim, 2.0)
	draw_circle(Vector2(0, -6), 6.5, Color(0.95, 0.8, 0.65))
	var hood := PackedVector2Array()
	for i in 9:
		hood.append(Vector2(0, -7) + Vector2.from_angle(PI + PI * i / 8.0) * 8.0)
	draw_colored_polygon(hood, trim)
	draw_circle(Vector2(-2.5, -6), 1.2, Color(0.1, 0.1, 0.2))
	draw_circle(Vector2(2.5, -6), 1.2, Color(0.1, 0.1, 0.2))
	draw_set_transform(Vector2.ZERO)
	draw_health_bar(18.0)
