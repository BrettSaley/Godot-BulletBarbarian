extends Enemy
## Dark Wizard (OSRS, Draynor Woods): hangs back casting strike spells -
## spirals of Water Strike and rings of Fire Strike.

const WATER := Color(0.35, 0.6, 1.0)
const FIRE := Color(1.0, 0.5, 0.2)

var spiral_angle := 0.0


func _init() -> void:
	display_name = "Dark Wizard"
	radius = 13.0
	move_speed = 70.0
	max_hp = 110.0
	xp = 22
	bullet_damage = 16.0
	contact_damage = 15.0
	preferred_range = 300.0
	aggro_range = 520.0
	projectile_style = Projectiles.Style.ORB


func _attacks() -> Array:
	return ["water_strike", "fire_strike"]


func _fire(attack_name: String) -> float:
	match attack_name:
		"water_strike":
			spiral_angle += 0.4
			var arms := 2 + int(difficulty * 1.99)
			for i in arms:
				shoot(position, Vector2.from_angle(spiral_angle + TAU * i / arms) * lerpf(100, 140, difficulty), 5.0, WATER)
			return lerpf(0.18, 0.1, difficulty)
		"fire_strike":
			ring(position, int(lerpf(8, 16, difficulty)), lerpf(90, 130, difficulty), 6.0, FIRE)
			return lerpf(1.1, 0.7, difficulty)
	return 1.0


func _draw() -> void:
	var robe := Color(0.12, 0.12, 0.25)
	var skin := Color(0.95, 0.78, 0.65)
	draw_set_transform(Vector2(0, 13), 0.0, Vector2(1.0, 0.35))
	draw_circle(Vector2.ZERO, 10.0, Color(0, 0, 0, 0.3))
	var float_y := sin(time * 3.0) * 1.5
	draw_set_transform(Vector2(0, float_y))
	# Staff with a glowing tip
	draw_line(Vector2(10, 12), Vector2(10, -14), Color(0.45, 0.3, 0.15), 2.0)
	var glow := 0.5 + 0.5 * sin(time * 6.0) if is_attacking() else 0.3
	var tip := FIRE if attack == "fire_strike" else WATER
	draw_circle(Vector2(10, -16), 4.0 + glow * 2.0, Color(tip, 0.35))
	draw_circle(Vector2(10, -16), 3.0, tip)
	# Dark robe with a red trim, white beard
	draw_colored_polygon(PackedVector2Array([Vector2(-8, 12), Vector2(-5, -2), Vector2(5, -2), Vector2(8, 12)]), robe)
	draw_line(Vector2(-8, 11), Vector2(8, 11), Color(0.7, 0.15, 0.15), 2.0)
	draw_circle(Vector2(0, -6), 6.5, skin)
	draw_colored_polygon(PackedVector2Array([Vector2(-5, -4), Vector2(5, -4), Vector2(0, 6)]), Color(0.92, 0.92, 0.92))
	draw_circle(Vector2(-2.5, -7), 1.3, Color(0.1, 0.1, 0.1))
	draw_circle(Vector2(2.5, -7), 1.3, Color(0.1, 0.1, 0.1))
	# Tall pointed hat
	draw_colored_polygon(PackedVector2Array([Vector2(-10, -10), Vector2(10, -10), Vector2(3, -28), Vector2(-1, -30)]), robe)
	draw_line(Vector2(-9, -11), Vector2(9, -11), Color(0.7, 0.15, 0.15), 2.0)
	draw_set_transform(Vector2.ZERO)
	draw_health_bar(18.0)
