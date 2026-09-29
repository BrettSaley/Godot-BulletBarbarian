extends Enemy
## Akkha (Tombs of Amascut, Path of Het). A warrior of shadow and light.
## "Memory": the room's four quarters flash and explode one after another -
## step into a quarter that has already gone off. At 80/60/40/20% health he
## splits off a Shadow and is immune until it's destroyed.

const GOLD := Color(0.95, 0.8, 0.3)
const SHADOW := Color(0.45, 0.25, 0.6)
const SHADOW_AT := [0.8, 0.6, 0.4, 0.2]

## Set by the raid.
var room: Rect2
var shadows_left := SHADOW_AT.duplicate()
var shadow: Enemy


func _init() -> void:
	display_name = "Akkha"
	radius = 28.0
	move_speed = 85.0
	max_hp = 1800.0
	xp = 900
	bullet_damage = 32.0
	contact_damage = 50.0
	is_boss = true
	drops_loot = false
	aggro_range = 2000.0
	preferred_range = 220.0
	projectile_style = Projectiles.Style.ORB


func _attacks() -> Array:
	return ["memory", "orbs", "orbs"]


func _move(delta: float) -> void:
	super._move(delta)
	if not shadows_left.is_empty() and hp / max_hp < shadows_left[0]:
		shadows_left.pop_front()
		shadow = summon(Minion.make("shadow"), position + Vector2(80, 0))
		DamageText.spawn(get_parent(), position + Vector2(0, -60), "Akkha's shadow splits away!", SHADOW.lightened(0.4), 18)
	invulnerable = is_instance_valid(shadow) and shadow.hp > 0.0


func _fire(attack_name: String) -> float:
	match attack_name:
		"memory":
			# The quarters go off one after another around the room, clockwise or
			# anticlockwise from a random corner, so the pattern is readable.
			var half := room.size / 2.0
			var quarters := [Rect2(room.position, half), Rect2(room.position + Vector2(half.x, 0), half),
					Rect2(room.position + half, half), Rect2(room.position + Vector2(0, half.y), half)]
			var start := randi() % 4
			var step := 1 if randf() < 0.5 else -1
			quarters = range(4).map(func(i): return quarters[posmod(start + i * step, 4)])
			DamageText.spawn(get_parent(), position + Vector2(0, -60), "Clockwise!" if step == 1 else "Anticlockwise!", GOLD, 16)
			for i in 4:
				hazards().rect_blast(quarters[i], 1.2 + i * 0.9, bullet_damage * 2.5, "Akkha's memory", GOLD if i % 2 == 0 else SHADOW)
			return 4.5
		"orbs":
			fan(position, dir_to_player(position), 2, 0.2, 190.0, 7.0, GOLD if randf() < 0.5 else SHADOW.lightened(0.3))
			return 0.6
	return 1.0


func _draw() -> void:
	var skin := Color(0.72, 0.52, 0.35)
	var blue := Color(0.2, 0.35, 0.8)
	draw_set_transform(Vector2(0, 30), 0.0, Vector2(1.1, 0.3))
	draw_circle(Vector2.ZERO, 26.0, Color(0, 0, 0, 0.3))
	draw_set_transform(Vector2(0, sin(time * 3.0) * 1.5))
	if invulnerable:
		draw_circle(Vector2.ZERO, 40.0, Color(SHADOW, 0.25 + 0.1 * sin(time * 6.0)))
		draw_arc(Vector2.ZERO, 40.0, 0.0, TAU, 40, SHADOW.lightened(0.4), 2.5)
	# Kilt, gold collar, staff of Het
	draw_colored_polygon(PackedVector2Array([Vector2(-12, 28), Vector2(-10, 6), Vector2(10, 6), Vector2(12, 28)]), Color(0.95, 0.92, 0.85))
	draw_circle(Vector2(0, -2), 13.0, skin)
	draw_arc(Vector2(0, -6), 12.0, 0.2, PI - 0.2, 12, GOLD, 4.0)
	draw_line(Vector2(18, 26), Vector2(20, -30), GOLD.darkened(0.2), 3.0)
	draw_circle(Vector2(20, -32), 5.0, GOLD)
	# Head in a striped nemes headdress
	draw_colored_polygon(PackedVector2Array([Vector2(-14, -12), Vector2(-10, -34), Vector2(10, -34), Vector2(14, -12), Vector2(8, -16), Vector2(-8, -16)]), GOLD)
	for s in 3:
		draw_line(Vector2(-11 + s, -28 + s * 5), Vector2(11 - s, -28 + s * 5), blue, 2.0)
	draw_circle(Vector2(0, -20), 7.5, skin)
	draw_circle(Vector2(-3, -21), 1.5, Color(0.1, 0.1, 0.1))
	draw_circle(Vector2(3, -21), 1.5, Color(0.1, 0.1, 0.1))
	draw_set_transform(Vector2.ZERO)
	if invulnerable:
		draw_string(ThemeDB.fallback_font, Vector2(-40, -48), "IMMUNE", HORIZONTAL_ALIGNMENT_CENTER, 80, 12, SHADOW.lightened(0.5))
	draw_health_bar(40.0)
