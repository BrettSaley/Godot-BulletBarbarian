extends Enemy
## Vorkath (OSRS). An undead dragon that barely moves but fills the area with
## fire: aimed fireballs, dragonfire bombs that land where you stand, a
## freezing breath that slows you, and the acid phase, where the ground fills
## with acid pools while it rapid-fires fireballs at you.

const FIRE := Color(1, 0.5, 0.15)
const ICE := Color(0.5, 0.8, 1.0)
const ACID := Color(0.5, 0.8, 0.15)
const ACID_PHASE_DURATION := 5.0

var facing := 1.0


func _init() -> void:
	display_name = "Vorkath"
	radius = 32.0
	move_speed = 35.0
	max_hp = 1600.0
	xp = 500
	bullet_damage = 30.0
	contact_damage = 40.0
	is_boss = true
	aggro_range = 650.0
	preferred_range = 260.0
	projectile_style = Projectiles.Style.ORB


func _attacks() -> Array:
	return ["fireball", "fireball", "bomb", "ice", "acid"]


func _on_attack_started(attack_name: String) -> void:
	if attack_name != "acid":
		return
	attack_timer = ACID_PHASE_DURATION
	var placed := 0
	while placed < 30:
		var at := position + Vector2.from_angle(randf() * TAU) * randf_range(60, 380)
		if at.distance_to(player.position) > 45.0:
			hazards().pool(at, 22.0, ACID_PHASE_DURATION + 2.0, bullet_damage * 1.5, "Vorkath's acid", ACID)
			placed += 1


func _move(delta: float) -> void:
	# Vorkath stays near where it spawned and turns to face the player.
	position = position.move_toward(home, move_speed * delta)
	facing = 1.0 if player.position.x >= position.x else -1.0


func _fire(attack_name: String) -> float:
	var d := difficulty
	match attack_name:
		"fireball":
			fan(position, dir_to_player(position), 1, 0.2, lerpf(170, 210, d), 9.0, FIRE)
			return 0.8
		"bomb":
			hazards().blast(player.position, 70.0, 1.3, bullet_damage * 3.0, "Vorkath's dragonfire bomb", FIRE)
			return 1.5
		"ice":
			hazards().blast(player.position, 55.0, 0.8, bullet_damage, "Vorkath's ice breath", ICE, 2.0)
			fan(position, dir_to_player(position), 2, 0.25, 160.0, 7.0, ICE)
			return 1.2
		"acid":
			shoot(position, dir_to_player(position) * 240.0, 7.0, ACID.lightened(0.2), 0.6)
			return 0.22
	return 1.0


func _draw() -> void:
	var bone := Color(0.78, 0.8, 0.85)
	var hide := Color(0.3, 0.36, 0.45)
	var dark := Color(0.12, 0.14, 0.2)
	var flap := sin(time * 3.0) * 0.12
	draw_set_transform(Vector2(0, 36), 0.0, Vector2(1.5, 0.35))
	draw_circle(Vector2.ZERO, 32.0, Color(0, 0, 0, 0.3))
	draw_set_transform(Vector2.ZERO, 0.0, Vector2(facing, 1.0))
	# Tattered bony wings
	for side in [-1.0, 1.0]:
		var wing := PackedVector2Array([Vector2(side * 14, -6), Vector2(side * 62, -40 - flap * 80), Vector2(side * 56, -8),
				Vector2(side * 66, 6), Vector2(side * 44, 4), Vector2(side * 48, 20), Vector2(side * 18, 10)])
		draw_colored_polygon(wing, hide.darkened(0.2))
		draw_line(Vector2(side * 14, -6), Vector2(side * 62, -40 - flap * 80), bone, 2.5)
		draw_line(Vector2(side * 30, -18), Vector2(side * 56, -8), bone, 1.5)
	# Body with exposed ribs
	draw_circle(Vector2(0, 8), 24.0, hide)
	for r in 3:
		draw_arc(Vector2(0, 2 + r * 7), 14.0 - r, 0.4, PI - 0.4, 10, bone, 2.0)
	# Skull head with horns and glowing eyes
	draw_colored_polygon(PackedVector2Array([Vector2(-10, -26), Vector2(-22, -44), Vector2(-4, -30)]), bone)
	draw_colored_polygon(PackedVector2Array([Vector2(10, -26), Vector2(22, -44), Vector2(4, -30)]), bone)
	draw_circle(Vector2(0, -22), 14.0, bone)
	draw_rect(Rect2(Vector2(-9, -16), Vector2(18, 14)), bone)
	draw_circle(Vector2(-5, -23), 3.5, dark)
	draw_circle(Vector2(5, -23), 3.5, dark)
	var glow := ACID if attack == "acid" else Color(0.4, 0.8, 1)
	draw_circle(Vector2(-5, -23), 2.0, glow)
	draw_circle(Vector2(5, -23), 2.0, glow)
	for t in 4:
		draw_line(Vector2(-6 + t * 4, -4), Vector2(-6 + t * 4, 0), dark, 1.5)
	draw_set_transform(Vector2.ZERO)
	draw_health_bar(40.0)
