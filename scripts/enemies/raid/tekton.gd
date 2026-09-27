extends Enemy
## Tekton (Chambers of Xeric). A hulking golem that stomps after you and
## brings its hammer down in a wide blast. Now and then it retreats to its
## anvil and hammers out a shower of molten sparks.

const SPARK := Color(1.0, 0.55, 0.15)

## Set by the raid.
var anvil: Vector2
var slam_anim := 0.0
var facing := 1.0


func _init() -> void:
	display_name = "Tekton"
	radius = 30.0
	move_speed = 75.0
	max_hp = 1100.0
	xp = 300
	bullet_damage = 28.0
	contact_damage = 45.0
	is_boss = true
	drops_loot = false
	aggro_range = 2000.0
	projectile_style = Projectiles.Style.ORB


func _attacks() -> Array:
	return ["hammer", "hammer", "anvil"]


func _on_attack_started(attack_name: String) -> void:
	if attack_name == "anvil":
		attack_timer = 4.5


func _move(delta: float) -> void:
	slam_anim = maxf(slam_anim - delta * 3.0, 0.0)
	var goal := anvil if attack == "anvil" else player.position
	var stop_distance := 4.0 if attack == "anvil" else 50.0
	if position.distance_to(goal) > stop_distance:
		var before := position
		position = position.move_toward(goal, move_speed * (2.0 if attack == "anvil" else 1.0) * delta)
		if absf(position.x - before.x) > 0.1:
			facing = signf(position.x - before.x)


func _fire(attack_name: String) -> float:
	match attack_name:
		"hammer":
			slam_anim = 1.0
			hazards().blast(position, 95.0, 0.75, bullet_damage * 2.5, "Tekton's hammer", Color(1, 0.6, 0.3))
			ring(position, 10, 120.0, 6.0, SPARK)
			return 1.3
		"anvil":
			if position.distance_to(anvil) > 10.0:
				return 0.1  # still walking over
			ring(anvil, 12, 140.0, 6.0, SPARK)
			fan(anvil, dir_to_player(anvil), 1, 0.2, 180.0, 7.0, SPARK.lightened(0.3))
			return 0.45
	return 1.0


func _draw() -> void:
	# The anvil, drawn from Tekton's point of view so it stays put.
	var a := (anvil - position) / size_scale
	draw_rect(Rect2(a + Vector2(-22, -6), Vector2(44, 12)), Color(0.25, 0.25, 0.28))
	draw_rect(Rect2(a + Vector2(-12, 6), Vector2(24, 14)), Color(0.2, 0.2, 0.22))
	if attack == "anvil":
		draw_circle(a + Vector2(0, -8), 8.0, Color(SPARK, 0.6))

	var plate := Color(0.42, 0.45, 0.52)
	var dark := Color(0.2, 0.2, 0.25)
	var molten := Color(1.0, 0.5, 0.15)
	draw_set_transform(Vector2(0, 34), 0.0, Vector2(1.2, 0.35))
	draw_circle(Vector2.ZERO, 30.0, Color(0, 0, 0, 0.3))
	var bob := -absf(sin(time * 5.0)) * 2.0
	draw_set_transform(Vector2(0, bob + slam_anim * 4.0), 0.0, Vector2(facing, 1.0))
	# Legs and body plates with molten seams
	draw_rect(Rect2(Vector2(-18, 16), Vector2(12, 18)), dark)
	draw_rect(Rect2(Vector2(6, 16), Vector2(12, 18)), dark)
	draw_circle(Vector2(0, 4), 24.0, plate)
	draw_line(Vector2(-18, 0), Vector2(18, 0), molten, 2.0)
	draw_line(Vector2(0, -16), Vector2(0, 22), molten, 2.0)
	draw_circle(Vector2(-24, 2), 9.0, dark)
	# Hammer: raised, then slammed down
	var swing := -1.4 + slam_anim * 2.0
	var hand := Vector2(26, 0)
	var head := hand + Vector2.from_angle(swing) * 30.0
	draw_line(hand, head, Color(0.35, 0.22, 0.1), 5.0)
	draw_set_transform(Vector2(0, bob + slam_anim * 4.0) + head * Vector2(facing, 1.0), swing * facing, Vector2(facing, 1.0))
	draw_rect(Rect2(Vector2(-7, -12), Vector2(14, 24)), Color(0.3, 0.3, 0.34))
	draw_set_transform(Vector2(0, bob + slam_anim * 4.0), 0.0, Vector2(facing, 1.0))
	draw_circle(hand, 9.0, dark)
	# Helmeted head with molten eyes
	draw_circle(Vector2(0, -22), 13.0, plate.darkened(0.15))
	draw_rect(Rect2(Vector2(-10, -24), Vector2(20, 4)), Color(0.05, 0.05, 0.05))
	draw_circle(Vector2(-4, -22), 2.0, molten)
	draw_circle(Vector2(4, -22), 2.0, molten)
	draw_set_transform(Vector2.ZERO)
	draw_health_bar(40.0)
