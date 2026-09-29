extends Enemy
## The Alchemical Hydra (Karuulm Slayer Dungeon). Loses a head every quarter
## of its health and changes element each time:
##   green  - poison splats that linger
##   blue   - lightning that runs along the floor at you
##   red    - walls of fire that box you in
##   grey   - enraged: all of it, faster

const PHASES := [
	{"name": "green", "color": Color(0.35, 0.75, 0.3)},
	{"name": "blue", "color": Color(0.35, 0.55, 1.0)},
	{"name": "red", "color": Color(0.95, 0.3, 0.2)},
	{"name": "grey", "color": Color(0.55, 0.55, 0.6)},
]

var room: Rect2
var phase := 0


func _init() -> void:
	display_name = "Alchemical Hydra"
	radius = 32.0
	move_speed = 70.0
	max_hp = 1400.0
	xp = 600
	bullet_damage = 28.0
	contact_damage = 45.0
	is_boss = true
	drops_loot = false
	aggro_range = 650.0
	preferred_range = 230.0
	projectile_style = Projectiles.Style.ORB


func _attacks() -> Array:
	match phase:
		0:
			return ["spit", "poison"]
		1:
			return ["spit", "lightning"]
		2:
			return ["spit", "fire_walls"]
	return ["poison", "lightning", "fire_walls", "spit"]


func _move(delta: float) -> void:
	super._move(delta)
	var new_phase := mini(3, int((1.0 - hp / max_hp) * 4.0))
	if new_phase != phase:
		phase = new_phase
		DamageText.spawn(get_parent(), position + Vector2(0, -60), "The Hydra turns %s!" % PHASES[phase].name, PHASES[phase].color, 18)


func _fire(attack_name: String) -> float:
	var color: Color = PHASES[phase].color
	var pace := 0.7 if phase == 3 else 1.0
	match attack_name:
		"spit":
			fan(position, dir_to_player(position), 1 + phase / 2, 0.16, 200.0, 7.0, color)
			return 0.7 * pace
		"poison":
			for i in 4:
				hazards().pool(player.position + Vector2.from_angle(randf() * TAU) * randf_range(0, 120), 38.0, 7.0,
						bullet_damage * 1.3, "Hydra's poison", PHASES[0].color)
			return 1.6 * pace
		"lightning":
			var dir := dir_to_player(position)
			for i in range(1, 8):
				hazards().blast(position + dir * i * 55.0, 34.0, 0.7 + i * 0.1, bullet_damage * 2.0, "Hydra's lightning", PHASES[1].color)
			return 1.5 * pace
		"fire_walls":
			for offset in [-100.0, 100.0]:
				hazards().rect_pool(Rect2(room.position.x, player.position.y + offset - 12, room.size.x, 24), 4.0,
						bullet_damage * 3.0, "Hydra's fire", PHASES[2].color)
			return 2.6 * pace
	return 1.0


func _draw() -> void:
	var color: Color = PHASES[phase].color
	var body := color.darkened(0.35)
	draw_set_transform(Vector2(0, 32), 0.0, Vector2(1.4, 0.3))
	draw_circle(Vector2.ZERO, 30.0, Color(0, 0, 0, 0.3))
	draw_set_transform(Vector2.ZERO)
	draw_circle(Vector2(0, 12), 24.0, body)
	# One neck per remaining head
	var heads := 4 - phase
	for h in maxi(heads, 1):
		var angle := -PI / 2.0 + (h - (maxi(heads, 1) - 1) / 2.0) * 0.45
		var neck_end := Vector2(0, 4) + Vector2.from_angle(angle + sin(time * 2.0 + h) * 0.1) * 34.0
		draw_line(Vector2(0, 4), neck_end, body.lightened(0.1), 8.0)
		draw_circle(neck_end, 9.0, color)
		draw_circle(neck_end + Vector2(-3, -2), 1.8, Color(1, 0.9, 0.3))
		draw_circle(neck_end + Vector2(3, -2), 1.8, Color(1, 0.9, 0.3))
	draw_health_bar(44.0)
