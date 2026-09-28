extends Enemy
## Zebak (Tombs of Amascut, Path of Crondis). A giant crocodile who sends
## walls of water surging across the room (dive through the gap), spits acid
## pools, and rains blood. Below 25% health he enrages and attacks faster.

const WATER := Color(0.35, 0.6, 1.0)
const ACID := Color(0.5, 0.8, 0.2)
const BLOOD := Color(0.85, 0.15, 0.15)
const LANE := 36.0

## Set by the raid.
var room: Rect2


func _init() -> void:
	display_name = "Zebak"
	radius = 32.0
	move_speed = 60.0
	max_hp = 2000.0
	xp = 900
	bullet_damage = 32.0
	contact_damage = 50.0
	is_boss = true
	drops_loot = false
	aggro_range = 2000.0
	preferred_range = 260.0
	projectile_style = Projectiles.Style.ORB


func is_enraged() -> bool:
	return hp / max_hp < 0.25


func _attacks() -> Array:
	return ["wave", "acid", "blood_rain"]


func _fire(attack_name: String) -> float:
	var pace := 0.7 if is_enraged() else 1.0
	match attack_name:
		"wave":
			# A wall of water from the west wall with one gap to slip through.
			var lanes := int(room.size.y / LANE)
			var gap := randi() % (lanes - 3)
			for lane in lanes:
				if lane >= gap and lane < gap + 3:
					continue
				shoot(Vector2(room.position.x + 16, room.position.y + (lane + 0.5) * LANE), Vector2(220, 0), 13.0, WATER, 1.5)
			return 2.6 * pace
		"acid":
			for i in 4:
				hazards().pool(player.position + Vector2.from_angle(randf() * TAU) * randf_range(0, 110), 40.0, 7.0,
						bullet_damage * 1.3, "Zebak's acid", ACID)
			return 1.5 * pace
		"blood_rain":
			fan(position, dir_to_player(position), 3, 0.16, 190.0, 7.0, BLOOD)
			hazards().blast(player.position, 50.0, 1.0, bullet_damage * 2.0, "Zebak's blood", BLOOD)
			return 0.9 * pace
	return 1.0


func _draw() -> void:
	var scale_color := Color(0.3, 0.45, 0.25)
	var gold := Color(0.95, 0.8, 0.3)
	var facing := 1.0 if player.position.x >= position.x else -1.0
	draw_set_transform(Vector2(0, 30), 0.0, Vector2(1.6, 0.3))
	draw_circle(Vector2.ZERO, 30.0, Color(0, 0, 0, 0.3))
	draw_set_transform(Vector2(0, sin(time * 2.0) * 2.0), 0.0, Vector2(facing, 1.0))
	# Heavy scaled body and tail
	draw_colored_polygon(PackedVector2Array([Vector2(-20, 10), Vector2(-56, 22), Vector2(-24, 22)]), scale_color.darkened(0.1))
	draw_circle(Vector2(-4, 8), 26.0, scale_color)
	for k in 4:
		draw_circle(Vector2(-16 + k * 9, -6), 4.0, scale_color.darkened(0.25))
	# Long jaws, open when attacking
	var open := 6.0 if is_attacking() else 2.0
	draw_colored_polygon(PackedVector2Array([Vector2(12, -10), Vector2(48, -8 - open), Vector2(48, -4), Vector2(12, -2)]), scale_color.lightened(0.1))
	draw_colored_polygon(PackedVector2Array([Vector2(12, 0), Vector2(48, 2), Vector2(48, 6 + open), Vector2(12, 6)]), scale_color.lightened(0.05))
	for t in 5:
		draw_colored_polygon(PackedVector2Array([Vector2(18 + t * 6, -4), Vector2(21 + t * 6, -4), Vector2(19.5 + t * 6, 0)]), Color(0.95, 0.92, 0.85))
	draw_circle(Vector2(16, -14), 4.0, Color(0.95, 0.8, 0.2))
	draw_circle(Vector2(16, -14), 1.5, Color(0.1, 0.1, 0.1))
	draw_arc(Vector2(4, -4), 16.0, 0.3, 2.5, 12, gold, 3.0)
	draw_set_transform(Vector2.ZERO)
	draw_health_bar(42.0)
