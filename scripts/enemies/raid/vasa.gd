extends Enemy
## Vasa Nistirio (Chambers of Xeric). A crystal golem guarded by four glowing
## crystals. It drops boulders on you, teleports you next to itself and
## detonates the spot, and walks over to a crystal to heal from it,
## so smash the crystals.

const CRYSTAL := Color(0.55, 0.8, 1.0)
const HEAL_PER_SECOND := 60.0

## Set by the raid.
var crystals: Array = []
var room_center: Vector2
var heal_crystal: Enemy


func _init() -> void:
	display_name = "Vasa Nistirio"
	radius = 30.0
	move_speed = 70.0
	max_hp = 1200.0
	xp = 350
	bullet_damage = 26.0
	contact_damage = 40.0
	is_boss = true
	drops_loot = false
	aggro_range = 2000.0
	projectile_style = Projectiles.Style.ORB


func _living_crystals() -> Array:
	return crystals.filter(func(c): return is_instance_valid(c) and c.hp > 0.0)


func _attacks() -> Array:
	var options := ["boulders", "boulders", "teleport"]
	if not _living_crystals().is_empty():
		options.append("heal")
	return options


func _on_attack_started(attack_name: String) -> void:
	match attack_name:
		"heal":
			heal_crystal = _living_crystals().pick_random()
			attack_timer = 5.0
		"teleport":
			attack_timer = 2.0
			# Teleported just below Vasa, onto a spot that is about to explode.
			var spot := room_center + Vector2(0, 130)
			player.position = spot
			hazards().blast(spot, 115.0, 1.6, bullet_damage * 3.0, "Vasa Nistirio", CRYSTAL)
			DamageText.spawn(get_parent(), spot + Vector2(0, -40), "RUN!", CRYSTAL, 18)


func _is_healing() -> bool:
	return attack == "heal" and is_instance_valid(heal_crystal) and heal_crystal.hp > 0.0 \
			and position.distance_to(heal_crystal.position) < 70.0


func _move(delta: float) -> void:
	if attack == "heal" and is_instance_valid(heal_crystal) and heal_crystal.hp > 0.0:
		if position.distance_to(heal_crystal.position) > 60.0:
			position = position.move_toward(heal_crystal.position, move_speed * 1.5 * delta)
		elif hp < max_hp:
			hp = minf(hp + HEAL_PER_SECOND * delta, max_hp)
	else:
		position = position.move_toward(room_center, move_speed * delta)


func _fire(attack_name: String) -> float:
	match attack_name:
		"boulders":
			for i in 3:
				var at := player.position + (Vector2.ZERO if i == 0 else Vector2.from_angle(randf() * TAU) * randf_range(50, 120))
				hazards().blast(at, 50.0, 1.2, bullet_damage * 2.0, "Vasa's boulder", Color(0.65, 0.55, 0.45))
			return 1.0
		"heal":
			if _is_healing():
				ring(position, 8, 110.0, 6.0, CRYSTAL)
			return 0.9
	return 99.0


func _draw() -> void:
	if _is_healing():
		draw_line(Vector2.ZERO, (heal_crystal.position - position) / size_scale, Color(CRYSTAL, 0.6 + 0.3 * sin(time * 12.0)), 4.0)
	var stone := Color(0.4, 0.38, 0.45)
	draw_set_transform(Vector2(0, 34), 0.0, Vector2(1.2, 0.35))
	draw_circle(Vector2.ZERO, 30.0, Color(0, 0, 0, 0.3))
	draw_set_transform(Vector2(0, sin(time * 2.0) * 2.0))
	# Stone arms and a crystal core body
	draw_circle(Vector2(-28, 6), 11.0, stone)
	draw_circle(Vector2(28, 6), 11.0, stone)
	draw_colored_polygon(PackedVector2Array([Vector2(0, -34), Vector2(22, -8), Vector2(16, 24), Vector2(-16, 24), Vector2(-22, -8)]), stone)
	var glow := CRYSTAL.lightened(0.3) if _is_healing() else CRYSTAL
	draw_colored_polygon(PackedVector2Array([Vector2(0, -22), Vector2(12, -4), Vector2(0, 16), Vector2(-12, -4)]), glow)
	draw_colored_polygon(PackedVector2Array([Vector2(0, -22), Vector2(12, -4), Vector2(0, -4)]), glow.lightened(0.4))
	draw_circle(Vector2(-6, -16), 2.5, Color(1, 1, 1))
	draw_circle(Vector2(6, -16), 2.5, Color(1, 1, 1))
	draw_set_transform(Vector2.ZERO)
	draw_health_bar(40.0)
