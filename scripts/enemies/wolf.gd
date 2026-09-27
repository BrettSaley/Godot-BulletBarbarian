extends Enemy
## Wolf (OSRS, Draynor Woods): fast and close-range. Lunges at the player and howls out a
## ring of rocks, so keep moving.

const STONE := Color(0.5, 0.5, 0.56)

var facing := 1.0


func _init() -> void:
	display_name = "Wolf"
	radius = 14.0
	move_speed = 150.0
	max_hp = 90.0
	xp = 18
	bullet_damage = 18.0
	contact_damage = 25.0
	preferred_range = 110.0
	aggro_range = 420.0


func _attacks() -> Array:
	return ["howl", "lunge"]


func _move(delta: float) -> void:
	if attack == "lunge":
		position = position.move_toward(player.position, move_speed * 1.3 * delta)
	else:
		super._move(delta)


func _fire(attack_name: String) -> float:
	match attack_name:
		"howl":
			ring(position, int(lerpf(6, 12, difficulty)), lerpf(110, 150, difficulty), 5.0, STONE)
			return lerpf(1.3, 0.8, difficulty)
	return 99.0  # lunge only hurts on contact


func _draw() -> void:
	facing = 1.0 if player.position.x >= position.x else -1.0
	var fur := Color(0.55, 0.56, 0.6)
	var fur_dark := Color(0.38, 0.39, 0.44)
	var dark := Color(0.1, 0.1, 0.12)
	draw_set_transform(Vector2(0, 11), 0.0, Vector2(1.3, 0.35))
	draw_circle(Vector2.ZERO, 11.0, Color(0, 0, 0, 0.3))
	var bob := -absf(sin(time * 14.0)) * 2.0
	draw_set_transform(Vector2(0, bob), 0.0, Vector2(facing, 1.0))
	# Tail, legs and body, side view facing right
	draw_colored_polygon(PackedVector2Array([Vector2(-11, 0), Vector2(-20, -7), Vector2(-17, 2)]), fur_dark)
	for x in [-8.0, -3.0, 4.0, 9.0]:
		draw_line(Vector2(x, 4), Vector2(x, 10), fur_dark, 2.5)
	draw_set_transform(Vector2(0, bob), 0.0, Vector2(facing * 1.5, 1.0))
	draw_circle(Vector2(0, 1), 7.0, fur)
	draw_set_transform(Vector2(0, bob), 0.0, Vector2(facing, 1.0))
	# Head with pointed ears and snout
	draw_colored_polygon(PackedVector2Array([Vector2(8, -9), Vector2(10, -17), Vector2(13, -9)]), fur_dark)
	draw_colored_polygon(PackedVector2Array([Vector2(13, -9), Vector2(16, -16), Vector2(17, -7)]), fur_dark)
	draw_circle(Vector2(13, -5), 6.0, fur)
	draw_colored_polygon(PackedVector2Array([Vector2(16, -7), Vector2(24, -3), Vector2(16, 0)]), fur)
	draw_circle(Vector2(23.5, -3.2), 1.5, dark)
	var eye := Color(1, 0.3, 0.2) if is_attacking() else Color(1, 0.85, 0.3)
	draw_circle(Vector2(15, -6.5), 1.6, eye)
	draw_set_transform(Vector2.ZERO)
	draw_health_bar(16.0)
