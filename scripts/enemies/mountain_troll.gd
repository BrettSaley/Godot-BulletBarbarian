extends Enemy
## Mountain Troll (OSRS, Troll Country): a hulking brute that hurls volleys of
## boulders and pounds the ground, sending out a ring of rubble.

## Colours are variables so the Ice Troll can recolour this troll.
var skin_color := Color(0.45, 0.5, 0.42)
var boulder_color := Color(0.52, 0.5, 0.47)

var facing := 1.0
var pound_anim := 0.0


func _init() -> void:
	display_name = "Mountain Troll"
	radius = 19.0
	move_speed = 70.0
	max_hp = 260.0
	xp = 40
	bullet_damage = 22.0
	contact_damage = 30.0
	preferred_range = 200.0
	aggro_range = 480.0


func _attacks() -> Array:
	return ["boulders", "pound"]


func _fire(attack_name: String) -> float:
	match attack_name:
		"boulders":
			fan(position, dir_to_player(position), 2, 0.22, lerpf(140, 170, difficulty), 10.0, boulder_color)
			return lerpf(1.3, 0.9, difficulty)
		"pound":
			pound_anim = 1.0
			ring(position, int(lerpf(10, 16, difficulty)), 120.0, 7.0, boulder_color.darkened(0.2))
			return lerpf(1.4, 1.0, difficulty)
	return 1.0


func _draw() -> void:
	facing = 1.0 if player.position.x >= position.x else -1.0
	pound_anim = maxf(pound_anim - 0.06, 0.0)
	var skin := skin_color
	var dark := Color(0.2, 0.22, 0.18)
	draw_set_transform(Vector2(0, 22), 0.0, Vector2(1.1, 0.35))
	draw_circle(Vector2.ZERO, 18.0, Color(0, 0, 0, 0.3))
	var bob := -absf(sin(time * 5.0)) * 2.0 + pound_anim * 3.0
	draw_set_transform(Vector2(0, bob), 0.0, Vector2(facing, 1.0))
	# Stubby legs, big hunched body, long arms dragging rocks
	draw_rect(Rect2(Vector2(-10, 12), Vector2(7, 10)), skin.darkened(0.15))
	draw_rect(Rect2(Vector2(3, 12), Vector2(7, 10)), skin.darkened(0.15))
	draw_circle(Vector2(0, 2), 16.0, skin)
	draw_circle(Vector2(0, 6), 9.0, skin.lightened(0.1))
	for side in [-1.0, 1.0]:
		var fist := Vector2(side * 19, 14 - pound_anim * 10.0)
		draw_line(Vector2(side * 13, -2), fist, skin, 6.0)
		draw_circle(fist, 6.0, skin.darkened(0.1))
	# Small head with a big nose, tusks and a tuft of hair
	draw_circle(Vector2(2, -15), 8.0, skin)
	draw_circle(Vector2(8, -13), 4.0, skin.darkened(0.08))
	draw_circle(Vector2(0, -18), 1.5, Color(0.9, 0.3, 0.1))
	draw_circle(Vector2(5, -18), 1.5, Color(0.9, 0.3, 0.1))
	draw_colored_polygon(PackedVector2Array([Vector2(-1, -10), Vector2(1, -10), Vector2(0, -14)]), Color(0.95, 0.92, 0.85))
	draw_colored_polygon(PackedVector2Array([Vector2(5, -10), Vector2(7, -10), Vector2(6, -14)]), Color(0.95, 0.92, 0.85))
	draw_colored_polygon(PackedVector2Array([Vector2(-4, -22), Vector2(2, -28), Vector2(4, -22)]), dark)
	draw_set_transform(Vector2.ZERO)
	draw_health_bar(26.0)
