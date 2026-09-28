extends Enemy
## Aviansie (OSRS, Armadyl's Eyrie): a winged warrior that circles overhead
## loosing volleys of arrows, then swoops down at you.

const FEATHER := Color(0.55, 0.6, 0.7)
const ARROW_TIP := Color(0.8, 0.85, 0.95)

var facing := 1.0


func _init() -> void:
	display_name = "Aviansie"
	radius = 15.0
	move_speed = 120.0
	max_hp = 170.0
	xp = 30
	bullet_damage = 18.0
	contact_damage = 22.0
	preferred_range = 260.0
	projectile_style = Projectiles.Style.ARROW


func _attacks() -> Array:
	return ["volley", "swoop"]


func _move(delta: float) -> void:
	if attack == "swoop":
		position = position.move_toward(player.position, move_speed * 1.6 * delta)
	else:
		super._move(delta)
	facing = 1.0 if player.position.x >= position.x else -1.0


func _fire(attack_name: String) -> float:
	match attack_name:
		"volley":
			fan(position, dir_to_player(position), 2, 0.12, 220.0, 5.0, ARROW_TIP)
			return 0.8
		"swoop":
			ring(position, 6, 110.0, 5.0, FEATHER.lightened(0.3))
			return 1.0
	return 1.0


func _draw() -> void:
	var flap := sin(time * 9.0)
	draw_set_transform(Vector2(0, 22), 0.0, Vector2(1.2, 0.3))
	draw_circle(Vector2.ZERO, 12.0, Color(0, 0, 0, 0.25))
	draw_set_transform(Vector2(0, -4 + flap * 2.0), 0.0, Vector2(facing, 1.0))
	# Big feathered wings
	for side in [-1.0, 1.0]:
		draw_colored_polygon(PackedVector2Array([Vector2(side * 5, -4), Vector2(side * 28, -16 - flap * 8),
				Vector2(side * 30, -2), Vector2(side * 22, 6), Vector2(side * 8, 4)]), FEATHER.darkened(0.15))
	# Body, beaked head, bow
	draw_circle(Vector2(0, 2), 9.0, FEATHER)
	draw_circle(Vector2(3, -9), 6.0, FEATHER.lightened(0.15))
	draw_colored_polygon(PackedVector2Array([Vector2(7, -10), Vector2(14, -8), Vector2(7, -6)]), Color(0.95, 0.75, 0.25))
	draw_circle(Vector2(5, -10), 1.4, Color(0.1, 0.1, 0.1))
	draw_arc(Vector2(10, 3), 9.0, -1.2, 1.2, 10, Color(0.5, 0.35, 0.2), 2.0)
	draw_set_transform(Vector2.ZERO)
	draw_health_bar(20.0)
