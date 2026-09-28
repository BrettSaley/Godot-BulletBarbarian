extends Enemy
## The Wardens (Tombs of Amascut), the final boss, in three phases:
##   1 Shielded by the Obelisk behind it: destroy the Obelisk first.
##   2 The Warden fights: divine lightning strips across the room, skull
##     barrages and crushing slams.
##   3 (below 35%) Enraged: the floor tiles themselves start to explode.

const DIVINE := Color(1.0, 0.85, 0.35)
const ELIDINIS := Color(0.4, 0.7, 1.0)
const CELL := 90.0
const ENRAGE_BELOW := 0.35

## Set by the raid.
var room: Rect2
var obelisk: Enemy
var announced := false
var tile_timer := 0.0


func _init() -> void:
	display_name = "Tumeken's Warden"
	radius = 30.0
	move_speed = 70.0
	max_hp = 2600.0
	xp = 1500
	bullet_damage = 34.0
	contact_damage = 55.0
	is_boss = true
	drops_loot = false
	aggro_range = 2000.0
	preferred_range = 240.0
	projectile_style = Projectiles.Style.ORB


func phase() -> int:
	if is_instance_valid(obelisk) and obelisk.hp > 0.0:
		return 1
	return 3 if hp / max_hp < ENRAGE_BELOW else 2


func _attacks() -> Array:
	return ["slam"] if phase() == 1 else ["divine", "skulls", "slam"]


func _move(delta: float) -> void:
	invulnerable = phase() == 1
	if phase() == 1:
		return
	if not announced:
		announced = true
		DamageText.spawn(get_parent(), position + Vector2(0, -70), "The Obelisk falls - the Warden awakens!", DIVINE, 18)
	super._move(delta)
	if phase() == 3:
		tile_timer -= delta
		if tile_timer <= 0.0:
			tile_timer = 2.4
			_explode_tiles()


## Enraged: a random 40% of the floor tiles light up and explode.
func _explode_tiles() -> void:
	var cols := int(room.size.x / CELL)
	var rows := int(room.size.y / CELL)
	for c in cols:
		for r in rows:
			if randf() < 0.4:
				hazards().rect_blast(Rect2(room.position + Vector2(c, r) * CELL, Vector2(CELL, CELL)), 1.4,
						bullet_damage * 2.0, "The Wardens' floor", DIVINE)


func _fire(attack_name: String) -> float:
	match attack_name:
		"slam":
			hazards().blast(player.position, 70.0, 1.1, bullet_damage * 2.5, "Warden's slam", DIVINE)
			return 1.6 if phase() == 1 else 1.1
		"divine":
			# Two strips of lightning, one across and one down.
			var y := clampf(player.position.y, room.position.y + 30, room.end.y - 30)
			var x := clampf(player.position.x, room.position.x + 30, room.end.x - 30)
			hazards().rect_blast(Rect2(room.position.x, y - 30, room.size.x, 60), 1.2, bullet_damage * 2.5, "Divine lightning", ELIDINIS)
			hazards().rect_blast(Rect2(x - 30, room.position.y, 60, room.size.y), 1.6, bullet_damage * 2.5, "Divine lightning", ELIDINIS)
			return 1.8
		"skulls":
			fan(position, dir_to_player(position), 3, 0.15, 200.0, 8.0, DIVINE.lightened(0.2))
			return 0.6
	return 1.0


func _draw() -> void:
	var stone := Color(0.55, 0.5, 0.42)
	var core := DIVINE if phase() > 1 else Color(0.6, 0.55, 0.45)
	draw_set_transform(Vector2(0, 36), 0.0, Vector2(1.3, 0.3))
	draw_circle(Vector2.ZERO, 30.0, Color(0, 0, 0, 0.3))
	draw_set_transform(Vector2(0, sin(time * 2.0) * 2.0))
	if invulnerable:
		draw_arc(Vector2.ZERO, 46.0, 0.0, TAU, 40, Color(ELIDINIS, 0.6 + 0.2 * sin(time * 5.0)), 3.0)
	# Towering statue body with a glowing core
	draw_colored_polygon(PackedVector2Array([Vector2(-22, 34), Vector2(-26, -6), Vector2(-14, -18), Vector2(14, -18),
			Vector2(26, -6), Vector2(22, 34)]), stone)
	draw_circle(Vector2(0, 4), 10.0 + (sin(time * 6.0) * 2.0 if phase() == 3 else 0.0), core)
	for side in [-1.0, 1.0]:
		draw_rect(Rect2(Vector2(side * 26 - 6, -10), Vector2(12, 34)), stone.darkened(0.15))
	# Head with a divine crest
	draw_colored_polygon(PackedVector2Array([Vector2(-12, -18), Vector2(-10, -40), Vector2(10, -40), Vector2(12, -18)]), stone.lightened(0.1))
	draw_colored_polygon(PackedVector2Array([Vector2(-8, -40), Vector2(0, -56), Vector2(8, -40)]), core)
	draw_circle(Vector2(-4, -30), 2.5, core)
	draw_circle(Vector2(4, -30), 2.5, core)
	draw_set_transform(Vector2.ZERO)
	if invulnerable:
		draw_string(ThemeDB.fallback_font, Vector2(-60, -64), "IMMUNE - destroy the Obelisk", HORIZONTAL_ALIGNMENT_CENTER, 120, 11, ELIDINIS)
	draw_health_bar(46.0)
