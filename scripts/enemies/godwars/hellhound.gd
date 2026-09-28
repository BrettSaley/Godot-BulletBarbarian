extends Enemy
## Hellhound (OSRS, Zamorak's Fortress): a burning hound that lunges at you
## and breathes cones of fire.

const FIRE := Color(1.0, 0.45, 0.1)

var facing := 1.0


func _init() -> void:
	display_name = "Hellhound"
	radius = 14.0
	move_speed = 150.0
	max_hp = 190.0
	xp = 32
	bullet_damage = 20.0
	contact_damage = 28.0
	preferred_range = 120.0
	projectile_style = Projectiles.Style.ORB


func _attacks() -> Array:
	return ["fire_breath", "lunge"]


func _move(delta: float) -> void:
	if attack == "lunge":
		position = position.move_toward(player.position, move_speed * 1.3 * delta)
	else:
		super._move(delta)
	facing = 1.0 if player.position.x >= position.x else -1.0


func _fire(attack_name: String) -> float:
	match attack_name:
		"fire_breath":
			fan(position, dir_to_player(position), 2, 0.14, 170.0, 6.0, FIRE)
			return 0.8
	return 99.0


func _draw() -> void:
	var fur := Color(0.35, 0.12, 0.08)
	draw_set_transform(Vector2(0, 11), 0.0, Vector2(1.3, 0.35))
	draw_circle(Vector2.ZERO, 11.0, Color(0, 0, 0, 0.3))
	var bob := -absf(sin(time * 14.0)) * 2.0
	draw_set_transform(Vector2(0, bob), 0.0, Vector2(facing, 1.0))
	# Flame mane flickering behind
	for k in 4:
		draw_circle(Vector2(-6 + k * 4, -6 - absf(sin(time * 12.0 + k)) * 5.0), 3.5, Color(FIRE, 0.7))
	for x in [-8.0, -3.0, 4.0, 9.0]:
		draw_line(Vector2(x, 4), Vector2(x, 10), fur.darkened(0.3), 2.5)
	draw_set_transform(Vector2(0, bob), 0.0, Vector2(facing * 1.5, 1.0))
	draw_circle(Vector2(0, 1), 7.0, fur)
	draw_set_transform(Vector2(0, bob), 0.0, Vector2(facing, 1.0))
	draw_circle(Vector2(13, -5), 6.0, fur)
	draw_colored_polygon(PackedVector2Array([Vector2(16, -7), Vector2(24, -3), Vector2(16, 0)]), fur)
	draw_colored_polygon(PackedVector2Array([Vector2(9, -9), Vector2(11, -17), Vector2(14, -9)]), fur.darkened(0.2))
	draw_circle(Vector2(15, -6.5), 1.8, Color(1, 0.8, 0.2))
	draw_set_transform(Vector2.ZERO)
	draw_health_bar(16.0)
