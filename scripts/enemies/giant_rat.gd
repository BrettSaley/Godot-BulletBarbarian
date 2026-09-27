extends Enemy
## Giant Rat (OSRS, Lumbridge): scurries straight at you to bite, and
## squeaks out a small ring of pebbles now and then.

const STONE := Color(0.6, 0.55, 0.5)

var facing := 1.0


func _init() -> void:
	display_name = "Giant Rat"
	radius = 11.0
	move_speed = 135.0
	max_hp = 45.0
	xp = 9
	bullet_damage = 12.0
	contact_damage = 18.0
	preferred_range = 60.0
	aggro_range = 380.0


func _attacks() -> Array:
	return ["squeak"]


func _fire(_attack_name: String) -> float:
	ring(position, 6, 110.0, 4.5, STONE)
	return 1.6


func _draw() -> void:
	facing = 1.0 if player.position.x >= position.x else -1.0
	var fur := Color(0.45, 0.38, 0.32)
	var pink := Color(0.95, 0.65, 0.65)
	draw_set_transform(Vector2(0, 8), 0.0, Vector2(1.3, 0.35))
	draw_circle(Vector2.ZERO, 10.0, Color(0, 0, 0, 0.3))
	var bob := -absf(sin(time * 16.0)) * 1.5
	draw_set_transform(Vector2(0, bob), 0.0, Vector2(facing, 1.0))
	# Tail curling behind
	draw_polyline(PackedVector2Array([Vector2(-10, 2), Vector2(-16, -2), Vector2(-20, 2), Vector2(-24, -1)]), pink, 1.5)
	# Body and head, side view facing right
	draw_set_transform(Vector2(0, bob), 0.0, Vector2(facing * 1.4, 1.0))
	draw_circle(Vector2(-1, 1), 7.0, fur)
	draw_set_transform(Vector2(0, bob), 0.0, Vector2(facing, 1.0))
	draw_circle(Vector2(9, -2), 5.5, fur)
	draw_colored_polygon(PackedVector2Array([Vector2(12, -5), Vector2(19, -1), Vector2(12, 1)]), fur)
	draw_circle(Vector2(19, -1), 1.5, pink)
	draw_circle(Vector2(7, -7), 3.0, pink)
	draw_circle(Vector2(11, -3.5), 1.3, Color(0.9, 0.1, 0.1))
	draw_set_transform(Vector2.ZERO)
	draw_health_bar(12.0)
