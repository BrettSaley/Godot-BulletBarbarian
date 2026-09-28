extends Enemy
## Xarpus (Theatre of Blood). A giant bloated tick in the middle of the room
## that spits poison splats which linger on the floor, slowly filling the room.
## Below 25% health it starts to stare: its gaze sweeps between directions,
## and any hit you land while standing in its gaze is reflected back at you.

const POISON := Color(0.45, 0.75, 0.2)
const STARE_BELOW := 0.25
const GAZE_WIDTH := 0.9  # radians either side of where it looks
const TURN_EVERY := 3.5

var gaze_angle := PI / 2.0
var turn_timer := TURN_EVERY


func _init() -> void:
	display_name = "Xarpus"
	radius = 32.0
	move_speed = 0.0
	max_hp = 1700.0
	xp = 700
	bullet_damage = 28.0
	contact_damage = 45.0
	is_boss = true
	drops_loot = false
	aggro_range = 2000.0
	projectile_style = Projectiles.Style.ORB


func is_staring() -> bool:
	return hp / max_hp < STARE_BELOW


func player_in_gaze() -> bool:
	return absf(angle_difference(gaze_angle, (player.position - position).angle())) < GAZE_WIDTH


func take_damage(amount: float) -> void:
	if is_staring() and player_in_gaze() and is_active() and not player_is_god():
		player.take_damage(amount * 0.2, "Xarpus's reflected gaze")
		DamageText.spawn(get_parent(), position + Vector2(0, -radius - 8), "REFLECTED", Color(1, 0.4, 0.4))
		return
	super.take_damage(amount)


func _attacks() -> Array:
	return ["spit"]


func _move(delta: float) -> void:
	if not is_staring():
		return
	turn_timer -= delta
	if turn_timer <= 0.0:
		turn_timer = TURN_EVERY
		gaze_angle = [0.0, PI / 2.0, PI, -PI / 2.0].pick_random()


func _fire(_attack_name: String) -> float:
	hazards().pool(player.position, 36.0, 14.0, bullet_damage * 1.3, "Xarpus's poison", POISON)
	fan(position, dir_to_player(position), 1, 0.2, 170.0, 7.0, POISON.lightened(0.2))
	return 0.7 if is_staring() else 1.1


func _draw() -> void:
	# The gaze cone, so you can see where it's safe to attack from.
	if is_staring():
		var cone := PackedVector2Array([Vector2.ZERO])
		for k in 9:
			cone.append(Vector2.from_angle(gaze_angle - GAZE_WIDTH + GAZE_WIDTH * 2.0 * k / 8.0) * 400.0 / size_scale)
		draw_colored_polygon(cone, Color(1, 0.2, 0.2, 0.12 + 0.05 * sin(time * 6.0)))
	var shell := Color(0.25, 0.22, 0.22)
	draw_set_transform(Vector2(0, 32), 0.0, Vector2(1.3, 0.3))
	draw_circle(Vector2.ZERO, 30.0, Color(0, 0, 0, 0.3))
	draw_set_transform(Vector2.ZERO)
	for side in [-1.0, 1.0]:
		for leg in 4:
			var base := Vector2(side * 18, -12 + leg * 9)
			draw_line(base, base + Vector2(side * 22, sin(time * 5.0 + leg) * 3.0 + leg * 3 - 4), shell.darkened(0.3), 4.0)
	# Bloated body with red veins
	draw_circle(Vector2(0, 4), 30.0, shell)
	for v in 5:
		var start := Vector2.from_angle(v * 1.25) * 8.0
		draw_line(start, start * 3.2 + Vector2(0, 4), Color(0.6, 0.1, 0.1), 1.5)
	# Head, and the great eye that turns to stare
	draw_circle(Vector2(0, -20), 13.0, shell.lightened(0.1))
	var look := Vector2.from_angle(gaze_angle) * 4.0 if is_staring() else Vector2.ZERO
	draw_circle(Vector2(0, -20), 8.0, Color(0.95, 0.9, 0.6) if is_staring() else Color(0.6, 0.55, 0.4))
	draw_circle(Vector2(0, -20) + look, 3.5, Color(0.6, 0.05, 0.05))
	draw_health_bar(42.0)
