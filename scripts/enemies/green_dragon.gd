extends Enemy
## Green Dragon (OSRS, the Wilderness): circles you breathing wide cones of
## dragonfire and spitting fireballs that burst where they land.

const FIRE := Color(1.0, 0.55, 0.15)
## Colours are variables so the Lava Dragon can recolour this dragon.
var scale_tint := Color(0.25, 0.6, 0.25)
var belly_tint := Color(0.75, 0.8, 0.45)

var facing := 1.0


func _init() -> void:
	display_name = "Green Dragon"
	radius = 20.0
	move_speed = 85.0
	max_hp = 300.0
	xp = 50
	bullet_damage = 24.0
	contact_damage = 30.0
	preferred_range = 240.0
	aggro_range = 520.0
	projectile_style = Projectiles.Style.ORB


func _attacks() -> Array:
	return ["breath", "fireball"]


func _fire(attack_name: String) -> float:
	match attack_name:
		"breath":
			fan(position, dir_to_player(position), 3, 0.12, 170.0, 7.0, FIRE)
			return 0.9
		"fireball":
			hazards().blast(player.position, 50.0, 1.0, bullet_damage * 1.8, display_name, FIRE)
			return 1.3
	return 1.0


func _draw() -> void:
	facing = 1.0 if player.position.x >= position.x else -1.0
	var scale_color := scale_tint
	var belly := belly_tint
	var flap := sin(time * 6.0)
	draw_set_transform(Vector2(0, 24), 0.0, Vector2(1.4, 0.35))
	draw_circle(Vector2.ZERO, 18.0, Color(0, 0, 0, 0.3))
	draw_set_transform(Vector2(0, flap * 2.0), 0.0, Vector2(facing, 1.0))
	# Wings
	for side in [-1.0, 1.0]:
		draw_colored_polygon(PackedVector2Array([Vector2(side * 6, -4), Vector2(side * 30, -18 - flap * 8),
				Vector2(side * 28, 2), Vector2(side * 10, 6)]), scale_color.darkened(0.25))
	# Tail, body, belly
	draw_colored_polygon(PackedVector2Array([Vector2(-8, 8), Vector2(-24, 18), Vector2(-6, 14)]), scale_color)
	draw_circle(Vector2(0, 4), 12.0, scale_color)
	draw_circle(Vector2(1, 7), 7.0, belly)
	# Head with horns, facing right
	draw_colored_polygon(PackedVector2Array([Vector2(8, -14), Vector2(4, -24), Vector2(11, -16)]), Color(0.9, 0.85, 0.7))
	draw_circle(Vector2(12, -10), 7.0, scale_color)
	draw_colored_polygon(PackedVector2Array([Vector2(15, -14), Vector2(25, -9), Vector2(15, -5)]), scale_color)
	draw_circle(Vector2(13, -12), 1.8, Color(1, 0.85, 0.2))
	if attack == "breath":
		draw_circle(Vector2(26, -9), 3.0 + flap, Color(FIRE, 0.7))
	draw_set_transform(Vector2.ZERO)
	draw_health_bar(24.0)
