extends Enemy
## The Nightmare (the Nightmare's Lair). Starts shielded behind four totems
## in the room's corners - destroy them to break her shield - and raises them
## again at 66% and 33%. Rakes the floor with grasping claws, surges across
## the room, and plants parasites that burst out and chase you.

const PURPLE := Color(0.55, 0.3, 0.7)
const CLAW := Color(0.35, 0.2, 0.45)
const TOTEMS_AT := [1.01, 0.66, 0.33]
const Totem := preload("res://scripts/enemies/raid/glowing_crystal.gd")

var room: Rect2
var totem_waves := TOTEMS_AT.duplicate()
var totems: Array = []
var surge_target: Vector2


func _init() -> void:
	display_name = "The Nightmare"
	radius = 30.0
	move_speed = 80.0
	max_hp = 1500.0
	xp = 650
	bullet_damage = 28.0
	contact_damage = 45.0
	is_boss = true
	drops_loot = false
	aggro_range = 650.0
	preferred_range = 220.0
	projectile_style = Projectiles.Style.ORB


func _attacks() -> Array:
	return ["claws", "surge", "parasites", "orbs"]


func _on_attack_started(attack_name: String) -> void:
	if attack_name == "surge":
		surge_target = Vector2(room.end.x - 80 if position.x < room.get_center().x else room.position.x + 80, player.position.y)


func _move(delta: float) -> void:
	if not totem_waves.is_empty() and aggro and hp / max_hp < totem_waves[0]:
		totem_waves.pop_front()
		totems.clear()
		for corner in [Vector2(-1, -1), Vector2(1, -1), Vector2(-1, 1), Vector2(1, 1)]:
			var totem: Enemy = summon(Totem.new(), room.get_center() + corner * (room.size / 2.0 - Vector2(70, 60)))
			totem.display_name = "Totem"
			totems.append(totem)
		DamageText.spawn(get_parent(), position + Vector2(0, -60), "The totems shield the Nightmare!", PURPLE.lightened(0.3), 18)
	totems = totems.filter(func(t): return is_instance_valid(t) and t.hp > 0.0)
	invulnerable = not totems.is_empty()
	if attack == "surge":
		position = position.move_toward(surge_target, move_speed * 4.0 * delta)
	else:
		super._move(delta)


func _fire(attack_name: String) -> float:
	match attack_name:
		"claws":
			for i in 7:
				var at := Vector2(randf_range(room.position.x + 40, room.end.x - 40), randf_range(room.position.y + 40, room.end.y - 40))
				hazards().blast(at, 45.0, 1.1, bullet_damage * 2.0, "Grasping claws", CLAW)
			hazards().blast(player.position, 45.0, 1.1, bullet_damage * 2.0, "Grasping claws", CLAW)
			return 1.5
		"surge":
			ring(position, 8, 120.0, 6.0, PURPLE)
			return 0.3
		"parasites":
			for i in 2:
				summon(Minion.make("parasite"), player.position + Vector2.from_angle(randf() * TAU) * 120.0)
			return 99.0
		"orbs":
			fan(position, dir_to_player(position), 2, 0.18, 190.0, 7.0, PURPLE.lightened(0.2))
			return 0.7
	return 1.0


func _draw() -> void:
	draw_set_transform(Vector2(0, 32), 0.0, Vector2(1.2, 0.3))
	draw_circle(Vector2.ZERO, 28.0, Color(0, 0, 0, 0.3))
	draw_set_transform(Vector2(0, sin(time * 2.0) * 3.0))
	if invulnerable:
		draw_circle(Vector2.ZERO, 46.0, Color(PURPLE, 0.2 + 0.1 * sin(time * 5.0)))
		draw_arc(Vector2.ZERO, 46.0, 0.0, TAU, 40, PURPLE.lightened(0.4), 3.0)
	# Tattered shadowy gown and long clawed arms
	draw_colored_polygon(PackedVector2Array([Vector2(-24, 32), Vector2(-14, -6), Vector2(14, -6), Vector2(24, 32), Vector2(10, 24),
			Vector2(0, 34), Vector2(-10, 24)]), Color(0.2, 0.12, 0.25))
	for side in [-1.0, 1.0]:
		draw_line(Vector2(side * 12, -2), Vector2(side * 30, 16), Color(0.75, 0.7, 0.8), 3.0)
		for c in 3:
			draw_line(Vector2(side * 30, 16), Vector2(side * (32 + c * 3), 24 + c), Color(0.9, 0.85, 0.95), 1.5)
	# Pale mask-like face with hollow glowing eyes and a crown of horns
	draw_circle(Vector2(0, -16), 13.0, Color(0.88, 0.85, 0.9))
	draw_circle(Vector2(-5, -18), 3.5, Color(0.2, 0.05, 0.25))
	draw_circle(Vector2(5, -18), 3.5, Color(0.2, 0.05, 0.25))
	draw_circle(Vector2(-5, -18), 1.5, PURPLE.lightened(0.5))
	draw_circle(Vector2(5, -18), 1.5, PURPLE.lightened(0.5))
	for k in 5:
		draw_colored_polygon(PackedVector2Array([Vector2(-10 + k * 5, -27), Vector2(-8 + k * 5, -38 - (k % 2) * 6), Vector2(-6 + k * 5, -27)]),
				Color(0.3, 0.2, 0.35))
	draw_set_transform(Vector2.ZERO)
	if invulnerable:
		draw_string(ThemeDB.fallback_font, Vector2(-60, -56), "IMMUNE - break the totems", HORIZONTAL_ALIGNMENT_CENTER, 120, 11, PURPLE.lightened(0.5))
	draw_health_bar(44.0)
