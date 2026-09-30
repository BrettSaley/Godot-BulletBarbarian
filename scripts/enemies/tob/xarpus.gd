extends Enemy
## Xarpus (Theatre of Blood). A giant bloated tick in the middle of the room
## that spits poison splats which linger on the floor, slowly filling the room.
## Below 25% health it starts to stare: after a clear warning its gaze sweeps
## between directions, and any hit you land while standing in its gaze is
## reflected back at you. Each turn is telegraphed before the gaze moves.

const POISON := Color(0.45, 0.75, 0.2)
const GAZE := Color(1, 0.2, 0.2)
const STARE_BELOW := 0.25
const GAZE_WIDTH := 0.9  # radians either side of where it looks
const GAZE_LENGTH := 400.0
const TURN_EVERY := 3.5
## Warning before the stare starts, and before each turn of the gaze.
const WAKE_TIME := 3.0
const TURN_WARNING := 1.2
## Reflected damage: a share of the hit, capped at a share of your max HP so
## a strong weapon can't reflect an instant kill.
const REFLECT_SHARE := 0.2
const REFLECT_CAP := 0.06

var gaze_angle := PI / 2.0
var next_angle := PI / 2.0
var turn_timer := TURN_EVERY
var wake_timer := WAKE_TIME
var woke := false


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


## Below the threshold, whether or not the warning has finished.
func is_staring() -> bool:
	return hp / max_hp < STARE_BELOW


## Actually reflecting: the warning is over.
func is_reflecting() -> bool:
	return is_staring() and wake_timer <= 0.0


func player_in_gaze() -> bool:
	return absf(angle_difference(gaze_angle, (player.position - position).angle())) < GAZE_WIDTH


func take_damage(amount: float) -> void:
	if is_reflecting() and player_in_gaze() and is_active() and not player_is_god():
		player.take_damage(minf(amount * REFLECT_SHARE, player.max_hp() * REFLECT_CAP), "Xarpus's reflected gaze")
		DamageText.spawn(get_parent(), position + Vector2(0, -radius - 8), "REFLECTED", Color(1, 0.4, 0.4))
		return
	super.take_damage(amount)


func _attacks() -> Array:
	return ["spit"]


func _move(delta: float) -> void:
	if not is_staring():
		return
	if not woke:
		woke = true
		DamageText.spawn(get_parent(), position + Vector2(0, -80), "Xarpus begins to stare! Don't attack from inside its gaze!", GAZE, 16)
	if wake_timer > 0.0:
		wake_timer -= delta
		return
	turn_timer -= delta
	if turn_timer <= TURN_WARNING and next_angle == gaze_angle:
		var options := [0.0, PI / 2.0, PI, -PI / 2.0].filter(func(a): return not is_equal_approx(a, gaze_angle))
		next_angle = options.pick_random()
	if turn_timer <= 0.0:
		turn_timer = TURN_EVERY
		gaze_angle = next_angle


func _fire(_attack_name: String) -> float:
	hazards().pool(player.position, 36.0, 14.0, bullet_damage * 1.3, "Xarpus's poison", POISON)
	fan(position, dir_to_player(position), 1, 0.2, 170.0, 7.0, POISON.lightened(0.2))
	return 0.7 if is_staring() else 1.1


func _cone(angle: float) -> PackedVector2Array:
	var cone := PackedVector2Array([Vector2.ZERO])
	for k in 9:
		cone.append(Vector2.from_angle(angle - GAZE_WIDTH + GAZE_WIDTH * 2.0 * k / 8.0) * GAZE_LENGTH / size_scale)
	return cone


func _draw() -> void:
	# The gaze cone, so you can see where it's safe to attack from.
	if is_staring():
		var cone := _cone(gaze_angle)
		if wake_timer > 0.0:
			# Warning: a flashing outline only, not reflecting yet.
			var blink := 0.35 + 0.35 * absf(sin(time * 8.0))
			cone.append(Vector2.ZERO)
			draw_polyline(cone, Color(GAZE, blink), 3.0)
		else:
			draw_colored_polygon(cone, Color(GAZE, 0.22 + 0.06 * sin(time * 6.0)))
			cone.append(Vector2.ZERO)
			draw_polyline(cone, Color(GAZE, 0.9), 2.0)
			if next_angle != gaze_angle:
				# Where it's about to look next.
				var next := _cone(next_angle)
				next.append(Vector2.ZERO)
				draw_polyline(next, Color(1, 0.8, 0.3, 0.5 + 0.4 * absf(sin(time * 10.0))), 2.5)
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
	if is_staring():
		var label := "Staring in %d..." % ceili(wake_timer) if wake_timer > 0.0 else "REFLECTING"
		draw_string(ThemeDB.fallback_font, Vector2(-60, -48), label, HORIZONTAL_ALIGNMENT_CENTER, 120, 12, GAZE.lightened(0.3))
	draw_health_bar(42.0)
