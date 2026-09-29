extends Enemy
## The Abyssal Sire (the Abyssal Nexus). A vast demon rooted in place at
## first: tentacles slam the ground around it, miasma pools spread, and its
## spawn wriggle out after you. Below half health it tears free and
## advances; below a quarter it gathers itself for a huge explosion - run.

const FLESH := Color(0.55, 0.15, 0.22)
const MIASMA := Color(0.6, 0.3, 0.55)
const EXPLOSION_RADIUS := 230.0

var room: Rect2
var exploded := false


func _init() -> void:
	display_name = "Abyssal Sire"
	radius = 36.0
	move_speed = 55.0
	max_hp = 1700.0
	xp = 750
	bullet_damage = 32.0
	contact_damage = 50.0
	is_boss = true
	drops_loot = false
	aggro_range = 650.0
	preferred_range = 90.0
	projectile_style = Projectiles.Style.ORB


func _attacks() -> Array:
	return ["tentacles", "miasma", "spawn", "orbs"]


func _move(delta: float) -> void:
	if hp / max_hp < 0.5:
		super._move(delta)
	if not exploded and hp / max_hp < 0.25:
		exploded = true
		hazards().blast(position, EXPLOSION_RADIUS, 3.0, bullet_damage * 5.0, "The Sire's explosion", FLESH.lightened(0.3))
		DamageText.spawn(get_parent(), position + Vector2(0, -70), "The Abyssal Sire is about to explode!", FLESH.lightened(0.5), 20)


func _fire(attack_name: String) -> float:
	match attack_name:
		"tentacles":
			for i in 6:
				hazards().blast(position + Vector2.from_angle(TAU * i / 6.0 + randf()) * randf_range(80, 180), 50.0, 1.1,
						bullet_damage * 2.2, "Sire's tentacle", FLESH)
			hazards().blast(player.position, 50.0, 1.1, bullet_damage * 2.2, "Sire's tentacle", FLESH)
			return 1.5
		"miasma":
			for i in 3:
				hazards().pool(player.position + Vector2.from_angle(randf() * TAU) * randf_range(0, 110), 44.0, 7.0,
						bullet_damage * 1.3, "Abyssal miasma", MIASMA)
			return 1.6
		"spawn":
			for i in 3:
				summon(Minion.make("abyssal_spawn"), position + Vector2.from_angle(randf() * TAU) * 60.0)
			return 99.0
		"orbs":
			ring(position, 14, 120.0, 7.0, MIASMA.lightened(0.2))
			return 0.9
	return 1.0


func _draw() -> void:
	draw_set_transform(Vector2(0, 36), 0.0, Vector2(1.5, 0.35))
	draw_circle(Vector2.ZERO, 38.0, Color(0.2, 0.05, 0.08, 0.6))
	draw_set_transform(Vector2(0, sin(time * 1.5) * 2.0))
	for t in 6:
		var angle := PI * 0.1 + t * PI * 0.16
		var tip := Vector2.from_angle(angle + sin(time * 3.0 + t) * 0.2) * 52.0
		draw_line(Vector2.ZERO, tip, FLESH.darkened(0.2), 6.0)
	draw_circle(Vector2(0, 6), 30.0, FLESH)
	draw_circle(Vector2(0, 10), 18.0, FLESH.lightened(0.1))
	# A hulking demon's head with many eyes
	draw_colored_polygon(PackedVector2Array([Vector2(-16, -22), Vector2(-30, -46), Vector2(-8, -28)]), Color(0.25, 0.1, 0.12))
	draw_colored_polygon(PackedVector2Array([Vector2(16, -22), Vector2(30, -46), Vector2(8, -28)]), Color(0.25, 0.1, 0.12))
	draw_circle(Vector2(0, -18), 16.0, FLESH.darkened(0.1))
	for e in 5:
		draw_circle(Vector2(-10 + e * 5, -22 + (e % 2) * 5), 2.0, Color(1, 0.8, 0.3))
	draw_set_transform(Vector2.ZERO)
	draw_health_bar(48.0)
