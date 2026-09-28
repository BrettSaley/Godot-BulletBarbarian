extends Enemy
## Verzik Vitur (Theatre of Blood), the final boss, in three phases:
##   1 (100-66%) On her throne, raining huge blasts on your position.
##   2 (66-33%)  Standing, she stalks you with electric orbs and lightning,
##               and summons crimson Nylocas.
##   3 (33-0%)   Her spider form: webs that slow you, green death balls,
##               and purple tornadoes that hunt you down.

const PURPLE := Color(0.6, 0.3, 0.85)
const ELECTRIC := Color(0.6, 0.9, 1.0)
const GREEN := Color(0.4, 0.95, 0.35)
const WEB := Color(0.9, 0.9, 0.95)

## Set by the raid.
var room: Rect2
var throne: Vector2
var phase := 1


func _init() -> void:
	display_name = "Verzik Vitur"
	radius = 30.0
	move_speed = 90.0
	max_hp = 2400.0
	xp = 1200
	bullet_damage = 30.0
	contact_damage = 50.0
	is_boss = true
	drops_loot = false
	aggro_range = 2000.0
	preferred_range = 220.0
	projectile_style = Projectiles.Style.ORB


func _on_setup() -> void:
	throne = position


func _attacks() -> Array:
	match phase:
		1:
			return ["dawn_blast", "throne_orbs"]
		2:
			return ["electric", "lightning", "nylocas"]
	return ["webs", "green_ball", "tornadoes"]


func _move(delta: float) -> void:
	var fraction := hp / max_hp
	var new_phase := 1 if fraction > 0.66 else (2 if fraction > 0.33 else 3)
	if new_phase != phase:
		phase = new_phase
		attack = ""
		attack_timer = 0.0
		rest_timer = 1.5
		move_speed *= 1.3
		var text := "Verzik rises from her throne!" if phase == 2 else "Verzik reveals her true form!"
		DamageText.spawn(get_parent(), position + Vector2(0, -70), text, PURPLE.lightened(0.4), 20)
	if phase == 1:
		position = position.move_toward(throne, 60.0 * delta)
	else:
		super._move(delta)


func _fire(attack_name: String) -> float:
	match attack_name:
		"dawn_blast":
			hazards().blast(player.position, 110.0, 1.6, bullet_damage * 3.0, "Verzik's blast", PURPLE)
			return 1.8
		"throne_orbs":
			ring(position, 16, 120.0, 7.0, PURPLE.lightened(0.2))
			return 1.0
		"electric":
			fan(position, dir_to_player(position), 3, 0.2, 190.0, 7.0, ELECTRIC)
			return 0.7
		"lightning":
			var dir := dir_to_player(position)
			for i in range(1, 7):
				hazards().blast(position + dir * i * 60.0, 36.0, 0.9, bullet_damage * 2.0, "Verzik's lightning", ELECTRIC)
			return 1.3
		"nylocas":
			for i in 3:
				summon(Minion.make("nylocas", Color(0.85, 0.2, 0.2)), position + Vector2.from_angle(TAU * i / 3.0) * 50.0)
			return 99.0
		"webs":
			for i in 4:
				hazards().pool(player.position + Vector2.from_angle(randf() * TAU) * randf_range(0, 120), 45.0, 6.0,
						bullet_damage * 0.5, "Verzik's web", WEB, 0.6)
			return 1.6
		"green_ball":
			shoot(position, dir_to_player(position) * 140.0, 18.0, GREEN, 4.0)
			return 1.4
		"tornadoes":
			for i in 2:
				summon(Minion.make("tornado"), position + Vector2.from_angle(randf() * TAU) * 60.0)
			return 99.0
	return 1.0


func _draw() -> void:
	var skin := Color(0.85, 0.8, 0.85)
	var robe := Color(0.35, 0.12, 0.45)
	draw_set_transform(Vector2(0, 34), 0.0, Vector2(1.4, 0.3))
	draw_circle(Vector2.ZERO, 30.0, Color(0, 0, 0, 0.3))
	draw_set_transform(Vector2(0, sin(time * 2.5) * 2.0))
	match phase:
		1:
			# Seated on a towering throne
			var t := (throne - position) / size_scale
			draw_rect(Rect2(t + Vector2(-34, -52), Vector2(68, 90)), Color(0.25, 0.2, 0.22))
			draw_rect(Rect2(t + Vector2(-28, -46), Vector2(56, 78)), Color(0.35, 0.1, 0.12))
			draw_colored_polygon(PackedVector2Array([Vector2(-18, 30), Vector2(-12, -6), Vector2(12, -6), Vector2(18, 30)]), robe)
		2:
			draw_colored_polygon(PackedVector2Array([Vector2(-16, 32), Vector2(-10, -8), Vector2(10, -8), Vector2(16, 32)]), robe)
			draw_line(Vector2(14, 20), Vector2(20, -30), Color(0.3, 0.3, 0.35), 3.0)
			draw_circle(Vector2(20, -32), 5.0, ELECTRIC)
		3:
			# Spider body beneath her torso
			for side in [-1.0, 1.0]:
				for leg in 4:
					var base := Vector2(side * 14, 6 + leg * 6)
					var knee := base + Vector2(side * 22, -16 + sin(time * 10.0 + leg) * 3.0)
					draw_line(base, knee, Color(0.15, 0.1, 0.2), 4.0)
					draw_line(knee, knee + Vector2(side * 12, 24), Color(0.15, 0.1, 0.2), 3.0)
			draw_circle(Vector2(0, 16), 22.0, Color(0.2, 0.1, 0.28))
			draw_colored_polygon(PackedVector2Array([Vector2(-10, 8), Vector2(-8, -8), Vector2(8, -8), Vector2(10, 8)]), robe)
	# Pale face, silver hair, red eyes
	draw_colored_polygon(PackedVector2Array([Vector2(-12, -26), Vector2(12, -26), Vector2(14, -2), Vector2(-14, -2)]), Color(0.85, 0.85, 0.9))
	draw_circle(Vector2(0, -16), 9.0, skin)
	draw_circle(Vector2(-3.5, -17), 2.0, Color(0.9, 0.1, 0.15))
	draw_circle(Vector2(3.5, -17), 2.0, Color(0.9, 0.1, 0.15))
	draw_line(Vector2(-3, -11), Vector2(3, -11), Color(0.5, 0.1, 0.2), 1.5)
	draw_set_transform(Vector2.ZERO)
	draw_string(ThemeDB.fallback_font, Vector2(-60, 58), "Phase %d / 3" % phase, HORIZONTAL_ALIGNMENT_CENTER, 120, 13, Color(1, 0.85, 1))
	draw_health_bar(46.0)
