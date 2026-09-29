extends Enemy
## Cerberus (Cerberus's Lair). The three-headed hound of the underworld:
## a rapid triple attack (one bolt per head), pools of lava around you, a
## howl of fire, and the Summoned Souls that rise to fire on you.

const FIRE := Color(1.0, 0.45, 0.1)
const HEAD_COLORS := [Color(0.95, 0.3, 0.2), Color(0.35, 0.85, 0.35), Color(0.4, 0.5, 1.0)]

var room: Rect2
var facing := 1.0


func _init() -> void:
	display_name = "Cerberus"
	radius = 32.0
	move_speed = 90.0
	max_hp = 1400.0
	xp = 600
	bullet_damage = 28.0
	contact_damage = 45.0
	is_boss = true
	drops_loot = false
	aggro_range = 650.0
	preferred_range = 200.0
	projectile_style = Projectiles.Style.ORB


func _attacks() -> Array:
	return ["triple", "lava", "howl", "souls"]


func _move(delta: float) -> void:
	super._move(delta)
	facing = 1.0 if player.position.x >= position.x else -1.0


func _fire(attack_name: String) -> float:
	match attack_name:
		"triple":
			for i in 3:
				shoot(position, dir_to_player(position).rotated((i - 1) * 0.12) * 210.0, 8.0, HEAD_COLORS[i])
			return 0.6
		"lava":
			for i in 3:
				hazards().pool(player.position + Vector2.from_angle(TAU * i / 3.0 + randf()) * randf_range(20, 90), 42.0, 5.0,
						bullet_damage * 1.4, "Cerberus's lava", FIRE)
			return 1.5
		"howl":
			ring(position, 18, 130.0, 7.0, FIRE)
			return 1.0
		"souls":
			for i in 3:
				summon(Minion.make("cerberus_ghost", HEAD_COLORS[i]), Vector2(room.position.x + room.size.x * (i + 1) / 4.0, room.position.y + 40))
			return 99.0
	return 1.0


func _draw() -> void:
	var fur := Color(0.22, 0.12, 0.1)
	draw_set_transform(Vector2(0, 34), 0.0, Vector2(1.5, 0.3))
	draw_circle(Vector2.ZERO, 30.0, Color(0, 0, 0, 0.3))
	draw_set_transform(Vector2(0, -absf(sin(time * 5.0)) * 2.0), 0.0, Vector2(facing, 1.0))
	for x in [-20.0, -8.0, 10.0, 22.0]:
		draw_line(Vector2(x, 10), Vector2(x, 30), fur.darkened(0.3), 6.0)
	draw_set_transform(Vector2(0, -absf(sin(time * 5.0)) * 2.0), 0.0, Vector2(facing * 1.5, 1.0))
	draw_circle(Vector2(0, 6), 18.0, fur)
	draw_set_transform(Vector2(0, -absf(sin(time * 5.0)) * 2.0), 0.0, Vector2(facing, 1.0))
	# Three heads on three necks, each with its own coloured eyes
	for h in 3:
		var head := Vector2(24 + (h - 1) * 4, -14 + (h - 1) * 14)
		draw_line(Vector2(12, 0), head, fur, 8.0)
		draw_circle(head, 9.0, fur.lightened(0.05))
		draw_colored_polygon(PackedVector2Array([head + Vector2(4, -3), head + Vector2(14, 0), head + Vector2(4, 3)]), fur.lightened(0.05))
		draw_circle(head + Vector2(2, -3), 2.0, HEAD_COLORS[h])
		draw_colored_polygon(PackedVector2Array([head + Vector2(-4, -6), head + Vector2(-2, -14), head + Vector2(1, -7)]), fur.darkened(0.3))
	# Flames licking along the back
	for k in 4:
		draw_circle(Vector2(-14 + k * 7, -10 - absf(sin(time * 10.0 + k)) * 6.0), 4.0, Color(FIRE, 0.7))
	draw_set_transform(Vector2.ZERO)
	draw_health_bar(44.0)
