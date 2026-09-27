extends Enemy
## Zulrah (OSRS). Rises from its toxic swamp in one of three forms, then dives
## and resurfaces at another spot around the swamp in a new form:
##   Serpentine (green, ranged)  - spits toxic spines, leaves venom clouds
##   Magma      (red, melee)     - glares at you, then whips its tail down a line
##   Tanzanite  (blue, magic)    - rings of magic orbs and venom clouds

const FORMS := {
	"serpentine": {"color": Color(0.3, 0.65, 0.3), "attacks": ["spit", "venom"]},
	"magma": {"color": Color(0.8, 0.28, 0.15), "attacks": ["tail_whip"]},
	"tanzanite": {"color": Color(0.25, 0.5, 0.85), "attacks": ["orbs", "venom"]},
}
const SPOTS := [Vector2(0, -150), Vector2(170, 0), Vector2(0, 150), Vector2(-170, 0)]
const SURFACE_TIME := 9.0
const DIVE_TIME := 1.4
const SWAMP_RADIUS := 230.0
const VENOM := Color(0.45, 0.75, 0.2)

var form := "serpentine"
var spot := 0
var surfaced_time := 0.0
var dive_timer := 0.0


func _init() -> void:
	display_name = "Zulrah"
	radius = 24.0
	move_speed = 0.0
	max_hp = 1400.0
	xp = 450
	bullet_damage = 28.0
	contact_damage = 30.0
	is_boss = true
	aggro_range = 650.0
	projectile_style = Projectiles.Style.ORB


func _on_setup() -> void:
	position = home + SPOTS[spot]


func _attacks() -> Array:
	return FORMS[form].attacks


func _move(delta: float) -> void:
	if dive_timer > 0.0:
		dive_timer -= delta
		if dive_timer <= 0.0:
			_surface()
		return
	surfaced_time += delta
	if aggro and surfaced_time > SURFACE_TIME:
		_dive()


func _dive() -> void:
	untargetable = true
	dive_timer = DIVE_TIME
	attack = ""
	attack_timer = 0.0
	rest_timer = DIVE_TIME + 0.7


func _surface() -> void:
	var others := range(SPOTS.size())
	others.erase(spot)
	spot = others.pick_random()
	position = home + SPOTS[spot]
	var forms := FORMS.keys()
	forms.erase(form)
	form = forms.pick_random()
	untargetable = false
	surfaced_time = 0.0


func _fire(attack_name: String) -> float:
	var d := difficulty
	match attack_name:
		"spit":
			fan(position, dir_to_player(position), 1 + int(d * 1.99), 0.18, 190.0, 7.0, FORMS.serpentine.color.lightened(0.2))
			return 0.7
		"venom":
			for i in 2:
				var at := player.position + Vector2.from_angle(randf() * TAU) * randf_range(20, 110)
				hazards().pool(at, 42.0, 7.0, bullet_damage * 1.2, "Zulrah's venom", VENOM)
			return 1.5
		"tail_whip":
			# A line of blasts from Zulrah toward where the player is standing.
			var dir := dir_to_player(position)
			for i in range(1, 8):
				hazards().blast(position + dir * i * 55.0, 38.0, 1.1, bullet_damage * 2.0, "Zulrah's tail", Color(1, 0.35, 0.15))
			return 1.9
		"orbs":
			ring(position, int(lerpf(10, 16, d)), 130.0, 7.0, FORMS.tanzanite.color.lightened(0.3))
			return 1.0
	return 1.0


func _draw() -> void:
	# The swamp stays put while Zulrah moves between spots around it.
	var swamp := (home - position) / size_scale
	draw_circle(swamp, SWAMP_RADIUS / size_scale, Color(0.12, 0.28, 0.2, 0.85))
	draw_circle(swamp, SWAMP_RADIUS * 0.8 / size_scale, Color(0.16, 0.34, 0.24, 0.8))
	for k in 5:
		var ripple := fmod(time * 0.5 + k * 0.2, 1.0)
		draw_arc(swamp + Vector2.from_angle(k * 1.3) * 90.0, 10.0 + ripple * 30.0, 0.0, TAU, 20, Color(0.5, 0.8, 0.6, 0.4 * (1.0 - ripple)), 1.5)

	if untargetable:
		# Bubbles where it will rise.
		for k in 4:
			draw_circle(Vector2.from_angle(time * 3.0 + k * 1.6) * 12.0, 4.0, Color(0.6, 0.9, 0.6, 0.6))
		return

	var body: Color = FORMS[form].color
	var belly := body.lightened(0.35)
	var rise := sin(time * 2.0) * 3.0
	# Coils in the water
	draw_set_transform(Vector2(0, 16), 0.0, Vector2(1.0, 0.45))
	draw_circle(Vector2.ZERO, 30.0, body.darkened(0.3))
	draw_circle(Vector2.ZERO, 22.0, body.darkened(0.1))
	draw_set_transform(Vector2.ZERO)
	# Neck rising up
	for i in 5:
		var p := Vector2(sin(time * 2.0 + i * 0.6) * 3.0, 10.0 - i * 9.0 + rise * i / 5.0)
		draw_circle(p, 12.0 - i * 0.6, body)
		draw_circle(p + Vector2(0, 2), 6.0 - i * 0.3, belly)
	# Head with frill
	var head := Vector2(sin(time * 2.0 + 3.0) * 3.0, -38.0 + rise)
	draw_colored_polygon(PackedVector2Array([head + Vector2(-20, -4), head + Vector2(0, -24), head + Vector2(20, -4), head + Vector2(0, 4)]), body.darkened(0.25))
	draw_circle(head, 13.0, body)
	draw_circle(head + Vector2(0, 7), 7.0, belly)
	var eye := Color(1, 0.9, 0.2) if is_attacking() else Color(0.9, 0.8, 0.4)
	draw_circle(head + Vector2(-6, -3), 3.0, eye)
	draw_circle(head + Vector2(6, -3), 3.0, eye)
	draw_line(head + Vector2(-6, -5), head + Vector2(-6, -1), Color(0.1, 0, 0), 1.5)
	draw_line(head + Vector2(6, -5), head + Vector2(6, -1), Color(0.1, 0, 0), 1.5)
	draw_colored_polygon(PackedVector2Array([head + Vector2(-4, 9), head + Vector2(-2, 9), head + Vector2(-3, 14)]), Color(1, 1, 1))
	draw_colored_polygon(PackedVector2Array([head + Vector2(2, 9), head + Vector2(4, 9), head + Vector2(3, 14)]), Color(1, 1, 1))
	draw_health_bar(34.0)
