extends Enemy
## Vet'ion (OSRS, the Wilderness). A skeletal knight who calls down lightning
## in a line of strikes, shakes the earth, and summons Skeleton Hellhounds -
## he's immune while they live, glowing behind a shield of bones.

const LIGHTNING := Color(0.75, 0.6, 1.0)
const BONE := Color(0.9, 0.88, 0.8)

var hounds: Array = []
var summons_left := [0.66, 0.33]


func _init() -> void:
	display_name = "Vet'ion"
	radius = 28.0
	move_speed = 80.0
	max_hp = 1800.0
	xp = 600
	bullet_damage = 32.0
	contact_damage = 45.0
	is_boss = true
	aggro_range = 650.0
	preferred_range = 200.0
	projectile_style = Projectiles.Style.ORB


func _attacks() -> Array:
	return ["lightning", "earthquake", "lightning"]


func _move(delta: float) -> void:
	super._move(delta)
	# Call the hounds at 66% and 33% health; immune until they're dead.
	if not summons_left.is_empty() and hp / max_hp < summons_left[0]:
		summons_left.pop_front()
		for side in [-1.0, 1.0]:
			hounds.append(summon(Minion.make("hellhound"), position + Vector2(side * 60, 20)))
		DamageText.spawn(get_parent(), position + Vector2(0, -60), "Hounds, to me!", BONE, 18)
	hounds = hounds.filter(func(h): return is_instance_valid(h) and h.hp > 0.0)
	invulnerable = not hounds.is_empty()


func _fire(attack_name: String) -> float:
	match attack_name:
		"lightning":
			var dir := dir_to_player(position)
			for i in range(1, 6):
				hazards().blast(position + dir * i * 70.0, 40.0, 0.9 + i * 0.12, bullet_damage * 2.0, display_name, LIGHTNING)
			return 1.4
		"earthquake":
			ring(position, 16, 120.0, 7.0, BONE.darkened(0.2))
			return 0.9
	return 1.0


func _draw() -> void:
	var armor := Color(0.35, 0.3, 0.4)
	draw_set_transform(Vector2(0, 32), 0.0, Vector2(1.2, 0.3))
	draw_circle(Vector2.ZERO, 26.0, Color(0, 0, 0, 0.3))
	draw_set_transform(Vector2(0, sin(time * 3.0) * 2.0))
	if invulnerable:
		draw_circle(Vector2.ZERO, 42.0, Color(LIGHTNING, 0.2 + 0.1 * sin(time * 6.0)))
		draw_arc(Vector2.ZERO, 42.0, 0.0, TAU, 40, Color(LIGHTNING, 0.8), 2.5)
	# Skeletal legs, armoured torso, halberd
	draw_line(Vector2(-7, 16), Vector2(-9, 30), BONE, 3.0)
	draw_line(Vector2(7, 16), Vector2(9, 30), BONE, 3.0)
	draw_colored_polygon(PackedVector2Array([Vector2(-16, -8), Vector2(16, -8), Vector2(12, 18), Vector2(-12, 18)]), armor)
	for r in 3:
		draw_line(Vector2(-10, -2 + r * 6), Vector2(10, -2 + r * 6), BONE.darkened(0.3), 1.5)
	draw_line(Vector2(20, 26), Vector2(26, -34), Color(0.4, 0.3, 0.25), 3.0)
	draw_colored_polygon(PackedVector2Array([Vector2(22, -30), Vector2(36, -38), Vector2(28, -22)]), Color(0.7, 0.7, 0.75))
	# Crowned skull with glowing eyes
	draw_circle(Vector2(0, -20), 11.0, BONE)
	draw_circle(Vector2(-4, -21), 3.0, Color(0.1, 0.05, 0.15))
	draw_circle(Vector2(4, -21), 3.0, Color(0.1, 0.05, 0.15))
	draw_circle(Vector2(-4, -21), 1.5, LIGHTNING)
	draw_circle(Vector2(4, -21), 1.5, LIGHTNING)
	for k in 5:
		draw_colored_polygon(PackedVector2Array([Vector2(-10 + k * 5, -29), Vector2(-7.5 + k * 5, -37), Vector2(-5 + k * 5, -29)]), Color(0.85, 0.7, 0.3))
	draw_set_transform(Vector2.ZERO)
	if invulnerable:
		draw_string(ThemeDB.fallback_font, Vector2(-40, -50), "IMMUNE", HORIZONTAL_ALIGNMENT_CENTER, 80, 12, LIGHTNING)
	draw_health_bar(40.0)
