extends Enemy
## Ba-Ba (Tombs of Amascut, Path of Apmeken). A great baboon who slams the
## floor, sends rows of boulders rolling across the room (find the gap), and
## brings the ceiling down in falling rocks. At 66% and 33% health she calls
## her baboon troop.

const BOULDER := Color(0.65, 0.55, 0.4)
const TROOP_AT := [0.66, 0.33]
const LANE := 60.0

## Set by the raid.
var room: Rect2
var troops_left := TROOP_AT.duplicate()
var slam_anim := 0.0
var facing := 1.0


func _init() -> void:
	display_name = "Ba-Ba"
	radius = 30.0
	move_speed = 90.0
	max_hp = 2000.0
	xp = 900
	bullet_damage = 32.0
	contact_damage = 50.0
	is_boss = true
	drops_loot = false
	aggro_range = 2000.0
	preferred_range = 160.0


func _attacks() -> Array:
	return ["slam", "boulders", "rockfall"]


func _move(delta: float) -> void:
	slam_anim = maxf(slam_anim - delta * 3.0, 0.0)
	super._move(delta)
	facing = 1.0 if player.position.x >= position.x else -1.0
	if not troops_left.is_empty() and hp / max_hp < troops_left[0]:
		troops_left.pop_front()
		for i in 3:
			summon(Minion.make("baboon"), position + Vector2.from_angle(TAU * i / 3.0) * 60.0)
		DamageText.spawn(get_parent(), position + Vector2(0, -60), "Ba-Ba calls her troop!", BOULDER.lightened(0.3), 18)


func _fire(attack_name: String) -> float:
	match attack_name:
		"slam":
			slam_anim = 1.0
			hazards().blast(position, 120.0, 0.7, bullet_damage * 2.5, display_name, BOULDER.lightened(0.2))
			ring(position, 12, 120.0, 7.0, BOULDER)
			return 1.3
		"boulders":
			# A column of boulders rolls across from the west wall with a two-lane gap.
			var lanes := int(room.size.y / LANE)
			var gap := randi() % (lanes - 1)
			for lane in lanes:
				if lane == gap or lane == gap + 1:
					continue
				shoot(Vector2(room.position.x + 20, room.position.y + (lane + 0.5) * LANE), Vector2(240, 0), 16.0, BOULDER, 2.0)
			return 2.2
		"rockfall":
			hazards().blast(player.position, 45.0, 1.1, bullet_damage * 2.0, "Falling rocks", BOULDER)
			for i in 5:
				var at := Vector2(randf_range(room.position.x + 40, room.end.x - 40), randf_range(room.position.y + 40, room.end.y - 40))
				hazards().blast(at, 45.0, 1.1, bullet_damage * 2.0, "Falling rocks", BOULDER)
			return 1.3
	return 1.0


func _draw() -> void:
	var fur := Color(0.5, 0.42, 0.35)
	var face := Color(0.9, 0.5, 0.45)
	var gold := Color(0.95, 0.8, 0.3)
	draw_set_transform(Vector2(0, 32), 0.0, Vector2(1.3, 0.3))
	draw_circle(Vector2.ZERO, 28.0, Color(0, 0, 0, 0.3))
	draw_set_transform(Vector2(0, slam_anim * 4.0 - absf(sin(time * 6.0)) * 2.0), 0.0, Vector2(facing, 1.0))
	draw_circle(Vector2(0, 8), 26.0, fur)
	draw_circle(Vector2(0, 12), 14.0, fur.lightened(0.15))
	for side in [-1.0, 1.0]:
		var fist := Vector2(side * 28, 16 - slam_anim * 14.0)
		draw_line(Vector2(side * 18, -2), fist, fur, 8.0)
		draw_circle(fist, 8.0, fur.darkened(0.15))
		draw_arc(Vector2(side * 18, 2), 7.0, 0.0, TAU, 10, gold, 2.5)
	# Big maned head with a pink muzzle
	draw_circle(Vector2(0, -18), 18.0, fur.lightened(0.05))
	draw_circle(Vector2(0, -14), 11.0, face)
	draw_circle(Vector2(-5, -22), 2.5, Color(0.1, 0.05, 0.05))
	draw_circle(Vector2(5, -22), 2.5, Color(0.1, 0.05, 0.05))
	draw_line(Vector2(-4, -10), Vector2(4, -10), Color(0.4, 0.1, 0.1), 2.0)
	draw_arc(Vector2(0, -18), 18.0, PI + 0.4, TAU - 0.4, 12, gold, 3.0)
	draw_set_transform(Vector2.ZERO)
	draw_health_bar(42.0)
