extends Enemy
## Chaos Druid (OSRS, the Chaos Temple): hurls bolts of chaotic magic and
## snares the ground around you with grasping vines that slow you down.

const CHAOS := Color(0.55, 0.85, 0.3)
const VINES := Color(0.3, 0.55, 0.2)


func _init() -> void:
	display_name = "Chaos Druid"
	radius = 13.0
	move_speed = 75.0
	max_hp = 130.0
	xp = 24
	bullet_damage = 18.0
	contact_damage = 15.0
	preferred_range = 280.0
	projectile_style = Projectiles.Style.ORB


func _attacks() -> Array:
	return ["bolts", "entangle"]


func _fire(attack_name: String) -> float:
	match attack_name:
		"bolts":
			fan(position, dir_to_player(position), 1, 0.25, 170.0, 6.0, CHAOS)
			return 0.7
		"entangle":
			hazards().pool(player.position, 45.0, 4.0, bullet_damage * 0.5, "Chaos Druid's vines", VINES, 0.5)
			return 1.6
	return 1.0


func _draw() -> void:
	var robe := Color(0.25, 0.35, 0.18)
	draw_set_transform(Vector2(0, 13), 0.0, Vector2(1.0, 0.35))
	draw_circle(Vector2.ZERO, 10.0, Color(0, 0, 0, 0.3))
	draw_set_transform(Vector2(0, sin(time * 3.0) * 1.5))
	draw_line(Vector2(-10, 12), Vector2(-10, -14), Color(0.45, 0.3, 0.15), 2.0)
	draw_circle(Vector2(-10, -15), 3.5 if is_attacking() else 2.5, CHAOS)
	draw_colored_polygon(PackedVector2Array([Vector2(-8, 12), Vector2(-5, -2), Vector2(5, -2), Vector2(8, 12)]), robe)
	draw_circle(Vector2(0, -6), 6.5, Color(0.9, 0.75, 0.6))
	# Long white beard and a deep hood
	draw_colored_polygon(PackedVector2Array([Vector2(-5, -4), Vector2(5, -4), Vector2(0, 8)]), Color(0.92, 0.92, 0.92))
	var hood := PackedVector2Array()
	for i in 9:
		hood.append(Vector2(0, -7) + Vector2.from_angle(PI + PI * i / 8.0) * 8.0)
	draw_colored_polygon(hood, robe.darkened(0.25))
	draw_circle(Vector2(-2.5, -7), 1.3, Color(0.8, 1, 0.3))
	draw_circle(Vector2(2.5, -7), 1.3, Color(0.8, 1, 0.3))
	draw_set_transform(Vector2.ZERO)
	draw_health_bar(18.0)
