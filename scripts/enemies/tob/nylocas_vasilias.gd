extends Enemy
## Nylocas Vasilias (Theatre of Blood). The Nylocas king, who arrives after
## the waves of Nylocas and shifts form every few seconds:
##   Ischyros (grey, melee) - scuttles after you
##   Toxobolos (green, ranged) - spreads of spines
##   Hagios (blue, magic) - rings of magic

const FORMS := {
	"melee": Color(0.8, 0.8, 0.78),
	"ranged": Color(0.35, 0.75, 0.3),
	"magic": Color(0.35, 0.5, 0.95),
}
const SHIFT_EVERY := 6.0

var form := "melee"
var shift_timer := SHIFT_EVERY


func _init() -> void:
	display_name = "Nylocas Vasilias"
	radius = 30.0
	move_speed = 100.0
	max_hp = 1700.0
	xp = 700
	bullet_damage = 28.0
	contact_damage = 45.0
	is_boss = true
	drops_loot = false
	aggro_range = 2000.0
	preferred_range = 220.0
	projectile_style = Projectiles.Style.ORB


func _attacks() -> Array:
	return ["strike"]


func _move(delta: float) -> void:
	shift_timer -= delta
	if shift_timer <= 0.0:
		shift_timer = SHIFT_EVERY
		var others := FORMS.keys()
		others.erase(form)
		form = others.pick_random()
	if form == "melee":
		position = position.move_toward(player.position, move_speed * 1.2 * delta)
	else:
		super._move(delta)


func _fire(_attack_name: String) -> float:
	var color: Color = FORMS[form]
	match form:
		"ranged":
			fan(position, dir_to_player(position), 2, 0.15, 210.0, 6.0, color.lightened(0.2))
			return 0.6
		"magic":
			ring(position, 14, 130.0, 7.0, color.lightened(0.2))
			return 0.8
	ring(position, 6, 120.0, 6.0, color)
	return 1.2


func _draw() -> void:
	var c: Color = FORMS[form]
	draw_set_transform(Vector2(0, 26), 0.0, Vector2(1.3, 0.3))
	draw_circle(Vector2.ZERO, 26.0, Color(0, 0, 0, 0.3))
	draw_set_transform(Vector2.ZERO)
	for side in [-1.0, 1.0]:
		for leg in 4:
			var base := Vector2(side * 16, -10 + leg * 7)
			var tip := base + Vector2(side * 22, sin(time * 12.0 + leg) * 4.0 + leg * 2 - 3)
			draw_line(base, tip, c.darkened(0.35), 4.0)
	draw_circle(Vector2(0, 4), 22.0, c.darkened(0.15))
	draw_circle(Vector2(0, 0), 16.0, c)
	# Crown of spines and pincers
	for k in 5:
		draw_colored_polygon(PackedVector2Array([Vector2(-12 + k * 6, -14), Vector2(-9 + k * 6, -26), Vector2(-6 + k * 6, -14)]), c.lightened(0.3))
	for side in [-1.0, 1.0]:
		draw_colored_polygon(PackedVector2Array([Vector2(side * 10, -10), Vector2(side * 22, -24), Vector2(side * 16, -8)]), c.darkened(0.25))
	draw_circle(Vector2(-6, -4), 3.0, Color(0.9, 0.1, 0.1))
	draw_circle(Vector2(6, -4), 3.0, Color(0.9, 0.1, 0.1))
	draw_health_bar(36.0)
