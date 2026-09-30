extends Enemy
## The Obelisk that shields both Wardens in phase 1. It pulses rings of energy
## and spirals; destroy it to wake the Wardens.

const ENERGY := Color(0.4, 0.7, 1.0)

var spiral := 0.0


func _init() -> void:
	display_name = "Obelisk"
	radius = 24.0
	move_speed = 0.0
	max_hp = 1200.0
	xp = 400
	bullet_damage = 28.0
	contact_damage = 0.0
	drops_loot = false
	aggro_range = 2000.0
	size_scale = 1.2
	projectile_style = Projectiles.Style.ORB


func _attacks() -> Array:
	return ["pulse", "spiral"]


func _move(_delta: float) -> void:
	pass


func _fire(attack_name: String) -> float:
	match attack_name:
		"pulse":
			ring(position, 14, 120.0, 7.0, ENERGY)
			return 1.0
		"spiral":
			spiral += 0.4
			for i in 3:
				shoot(position, Vector2.from_angle(spiral + TAU * i / 3.0) * 130.0, 6.0, ENERGY.lightened(0.3))
			return 0.15
	return 1.0


func _draw() -> void:
	var stone := Color(0.5, 0.46, 0.4)
	draw_set_transform(Vector2(0, 30), 0.0, Vector2(1.0, 0.3))
	draw_circle(Vector2.ZERO, 22.0, Color(0, 0, 0, 0.3))
	draw_set_transform(Vector2.ZERO)
	draw_colored_polygon(PackedVector2Array([Vector2(-16, 30), Vector2(-12, -34), Vector2(0, -48), Vector2(12, -34), Vector2(16, 30)]), stone)
	for g in 3:
		draw_line(Vector2(-8, -20 + g * 14), Vector2(8, -20 + g * 14), stone.darkened(0.3), 2.0)
	draw_circle(Vector2(0, -36), 7.0 + sin(time * 5.0), ENERGY)
	draw_health_bar(36.0)
