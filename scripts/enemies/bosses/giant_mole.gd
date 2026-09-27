extends Enemy
## Giant Mole (OSRS). Throws dirt, pounds the ground around you, and burrows:
## a mound of earth tunnels toward where you're standing and the mole bursts
## out there, so keep moving when the ground shakes.

const DIRT := Color(0.5, 0.36, 0.22)
const BURROW_TIME := 1.8

var burrow_timer := 0.0
var burrow_target: Vector2
var burrow_start: Vector2
var facing := 1.0


func _init() -> void:
	display_name = "Giant Mole"
	radius = 28.0
	move_speed = 90.0
	max_hp = 1300.0
	xp = 400
	bullet_damage = 26.0
	contact_damage = 35.0
	is_boss = true
	aggro_range = 620.0


func _attacks() -> Array:
	return ["dirt", "burrow", "pound"]


func _on_attack_started(attack_name: String) -> void:
	if attack_name == "burrow":
		untargetable = true
		burrow_timer = BURROW_TIME
		burrow_start = position
		burrow_target = player.position
		hazards().blast(burrow_target, 75.0, BURROW_TIME, bullet_damage * 2.0, "Giant Mole", DIRT.lightened(0.2))


func _move(delta: float) -> void:
	if burrow_timer > 0.0:
		burrow_timer -= delta
		position = burrow_start.lerp(burrow_target, 1.0 - burrow_timer / BURROW_TIME)
		if burrow_timer <= 0.0:
			untargetable = false
			ring(position, int(lerpf(12, 20, difficulty)), 130.0, 7.0, DIRT)
		return
	super._move(delta)
	facing = 1.0 if player.position.x >= position.x else -1.0


func _fire(attack_name: String) -> float:
	match attack_name:
		"dirt":
			fan(position, dir_to_player(position), 2, 0.2, lerpf(160, 200, difficulty), 7.0, DIRT)
			return 0.7
		"pound":
			hazards().blast(player.position, 55.0, 0.9, bullet_damage * 1.5, "Giant Mole", DIRT.lightened(0.2))
			return 0.6
	return 99.0  # burrow resolves in _move


func _draw() -> void:
	if burrow_timer > 0.0:
		# Only the moving mound of earth shows while it tunnels.
		draw_circle(Vector2.ZERO, 18.0, DIRT.darkened(0.2))
		draw_circle(Vector2(-5, -4), 9.0, DIRT)
		for k in 5:
			var clod := Vector2.from_angle(time * 9.0 + k * 1.25) * randf_range(14, 24)
			draw_circle(clod, 3.0, DIRT.lightened(0.15))
		return
	var fur := Color(0.28, 0.22, 0.2)
	var pink := Color(0.95, 0.6, 0.62)
	draw_set_transform(Vector2(0, 28), 0.0, Vector2(1.3, 0.35))
	draw_circle(Vector2.ZERO, 28.0, Color(0, 0, 0, 0.3))
	var bob := -absf(sin(time * 7.0)) * 2.0
	draw_set_transform(Vector2(0, bob), 0.0, Vector2(facing, 1.0))
	# Round furry body and big digging claws
	draw_circle(Vector2(0, 6), 26.0, fur)
	draw_circle(Vector2(0, 12), 16.0, fur.lightened(0.12))
	for side in [-1.0, 1.0]:
		var hand := Vector2(side * 25, 10)
		draw_circle(hand, 9.0, pink)
		for c in 4:
			var tip := hand + Vector2(side * (4 + c * 1.5), -6 + c * 4)
			draw_line(hand, tip + Vector2(side * 4, 0), Color(0.95, 0.92, 0.85), 2.0)
	# Snout, nose and tiny squinty eyes
	draw_circle(Vector2(0, -8), 14.0, fur)
	draw_circle(Vector2(0, -2), 7.0, pink.darkened(0.1))
	draw_circle(Vector2(0, -3), 4.0, pink.darkened(0.35))
	draw_line(Vector2(-9, -13), Vector2(-4, -11), Color(0.05, 0.02, 0.02), 2.0)
	draw_line(Vector2(9, -13), Vector2(4, -11), Color(0.05, 0.02, 0.02), 2.0)
	for side in [-1.0, 1.0]:
		for w in 3:
			draw_line(Vector2(side * 6, -2), Vector2(side * 17, -6 + w * 4), Color(0.9, 0.85, 0.8, 0.7), 1.0)
	draw_set_transform(Vector2.ZERO)
	draw_health_bar(36.0)
