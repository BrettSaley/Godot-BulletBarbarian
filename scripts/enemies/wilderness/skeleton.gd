extends Enemy
## Skeleton (OSRS, the Wilderness): rattles after you hurling bones, and
## bursts into a ring of bone shards.

const BONE := Color(0.92, 0.9, 0.82)

var facing := 1.0


func _init() -> void:
	display_name = "Skeleton"
	radius = 12.0
	move_speed = 95.0
	max_hp = 90.0
	xp = 16
	bullet_damage = 16.0
	contact_damage = 18.0
	preferred_range = 200.0


func _attacks() -> Array:
	return ["bones", "shatter"]


func _fire(attack_name: String) -> float:
	match attack_name:
		"bones":
			fan(position, dir_to_player(position), 1, 0.18, 180.0, 6.0, BONE)
			return 0.8
		"shatter":
			ring(position, 10, 120.0, 5.0, BONE.darkened(0.15))
			return 1.3
	return 1.0


func _draw() -> void:
	facing = 1.0 if player.position.x >= position.x else -1.0
	var dark := Color(0.15, 0.13, 0.12)
	draw_set_transform(Vector2(0, 14), 0.0, Vector2(1.0, 0.35))
	draw_circle(Vector2.ZERO, 9.0, Color(0, 0, 0, 0.3))
	draw_set_transform(Vector2(0, -absf(sin(time * 10.0)) * 1.5), 0.0, Vector2(facing, 1.0))
	# Legs, spine and ribs
	draw_line(Vector2(-3, 6), Vector2(-4, 14), BONE, 2.0)
	draw_line(Vector2(3, 6), Vector2(4, 14), BONE, 2.0)
	draw_line(Vector2(0, -4), Vector2(0, 7), BONE, 2.0)
	for r in 3:
		draw_line(Vector2(-6, -2 + r * 3), Vector2(6, -2 + r * 3), BONE, 1.5)
	draw_line(Vector2(6, -1), Vector2(11, 5), BONE, 1.5)
	# Skull
	draw_circle(Vector2(0, -10), 6.5, BONE)
	draw_circle(Vector2(-2.5, -11), 1.8, dark)
	draw_circle(Vector2(2.5, -11), 1.8, dark)
	draw_line(Vector2(-2, -6), Vector2(2, -6), dark, 1.0)
	draw_set_transform(Vector2.ZERO)
	draw_health_bar(18.0)
