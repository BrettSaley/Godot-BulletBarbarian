extends Enemy
## The King Black Dragon (his lair). Three heads, four breaths:
##   fire   - a wide cone of flame
##   poison - lingering green clouds
##   ice    - a frozen blast that slows you
##   shock  - a line of lightning strikes

const FIRE := Color(1.0, 0.5, 0.15)
const POISON := Color(0.45, 0.8, 0.25)
const ICE := Color(0.6, 0.85, 1.0)
const SHOCK := Color(0.9, 0.9, 0.4)

var room: Rect2
var facing := 1.0


func _init() -> void:
	display_name = "King Black Dragon"
	radius = 34.0
	move_speed = 60.0
	max_hp = 1500.0
	xp = 700
	bullet_damage = 30.0
	contact_damage = 50.0
	is_boss = true
	drops_loot = false
	aggro_range = 650.0
	preferred_range = 220.0
	projectile_style = Projectiles.Style.ORB


func _attacks() -> Array:
	return ["fire", "poison", "ice", "shock"]


func _move(delta: float) -> void:
	super._move(delta)
	facing = 1.0 if player.position.x >= position.x else -1.0


func _fire(attack_name: String) -> float:
	match attack_name:
		"fire":
			fan(position, dir_to_player(position), 4, 0.12, 180.0, 8.0, FIRE)
			return 0.9
		"poison":
			for i in 3:
				hazards().pool(player.position + Vector2.from_angle(randf() * TAU) * randf_range(0, 100), 45.0, 6.0,
						bullet_damage * 1.3, "KBD's poison breath", POISON)
			return 1.5
		"ice":
			hazards().blast(player.position, 70.0, 1.0, bullet_damage * 2.0, "KBD's ice breath", ICE, 2.5)
			return 1.3
		"shock":
			var dir := dir_to_player(position)
			for i in range(1, 7):
				hazards().blast(position + dir * i * 60.0, 36.0, 0.8 + i * 0.1, bullet_damage * 2.2, "KBD's shock breath", SHOCK)
			return 1.4
	return 1.0


func _draw() -> void:
	var scale_color := Color(0.12, 0.1, 0.14)
	var flap := sin(time * 3.0)
	draw_set_transform(Vector2(0, 36), 0.0, Vector2(1.6, 0.3))
	draw_circle(Vector2.ZERO, 32.0, Color(0, 0, 0, 0.35))
	draw_set_transform(Vector2.ZERO, 0.0, Vector2(facing, 1.0))
	for side in [-1.0, 1.0]:
		draw_colored_polygon(PackedVector2Array([Vector2(side * 12, -6), Vector2(side * 62, -36 - flap * 10), Vector2(side * 58, 0),
				Vector2(side * 40, 10), Vector2(side * 16, 8)]), scale_color.lightened(0.08))
	draw_circle(Vector2(0, 8), 26.0, scale_color)
	draw_circle(Vector2(0, 12), 14.0, Color(0.3, 0.25, 0.3))
	# Three heads on three necks, each glowing with a different breath
	var head_colors := [FIRE, POISON, ICE]
	for h in 3:
		var head := Vector2(14 + (h - 1) * 16, -26 - absf(h - 1) * -6)
		draw_line(Vector2((h - 1) * 8, -6), head, scale_color, 7.0)
		draw_circle(head, 9.0, scale_color.lightened(0.05))
		draw_colored_polygon(PackedVector2Array([head + Vector2(-5, -6), head + Vector2(-8, -16), head + Vector2(-1, -8)]), Color(0.5, 0.45, 0.4))
		draw_circle(head + Vector2(3, -2), 2.2, head_colors[h])
	draw_set_transform(Vector2.ZERO)
	draw_health_bar(44.0)
