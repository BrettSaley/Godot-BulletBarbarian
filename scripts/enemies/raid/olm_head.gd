extends Enemy
## The Great Olm's head, the final boss of the Chambers of Xeric. It sits in
## the north wall, shielded while either hand lives, firing alternating
## ranged and magic orbs, spraying acid pools, and trapping you between
## walls of fire. Once both hands are dead it can be hurt, and fights harder.

const ACID := Color(0.45, 0.8, 0.2)
const FIRE := Color(1.0, 0.45, 0.1)
const RANGED := Color(0.4, 0.85, 0.35)
const MAGIC := Color(0.4, 0.55, 1.0)

## Set by the raid.
var hands: Array = []
var room: Rect2
var magic_next := false
var enraged := false


func _init() -> void:
	display_name = "Great Olm"
	radius = 50.0
	move_speed = 0.0
	max_hp = 1500.0
	xp = 800
	bullet_damage = 28.0
	contact_damage = 50.0
	is_boss = true
	drops_loot = false
	aggro_range = 2000.0
	projectile_style = Projectiles.Style.ORB


func _hands_alive() -> bool:
	return hands.any(func(h): return is_instance_valid(h) and h.hp > 0.0)


func _attacks() -> Array:
	return ["orbs", "orbs", "acid", "fire_wall"]


func _move(_delta: float) -> void:
	var protected := _hands_alive()
	if untargetable and not protected:
		enraged = true
		difficulty = 1.0
		DamageText.spawn(get_parent(), position + Vector2(0, 70), "The Great Olm is vulnerable!", Color(1, 0.8, 0.3), 18)
	untargetable = protected


func _fire(attack_name: String) -> float:
	var speed_up := 0.7 if enraged else 1.0
	match attack_name:
		"orbs":
			magic_next = not magic_next
			fan(position, dir_to_player(position), 2, 0.18, 190.0, 8.0, MAGIC if magic_next else RANGED)
			return 0.6 * speed_up
		"acid":
			for i in 6:
				var at := Vector2(randf_range(room.position.x + 40, room.end.x - 40), randf_range(room.position.y + 150, room.end.y - 40))
				hazards().pool(at, 34.0, 8.0, bullet_damage * 1.4, "Great Olm's acid", ACID)
			return 2.0 * speed_up
		"fire_wall":
			# Walls of fire on both sides of the player: don't touch them.
			for offset in [-90.0, 90.0]:
				var x: float = player.position.x + offset
				hazards().rect_pool(Rect2(x - 12, room.position.y + 120, 24, room.size.y - 120), 5.0,
						bullet_damage * 3.0, "Great Olm's fire wall", FIRE)
			return 3.0 * speed_up
	return 1.0


func _draw() -> void:
	var stone := Color(0.3, 0.36, 0.33)
	var dark := Color(0.12, 0.15, 0.13)
	# Massive head emerging from the wall
	draw_colored_polygon(PackedVector2Array([Vector2(-70, -40), Vector2(70, -40), Vector2(56, 30), Vector2(30, 52),
			Vector2(-30, 52), Vector2(-56, 30)]), stone)
	draw_colored_polygon(PackedVector2Array([Vector2(-40, 20), Vector2(40, 20), Vector2(26, 46), Vector2(-26, 46)]), dark)
	# Crystal crown
	for k in 5:
		var x := -40.0 + k * 20.0
		draw_colored_polygon(PackedVector2Array([Vector2(x - 8, -38), Vector2(x, -60 - (k % 2) * 10), Vector2(x + 8, -38)]),
				Color(0.6, 0.85, 0.75))
	# Eyes: dull and half closed while shielded, blazing once vulnerable
	var eye := Color(0.3, 0.9, 0.3) if not untargetable else Color(0.35, 0.5, 0.35)
	var open := 10.0 if not untargetable else 4.0
	for side in [-1.0, 1.0]:
		draw_set_transform(Vector2(side * 24, -8), 0.0, Vector2(1.0, open / 10.0))
		draw_circle(Vector2.ZERO, 10.0, eye)
		draw_circle(Vector2.ZERO, 4.0, dark)
	draw_set_transform(Vector2.ZERO)
	# Teeth
	for t in 6:
		var x := -25.0 + t * 10.0
		draw_colored_polygon(PackedVector2Array([Vector2(x - 3, 20), Vector2(x + 3, 20), Vector2(x, 30)]), Color(0.9, 0.9, 0.8))
	if untargetable:
		draw_arc(Vector2.ZERO, 64.0, 0.0, TAU, 40, Color(0.6, 0.85, 1.0, 0.35 + 0.15 * sin(time * 4.0)), 3.0)
	draw_health_bar(60.0)
