extends Enemy
## The Corrupted Hunllef (the Corrupted Gauntlet). Alternates between ranged
## (red) and magic (blue) volleys every four attacks, summons corrupted
## tornadoes, and corrupts the floor in rows of tiles that erupt.

const RANGED := Color(0.95, 0.25, 0.25)
const MAGIC := Color(0.45, 0.4, 1.0)
const CORRUPTION := Color(0.85, 0.15, 0.2)
const TILE := 90.0

var room: Rect2
var magic_style := false
var volleys := 0


func _init() -> void:
	display_name = "Corrupted Hunllef"
	radius = 32.0
	move_speed = 60.0
	max_hp = 1300.0
	xp = 600
	bullet_damage = 28.0
	contact_damage = 45.0
	is_boss = true
	drops_loot = false
	aggro_range = 650.0
	preferred_range = 240.0
	projectile_style = Projectiles.Style.ORB


func _attacks() -> Array:
	return ["volley", "volley", "tiles", "tornadoes"]


func _fire(attack_name: String) -> float:
	match attack_name:
		"volley":
			volleys += 1
			if volleys % 4 == 0:
				magic_style = not magic_style
				DamageText.spawn(get_parent(), position + Vector2(0, -60), "Magic!" if magic_style else "Ranged!", MAGIC if magic_style else RANGED, 16)
			fan(position, dir_to_player(position), 1, 0.1, 230.0, 8.0, MAGIC if magic_style else RANGED)
			return 0.6
		"tiles":
			# Rows of floor tiles erupt; stand between them.
			var rows := int(room.size.y / TILE)
			var bad := randi() % 2
			for r in rows:
				if r % 2 == bad:
					hazards().rect_blast(Rect2(room.position.x, room.position.y + r * TILE, room.size.x, TILE), 1.4,
							bullet_damage * 2.5, "Corrupted floor", CORRUPTION)
			return 2.0
		"tornadoes":
			for i in 2:
				summon(Minion.make("tornado", CORRUPTION), position + Vector2.from_angle(randf() * TAU) * 60.0)
			return 99.0
	return 1.0


func _draw() -> void:
	var crystal := Color(0.75, 0.2, 0.25)
	draw_set_transform(Vector2(0, 34), 0.0, Vector2(1.3, 0.3))
	draw_circle(Vector2.ZERO, 30.0, Color(0, 0, 0, 0.3))
	draw_set_transform(Vector2(0, sin(time * 2.0) * 2.0))
	# A hulking crystalline beast: legs, spiked back, horned head
	for x in [-20.0, -7.0, 7.0, 20.0]:
		draw_line(Vector2(x, 12), Vector2(x * 1.2, 32), crystal.darkened(0.3), 6.0)
	draw_circle(Vector2(0, 8), 26.0, crystal.darkened(0.15))
	for k in 5:
		var x := -16.0 + k * 8.0
		draw_colored_polygon(PackedVector2Array([Vector2(x - 4, -8), Vector2(x, -26 - (k % 2) * 8), Vector2(x + 4, -8)]), crystal.lightened(0.2))
	draw_circle(Vector2(0, -8), 15.0, crystal)
	var eye := MAGIC if magic_style else RANGED
	draw_circle(Vector2(-6, -10), 3.0, eye.lightened(0.3))
	draw_circle(Vector2(6, -10), 3.0, eye.lightened(0.3))
	draw_colored_polygon(PackedVector2Array([Vector2(-8, 0), Vector2(8, 0), Vector2(0, 8)]), Color(0.2, 0.05, 0.08))
	draw_set_transform(Vector2.ZERO)
	draw_health_bar(44.0)
