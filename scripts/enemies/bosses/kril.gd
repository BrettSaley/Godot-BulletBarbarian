extends Enemy
## K'ril Tsutsaroth (OSRS, Zamorak's general). A hulking demon that surrounds
## itself in fire, poisons the ground, and bellows "YARRR!" before a massive
## telegraphed strike that hits far harder than anything else it does.

const FIRE := Color(1.0, 0.35, 0.1)
const POISON := Color(0.45, 0.8, 0.2)


func _init() -> void:
	display_name = "K'ril Tsutsaroth"
	radius = 32.0
	move_speed = 85.0
	max_hp = 1700.0
	xp = 500
	bullet_damage = 30.0
	contact_damage = 45.0
	is_boss = true
	aggro_range = 650.0
	preferred_range = 150.0
	projectile_style = Projectiles.Style.ORB


func _attacks() -> Array:
	return ["fire_ring", "poison", "yarrr"]


func _fire(attack_name: String) -> float:
	match attack_name:
		"fire_ring":
			ring(position, 18, 130.0, 7.0, FIRE)
			return 0.8
		"poison":
			for i in 3:
				hazards().pool(player.position + Vector2.from_angle(randf() * TAU) * randf_range(0, 100), 40.0, 6.0,
						bullet_damage, "K'ril's poison", POISON)
			return 1.5
		"yarrr":
			DamageText.spawn(get_parent(), position + Vector2(0, -60), "YARRR!", Color(1, 0.3, 0.2), 22)
			hazards().blast(player.position, 70.0, 1.3, bullet_damage * 4.0, "K'ril's special attack", FIRE)
			return 2.5
	return 1.0


func _draw() -> void:
	var red := Color(0.6, 0.1, 0.08)
	var dark := Color(0.2, 0.03, 0.03)
	draw_set_transform(Vector2(0, 36), 0.0, Vector2(1.3, 0.35))
	draw_circle(Vector2.ZERO, 30.0, Color(0, 0, 0, 0.3))
	draw_set_transform(Vector2(0, sin(time * 3.0) * 2.0))
	# Burning aura
	for k in 6:
		draw_circle(Vector2.from_angle(TAU * k / 6.0 + time) * 30.0, 6.0 + sin(time * 8.0 + k) * 2.0, Color(FIRE, 0.4))
	# Wings, body, arms
	for side in [-1.0, 1.0]:
		draw_colored_polygon(PackedVector2Array([Vector2(side * 14, -10), Vector2(side * 54, -36), Vector2(side * 48, -8),
				Vector2(side * 58, 6), Vector2(side * 22, 8)]), dark)
		draw_line(Vector2(side * 20, 0), Vector2(side * 32, 18), red, 7.0)
	draw_circle(Vector2(0, 6), 24.0, red)
	draw_circle(Vector2(0, 10), 13.0, red.lightened(0.15))
	# Horned head and a flaming mace
	draw_colored_polygon(PackedVector2Array([Vector2(-10, -26), Vector2(-20, -46), Vector2(-4, -30)]), Color(0.25, 0.2, 0.18))
	draw_colored_polygon(PackedVector2Array([Vector2(10, -26), Vector2(20, -46), Vector2(4, -30)]), Color(0.25, 0.2, 0.18))
	draw_circle(Vector2(0, -20), 13.0, red)
	var eye := Color(1, 0.9, 0.2) if is_attacking() else Color(1, 0.5, 0.1)
	draw_circle(Vector2(-5, -22), 2.5, eye)
	draw_circle(Vector2(5, -22), 2.5, eye)
	draw_line(Vector2(32, 18), Vector2(40, -8), Color(0.3, 0.25, 0.2), 4.0)
	draw_circle(Vector2(40, -10), 7.0, FIRE)
	draw_set_transform(Vector2.ZERO)
	draw_health_bar(44.0)
