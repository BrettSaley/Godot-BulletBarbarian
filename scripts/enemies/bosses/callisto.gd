extends Enemy
## Callisto (OSRS, the Wilderness). A colossal bear: it roars and throws you
## back, slams the ground in shockwaves, and charges where you're standing.

const SHOCK := Color(0.65, 0.5, 0.35)
const CHARGE_WINDUP := 0.5

var charge_target: Vector2
var windup := 0.0
var slam_anim := 0.0
var facing := 1.0


func _init() -> void:
	display_name = "Callisto"
	radius = 34.0
	move_speed = 80.0
	max_hp = 1800.0
	xp = 600
	bullet_damage = 32.0
	contact_damage = 50.0
	is_boss = true
	aggro_range = 650.0
	preferred_range = 120.0


func _attacks() -> Array:
	return ["slam", "roar", "charge"]


func _on_attack_started(attack_name: String) -> void:
	match attack_name:
		"charge":
			charge_target = player.position + dir_to_player(position) * 80.0
			windup = CHARGE_WINDUP
		"roar":
			# A ring of shockwaves instead of a shove: overworld bosses never move
			# the player (it could push them into other monsters' shots).
			ring(position, 16, 150.0, 7.0, Color(1, 0.7, 0.3))
			DamageText.spawn(get_parent(), position + Vector2(0, -60), "ROAR!", Color(1, 0.7, 0.3), 20)


func _move(delta: float) -> void:
	slam_anim = maxf(slam_anim - delta * 4.0, 0.0)
	var before := position
	if attack == "charge":
		if windup > 0.0:
			windup -= delta
		else:
			position = position.move_toward(charge_target, move_speed * 3.5 * delta)
			if position.distance_to(charge_target) < 4.0:
				ring(position, 12, 120.0, 7.0, SHOCK)
				charge_target = player.position + dir_to_player(position) * 80.0
				windup = CHARGE_WINDUP
	elif attack != "slam":
		super._move(delta)
	if absf(position.x - before.x) > 0.1:
		facing = signf(position.x - before.x)


func _fire(attack_name: String) -> float:
	match attack_name:
		"slam":
			slam_anim = 1.0
			hazards().blast(position, 120.0, 0.7, bullet_damage * 2.5, display_name, SHOCK.lightened(0.2))
			ring(position, 20, 110.0, 7.0, SHOCK)
			return 1.2
		"roar":
			fan(position, dir_to_player(position), 3, 0.18, 170.0, 8.0, SHOCK.lightened(0.1))
			return 0.8
	return 99.0


func _draw() -> void:
	var fur := Color(0.32, 0.22, 0.14)
	var fur_dark := Color(0.22, 0.14, 0.08)
	var tan := Color(0.6, 0.45, 0.3)
	draw_set_transform(Vector2(0, 38), 0.0, Vector2(1.3, 0.3))
	draw_circle(Vector2.ZERO, 32.0, Color(0, 0, 0, 0.3))
	var shake := Vector2(randf_range(-2, 2), 0) if windup > 0.0 else Vector2.ZERO
	draw_set_transform(shake + Vector2(0, slam_anim * 4.0), 0.0, Vector2(facing * (1.0 + slam_anim * 0.1), 1.0 - slam_anim * 0.08))
	draw_circle(Vector2(-14, 32), 8.0, fur_dark)
	draw_circle(Vector2(14, 32), 8.0, fur_dark)
	draw_circle(Vector2(0, 12), 26.0, fur)
	draw_circle(Vector2(0, 16), 15.0, tan)
	for side in [-1.0, 1.0]:
		var paw := Vector2(side * 26, 14 - slam_anim * 12.0)
		draw_circle(paw, 10.0, fur_dark)
		for c in 3:
			draw_line(paw + Vector2((c - 1) * 4, 7), paw + Vector2((c - 1) * 4, 12), Color(0.95, 0.92, 0.85), 2.0)
	draw_circle(Vector2(-18, -28), 9.0, fur)
	draw_circle(Vector2(18, -28), 9.0, fur)
	draw_circle(Vector2(0, -12), 22.0, fur)
	draw_circle(Vector2(0, -3), 10.0, tan)
	draw_circle(Vector2(0, -7), 5.0, Color(0.1, 0.05, 0.03))
	var eye := Color(0.95, 0.2, 0.1) if is_attacking() else Color(0.1, 0.05, 0.03)
	draw_circle(Vector2(-9, -17), 3.5, eye)
	draw_circle(Vector2(9, -17), 3.5, eye)
	draw_line(Vector2(-15, -24), Vector2(-4, -19), Color(0.1, 0.05, 0.03), 3.0)
	draw_line(Vector2(15, -24), Vector2(4, -19), Color(0.1, 0.05, 0.03), 3.0)
	draw_colored_polygon(PackedVector2Array([Vector2(-5, 2), Vector2(-2, 2), Vector2(-3.5, 7)]), Color(1, 1, 1))
	draw_colored_polygon(PackedVector2Array([Vector2(2, 2), Vector2(5, 2), Vector2(3.5, 7)]), Color(1, 1, 1))
	draw_set_transform(Vector2.ZERO)
	draw_health_bar(46.0)
