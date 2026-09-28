class_name Minion
extends Enemy
## Small adds that bosses summon, configured by `kind` via make():
##   nylocas    - ToB crab that chases and bites (color = melee/ranged/magic)
##   matomenos  - Maiden's blood spawn: crawls to its master and heals it
##   baboon     - Ba-Ba's baboon: chases and flings stones
##   scarab     - Kephri's swarm: crawls to its master and heals it
##   soldier    - Kephri's soldier scarab: guards her shield, spits
##   spiderling - Venenatis's brood: fast, bites
##   hellhound  - Vet'ion's hound: chases, breathes fire
##   shadow     - Akkha's shadow: shielded master until it dies, fires orbs
##   tornado    - Verzik's purple tornado: untargetable, slowly hunts you

const KINDS := {
	"nylocas": {"name": "Nylocas", "radius": 12.0, "hp": 120.0, "speed": 95.0, "color": Color(0.75, 0.75, 0.7), "behavior": "chase"},
	"matomenos": {"name": "Nylocas Matomenos", "radius": 13.0, "hp": 260.0, "speed": 45.0, "color": Color(0.7, 0.1, 0.1), "behavior": "healer"},
	"baboon": {"name": "Baboon", "radius": 12.0, "hp": 160.0, "speed": 110.0, "color": Color(0.6, 0.45, 0.3), "behavior": "ranged"},
	"scarab": {"name": "Scarab Swarm", "radius": 10.0, "hp": 90.0, "speed": 55.0, "color": Color(0.35, 0.3, 0.2), "behavior": "healer"},
	"soldier": {"name": "Soldier Scarab", "radius": 15.0, "hp": 420.0, "speed": 60.0, "color": Color(0.8, 0.6, 0.2), "behavior": "ranged"},
	"spiderling": {"name": "Spiderling", "radius": 10.0, "hp": 110.0, "speed": 130.0, "color": Color(0.25, 0.2, 0.3), "behavior": "chase"},
	"hellhound": {"name": "Skeleton Hellhound", "radius": 13.0, "hp": 300.0, "speed": 110.0, "color": Color(0.85, 0.82, 0.75), "behavior": "chase"},
	"shadow": {"name": "Akkha's Shadow", "radius": 16.0, "hp": 500.0, "speed": 70.0, "color": Color(0.2, 0.1, 0.3), "behavior": "ranged"},
	"tornado": {"name": "Purple Tornado", "radius": 14.0, "hp": 1.0, "speed": 70.0, "color": Color(0.6, 0.3, 0.8), "behavior": "tornado"},
}

var kind := "nylocas"
var behavior := "chase"
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
			position = position.move_toward(player.position, move_speed * delta)


func _fire(attack_name: String) -> float:
	if attack_name != "shoot":
		return 99.0
	shoot(position, dir_to_player(position) * 170.0, 6.0, body_color.lightened(0.3))
	return 1.3


func _draw() -> void:
	var c := body_color
	var dark := c.darkened(0.5)
	var wobble := sin(time * 10.0)
	match kind:
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
		"baboon":
			draw_circle(Vector2(0, 3), 10.0, c)
			draw_circle(Vector2(0, -8), 7.0, c)
			draw_circle(Vector2(0, -6), 4.0, Color(0.9, 0.55, 0.5))
			draw_circle(Vector2(-2.5, -10), 1.3, dark)
			draw_circle(Vector2(2.5, -10), 1.3, dark)
		"hellhound":
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
