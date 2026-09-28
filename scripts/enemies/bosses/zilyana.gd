extends Enemy
## Commander Zilyana (OSRS, Saradomin's general). Fast and relentless: she
## dashes around you, calls down a ring of lightning strikes on your position,
## and throws holy light.

const HOLY := Color(1.0, 0.95, 0.6)
const LIGHTNING := Color(0.6, 0.8, 1.0)

var dash_target: Vector2


func _init() -> void:
	display_name = "Commander Zilyana"
	radius = 24.0
	move_speed = 150.0
	max_hp = 1300.0
	xp = 500
	bullet_damage = 26.0
	contact_damage = 40.0
	is_boss = true
	aggro_range = 650.0
	preferred_range = 160.0
	projectile_style = Projectiles.Style.ORB


func _attacks() -> Array:
	return ["lightning", "holy_light", "dash"]


func _on_attack_started(attack_name: String) -> void:
	if attack_name == "dash":
		dash_target = player.position + Vector2.from_angle(randf() * TAU) * 180.0


func _move(delta: float) -> void:
	if attack == "dash":
		position = position.move_toward(dash_target, move_speed * 2.5 * delta)
	else:
		super._move(delta)


func _fire(attack_name: String) -> float:
	match attack_name:
		"lightning":
			# A ring of strikes around you, plus one right on top of you.
			hazards().blast(player.position, 45.0, 1.1, bullet_damage * 2.0, display_name, LIGHTNING)
			for i in 6:
				hazards().blast(player.position + Vector2.from_angle(TAU * i / 6.0) * 90.0, 45.0, 1.1,
						bullet_damage * 2.0, display_name, LIGHTNING)
			return 1.6
		"holy_light":
			fan(position, dir_to_player(position), 2, 0.15, 200.0, 7.0, HOLY)
			return 0.6
		"dash":
			ring(position, 10, 130.0, 6.0, HOLY.darkened(0.1))
			return 0.7
	return 1.0


func _draw() -> void:
	var skin := Color(0.9, 0.8, 0.7)
	var armor := Color(0.92, 0.92, 0.96)
	var trim := Color(0.3, 0.45, 0.9)
	draw_set_transform(Vector2(0, 30), 0.0, Vector2(1.0, 0.3))
	draw_circle(Vector2.ZERO, 22.0, Color(0, 0, 0, 0.3))
	draw_set_transform(Vector2(0, sin(time * 3.0) * 2.0))
	# Radiant wings of light
	for side in [-1.0, 1.0]:
		draw_colored_polygon(PackedVector2Array([Vector2(side * 8, -10), Vector2(side * 40, -34), Vector2(side * 36, -6),
				Vector2(side * 14, 4)]), Color(HOLY, 0.6))
	# Armoured body with a blue tabard
	draw_colored_polygon(PackedVector2Array([Vector2(-14, 26), Vector2(-12, -6), Vector2(12, -6), Vector2(14, 26)]), armor)
	draw_rect(Rect2(Vector2(-5, -6), Vector2(10, 32)), trim)
	# Sword raised
	draw_line(Vector2(16, 6), Vector2(26, -26), Color(0.85, 0.85, 0.9), 3.0)
	draw_line(Vector2(12, 4), Vector2(20, 8), Color(0.85, 0.7, 0.3), 3.0)
	# Head with golden hair
	draw_circle(Vector2(0, -16), 10.0, skin)
	draw_colored_polygon(PackedVector2Array([Vector2(-11, -18), Vector2(0, -30), Vector2(11, -18), Vector2(12, -4), Vector2(8, -12), Vector2(-8, -12), Vector2(-12, -4)]),
			Color(0.95, 0.8, 0.35))
	draw_circle(Vector2(-4, -15), 1.8, Color(0.2, 0.4, 0.9))
	draw_circle(Vector2(4, -15), 1.8, Color(0.2, 0.4, 0.9))
	draw_set_transform(Vector2.ZERO)
	draw_health_bar(36.0)
