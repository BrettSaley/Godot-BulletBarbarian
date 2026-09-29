extends Enemy
## The Kraken (Kraken Cove). Lurks in the middle of its pool, whipping up
## whirlpool rings, firing water bolts, and slamming tentacles down around you.

const WATER := Color(0.35, 0.7, 0.95)

var room: Rect2


func _init() -> void:
	display_name = "Kraken"
	radius = 32.0
	move_speed = 0.0
	max_hp = 1200.0
	xp = 500
	bullet_damage = 26.0
	contact_damage = 45.0
	is_boss = true
	drops_loot = false
	aggro_range = 650.0
	projectile_style = Projectiles.Style.ORB


func _attacks() -> Array:
	return ["whirlpool", "bolts", "tentacles"]


func _fire(attack_name: String) -> float:
	match attack_name:
		"whirlpool":
			ring(position, 16, 120.0, 7.0, WATER)
			return 0.9
		"bolts":
			fan(position, dir_to_player(position), 2, 0.12, 200.0, 7.0, WATER.lightened(0.3))
			return 0.6
		"tentacles":
			hazards().blast(player.position, 50.0, 1.0, bullet_damage * 2.2, "Kraken's tentacle", WATER.darkened(0.2))
			for i in 3:
				hazards().blast(player.position + Vector2.from_angle(randf() * TAU) * 100.0, 50.0, 1.0,
						bullet_damage * 2.2, "Kraken's tentacle", WATER.darkened(0.2))
			return 1.4
	return 1.0


func _draw() -> void:
	var skin := Color(0.4, 0.2, 0.35)
	# Its pool of dark water
	draw_set_transform(Vector2(0, 10), 0.0, Vector2(1.5, 0.8))
	draw_circle(Vector2.ZERO, 60.0, Color(0.1, 0.25, 0.35, 0.85))
	for k in 3:
		var ripple := fmod(time * 0.6 + k * 0.33, 1.0)
		draw_arc(Vector2.ZERO, 30.0 + ripple * 30.0, 0.0, TAU, 24, Color(0.5, 0.8, 1.0, 0.4 * (1.0 - ripple)), 1.5)
	draw_set_transform(Vector2.ZERO)
	# Writhing tentacles around the body
	for t in 8:
		var angle := TAU * t / 8.0
		var mid := Vector2.from_angle(angle + sin(time * 2.0 + t) * 0.3) * 30.0
		var tip := Vector2.from_angle(angle + sin(time * 2.0 + t + 1.0) * 0.4) * 52.0
		draw_line(Vector2.ZERO, mid, skin, 7.0)
		draw_line(mid, tip, skin.lightened(0.1), 4.0)
	draw_circle(Vector2.ZERO, 24.0, skin)
	draw_circle(Vector2(0, -4), 16.0, skin.lightened(0.08))
	draw_circle(Vector2(-8, -6), 5.0, Color(1, 0.85, 0.3))
	draw_circle(Vector2(8, -6), 5.0, Color(1, 0.85, 0.3))
	draw_line(Vector2(-8, -9), Vector2(-8, -3), Color(0.1, 0.05, 0.05), 2.0)
	draw_line(Vector2(8, -9), Vector2(8, -3), Color(0.1, 0.05, 0.05), 2.0)
	draw_health_bar(40.0)
