extends Enemy
## Sarachnis (Forthos Dungeon). A giant spider that webs the floor to slow you,
## lunges in to bite, spits venom, and calls her spawn at 66% and 33% health.

const VENOM := Color(0.6, 0.85, 0.25)
const WEB := Color(0.9, 0.9, 0.9)
const SPAWN_AT := [0.66, 0.33]

var room: Rect2
var spawns_left := SPAWN_AT.duplicate()


func _init() -> void:
	display_name = "Sarachnis"
	radius = 28.0
	move_speed = 95.0
	max_hp = 1100.0
	xp = 500
	bullet_damage = 26.0
	contact_damage = 40.0
	is_boss = true
	drops_loot = false
	aggro_range = 650.0
	preferred_range = 200.0
	projectile_style = Projectiles.Style.ORB


func _attacks() -> Array:
	return ["webs", "lunge", "venom"]


func _move(delta: float) -> void:
	if attack == "lunge":
		position = position.move_toward(player.position, move_speed * 1.8 * delta)
	else:
		super._move(delta)
	if not spawns_left.is_empty() and hp / max_hp < spawns_left[0]:
		spawns_left.pop_front()
		for i in 3:
			summon(Minion.make("spiderling"), position + Vector2.from_angle(TAU * i / 3.0) * 50.0)
		DamageText.spawn(get_parent(), position + Vector2(0, -60), "Sarachnis calls her spawn!", VENOM, 18)


func _fire(attack_name: String) -> float:
	match attack_name:
		"webs":
			for i in 3:
				hazards().pool(player.position + Vector2.from_angle(randf() * TAU) * randf_range(0, 110), 48.0, 6.0,
						0.0, "Sarachnis's web", WEB, 0.6)
			return 1.6
		"lunge":
			ring(position, 10, 120.0, 6.0, VENOM.darkened(0.2))
			return 1.2
		"venom":
			fan(position, dir_to_player(position), 2, 0.16, 190.0, 7.0, VENOM)
			return 0.7
	return 1.0


func _draw() -> void:
	var body := Color(0.3, 0.2, 0.15)
	draw_set_transform(Vector2(0, 28), 0.0, Vector2(1.4, 0.35))
	draw_circle(Vector2.ZERO, 28.0, Color(0, 0, 0, 0.3))
	draw_set_transform(Vector2.ZERO)
	for side in [-1.0, 1.0]:
		for leg in 4:
			var base := Vector2(side * 12, -8 + leg * 7)
			var knee := base + Vector2(side * 20, -12 + leg * 3 + sin(time * 10.0 + leg) * 3.0)
			draw_line(base, knee, body.lightened(0.15), 4.0)
			draw_line(knee, knee + Vector2(side * 12, 18), body.lightened(0.15), 3.0)
	draw_circle(Vector2(0, 14), 19.0, body)
	# Bone-white markings like a skull on her back
	draw_circle(Vector2(0, 14), 8.0, Color(0.85, 0.82, 0.7))
	draw_circle(Vector2(-3, 12), 2.0, body)
	draw_circle(Vector2(3, 12), 2.0, body)
	draw_circle(Vector2(0, -10), 13.0, body.lightened(0.08))
	for e in 4:
		draw_circle(Vector2(-6 + e * 4, -14), 2.0, Color(0.9, 0.25, 0.2))
	draw_colored_polygon(PackedVector2Array([Vector2(-5, -2), Vector2(-2, -2), Vector2(-4, 6)]), VENOM)
	draw_colored_polygon(PackedVector2Array([Vector2(2, -2), Vector2(5, -2), Vector2(4, 6)]), VENOM)
	draw_health_bar(40.0)
