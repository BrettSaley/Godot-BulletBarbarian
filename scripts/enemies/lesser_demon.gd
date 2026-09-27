extends Enemy
## Lesser Demon (OSRS, the Wilderness): stalks you through fire, throwing
## rings of flame and triple fire blasts.

const FIRE := Color(1.0, 0.35, 0.15)


func _init() -> void:
	display_name = "Lesser Demon"
	radius = 17.0
	move_speed = 95.0
	max_hp = 260.0
	xp = 45
	bullet_damage = 22.0
	contact_damage = 35.0
	preferred_range = 180.0
	aggro_range = 500.0
	projectile_style = Projectiles.Style.ORB


func _attacks() -> Array:
	return ["flame_ring", "fire_blast"]


func _fire(attack_name: String) -> float:
	match attack_name:
		"flame_ring":
			ring(position, int(lerpf(12, 18, difficulty)), 120.0, 6.0, FIRE)
			return 0.9
		"fire_blast":
			fan(position, dir_to_player(position), 1, 0.15, 190.0, 8.0, FIRE.lightened(0.2))
			return 0.6
	return 1.0


func _draw() -> void:
	var red := Color(0.7, 0.12, 0.1)
	var dark := Color(0.2, 0.03, 0.03)
	draw_set_transform(Vector2(0, 20), 0.0, Vector2(1.0, 0.35))
	draw_circle(Vector2.ZERO, 16.0, Color(0, 0, 0, 0.3))
	var bob := sin(time * 4.0) * 1.5
	draw_set_transform(Vector2(0, bob))
	# Bat wings
	for side in [-1.0, 1.0]:
		draw_colored_polygon(PackedVector2Array([Vector2(side * 8, -6), Vector2(side * 28, -20), Vector2(side * 24, -6),
				Vector2(side * 30, 2), Vector2(side * 12, 4)]), dark)
	# Legs, body, arms with claws
	draw_line(Vector2(-5, 10), Vector2(-7, 19), red.darkened(0.2), 4.0)
	draw_line(Vector2(5, 10), Vector2(7, 19), red.darkened(0.2), 4.0)
	draw_circle(Vector2(0, 2), 11.0, red)
	for side in [-1.0, 1.0]:
		draw_line(Vector2(side * 9, 0), Vector2(side * 15, 8), red, 3.5)
		draw_line(Vector2(side * 15, 8), Vector2(side * 18, 11), Color(0.95, 0.9, 0.8), 1.5)
	# Horned head, glowing eyes, fangs
	draw_colored_polygon(PackedVector2Array([Vector2(-6, -15), Vector2(-11, -26), Vector2(-3, -17)]), Color(0.3, 0.25, 0.2))
	draw_colored_polygon(PackedVector2Array([Vector2(6, -15), Vector2(11, -26), Vector2(3, -17)]), Color(0.3, 0.25, 0.2))
	draw_circle(Vector2(0, -12), 8.0, red)
	var eye := Color(1, 0.9, 0.2) if is_attacking() else Color(1, 0.6, 0.1)
	draw_circle(Vector2(-3, -13), 1.8, eye)
	draw_circle(Vector2(3, -13), 1.8, eye)
	draw_colored_polygon(PackedVector2Array([Vector2(-3, -8), Vector2(-1.5, -8), Vector2(-2.2, -5)]), Color(1, 1, 1))
	draw_colored_polygon(PackedVector2Array([Vector2(1.5, -8), Vector2(3, -8), Vector2(2.2, -5)]), Color(1, 1, 1))
	draw_set_transform(Vector2.ZERO)
	draw_health_bar(22.0)
