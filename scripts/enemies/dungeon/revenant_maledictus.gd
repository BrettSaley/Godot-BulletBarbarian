extends Enemy
## Revenant Maledictus (the Revenant Caves). The mightiest revenant: fades out
## of reach every few seconds, fires barrages of spectral bolts, sweeps beams
## of ether across the cave, and calls lesser revenants to its side.

const Revenant := preload("res://scripts/enemies/wilderness/revenant.gd")
const ETHER := Color(0.45, 0.95, 0.85)
const PHASE_EVERY := 6.0
const PHASE_TIME := 1.6

var room: Rect2
var phase_clock := 0.0


func _init() -> void:
	display_name = "Revenant Maledictus"
	radius = 28.0
	move_speed = 95.0
	max_hp = 1500.0
	xp = 700
	bullet_damage = 30.0
	contact_damage = 45.0
	is_boss = true
	drops_loot = false
	aggro_range = 650.0
	preferred_range = 240.0
	projectile_style = Projectiles.Style.ORB


func _attacks() -> Array:
	return ["barrage", "ether_beam", "summon"]


func _move(delta: float) -> void:
	super._move(delta)
	phase_clock += delta
	untargetable = fmod(phase_clock, PHASE_EVERY) > PHASE_EVERY - PHASE_TIME


func _fire(attack_name: String) -> float:
	if untargetable:
		return 0.2
	match attack_name:
		"barrage":
			fan(position, dir_to_player(position), 3, 0.12, 220.0, 7.0, ETHER)
			return 0.5
		"ether_beam":
			var horizontal := randf() < 0.5
			var line := Rect2(room.position.x, player.position.y - 30, room.size.x, 60) if horizontal \
					else Rect2(player.position.x - 30, room.position.y, 60, room.size.y)
			hazards().rect_blast(line, 1.2, bullet_damage * 2.5, "Ether beam", ETHER)
			return 1.4
		"summon":
			for i in 2:
				summon(Revenant.new(), position + Vector2.from_angle(randf() * TAU) * 70.0)
			return 99.0
	return 1.0


func _draw() -> void:
	var alpha := 0.3 if untargetable else 0.9
	var float_y := sin(time * 2.5) * 4.0
	draw_set_transform(Vector2(0, float_y))
	draw_circle(Vector2.ZERO, 36.0, Color(ETHER, 0.12 * alpha))
	# A towering spectral knight in tattered robes
	draw_colored_polygon(PackedVector2Array([Vector2(-20, -10), Vector2(20, -10), Vector2(24, 30), Vector2(12, 22), Vector2(4, 34),
			Vector2(-4, 22), Vector2(-14, 32), Vector2(-24, 30)]), Color(ETHER.darkened(0.4), alpha * 0.8))
	draw_rect(Rect2(Vector2(-14, -14), Vector2(28, 18)), Color(0.4, 0.45, 0.45, alpha))
	draw_circle(Vector2(0, -24), 12.0, Color(ETHER.darkened(0.2), alpha))
	draw_circle(Vector2(-4, -25), 2.5, Color(1, 1, 1, alpha))
	draw_circle(Vector2(4, -25), 2.5, Color(1, 1, 1, alpha))
	for k in 3:
		draw_colored_polygon(PackedVector2Array([Vector2(-8 + k * 8, -34), Vector2(-6 + k * 8, -44), Vector2(-4 + k * 8, -34)]), Color(0.75, 0.7, 0.4, alpha))
	draw_set_transform(Vector2.ZERO)
	draw_health_bar(44.0)
