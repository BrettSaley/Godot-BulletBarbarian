extends Enemy
## The Kalphite Queen (Kalphite Lair). Fights in two forms: when her crawling
## form falls she sheds it and rises again, winged and faster, at full health.
## Spits spines, sprays acid pools, and chains bolts of magic at you.

const SPINE := Color(0.75, 0.65, 0.35)
const ACID := Color(0.55, 0.8, 0.2)
const MAGIC := Color(0.6, 0.4, 1.0)

var room: Rect2
var form := 1
var facing := 1.0


func _init() -> void:
	display_name = "Kalphite Queen"
	radius = 30.0
	move_speed = 75.0
	max_hp = 1100.0
	xp = 500
	bullet_damage = 26.0
	contact_damage = 40.0
	is_boss = true
	drops_loot = false
	aggro_range = 650.0
	preferred_range = 180.0
	projectile_style = Projectiles.Style.ORB


## Her first death just ends the crawling form.
func take_damage(amount: float) -> void:
	if form == 1 and hp - amount <= 0.0 and can_be_hit_by_player():
		form = 2
		hp = max_hp
		move_speed *= 1.4
		DamageText.spawn(get_parent(), position + Vector2(0, -60), "The Kalphite Queen takes flight!", SPINE, 18)
		return
	super.take_damage(amount)


func _attacks() -> Array:
	return ["spines", "acid", "magic"] if form == 1 else ["spines", "magic", "swarm"]


func _move(delta: float) -> void:
	super._move(delta)
	facing = 1.0 if player.position.x >= position.x else -1.0


func _fire(attack_name: String) -> float:
	var pace := 0.75 if form == 2 else 1.0
	match attack_name:
		"spines":
			var saved := projectile_style
			projectile_style = Projectiles.Style.ARROW
			fan(position, dir_to_player(position), 2, 0.14, 210.0, 6.0, SPINE)
			projectile_style = saved
			return 0.7 * pace
		"acid":
			for i in 3:
				hazards().pool(player.position + Vector2.from_angle(randf() * TAU) * randf_range(0, 100), 40.0, 6.0,
						bullet_damage * 1.2, "Kalphite acid", ACID)
			return 1.5
		"magic":
			for i in 3:
				shoot(position, dir_to_player(position).rotated(randf_range(-0.1, 0.1)) * (170.0 + i * 25.0), 8.0, MAGIC)
			return 0.9 * pace
		"swarm":
			ring(position, 16, 130.0, 6.0, SPINE.darkened(0.2))
			return 1.0
	return 1.0


func _draw() -> void:
	var shell := Color(0.5, 0.42, 0.22) if form == 1 else Color(0.62, 0.5, 0.25)
	draw_set_transform(Vector2(0, 32), 0.0, Vector2(1.4, 0.3))
	draw_circle(Vector2.ZERO, 30.0, Color(0, 0, 0, 0.3))
	draw_set_transform(Vector2(0, -8 if form == 2 else 0), 0.0, Vector2(facing, 1.0))
	if form == 2:
		var flap := sin(time * 14.0)
		for side in [-1.0, 1.0]:
			draw_colored_polygon(PackedVector2Array([Vector2(side * 8, -8), Vector2(side * 44, -26 - flap * 10), Vector2(side * 38, 0)]),
					Color(0.85, 0.9, 0.75, 0.55))
	for side in [-1.0, 1.0]:
		for leg in 3:
			var base := Vector2(side * 14, -2 + leg * 10)
			draw_line(base, base + Vector2(side * 18, 6 + sin(time * 8.0 + leg) * 3.0), shell.darkened(0.3), 4.0)
	# Long segmented abdomen, thorax and armoured head
	draw_circle(Vector2(-18, 10), 18.0, shell.darkened(0.1))
	draw_circle(Vector2(0, 4), 16.0, shell)
	draw_circle(Vector2(16, -4), 12.0, shell.lightened(0.1))
	for s in 3:
		draw_arc(Vector2(-18, 10), 18.0 - s * 5.0, PI * 1.1, PI * 1.9, 8, shell.darkened(0.35), 1.5)
	draw_colored_polygon(PackedVector2Array([Vector2(24, -8), Vector2(36, -4), Vector2(24, 0)]), shell.darkened(0.2))
	draw_circle(Vector2(18, -8), 2.5, Color(0.2, 0.9, 0.3))
	draw_set_transform(Vector2.ZERO)
	draw_string(ThemeDB.fallback_font, Vector2(-60, 50), "Form %d / 2" % form, HORIZONTAL_ALIGNMENT_CENTER, 120, 12, Color(1, 0.9, 0.6))
	draw_health_bar(42.0)
