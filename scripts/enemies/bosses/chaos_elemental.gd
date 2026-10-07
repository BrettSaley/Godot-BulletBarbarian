extends Enemy
## Chaos Elemental (OSRS, the Wilderness). A swirling mass of chaos that
## fires rainbow barrages, spirals of chaos ("madness"),
## and scatters exploding discord around you.

const COLORS := [Color(1, 0.3, 0.3), Color(0.3, 1, 0.4), Color(0.35, 0.5, 1), Color(1, 0.9, 0.3), Color(0.9, 0.4, 1)]

var spiral := 0.0


func _init() -> void:
	display_name = "Chaos Elemental"
	radius = 30.0
	move_speed = 90.0
	max_hp = 1600.0
	xp = 600
	bullet_damage = 30.0
	contact_damage = 40.0
	is_boss = true
	aggro_range = 650.0
	preferred_range = 240.0
	projectile_style = Projectiles.Style.ORB


func _attacks() -> Array:
	return ["rainbow", "madness", "discord"]


func _fire(attack_name: String) -> float:
	match attack_name:
		"rainbow":
			var offset := randf() * TAU
			for i in 15:
				shoot(position, Vector2.from_angle(offset + TAU * i / 15.0) * 135.0, 7.0, COLORS[i % COLORS.size()])
			return 0.7
		"madness":
			# A spiralling rainbow barrage. (It used to fling the player, but
			# overworld bosses never move the player into other monsters' shots.)
			spiral += 0.5
			for i in 3:
				shoot(position, Vector2.from_angle(spiral + TAU * i / 3.0) * 150.0, 7.0, COLORS[(i + int(spiral)) % COLORS.size()])
			return 0.12
		"discord":
			for i in 5:
				hazards().blast(player.position + Vector2.from_angle(randf() * TAU) * randf_range(0, 130), 45.0, 1.1,
						bullet_damage * 2.0, display_name, COLORS.pick_random())
			return 1.5
	return 1.0


func _draw() -> void:
	draw_set_transform(Vector2(0, 30), 0.0, Vector2(1.2, 0.3))
	draw_circle(Vector2.ZERO, 28.0, Color(0, 0, 0, 0.3))
	draw_set_transform(Vector2.ZERO)
	# A shifting knot of coloured blobs orbiting a dark core
	for k in 10:
		var angle := time * (1.5 + k * 0.1) + k * 0.9
		var r := 16.0 + sin(time * 2.0 + k) * 6.0
		draw_circle(Vector2.from_angle(angle) * r, 10.0 + sin(time * 3.0 + k) * 2.0, Color(COLORS[k % COLORS.size()], 0.85))
	draw_circle(Vector2.ZERO, 14.0, Color(0.1, 0.05, 0.12))
	draw_circle(Vector2(-5, -3), 3.0, Color(1, 1, 1))
	draw_circle(Vector2(5, -3), 3.0, Color(1, 1, 1))
	draw_health_bar(40.0)
