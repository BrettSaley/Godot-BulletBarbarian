extends Enemy
## Icefiend (OSRS, Trollheim): a small floating ice demon that flings rings
## and spreads of ice shards.

const ICE := Color(0.6, 0.85, 1.0)


func _init() -> void:
	display_name = "Icefiend"
	radius = 12.0
	move_speed = 85.0
	max_hp = 70.0
	xp = 14
	bullet_damage = 16.0
	contact_damage = 15.0
	preferred_range = 220.0
	projectile_style = Projectiles.Style.ORB


func _attacks() -> Array:
	return ["shards", "frost_ring"]


func _fire(attack_name: String) -> float:
	match attack_name:
		"shards":
			fan(position, dir_to_player(position), 1, 0.2, 170.0, 6.0, ICE)
			return 0.9
		"frost_ring":
			ring(position, 8, 120.0, 5.0, ICE.darkened(0.1))
			return 1.2
	return 1.0


func _draw() -> void:
	var float_y := sin(time * 4.0) * 2.0
	draw_set_transform(Vector2(0, 14), 0.0, Vector2(1.0, 0.35))
	draw_circle(Vector2.ZERO, 9.0, Color(0, 0, 0, 0.25))
	draw_set_transform(Vector2(0, float_y))
	# Jagged icy body with little horns
	var body := PackedVector2Array()
	for i in 10:
		var r := 11.0 if i % 2 == 0 else 7.5
		body.append(Vector2.from_angle(TAU * i / 10.0 - PI / 2.0) * r)
	draw_colored_polygon(body, ICE.darkened(0.15))
	draw_circle(Vector2.ZERO, 6.5, ICE.lightened(0.3))
	draw_colored_polygon(PackedVector2Array([Vector2(-6, -8), Vector2(-9, -16), Vector2(-3, -9)]), Color(0.9, 0.95, 1))
	draw_colored_polygon(PackedVector2Array([Vector2(6, -8), Vector2(9, -16), Vector2(3, -9)]), Color(0.9, 0.95, 1))
	draw_circle(Vector2(-2.5, -1), 1.6, Color(0.1, 0.2, 0.5))
	draw_circle(Vector2(2.5, -1), 1.6, Color(0.1, 0.2, 0.5))
	draw_set_transform(Vector2.ZERO)
	draw_health_bar(16.0)
