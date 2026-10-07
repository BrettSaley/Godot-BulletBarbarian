extends Enemy
## The Pestilent Bloat (Theatre of Blood). A swollen corpse that lumbers
## around the edge of the room while flies drop rotting limbs all over the
## floor. Touching it hurts badly. Every so often it collapses asleep and
## takes triple damage (it barely feels hits while walking), then wakes with
## a huge stomp - get clear.

const ROT := Color(0.45, 0.5, 0.3)
const WALK_TIME := 8.0
const SLEEP_TIME := 3.5
## Damage taken while walking (barely scratched) and while collapsed (wide open).
const AWAKE_DAMAGE := 0.2
const ASLEEP_DAMAGE := 3.0

## Set by the raid.
var room: Rect2
var track: Array[Vector2] = []
var next_corner := 0
var walk_timer := WALK_TIME
var sleep_timer := 0.0


func _init() -> void:
	display_name = "The Pestilent Bloat"
	radius = 34.0
	move_speed = 75.0
	max_hp = 1800.0
	xp = 700
	bullet_damage = 28.0
	contact_damage = 60.0
	is_boss = true
	drops_loot = false
	aggro_range = 2000.0


func _on_setup() -> void:
	var inset := room.grow(-110)
	track = [inset.position, Vector2(inset.end.x, inset.position.y), inset.end, Vector2(inset.position.x, inset.end.y)]


func is_asleep() -> bool:
	return sleep_timer > 0.0


func take_damage(amount: float) -> void:
	super.take_damage(amount * (ASLEEP_DAMAGE if is_asleep() else AWAKE_DAMAGE))


func _attacks() -> Array:
	return ["limbs"]


func _move(delta: float) -> void:
	if is_asleep():
		sleep_timer -= delta
		if sleep_timer <= 0.0:
			# Wakes with a stomp.
			hazards().blast(position, 170.0, 0.45, bullet_damage * 3.0, "Bloat's stomp", ROT.lightened(0.2))
			ring(position, 18, 130.0, 7.0, ROT)
			walk_timer = WALK_TIME
		return
	walk_timer -= delta
	if walk_timer <= 0.0:
		sleep_timer = SLEEP_TIME
		DamageText.spawn(get_parent(), position + Vector2(0, -60), "Zzz... (triple damage!)", Color(0.8, 0.9, 0.6), 16)
		return
	position = position.move_toward(track[next_corner], move_speed * delta)
	if position.distance_to(track[next_corner]) < 4.0:
		next_corner = (next_corner + 1) % track.size()


func _fire(_attack_name: String) -> float:
	if is_asleep():
		return 0.3
	for i in 5:
		var at := Vector2(randf_range(room.position.x + 30, room.end.x - 30), randf_range(room.position.y + 30, room.end.y - 30))
		hazards().blast(at, 36.0, 1.1, bullet_damage * 1.8, "Falling limbs", ROT)
	hazards().blast(player.position, 36.0, 1.1, bullet_damage * 1.8, "Falling limbs", ROT)
	return 1.1


func _draw() -> void:
	var flesh := Color(0.62, 0.6, 0.48)
	draw_set_transform(Vector2(0, 36), 0.0, Vector2(1.3, 0.3))
	draw_circle(Vector2.ZERO, 32.0, Color(0, 0, 0, 0.3))
	var squash := Vector2(1.15, 0.8) if is_asleep() else Vector2(1.0, 1.0 + sin(time * 4.0) * 0.03)
	draw_set_transform(Vector2(0, 8 if is_asleep() else 0), 0.0, squash)
	# Swollen stitched body
	draw_circle(Vector2(0, 4), 32.0, flesh)
	draw_circle(Vector2(-10, 10), 16.0, flesh.darkened(0.08))
	for s in 4:
		var y := -14.0 + s * 9.0
		draw_line(Vector2(-18, y), Vector2(18, y + 4), Color(0.25, 0.2, 0.15), 1.5)
		for k in 5:
			draw_line(Vector2(-16 + k * 8, y - 2), Vector2(-14 + k * 8, y + 4), Color(0.25, 0.2, 0.15), 1.0)
	# Small head sunk into the bulk
	draw_circle(Vector2(0, -26), 11.0, flesh.darkened(0.1))
	if is_asleep():
		draw_line(Vector2(-6, -27), Vector2(-2, -27), Color(0.1, 0.1, 0.1), 2.0)
		draw_line(Vector2(2, -27), Vector2(6, -27), Color(0.1, 0.1, 0.1), 2.0)
	else:
		draw_circle(Vector2(-4, -27), 2.5, Color(0.9, 0.85, 0.3))
		draw_circle(Vector2(4, -27), 2.5, Color(0.9, 0.85, 0.3))
	draw_set_transform(Vector2.ZERO)
	# Buzzing flies
	for f in 8:
		draw_circle(Vector2.from_angle(time * (4.0 + f * 0.3) + f) * (36.0 + (f % 3) * 6.0), 1.8, Color(0.1, 0.1, 0.1))
	draw_health_bar(44.0)
