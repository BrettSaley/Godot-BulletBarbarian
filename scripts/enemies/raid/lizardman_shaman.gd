extends Enemy
## Lizardman Shaman (Chambers of Xeric). Fought in a group. Leaps into the
## air and crashes down where you stood, sprays acid pools, spits at you, and
## summons little spawn that run at you and explode.

const Spawn := preload("res://scripts/enemies/raid/lizardman_spawn.gd")
const ACID := Color(0.45, 0.8, 0.2)
const JUMP_TIME := 1.2

var jump_timer := 0.0
var jump_from: Vector2
var jump_to: Vector2
var facing := 1.0


func _init() -> void:
	display_name = "Lizardman Shaman"
	radius = 18.0
	move_speed = 80.0
	max_hp = 480.0
	xp = 150
	bullet_damage = 22.0
	contact_damage = 30.0
	drops_loot = false
	size_scale = 1.25
	aggro_range = 2000.0
	preferred_range = 230.0
	projectile_style = Projectiles.Style.ORB


func _attacks() -> Array:
	return ["jump", "acid", "spit", "spawn"]


func _on_attack_started(attack_name: String) -> void:
	match attack_name:
		"jump":
			untargetable = true
			jump_timer = JUMP_TIME
			jump_from = position
			jump_to = player.position
			attack_timer = JUMP_TIME + 0.3
			hazards().blast(jump_to, 70.0, JUMP_TIME, bullet_damage * 2.5, display_name, ACID.lightened(0.2))
		"spawn":
			attack_timer = 0.5
			for i in 2:
				var spawn: Enemy = Spawn.new()
				spawn.position = position + Vector2.from_angle(randf() * TAU) * 30.0
				spawn.setup(tier, shots, player)
				spawn.add_to_group("raid_enemies")
				get_parent().add_child(spawn)


func _move(delta: float) -> void:
	if jump_timer > 0.0:
		jump_timer -= delta
		position = jump_from.lerp(jump_to, 1.0 - jump_timer / JUMP_TIME)
		if jump_timer <= 0.0:
			untargetable = false
		return
	super._move(delta)
	facing = 1.0 if player.position.x >= position.x else -1.0


func _fire(attack_name: String) -> float:
	match attack_name:
		"acid":
			hazards().pool(player.position, 45.0, 6.0, bullet_damage * 1.2, "Lizardman acid", ACID)
			return 1.3
		"spit":
			fan(position, dir_to_player(position), 1, 0.2, 180.0, 6.0, ACID.lightened(0.2))
			return 0.7
	return 99.0


func _draw() -> void:
	var scale_color := Color(0.3, 0.5, 0.25)
	var belly := Color(0.7, 0.75, 0.45)
	# While leaping, the shadow stays on the ground and the body rises.
	var height := sin(PI * (1.0 - jump_timer / JUMP_TIME)) * 50.0 if jump_timer > 0.0 else 0.0
	draw_set_transform(Vector2(0, 20), 0.0, Vector2(1.0, 0.35))
	draw_circle(Vector2.ZERO, 16.0 * (1.0 - height / 120.0), Color(0, 0, 0, 0.3))
	draw_set_transform(Vector2(0, -height), 0.0, Vector2(facing, 1.0))
	# Tail, legs, body
	draw_colored_polygon(PackedVector2Array([Vector2(-8, 10), Vector2(-24, 18), Vector2(-6, 16)]), scale_color)
	draw_line(Vector2(-5, 10), Vector2(-7, 19), scale_color.darkened(0.2), 4.0)
	draw_line(Vector2(5, 10), Vector2(7, 19), scale_color.darkened(0.2), 4.0)
	draw_circle(Vector2(0, 2), 11.0, scale_color)
	draw_circle(Vector2(1, 4), 6.0, belly)
	# Staff with a skull and feathers
	draw_line(Vector2(12, 12), Vector2(14, -20), Color(0.45, 0.3, 0.15), 2.0)
	draw_circle(Vector2(14, -22), 4.0, Color(0.9, 0.88, 0.8))
	draw_line(Vector2(12, -18), Vector2(8, -12), Color(0.9, 0.3, 0.2), 1.5)
	# Head with a frill
	draw_colored_polygon(PackedVector2Array([Vector2(-8, -14), Vector2(-4, -26), Vector2(2, -16)]), Color(0.8, 0.35, 0.2))
	draw_circle(Vector2(3, -12), 7.5, scale_color)
	draw_colored_polygon(PackedVector2Array([Vector2(7, -15), Vector2(15, -11), Vector2(7, -8)]), scale_color)
	draw_circle(Vector2(6, -14), 1.8, Color(1, 0.85, 0.1))
	draw_set_transform(Vector2.ZERO)
	draw_health_bar(24.0)
