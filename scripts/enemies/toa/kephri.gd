extends Enemy
## Kephri (Tombs of Amascut, Path of Scabaras). A giant scarab bearing the
## sun. Hurls exploding fireballs, spits dung, and sends scarab swarms that
## crawl to her and heal her. At 66% and 33% she raises a golden shield,
## guarded by Soldier Scarabs - she's immune until they're dead.

const SUN := Color(1.0, 0.7, 0.2)
const DUNG := Color(0.45, 0.35, 0.2)
const SHIELD_AT := [0.66, 0.33]

## Set by the raid.
var room: Rect2
var shields_left := SHIELD_AT.duplicate()
var guards: Array = []


func _init() -> void:
	display_name = "Kephri"
	radius = 32.0
	move_speed = 0.0
	max_hp = 1900.0
	xp = 900
	bullet_damage = 32.0
	contact_damage = 50.0
	is_boss = true
	drops_loot = false
	aggro_range = 2000.0
	projectile_style = Projectiles.Style.ORB


func _attacks() -> Array:
	return ["fireballs", "dung", "swarm"]


func _move(_delta: float) -> void:
	if not shields_left.is_empty() and hp / max_hp < shields_left[0]:
		shields_left.pop_front()
		for side in [-1.0, 1.0]:
			guards.append(summon(Minion.make("soldier"), position + Vector2(side * 90, 60)))
		DamageText.spawn(get_parent(), position + Vector2(0, -60), "Kephri's shield rises! Kill the soldiers.", SUN, 18)
	guards = guards.filter(func(g): return is_instance_valid(g) and g.hp > 0.0)
	invulnerable = not guards.is_empty()


func _fire(attack_name: String) -> float:
	match attack_name:
		"fireballs":
			hazards().blast(player.position, 55.0, 1.2, bullet_damage * 2.2, "Kephri's fireball", SUN)
			for i in 2:
				hazards().blast(player.position + Vector2.from_angle(randf() * TAU) * 110.0, 55.0, 1.2,
						bullet_damage * 2.2, "Kephri's fireball", SUN)
			return 1.4
		"dung":
			fan(position, dir_to_player(position), 2, 0.2, 180.0, 7.0, DUNG)
			return 0.7
		"swarm":
			for i in 5:
				var from := Vector2(room.position.x + 30 if i % 2 == 0 else room.end.x - 30, randf_range(room.position.y + 40, room.end.y - 40))
				var bug := Minion.make("scarab")
				bug.master = self
				bug.heal_fraction = 0.04
				summon(bug, from)
			return 99.0
	return 1.0


func _draw() -> void:
	var shell := Color(0.12, 0.3, 0.3)
	draw_set_transform(Vector2(0, 34), 0.0, Vector2(1.3, 0.3))
	draw_circle(Vector2.ZERO, 30.0, Color(0, 0, 0, 0.3))
	draw_set_transform(Vector2.ZERO)
	if invulnerable:
		draw_circle(Vector2.ZERO, 50.0, Color(SUN, 0.2 + 0.1 * sin(time * 5.0)))
		draw_arc(Vector2.ZERO, 50.0, 0.0, TAU, 40, SUN, 3.0)
	for side in [-1.0, 1.0]:
		for leg in 3:
			var base := Vector2(side * 18, -4 + leg * 12)
			draw_line(base, base + Vector2(side * 18, sin(time * 6.0 + leg) * 3.0 + 4), Color(0.1, 0.12, 0.12), 4.0)
	# Iridescent shell split down the middle
	draw_set_transform(Vector2(0, 6), 0.0, Vector2(1.0, 1.15))
	draw_circle(Vector2.ZERO, 26.0, shell)
	draw_set_transform(Vector2.ZERO)
	draw_line(Vector2(0, -20), Vector2(0, 34), Color(0.05, 0.15, 0.15), 2.0)
	draw_circle(Vector2(-10, 4), 6.0, Color(0.2, 0.55, 0.5, 0.6))
	draw_circle(Vector2(10, 14), 5.0, Color(0.2, 0.55, 0.5, 0.6))
	# Head with horns, holding the sun aloft
	draw_circle(Vector2(0, -24), 11.0, shell.darkened(0.2))
	draw_colored_polygon(PackedVector2Array([Vector2(-6, -32), Vector2(-10, -42), Vector2(-2, -34)]), shell)
	draw_colored_polygon(PackedVector2Array([Vector2(6, -32), Vector2(10, -42), Vector2(2, -34)]), shell)
	draw_circle(Vector2(0, -54), 12.0 + sin(time * 4.0), Color(SUN, 0.4))
	draw_circle(Vector2(0, -54), 9.0, SUN)
	draw_circle(Vector2(-4, -25), 2.0, SUN)
	draw_circle(Vector2(4, -25), 2.0, SUN)
	if invulnerable:
		draw_string(ThemeDB.fallback_font, Vector2(-40, 56), "IMMUNE", HORIZONTAL_ALIGNMENT_CENTER, 80, 12, SUN)
	draw_health_bar(46.0)
