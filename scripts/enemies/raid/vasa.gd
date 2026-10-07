extends Enemy
## Vasa Nistirio (Chambers of Xeric). A crystal golem guarded by four glowing
## crystals. It never stops trudging toward the nearest crystal; while it
## walks it can be hurt, but once it reaches one it's shielded and heals
## until you destroy that crystal - then it sets off for the next. Along the
## way it drops boulders on you, and teleports you next to itself before
## detonating the spot.

const CRYSTAL := Color(0.55, 0.8, 1.0)
## Healing while on a crystal, as a share of max health per second.
const HEAL_RATE := 0.04
## Close enough to draw on a crystal (they can't overlap: monsters are kept apart).
const ARRIVE_DISTANCE := 85.0

## Set by the raid.
var crystals: Array = []
var room_center: Vector2
var target_crystal: Enemy


func _init() -> void:
	display_name = "Vasa Nistirio"
	radius = 30.0
	move_speed = 55.0
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
	return ["boulders", "boulders", "teleport"]


func _on_attack_started(attack_name: String) -> void:
	if attack_name == "teleport":
		attack_timer = 2.0
		# Teleported just below Vasa, onto a spot that is about to explode.
		var spot := room_center + Vector2(0, 130)
		player.position = spot
		hazards().blast(spot, 115.0, 1.6, bullet_damage * 3.0, "Vasa Nistirio", CRYSTAL)
		DamageText.spawn(get_parent(), spot + Vector2(0, -40), "RUN!", CRYSTAL, 18)


## On a crystal: shielded and healing until it's destroyed.
func is_on_crystal() -> bool:
	return is_instance_valid(target_crystal) and target_crystal.hp > 0.0 \
			and position.distance_to(target_crystal.position) <= ARRIVE_DISTANCE + 1.0


func _move(delta: float) -> void:
	if not (is_instance_valid(target_crystal) and target_crystal.hp > 0.0):
		# Off to the nearest remaining crystal (or back to the middle once
		# they're all gone).
		var living := _living_crystals()
		target_crystal = null
		if not living.is_empty():
			living.sort_custom(func(a, b): return position.distance_to(a.position) < position.distance_to(b.position))
			target_crystal = living[0]
	if target_crystal == null:
		invulnerable = false
		position = position.move_toward(room_center, move_speed * delta)
		return
	if position.distance_to(target_crystal.position) > ARRIVE_DISTANCE:
		invulnerable = false
		position = position.move_toward(target_crystal.position, move_speed * delta)
		return
	if not invulnerable:
		DamageText.spawn(get_parent(), position + Vector2(0, -60), "Vasa draws on the crystal - destroy it!", CRYSTAL, 16)
	invulnerable = true
	hp = minf(hp + max_hp * HEAL_RATE * delta, max_hp)


func _fire(attack_name: String) -> float:
	match attack_name:
		"boulders":
			for i in 3:
				var at := player.position + (Vector2.ZERO if i == 0 else Vector2.from_angle(randf() * TAU) * randf_range(50, 120))
				hazards().blast(at, 50.0, 1.2, bullet_damage * 2.0, "Vasa's boulder", Color(0.65, 0.55, 0.45))
			return 1.0
	return 99.0


func _draw() -> void:
	if is_on_crystal():
		draw_line(Vector2.ZERO, (target_crystal.position - position) / size_scale, Color(CRYSTAL, 0.6 + 0.3 * sin(time * 12.0)), 4.0)
		draw_arc(Vector2.ZERO, 44.0, 0.0, TAU, 40, Color(CRYSTAL, 0.5 + 0.2 * sin(time * 5.0)), 3.0)
	var stone := Color(0.4, 0.38, 0.45)
	draw_set_transform(Vector2(0, 34), 0.0, Vector2(1.2, 0.35))
	draw_circle(Vector2.ZERO, 30.0, Color(0, 0, 0, 0.3))
	draw_set_transform(Vector2(0, sin(time * 2.0) * 2.0))
	# Stone arms and a crystal core body
	draw_circle(Vector2(-28, 6), 11.0, stone)
	draw_circle(Vector2(28, 6), 11.0, stone)
	draw_colored_polygon(PackedVector2Array([Vector2(0, -34), Vector2(22, -8), Vector2(16, 24), Vector2(-16, 24), Vector2(-22, -8)]), stone)
	var glow := CRYSTAL.lightened(0.3) if is_on_crystal() else CRYSTAL
	draw_colored_polygon(PackedVector2Array([Vector2(0, -22), Vector2(12, -4), Vector2(0, 16), Vector2(-12, -4)]), glow)
	draw_colored_polygon(PackedVector2Array([Vector2(0, -22), Vector2(12, -4), Vector2(0, -4)]), glow.lightened(0.4))
	draw_circle(Vector2(-6, -16), 2.5, Color(1, 1, 1))
	draw_circle(Vector2(6, -16), 2.5, Color(1, 1, 1))
	draw_set_transform(Vector2.ZERO)
	if is_on_crystal():
		draw_string(ThemeDB.fallback_font, Vector2(-70, -52), "IMMUNE - healing", HORIZONTAL_ALIGNMENT_CENTER, 140, 11, CRYSTAL)
	draw_health_bar(40.0)
