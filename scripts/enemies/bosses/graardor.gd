extends Enemy
## General Graardor (OSRS, Bandos's general). A towering ogre that stomps
## after you, smashes the ground where you stand, and hurls rocks in every
## direction.

const ROCK := Color(0.55, 0.47, 0.38)

var facing := 1.0
var smash_anim := 0.0


func _init() -> void:
	display_name = "General Graardor"
	radius = 32.0
	move_speed = 80.0
	max_hp = 1600.0
	xp = 500
	bullet_damage = 30.0
	contact_damage = 45.0
	is_boss = true
	aggro_range = 650.0
	preferred_range = 90.0


func _attacks() -> Array:
	return ["smash", "rock_storm", "smash"]


func _move(delta: float) -> void:
	smash_anim = maxf(smash_anim - delta * 3.0, 0.0)
	super._move(delta)
	facing = 1.0 if player.position.x >= position.x else -1.0


func _fire(attack_name: String) -> float:
	match attack_name:
		"smash":
			smash_anim = 1.0
			hazards().blast(player.position, 80.0, 0.9, bullet_damage * 2.5, display_name, ROCK.lightened(0.2))
			return 1.2
		"rock_storm":
			ring(position, 16, 140.0, 9.0, ROCK)
			fan(position, dir_to_player(position), 1, 0.25, 170.0, 10.0, ROCK.darkened(0.2))
			return 0.9
	return 1.0


func _draw() -> void:
	var skin := Color(0.5, 0.55, 0.35)
	var armor := Color(0.45, 0.38, 0.28)
	var gold := Color(0.85, 0.7, 0.3)
	draw_set_transform(Vector2(0, 36), 0.0, Vector2(1.3, 0.35))
	draw_circle(Vector2.ZERO, 30.0, Color(0, 0, 0, 0.3))
	draw_set_transform(Vector2(0, -absf(sin(time * 4.0)) * 2.0 + smash_anim * 4.0), 0.0, Vector2(facing, 1.0))
	draw_rect(Rect2(Vector2(-16, 18), Vector2(12, 18)), skin.darkened(0.2))
	draw_rect(Rect2(Vector2(4, 18), Vector2(12, 18)), skin.darkened(0.2))
	# Huge body in Bandos plate
	draw_circle(Vector2(0, 4), 26.0, skin)
	draw_rect(Rect2(Vector2(-22, -8), Vector2(44, 24)), armor)
	draw_line(Vector2(-22, 4), Vector2(22, 4), gold, 3.0)
	draw_circle(Vector2(0, 4), 5.0, gold)
	# Spiked club
	var swing := -1.3 + smash_anim * 1.9
	var head := Vector2(28, 0) + Vector2.from_angle(swing) * 34.0
	draw_line(Vector2(28, 0), head, Color(0.4, 0.25, 0.1), 7.0)
	draw_circle(head, 10.0, Color(0.35, 0.3, 0.25))
	for s in 5:
		draw_line(head, head + Vector2.from_angle(TAU * s / 5.0 + time) * 14.0, Color(0.7, 0.7, 0.7), 2.0)
	draw_circle(Vector2(-26, 2), 10.0, skin)
	# Tusked head with an angry brow
	draw_circle(Vector2(0, -26), 14.0, skin)
	draw_line(Vector2(-10, -31), Vector2(-2, -28), Color(0.15, 0.1, 0.05), 3.0)
	draw_line(Vector2(10, -31), Vector2(2, -28), Color(0.15, 0.1, 0.05), 3.0)
	draw_circle(Vector2(-5, -26), 2.5, Color(1, 0.3, 0.1))
	draw_circle(Vector2(5, -26), 2.5, Color(1, 0.3, 0.1))
	draw_colored_polygon(PackedVector2Array([Vector2(-7, -18), Vector2(-4, -18), Vector2(-5.5, -25)]), Color(0.95, 0.92, 0.85))
	draw_colored_polygon(PackedVector2Array([Vector2(4, -18), Vector2(7, -18), Vector2(5.5, -25)]), Color(0.95, 0.92, 0.85))
	draw_set_transform(Vector2.ZERO)
	draw_health_bar(42.0)
