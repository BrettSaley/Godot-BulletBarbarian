extends Enemy
## Kree'arra (OSRS, Armadyl's general). A great eagle that circles you firing
## barrages of feathered arrows, whips up whirlwinds, and beats its wings in a
## gust that throws you backwards.

const FEATHER := Color(0.75, 0.78, 0.85)
const WIND := Color(0.7, 0.9, 1.0)

var facing := 1.0


func _init() -> void:
	display_name = "Kree'arra"
	radius = 30.0
	move_speed = 110.0
	max_hp = 1400.0
	xp = 500
	bullet_damage = 26.0
	contact_damage = 40.0
	is_boss = true
	aggro_range = 650.0
	preferred_range = 280.0
	projectile_style = Projectiles.Style.ARROW


func _attacks() -> Array:
	return ["barrage", "whirlwind", "gust"]


func _move(delta: float) -> void:
	super._move(delta)
	facing = 1.0 if player.position.x >= position.x else -1.0


func _fire(attack_name: String) -> float:
	match attack_name:
		"barrage":
			fan(position, dir_to_player(position), 3, 0.1, 240.0, 6.0, FEATHER)
			return 0.45
		"whirlwind":
			projectile_style = Projectiles.Style.ORB
			ring(position, 14, 130.0, 7.0, WIND)
			projectile_style = Projectiles.Style.ARROW
			return 0.9
		"gust":
			# Wind blasts around the player (no shove: overworld bosses never move
			# the player into other monsters' shots).
			var away := (player.position - position).normalized()
			hazards().blast(player.position + away * 60.0, 55.0, 1.0, bullet_damage * 2.0, display_name, WIND)
			DamageText.spawn(get_parent(), player.position + Vector2(0, -40), "GUST!", WIND, 16)
			return 2.0
	return 1.0


func _draw() -> void:
	var flap := sin(time * 5.0)
	var dark := Color(0.35, 0.36, 0.42)
	draw_set_transform(Vector2(0, 40), 0.0, Vector2(1.5, 0.3))
	draw_circle(Vector2.ZERO, 28.0, Color(0, 0, 0, 0.25))
	draw_set_transform(Vector2(0, -8 + flap * 3.0), 0.0, Vector2(facing, 1.0))
	# Vast wings
	for side in [-1.0, 1.0]:
		draw_colored_polygon(PackedVector2Array([Vector2(side * 10, -6), Vector2(side * 60, -34 - flap * 14),
				Vector2(side * 66, -8), Vector2(side * 56, 8), Vector2(side * 40, 12), Vector2(side * 14, 8)]), dark)
		for f in 3:
			draw_line(Vector2(side * (24 + f * 12), -6), Vector2(side * (30 + f * 12), 10), FEATHER, 1.5)
	# Body and armoured chest
	draw_circle(Vector2(0, 4), 20.0, FEATHER)
	draw_rect(Rect2(Vector2(-12, -2), Vector2(24, 14)), Color(0.7, 0.6, 0.3))
	draw_circle(Vector2(0, 4), 3.5, Color(0.5, 0.8, 1.0))
	# Eagle head with a hooked beak
	draw_circle(Vector2(4, -20), 12.0, Color(0.95, 0.95, 0.95))
	draw_colored_polygon(PackedVector2Array([Vector2(12, -24), Vector2(24, -18), Vector2(14, -12)]), Color(0.95, 0.75, 0.2))
	draw_circle(Vector2(8, -23), 2.5, Color(0.1, 0.1, 0.1))
	draw_line(Vector2(2, -28), Vector2(12, -26), Color(0.2, 0.2, 0.2), 2.0)
	draw_set_transform(Vector2.ZERO)
	draw_health_bar(44.0)
