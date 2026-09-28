extends Enemy
## The Maiden of Sugadinti (Theatre of Blood). Sits in a pool of blood,
## splattering the floor with lingering blood pools and throwing blood orbs.
## At 70%, 50% and 30% health she calls Nylocas Matomenos from the far wall:
## if they crawl all the way to her, they heal her. Kill them on the way.

const BLOOD := Color(0.75, 0.05, 0.08)
const SPAWN_AT := [0.7, 0.5, 0.3]

## Set by the raid.
var room: Rect2
var spawns_left := SPAWN_AT.duplicate()


func _init() -> void:
	display_name = "The Maiden of Sugadinti"
	radius = 34.0
	move_speed = 0.0
	max_hp = 1600.0
	xp = 700
	bullet_damage = 28.0
	contact_damage = 40.0
	is_boss = true
	drops_loot = false
	aggro_range = 2000.0
	projectile_style = Projectiles.Style.ORB


func _attacks() -> Array:
	return ["blood_splat", "blood_orbs"]


func _move(_delta: float) -> void:
	if not spawns_left.is_empty() and hp / max_hp < spawns_left[0]:
		spawns_left.pop_front()
		for i in 4:
			var crab := Minion.make("matomenos")
			crab.master = self
			crab.heal_fraction = 0.12
			summon(crab, Vector2(room.end.x - 40, room.position.y + room.size.y * (i + 0.5) / 4.0))
		DamageText.spawn(get_parent(), position + Vector2(0, -60), "Nylocas Matomenos crawl toward her!", BLOOD.lightened(0.4), 16)


func _fire(attack_name: String) -> float:
	match attack_name:
		"blood_splat":
			for i in 3:
				var at := player.position + (Vector2.ZERO if i == 0 else Vector2.from_angle(randf() * TAU) * randf_range(60, 140))
				hazards().pool(at, 40.0, 8.0, bullet_damage * 1.2, "Maiden's blood", BLOOD)
			return 1.6
		"blood_orbs":
			fan(position, dir_to_player(position), 2, 0.18, 180.0, 7.0, BLOOD.lightened(0.2))
			return 0.8
	return 1.0


func _draw() -> void:
	# She sits in a spreading pool of blood.
	draw_set_transform(Vector2(0, 14), 0.0, Vector2(1.6, 0.6))
	draw_circle(Vector2.ZERO, 40.0, Color(0.45, 0.02, 0.04, 0.85))
	draw_set_transform(Vector2.ZERO)
	var skin := Color(0.9, 0.82, 0.8)
	# Blood-soaked gown spreading around her
	draw_colored_polygon(PackedVector2Array([Vector2(-34, 24), Vector2(-14, -6), Vector2(14, -6), Vector2(34, 24), Vector2(0, 30)]), Color(0.55, 0.05, 0.08))
	draw_colored_polygon(PackedVector2Array([Vector2(-12, -6), Vector2(12, -6), Vector2(9, 12), Vector2(-9, 12)]), Color(0.7, 0.1, 0.12))
	draw_circle(Vector2(-14, 4), 5.0, skin)
	draw_circle(Vector2(14, 4), 5.0, skin)
	# Pale face framed by long black hair, red eyes
	draw_colored_polygon(PackedVector2Array([Vector2(-13, -24), Vector2(13, -24), Vector2(15, 4), Vector2(-15, 4)]), Color(0.08, 0.05, 0.06))
	draw_circle(Vector2(0, -16), 10.0, skin)
	draw_circle(Vector2(-4, -17), 2.2, BLOOD)
	draw_circle(Vector2(4, -17), 2.2, BLOOD)
	draw_line(Vector2(-3, -10), Vector2(3, -10), Color(0.4, 0.05, 0.05), 1.5)
	draw_line(Vector2(-2, -14), Vector2(-3, -6), Color(BLOOD, 0.8), 1.2)
	draw_health_bar(40.0)
