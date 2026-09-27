extends Enemy
## Goblin (OSRS, Lumbridge): circles the player at range, slinging rocks at them.
## Deeper zones sling three-rock spreads.

const STONE := Color(0.62, 0.62, 0.64)

var facing := 1.0


func _init() -> void:
	display_name = "Goblin"
	radius = 12.0
	move_speed = 95.0
	max_hp = 60.0
	xp = 12
	bullet_damage = 15.0
	contact_damage = 15.0
	preferred_range = 240.0


func _attacks() -> Array:
	return ["sling"]


func _fire(_attack_name: String) -> float:
	var side := 1 if tier >= 2 else 0
	fan(position, dir_to_player(position), side, 0.2, lerpf(150, 200, difficulty), 6.0, STONE)
	return lerpf(1.2, 0.7, difficulty)


func _draw() -> void:
	facing = 1.0 if player.position.x >= position.x else -1.0
	var skin := Color(0.45, 0.68, 0.3)
	var dark := Color(0.12, 0.15, 0.06)
	draw_set_transform(Vector2(0, 12), 0.0, Vector2(1.0, 0.35))
	draw_circle(Vector2.ZERO, 10.0, Color(0, 0, 0, 0.3))
	var bob := -absf(sin(time * 10.0)) * 1.5
	draw_set_transform(Vector2(0, bob), 0.0, Vector2(facing, 1.0))
	# Body in a ragged tunic
	draw_circle(Vector2(-3, 10), 2.5, dark)
	draw_circle(Vector2(3, 10), 2.5, dark)
	draw_circle(Vector2(0, 4), 6.5, Color(0.5, 0.38, 0.22))
	# Big-eared head
	draw_colored_polygon(PackedVector2Array([Vector2(-6, -7), Vector2(-15, -11), Vector2(-7, -3)]), skin)
	draw_colored_polygon(PackedVector2Array([Vector2(6, -7), Vector2(15, -11), Vector2(7, -3)]), skin)
	draw_circle(Vector2(0, -5), 7.5, skin)
	draw_circle(Vector2(-2.5, -6), 1.8, Color(1, 0.9, 0.2))
	draw_circle(Vector2(3, -6), 1.8, Color(1, 0.9, 0.2))
	draw_line(Vector2(-4.5, -9), Vector2(-1, -7.5), dark, 1.2)
	draw_line(Vector2(5, -9), Vector2(1.5, -7.5), dark, 1.2)
	draw_line(Vector2(-2, -1.5), Vector2(3, -1.5), dark, 1.2)
	# Sling
	draw_line(Vector2(6, 3), Vector2(11, -3), Color(0.45, 0.3, 0.15), 1.5)
	draw_circle(Vector2(11, -3), 2.0, STONE)
	draw_set_transform(Vector2.ZERO)
	draw_health_bar(16.0)
