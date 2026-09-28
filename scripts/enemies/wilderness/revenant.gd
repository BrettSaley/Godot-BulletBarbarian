extends Enemy
## Revenant (OSRS, the Revenant Caves): a vengeful ghost that drifts toward
## you firing spectral bolts, and fades out of reach every few seconds.

const SPECTRAL := Color(0.55, 0.9, 0.85)
const PHASE_EVERY := 5.0
const PHASE_TIME := 1.5

var phase_clock := 0.0


func _init() -> void:
	display_name = "Revenant"
	radius = 14.0
	move_speed = 90.0
	max_hp = 180.0
	xp = 32
	bullet_damage = 20.0
	contact_damage = 20.0
	preferred_range = 230.0
	projectile_style = Projectiles.Style.ORB


func _attacks() -> Array:
	return ["bolts", "wail"]


func _move(delta: float) -> void:
	super._move(delta)
	if aggro:
		phase_clock += delta
		untargetable = fmod(phase_clock, PHASE_EVERY) > PHASE_EVERY - PHASE_TIME


func _fire(attack_name: String) -> float:
	if untargetable:
		return 0.2
	match attack_name:
		"bolts":
			fan(position, dir_to_player(position), 1, 0.15, 190.0, 6.0, SPECTRAL)
			return 0.7
		"wail":
			ring(position, 12, 115.0, 5.0, SPECTRAL.darkened(0.2))
			return 1.2
	return 1.0


func _draw() -> void:
	var alpha := 0.3 if untargetable else 0.85
	var float_y := sin(time * 3.0) * 3.0
	draw_set_transform(Vector2(0, float_y))
	# Wispy ghost body with a tattered tail
	var body := PackedVector2Array([Vector2(-12, -8), Vector2(-10, -16), Vector2(0, -20), Vector2(10, -16), Vector2(12, -8),
			Vector2(10, 8), Vector2(6, 4), Vector2(2, 12), Vector2(-2, 5), Vector2(-7, 12), Vector2(-10, 6)])
	draw_colored_polygon(body, Color(SPECTRAL, alpha * 0.7))
	draw_circle(Vector2(-4, -10), 2.5, Color(0.05, 0.15, 0.15, alpha))
	draw_circle(Vector2(4, -10), 2.5, Color(0.05, 0.15, 0.15, alpha))
	draw_line(Vector2(-3, -3), Vector2(3, -3), Color(0.05, 0.15, 0.15, alpha), 1.5)
	draw_set_transform(Vector2.ZERO)
	draw_health_bar(18.0)
