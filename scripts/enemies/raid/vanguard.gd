extends Enemy
## Vanguards (Chambers of Xeric). Three armoured constructs fought together:
##   Melee  - rushes you down
##   Ranged - calls down rock falls around you
##   Magic  - fires spreads of magic orbs
## If one falls too far behind the others in health, the raid shields it: it
## turns grey inside a crystal barrier and shots do nothing until the others
## catch up (see raid.gd).

const KINDS := {
	"melee": Color(0.85, 0.25, 0.2),
	"ranged": Color(0.3, 0.75, 0.3),
	"magic": Color(0.3, 0.5, 0.95),
}

var kind := "melee"


func _init() -> void:
	display_name = "Vanguard"
	radius = 20.0
	move_speed = 85.0
	max_hp = 650.0
	xp = 120
	bullet_damage = 22.0
	contact_damage = 35.0
	drops_loot = false
	size_scale = 1.25
	aggro_range = 2000.0
	preferred_range = 260.0
	projectile_style = Projectiles.Style.ORB


func set_kind(new_kind: String) -> void:
	kind = new_kind
	display_name = "%s Vanguard" % kind.capitalize()
	if kind == "melee":
		move_speed = 115.0


func _attacks() -> Array:
	match kind:
		"melee":
			return ["rush"]
		"ranged":
			return ["rock_fall"]
	return ["orbs"]


func _move(delta: float) -> void:
	if kind == "melee":
		position = position.move_toward(player.position, move_speed * delta)
	else:
		super._move(delta)


func _fire(attack_name: String) -> float:
	var color: Color = KINDS[kind]
	match attack_name:
		"rush":
			ring(position, 8, 110.0, 5.0, color)
			return 1.1
		"rock_fall":
			for i in 4:
				var at := player.position + Vector2.from_angle(randf() * TAU) * randf_range(0, 130)
				hazards().blast(at, 45.0, 1.1, bullet_damage * 1.8, display_name, Color(0.7, 0.6, 0.45))
			return 1.4
		"orbs":
			fan(position, dir_to_player(position), 2, 0.2, 170.0, 7.0, color.lightened(0.3))
			return 0.8
	return 1.0


func _draw() -> void:
	var color: Color = KINDS[kind]
	var metal := Color(0.35, 0.36, 0.4)
	if invulnerable:
		# Drained of colour while shielded.
		color = Color(0.55, 0.57, 0.62)
		metal = Color(0.28, 0.29, 0.32)
	draw_set_transform(Vector2(0, 22), 0.0, Vector2(1.0, 0.35))
	draw_circle(Vector2.ZERO, 20.0, Color(0, 0, 0, 0.3))
	draw_set_transform(Vector2(0, sin(time * 5.0) * 1.5))
	# Spiked shell with coloured plating and a single glowing eye
	for k in 8:
		var angle := TAU * k / 8.0 + time * 0.5
		draw_colored_polygon(PackedVector2Array([Vector2.from_angle(angle - 0.2) * 18.0,
				Vector2.from_angle(angle) * 26.0, Vector2.from_angle(angle + 0.2) * 18.0]), metal)
	draw_circle(Vector2.ZERO, 19.0, metal)
	draw_circle(Vector2.ZERO, 14.0, color.darkened(0.2))
	draw_circle(Vector2.ZERO, 7.0, Color(0.1, 0.1, 0.1))
	var glow := color.lightened(0.5) if is_attacking() else color.lightened(0.2)
	draw_circle(Vector2.ZERO, 4.0, glow)
	draw_set_transform(Vector2.ZERO)
	if invulnerable:
		_draw_shield()
	draw_health_bar(28.0)


## A pulsing crystal barrier with rotating facets and an IMMUNE label.
func _draw_shield() -> void:
	var pulse := 0.5 + 0.5 * sin(time * 5.0)
	var ice := Color(0.6, 0.88, 1.0)
	draw_circle(Vector2.ZERO, 32.0, Color(ice, 0.18 + 0.1 * pulse))
	draw_arc(Vector2.ZERO, 32.0, 0.0, TAU, 40, Color(ice, 0.7 + 0.3 * pulse), 2.5)
	for k in 6:
		var angle := TAU * k / 6.0 - time * 0.8
		var a := Vector2.from_angle(angle) * 32.0
		var b := Vector2.from_angle(angle + TAU / 6.0) * 32.0
		draw_line(a, b, Color(1, 1, 1, 0.5), 1.5)
		draw_circle(a, 2.5, Color(1, 1, 1, 0.8))
	draw_string(ThemeDB.fallback_font, Vector2(-40, -38), "IMMUNE", HORIZONTAL_ALIGNMENT_CENTER, 80, 12, ice)
