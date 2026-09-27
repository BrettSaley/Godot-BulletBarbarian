extends Enemy
## Hill Giant (OSRS, Giants' Plateau): big and slow. Stomps toward you and
## slams its club where you're standing, and hurls boulders.

const BOULDER := Color(0.55, 0.5, 0.45)

var facing := 1.0
var slam_anim := 0.0


func _init() -> void:
	display_name = "Hill Giant"
	radius = 20.0
	move_speed = 60.0
	max_hp = 220.0
	xp = 35
	bullet_damage = 22.0
	contact_damage = 30.0
	preferred_range = 170.0
	aggro_range = 480.0


func _attacks() -> Array:
	return ["club", "boulders"]


func _fire(attack_name: String) -> float:
	match attack_name:
		"club":
			slam_anim = 1.0
			hazards().blast(player.position, 55.0, 1.0, bullet_damage * 2.0, display_name, Color(0.8, 0.6, 0.3))
			return lerpf(1.5, 1.0, difficulty)
		"boulders":
			fan(position, dir_to_player(position), 1, 0.3, lerpf(130, 160, difficulty), 10.0, BOULDER)
			return lerpf(1.2, 0.8, difficulty)
	return 1.0


func _draw() -> void:
	facing = 1.0 if player.position.x >= position.x else -1.0
	slam_anim = maxf(slam_anim - 0.05, 0.0)
	var skin := Color(0.85, 0.66, 0.5)
	var hide := Color(0.5, 0.36, 0.22)
	draw_set_transform(Vector2(0, 24), 0.0, Vector2(1.0, 0.35))
	draw_circle(Vector2.ZERO, 18.0, Color(0, 0, 0, 0.3))
	var bob := -absf(sin(time * 5.0)) * 2.0
	draw_set_transform(Vector2(0, bob), 0.0, Vector2(facing, 1.0))
	# Legs, loincloth body, arms
	draw_rect(Rect2(Vector2(-9, 12), Vector2(6, 12)), skin.darkened(0.1))
	draw_rect(Rect2(Vector2(3, 12), Vector2(6, 12)), skin.darkened(0.1))
	draw_circle(Vector2(0, 2), 15.0, skin)
	draw_rect(Rect2(Vector2(-14, 6), Vector2(28, 9)), hide)
	draw_circle(Vector2(-15, 2), 5.0, skin)
	# Club raised, swung down during a slam
	var swing := -1.2 + slam_anim * 1.8
	var hand := Vector2(15, 0)
	var club_end := hand + Vector2.from_angle(swing) * 22.0
	draw_line(hand, club_end, Color(0.45, 0.28, 0.12), 5.0)
	draw_circle(club_end, 6.0, Color(0.4, 0.25, 0.1))
	draw_circle(hand, 5.0, skin)
	# Head with a single brow
	draw_circle(Vector2(0, -16), 9.0, skin)
	draw_line(Vector2(-6, -19), Vector2(6, -19), Color(0.2, 0.12, 0.05), 2.5)
	draw_circle(Vector2(-3, -16), 1.5, Color(0.1, 0.1, 0.1))
	draw_circle(Vector2(3, -16), 1.5, Color(0.1, 0.1, 0.1))
	draw_line(Vector2(-3, -11), Vector2(3, -11), Color(0.2, 0.12, 0.05), 1.5)
	draw_set_transform(Vector2.ZERO)
	draw_health_bar(28.0)
