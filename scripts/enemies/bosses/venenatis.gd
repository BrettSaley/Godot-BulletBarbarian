extends Enemy
## Venenatis (OSRS, the Wilderness). A giant spider that spins webs that slow
## you to a crawl, spits venom, and calls its spiderlings.

const VENOM := Color(0.55, 0.85, 0.2)
const WEB := Color(0.9, 0.9, 0.9)


func _init() -> void:
	display_name = "Venenatis"
	radius = 32.0
	move_speed = 95.0
	max_hp = 1700.0
	xp = 600
	bullet_damage = 30.0
	contact_damage = 45.0
	is_boss = true
	aggro_range = 650.0
	preferred_range = 220.0
	projectile_style = Projectiles.Style.ORB


func _attacks() -> Array:
	return ["venom", "webs", "brood"]


func _fire(attack_name: String) -> float:
	match attack_name:
		"venom":
			fan(position, dir_to_player(position), 2, 0.16, 190.0, 7.0, VENOM)
			return 0.6
		"webs":
			for i in 3:
				hazards().pool(player.position + Vector2.from_angle(randf() * TAU) * randf_range(0, 90), 50.0, 6.0,
						0.0, "Venenatis's web", WEB, 0.6)
			hazards().blast(player.position, 45.0, 1.2, bullet_damage * 2.0, display_name, VENOM)
			return 1.8
		"brood":
			for i in 3:
				summon(Minion.make("spiderling"), position + Vector2.from_angle(TAU * i / 3.0) * 40.0)
			return 99.0
	return 1.0


func _draw() -> void:
	var body := Color(0.2, 0.16, 0.24)
	var mark := Color(0.7, 0.2, 0.3)
	draw_set_transform(Vector2(0, 30), 0.0, Vector2(1.4, 0.35))
	draw_circle(Vector2.ZERO, 30.0, Color(0, 0, 0, 0.3))
	draw_set_transform(Vector2.ZERO)
	# Eight legs scuttling
	for side in [-1.0, 1.0]:
		for leg in 4:
			var base := Vector2(side * 14, -10 + leg * 8)
			var knee := base + Vector2(side * 22, -14 + leg * 4 + sin(time * 10.0 + leg) * 3.0)
			var foot := knee + Vector2(side * 14, 20)
			draw_line(base, knee, body.lightened(0.1), 4.0)
			draw_line(knee, foot, body.lightened(0.1), 3.0)
	# Abdomen with a red marking, head with a cluster of eyes and fangs
	draw_circle(Vector2(0, 16), 22.0, body)
	draw_colored_polygon(PackedVector2Array([Vector2(0, 6), Vector2(8, 16), Vector2(0, 28), Vector2(-8, 16)]), mark)
	draw_circle(Vector2(0, -12), 15.0, body.lightened(0.05))
	for e in 6:
		draw_circle(Vector2(-7.5 + (e % 3) * 7.5, -18 + (e / 3) * 6), 2.5 if e / 3 == 0 else 1.8, Color(0.9, 0.2, 0.3))
	draw_colored_polygon(PackedVector2Array([Vector2(-6, -2), Vector2(-2, -2), Vector2(-5, 8)]), VENOM)
	draw_colored_polygon(PackedVector2Array([Vector2(2, -2), Vector2(6, -2), Vector2(5, 8)]), VENOM)
	draw_health_bar(44.0)
