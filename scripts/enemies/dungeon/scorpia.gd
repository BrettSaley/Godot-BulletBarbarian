extends Enemy
## Scorpia (Scorpia's Cave). A giant scorpion that scuttles in with her
## stinger, sprays poison, and below half health calls her guardians - they
## crawl to her and heal her unless you kill them first.

const STINGER := Color(0.9, 0.7, 0.25)
const POISON := Color(0.5, 0.8, 0.25)

var room: Rect2
var guardians_called := false
var facing := 1.0


func _init() -> void:
	display_name = "Scorpia"
	radius = 30.0
	move_speed = 100.0
	max_hp = 1500.0
	xp = 700
	bullet_damage = 30.0
	contact_damage = 50.0
	is_boss = true
	drops_loot = false
	aggro_range = 650.0
	preferred_range = 150.0
	projectile_style = Projectiles.Style.ORB


func _attacks() -> Array:
	return ["sting", "poison", "charge"]


func _move(delta: float) -> void:
	if attack == "charge":
		position = position.move_toward(player.position, move_speed * 1.8 * delta)
	else:
		super._move(delta)
	facing = 1.0 if player.position.x >= position.x else -1.0
	if not guardians_called and hp / max_hp < 0.5:
		guardians_called = true
		for i in 3:
			var guardian := Minion.make("scorpia_guardian")
			guardian.master = self
			guardian.heal_fraction = 0.1
			summon(guardian, position + Vector2.from_angle(TAU * i / 3.0) * 220.0)
		DamageText.spawn(get_parent(), position + Vector2(0, -60), "Scorpia's guardians come to heal her!", STINGER, 18)


func _fire(attack_name: String) -> float:
	match attack_name:
		"sting":
			fan(position, dir_to_player(position), 2, 0.14, 210.0, 7.0, STINGER)
			return 0.6
		"poison":
			for i in 3:
				hazards().pool(player.position + Vector2.from_angle(randf() * TAU) * randf_range(0, 100), 40.0, 6.0,
						bullet_damage * 1.3, "Scorpia's poison", POISON)
			return 1.5
		"charge":
			ring(position, 10, 120.0, 6.0, STINGER.darkened(0.2))
			return 1.1
	return 1.0


func _draw() -> void:
	var shell := Color(0.35, 0.22, 0.12)
	draw_set_transform(Vector2(0, 30), 0.0, Vector2(1.5, 0.3))
	draw_circle(Vector2.ZERO, 30.0, Color(0, 0, 0, 0.3))
	draw_set_transform(Vector2.ZERO, 0.0, Vector2(facing, 1.0))
	for side in [-1.0, 1.0]:
		for leg in 4:
			var base := Vector2(-6 + leg * 7, side * 12)
			draw_line(base, base + Vector2(-4, side * (14 + sin(time * 10.0 + leg) * 3.0)), shell.darkened(0.3), 3.0)
	# Segmented body, big pincers, and the stinger curled overhead
	for s in 4:
		draw_circle(Vector2(-18 + s * 10, 0), 11.0 - absf(s - 1.5), shell.lightened(s * 0.03))
	for side in [-1.0, 1.0]:
		draw_line(Vector2(16, side * 6), Vector2(30, side * 14), shell, 5.0)
		draw_colored_polygon(PackedVector2Array([Vector2(28, side * 10), Vector2(40, side * 16), Vector2(30, side * 20)]), shell.darkened(0.1))
	var tail := PackedVector2Array([Vector2(-26, 0), Vector2(-36, -10), Vector2(-34, -26), Vector2(-20, -34), Vector2(-8, -30)])
	draw_polyline(tail, shell.lightened(0.1), 6.0)
	draw_colored_polygon(PackedVector2Array([Vector2(-10, -34), Vector2(0, -28), Vector2(-8, -24)]), STINGER)
	draw_circle(Vector2(20, -4), 2.0, Color(0.9, 0.2, 0.1))
	draw_circle(Vector2(20, 4), 2.0, Color(0.9, 0.2, 0.1))
	draw_set_transform(Vector2.ZERO)
	draw_health_bar(42.0)
