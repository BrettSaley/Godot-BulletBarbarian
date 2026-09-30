class_name Minion
extends Enemy
## Small monsters configured by `kind` via make(): the adds bosses summon,
## and the rank-and-file monsters of the dungeons. Boss adds:
##   nylocas    - ToB crab that chases and bites (color = melee/ranged/magic)
##   matomenos  - Maiden's blood spawn: crawls to its master and heals it
##   baboon     - Ba-Ba's baboon: chases and flings stones
##   scarab     - Kephri's swarm: crawls to its master and heals it
##   soldier    - Kephri's soldier scarab: guards her shield, spits
##   spiderling - Venenatis's brood: fast, bites
##   hellhound  - Vet'ion's hound: chases, breathes fire
##   shadow     - Akkha's shadow: shielded master until it dies, fires orbs
##   tornado    - Verzik's purple tornado: untargetable, slowly hunts you

## Each kind: name, size, health, speed, colour, behaviour ("chase", "ranged",
## "healer", "tornado") and body shape ("bug", "hound", "baboon", "shadow",
## "ghost", "golem", "blob", "bat", "tornado").
const KINDS := {
	# Raid and boss adds
	"nylocas": {"name": "Nylocas", "radius": 12.0, "hp": 50.0, "speed": 95.0, "color": Color(0.75, 0.75, 0.7), "behavior": "chase", "shape": "bug"},
	"matomenos": {"name": "Nylocas Matomenos", "radius": 13.0, "hp": 260.0, "speed": 45.0, "color": Color(0.7, 0.1, 0.1), "behavior": "healer", "shape": "bug"},
	"baboon": {"name": "Baboon", "radius": 12.0, "hp": 160.0, "speed": 110.0, "color": Color(0.6, 0.45, 0.3), "behavior": "ranged", "shape": "baboon"},
	"scarab": {"name": "Scarab Swarm", "radius": 10.0, "hp": 90.0, "speed": 55.0, "color": Color(0.35, 0.3, 0.2), "behavior": "healer", "shape": "bug"},
	"soldier": {"name": "Soldier Scarab", "radius": 15.0, "hp": 420.0, "speed": 60.0, "color": Color(0.8, 0.6, 0.2), "behavior": "ranged", "shape": "bug"},
	"spiderling": {"name": "Spiderling", "radius": 10.0, "hp": 110.0, "speed": 130.0, "color": Color(0.25, 0.2, 0.3), "behavior": "chase", "shape": "bug"},
	"hellhound": {"name": "Skeleton Hellhound", "radius": 13.0, "hp": 300.0, "speed": 110.0, "color": Color(0.85, 0.82, 0.75), "behavior": "chase", "shape": "hound"},
	"shadow": {"name": "Akkha's Shadow", "radius": 16.0, "hp": 500.0, "speed": 70.0, "color": Color(0.2, 0.1, 0.3), "behavior": "ranged", "shape": "shadow"},
	"yt_hurkot": {"name": "Yt-HurKot", "radius": 12.0, "hp": 200.0, "speed": 60.0, "color": Color(0.55, 0.35, 0.25), "behavior": "healer", "shape": "golem"},
	"scorpia_guardian": {"name": "Scorpia's Guardian", "radius": 11.0, "hp": 180.0, "speed": 60.0, "color": Color(0.45, 0.3, 0.2), "behavior": "healer", "shape": "bug"},
	"cerberus_ghost": {"name": "Summoned Soul", "radius": 13.0, "hp": 150.0, "speed": 50.0, "color": Color(0.6, 0.8, 1.0), "behavior": "ranged", "shape": "ghost"},
	"abyssal_spawn": {"name": "Abyssal Spawn", "radius": 10.0, "hp": 120.0, "speed": 120.0, "color": Color(0.5, 0.15, 0.2), "behavior": "chase", "shape": "blob"},
	"parasite": {"name": "Parasite", "radius": 10.0, "hp": 110.0, "speed": 115.0, "color": Color(0.4, 0.55, 0.35), "behavior": "chase", "shape": "bug"},
	# Dungeon monsters
	"kalphite_worker": {"name": "Kalphite Worker", "radius": 11.0, "hp": 70.0, "speed": 110.0, "color": Color(0.55, 0.45, 0.25), "behavior": "chase", "shape": "bug"},
	"kalphite_soldier": {"name": "Kalphite Soldier", "radius": 14.0, "hp": 150.0, "speed": 85.0, "color": Color(0.5, 0.5, 0.3), "behavior": "ranged", "shape": "bug"},
	"kalphite_guardian": {"name": "Kalphite Guardian", "radius": 18.0, "hp": 300.0, "speed": 70.0, "color": Color(0.4, 0.4, 0.25), "behavior": "chase", "shape": "bug"},
	"temple_spider": {"name": "Temple Spider", "radius": 12.0, "hp": 120.0, "speed": 90.0, "color": Color(0.35, 0.25, 0.2), "behavior": "ranged", "shape": "bug"},
	"cave_kraken": {"name": "Cave Kraken", "radius": 15.0, "hp": 160.0, "speed": 45.0, "color": Color(0.35, 0.55, 0.6), "behavior": "ranged", "shape": "blob"},
	"waterfiend": {"name": "Waterfiend", "radius": 13.0, "hp": 130.0, "speed": 80.0, "color": Color(0.35, 0.55, 0.95), "behavior": "ranged", "shape": "ghost"},
	"tz_kih": {"name": "Tz-Kih", "radius": 10.0, "hp": 60.0, "speed": 140.0, "color": Color(0.35, 0.25, 0.25), "behavior": "chase", "shape": "bat"},
	"tok_xil": {"name": "Tok-Xil", "radius": 15.0, "hp": 180.0, "speed": 70.0, "color": Color(0.45, 0.3, 0.25), "behavior": "ranged", "shape": "golem"},
	"yt_mejkot": {"name": "Yt-MejKot", "radius": 17.0, "hp": 280.0, "speed": 75.0, "color": Color(0.5, 0.3, 0.2), "behavior": "chase", "shape": "golem"},
	"corrupted_wolf": {"name": "Corrupted Wolf", "radius": 13.0, "hp": 140.0, "speed": 130.0, "color": Color(0.8, 0.2, 0.2), "behavior": "chase", "shape": "hound"},
	"corrupted_bear": {"name": "Corrupted Bear", "radius": 18.0, "hp": 300.0, "speed": 75.0, "color": Color(0.7, 0.15, 0.2), "behavior": "chase", "shape": "golem"},
	"corrupted_dragon": {"name": "Corrupted Dragon", "radius": 15.0, "hp": 200.0, "speed": 80.0, "color": Color(0.85, 0.25, 0.3), "behavior": "ranged", "shape": "bat"},
	"wyrm": {"name": "Wyrm", "radius": 14.0, "hp": 170.0, "speed": 85.0, "color": Color(0.4, 0.35, 0.5), "behavior": "ranged", "shape": "bug"},
	"drake": {"name": "Drake", "radius": 16.0, "hp": 220.0, "speed": 90.0, "color": Color(0.55, 0.3, 0.2), "behavior": "chase", "shape": "bat"},
	"ghost": {"name": "Ghost", "radius": 13.0, "hp": 120.0, "speed": 85.0, "color": Color(0.8, 0.85, 0.95), "behavior": "ranged", "shape": "ghost"},
	"husk": {"name": "Husk", "radius": 15.0, "hp": 220.0, "speed": 70.0, "color": Color(0.45, 0.4, 0.35), "behavior": "chase", "shape": "golem"},
	"sleepwalker": {"name": "Sleepwalker", "radius": 13.0, "hp": 140.0, "speed": 80.0, "color": Color(0.55, 0.5, 0.7), "behavior": "ranged", "shape": "ghost"},
	"baby_black_dragon": {"name": "Baby Black Dragon", "radius": 13.0, "hp": 150.0, "speed": 95.0, "color": Color(0.2, 0.18, 0.22), "behavior": "ranged", "shape": "bat"},
	"abyssal_walker": {"name": "Abyssal Walker", "radius": 16.0, "hp": 260.0, "speed": 70.0, "color": Color(0.45, 0.15, 0.25), "behavior": "chase", "shape": "golem"},
	"abyssal_leech": {"name": "Abyssal Leech", "radius": 11.0, "hp": 110.0, "speed": 120.0, "color": Color(0.55, 0.2, 0.3), "behavior": "chase", "shape": "blob"},
	"abyssal_demon": {"name": "Abyssal Demon", "radius": 16.0, "hp": 280.0, "speed": 105.0, "color": Color(0.45, 0.12, 0.35), "behavior": "chase", "shape": "shadow"},
	"abyssal_guardian": {"name": "Abyssal Guardian", "radius": 15.0, "hp": 230.0, "speed": 60.0, "color": Color(0.6, 0.18, 0.2), "behavior": "ranged", "shape": "golem"},
	"scorpion": {"name": "Scorpion", "radius": 12.0, "hp": 130.0, "speed": 100.0, "color": Color(0.35, 0.25, 0.15), "behavior": "chase", "shape": "bug"},
	"king_scorpion": {"name": "King Scorpion", "radius": 16.0, "hp": 250.0, "speed": 80.0, "color": Color(0.5, 0.35, 0.15), "behavior": "ranged", "shape": "bug"},
	"tornado": {"name": "Purple Tornado", "radius": 14.0, "hp": 1.0, "speed": 70.0, "color": Color(0.6, 0.3, 0.8), "behavior": "tornado", "shape": "tornado"},
}

var kind := "nylocas"
var behavior := "chase"
var shape := "bug"
var body_color := Color.WHITE
## For healers: the enemy they crawl to and heal (by this fraction of its max HP).
var master: Enemy
var heal_fraction := 0.08
var lifetime := 0.0


static func make(minion_kind: String, color_override := Color(0, 0, 0, 0)) -> Minion:
	var m := Minion.new()
	m.kind = minion_kind
	var info: Dictionary = KINDS[minion_kind]
	m.display_name = info.name
	m.radius = info.radius
	m.max_hp = info.hp
	m.move_speed = info.speed
	m.behavior = info.behavior
	m.shape = info.shape
	m.body_color = info.color if color_override.a == 0.0 else color_override
	return m


func _init() -> void:
	xp = 10
	bullet_damage = 18.0
	contact_damage = 22.0
	aggro_range = 2000.0
	drops_loot = false
	size_scale = 1.3
	projectile_style = Projectiles.Style.ORB


func _on_setup() -> void:
	if behavior == "tornado":
		untargetable = true
		lifetime = 12.0


func _attacks() -> Array:
	return ["shoot"] if behavior == "ranged" else ["none"]


func _move(delta: float) -> void:
	match behavior:
		"healer":
			if not is_instance_valid(master) or master.hp <= 0.0:
				queue_free()
				return
			position = position.move_toward(master.position, move_speed * delta)
			if position.distance_to(master.position) < master.radius + radius:
				master.hp = minf(master.hp + master.max_hp * heal_fraction, master.max_hp)
				DamageText.spawn(get_parent(), master.position + Vector2(0, -master.radius - 20), "+HEAL", Color(0.4, 1, 0.4), 16)
				queue_free()
		"tornado":
			lifetime -= delta
			if lifetime <= 0.0:
				queue_free()
			position = position.move_toward(player.position, move_speed * delta)
			# Tornadoes are untargetable, so they deal their touch damage here.
			if contact_timer <= 0.0 and touches(player.position, player.hitbox_radius):
				player.take_damage(contact_damage * 1.5, display_name)
				contact_timer = 0.8
		"ranged":
			super._move(delta)
		_:
			# Chasers idle about until they notice you, then run you down.
			if aggro:
				position = position.move_toward(player.position, move_speed * delta)
			else:
				super._move(delta)


func _fire(attack_name: String) -> float:
	if attack_name != "shoot":
		return 99.0
	shoot(position, dir_to_player(position) * 170.0, 6.0, body_color.lightened(0.3))
	return 1.3


func _draw() -> void:
	var c := body_color
	var dark := c.darkened(0.5)
	var wobble := sin(time * 10.0)
	match shape:
		"tornado":
			for k in 4:
				var r := 16.0 - k * 3.0
				draw_arc(Vector2(sin(time * 8.0 + k) * 3.0, -k * 6.0), r, time * 6.0 + k, time * 6.0 + k + PI * 1.5, 12, Color(c, 0.8), 3.0)
			return
		"shadow":
			draw_circle(Vector2.ZERO, 18.0, Color(c, 0.7))
			draw_colored_polygon(PackedVector2Array([Vector2(-10, -12), Vector2(0, -26), Vector2(10, -12)]), Color(c, 0.8))
			draw_circle(Vector2(-5, -4), 2.5, Color(0.8, 0.5, 1))
			draw_circle(Vector2(5, -4), 2.5, Color(0.8, 0.5, 1))
		"ghost":
			var float_y := sin(time * 3.0) * 2.0
			draw_colored_polygon(PackedVector2Array([Vector2(-10, -6 + float_y), Vector2(-8, -14 + float_y), Vector2(0, -17 + float_y),
					Vector2(8, -14 + float_y), Vector2(10, -6 + float_y), Vector2(8, 8 + float_y), Vector2(4, 4 + float_y),
					Vector2(0, 10 + float_y), Vector2(-4, 4 + float_y), Vector2(-8, 8 + float_y)]), Color(c, 0.75))
			draw_circle(Vector2(-3.5, -8 + float_y), 2.0, dark)
			draw_circle(Vector2(3.5, -8 + float_y), 2.0, dark)
		"golem":
			draw_rect(Rect2(Vector2(-8, 8), Vector2(6, 8)), dark)
			draw_rect(Rect2(Vector2(2, 8), Vector2(6, 8)), dark)
			draw_rect(Rect2(Vector2(-11, -6), Vector2(22, 16)), c)
			draw_rect(Rect2(Vector2(-15, -4), Vector2(5, 12)), c.darkened(0.15))
			draw_rect(Rect2(Vector2(10, -4), Vector2(5, 12)), c.darkened(0.15))
			draw_rect(Rect2(Vector2(-6, -15), Vector2(12, 10)), c.lightened(0.1))
			draw_circle(Vector2(-2.5, -10), 1.6, Color(1, 0.6, 0.15))
			draw_circle(Vector2(2.5, -10), 1.6, Color(1, 0.6, 0.15))
		"blob":
			for k in 4:
				var tentacle := Vector2.from_angle(PI * 0.2 + k * PI * 0.2) * 12.0
				draw_line(tentacle * 0.5, tentacle + Vector2(sin(time * 5.0 + k) * 3.0, 6), c.darkened(0.2), 3.0)
			draw_circle(Vector2(0, -2), 11.0 + wobble * 0.6, c)
			draw_circle(Vector2(-4, -5), 2.2, Color(1, 0.9, 0.3))
			draw_circle(Vector2(4, -5), 2.2, Color(1, 0.9, 0.3))
		"bat":
			var flap := sin(time * 12.0)
			for side in [-1.0, 1.0]:
				draw_colored_polygon(PackedVector2Array([Vector2(side * 4, -2), Vector2(side * 20, -10 - flap * 6),
						Vector2(side * 18, 2), Vector2(side * 8, 4)]), c.darkened(0.2))
			draw_circle(Vector2.ZERO, 8.0, c)
			draw_circle(Vector2(-2.5, -2), 1.6, Color(1, 0.5, 0.2))
			draw_circle(Vector2(2.5, -2), 1.6, Color(1, 0.5, 0.2))
		"baboon":
			draw_circle(Vector2(0, 3), 10.0, c)
			draw_circle(Vector2(0, -8), 7.0, c)
			draw_circle(Vector2(0, -6), 4.0, Color(0.9, 0.55, 0.5))
			draw_circle(Vector2(-2.5, -10), 1.3, dark)
			draw_circle(Vector2(2.5, -10), 1.3, dark)
		"hound":
			draw_circle(Vector2(0, 2), 9.0, c)
			draw_circle(Vector2(9, -4), 6.0, c)
			for rib in 3:
				draw_line(Vector2(-5 + rib * 4, -3), Vector2(-5 + rib * 4, 7), dark, 1.2)
			draw_circle(Vector2(11, -5), 1.8, Color(1, 0.4, 0.1))
		_:
			# Bugs and crabs: round body with legs.
			for side in [-1.0, 1.0]:
				for leg in 3:
					var base := Vector2(side * 6, -4 + leg * 5)
					draw_line(base, base + Vector2(side * 8, wobble * 1.5 + leg - 1), dark, 1.5)
			draw_circle(Vector2.ZERO, 9.0, c)
			draw_circle(Vector2(0, -6), 5.0, c.darkened(0.15))
			draw_circle(Vector2(-2, -7), 1.3, Color(1, 0.2, 0.2) if kind != "scarab" else Color(0.1, 0.1, 0.1))
			draw_circle(Vector2(2, -7), 1.3, Color(1, 0.2, 0.2) if kind != "scarab" else Color(0.1, 0.1, 0.1))
	draw_health_bar(14.0)
