extends Enemy
## Ork (OSRS, Bandos Stronghold): an armoured Bandosian brute that charges in
## and smashes the ground with its club.

const DIRT := Color(0.55, 0.45, 0.3)

var facing := 1.0
var smash_anim := 0.0


func _init() -> void:
	display_name = "Ork"
	radius = 17.0
	move_speed = 90.0
	max_hp = 240.0
	xp = 36
	bullet_damage = 22.0
	contact_damage = 30.0
	preferred_range = 110.0


func _attacks() -> Array:
	return ["smash", "charge"]


func _move(delta: float) -> void:
	smash_anim = maxf(smash_anim - delta * 3.0, 0.0)
	if attack == "charge":
		position = position.move_toward(player.position, move_speed * 1.5 * delta)
	else:
		super._move(delta)
	facing = 1.0 if player.position.x >= position.x else -1.0


func _fire(attack_name: String) -> float:
	match attack_name:
		"smash":
			smash_anim = 1.0
			hazards().blast(player.position, 55.0, 0.9, bullet_damage * 2.0, display_name, DIRT.lightened(0.2))
			ring(position, 8, 120.0, 6.0, DIRT)
			return 1.3
		"charge":
			return 99.0
	return 1.0


func _draw() -> void:
	var skin := Color(0.4, 0.55, 0.3)
	var armor := Color(0.45, 0.4, 0.3)
	draw_set_transform(Vector2(0, 20), 0.0, Vector2(1.0, 0.35))
	draw_circle(Vector2.ZERO, 15.0, Color(0, 0, 0, 0.3))
	draw_set_transform(Vector2(0, -absf(sin(time * 6.0)) * 2.0), 0.0, Vector2(facing, 1.0))
	draw_rect(Rect2(Vector2(-8, 10), Vector2(6, 10)), skin.darkened(0.2))
	draw_rect(Rect2(Vector2(2, 10), Vector2(6, 10)), skin.darkened(0.2))
	# Bandos plate over a green body
	draw_circle(Vector2(0, 2), 12.0, skin)
	draw_rect(Rect2(Vector2(-11, -4), Vector2(22, 12)), armor)
	draw_line(Vector2(-11, 2), Vector2(11, 2), Color(0.75, 0.6, 0.3), 2.0)
	# Club swung down on a smash
	var swing := -1.2 + smash_anim * 1.8
	var club := Vector2(13, 0) + Vector2.from_angle(swing) * 18.0
	draw_line(Vector2(13, 0), club, Color(0.4, 0.25, 0.1), 4.0)
	draw_circle(club, 5.0, Color(0.35, 0.22, 0.1))
	# Tusked head
	draw_circle(Vector2(0, -12), 7.5, skin)
	draw_colored_polygon(PackedVector2Array([Vector2(-3, -8), Vector2(-1, -8), Vector2(-2, -12)]), Color(0.95, 0.92, 0.85))
	draw_colored_polygon(PackedVector2Array([Vector2(1, -8), Vector2(3, -8), Vector2(2, -12)]), Color(0.95, 0.92, 0.85))
	draw_circle(Vector2(-3, -14), 1.5, Color(0.9, 0.2, 0.1))
	draw_circle(Vector2(3, -14), 1.5, Color(0.9, 0.2, 0.1))
	draw_set_transform(Vector2.ZERO)
	draw_health_bar(24.0)
