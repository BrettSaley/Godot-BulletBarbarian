extends Enemy
## TzTok-Jad (the Fight Caves). The famous tell: Jad rears up, glowing blue,
## before a magic bolt, or stomps glowing orange before a rock falls on you.
## Each is telegraphed for a second - move! At half health the Yt-HurKot
## healers come to heal him; kill them first.

const MAGIC := Color(0.35, 0.55, 1.0)
const RANGED := Color(1.0, 0.55, 0.15)
const TELL_TIME := 1.1

var room: Rect2
var tell := ""
var tell_timer := 0.0
var healers_called := false


func _init() -> void:
	display_name = "TzTok-Jad"
	radius = 34.0
	move_speed = 55.0
	max_hp = 1300.0
	xp = 550
	bullet_damage = 30.0
	contact_damage = 45.0
	is_boss = true
	drops_loot = false
	aggro_range = 650.0
	preferred_range = 260.0
	projectile_style = Projectiles.Style.ORB


func _attacks() -> Array:
	return ["magic", "ranged", "magic", "ranged", "ring"]


func _move(delta: float) -> void:
	super._move(delta)
	if tell_timer > 0.0:
		tell_timer -= delta
		if tell_timer <= 0.0:
			if tell == "magic":
				shoot(position, dir_to_player(position) * 280.0, 16.0, MAGIC, 3.5)
			else:
				hazards().blast(player.position, 60.0, 0.5, bullet_damage * 3.5, "Jad's rock", RANGED)
			tell = ""
	if not healers_called and hp / max_hp < 0.5:
		healers_called = true
		for i in 4:
			var healer := Minion.make("yt_hurkot")
			healer.master = self
			healer.heal_fraction = 0.1
			summon(healer, position + Vector2.from_angle(TAU * i / 4.0) * 220.0)
		DamageText.spawn(get_parent(), position + Vector2(0, -60), "The Yt-HurKot come to heal Jad!", RANGED, 18)


func _fire(attack_name: String) -> float:
	match attack_name:
		"magic", "ranged":
			tell = attack_name
			tell_timer = TELL_TIME
			return 2.4
		"ring":
			ring(position, 14, 120.0, 7.0, RANGED.darkened(0.2))
			return 1.2
	return 1.0


func _draw() -> void:
	var rock := Color(0.4, 0.28, 0.22)
	var glow := MAGIC if tell == "magic" else (RANGED if tell == "ranged" else Color(1, 0.4, 0.1))
	draw_set_transform(Vector2(0, 36), 0.0, Vector2(1.3, 0.3))
	draw_circle(Vector2.ZERO, 32.0, Color(0, 0, 0, 0.3))
	var rear := -10.0 if tell == "magic" else 0.0
	var stomp := 4.0 if tell == "ranged" else 0.0
	draw_set_transform(Vector2(0, rear + stomp))
	if tell != "":
		draw_circle(Vector2(0, 0), 46.0, Color(glow, 0.25 + 0.15 * sin(time * 12.0)))
	# Four heavy legs and a craggy body with molten seams
	for x in [-22.0, -8.0, 8.0, 22.0]:
		draw_rect(Rect2(Vector2(x - 5, 18), Vector2(10, 16)), rock.darkened(0.2))
	draw_circle(Vector2(0, 6), 28.0, rock)
	for s in 4:
		draw_line(Vector2(-20 + s * 12, -6), Vector2(-16 + s * 12, 18), Color(1, 0.45, 0.1, 0.8), 2.0)
	# Great horned head
	draw_colored_polygon(PackedVector2Array([Vector2(-14, -22), Vector2(-28, -44), Vector2(-6, -28)]), rock.darkened(0.3))
	draw_colored_polygon(PackedVector2Array([Vector2(14, -22), Vector2(28, -44), Vector2(6, -28)]), rock.darkened(0.3))
	draw_circle(Vector2(0, -20), 15.0, rock.lightened(0.05))
	draw_circle(Vector2(-6, -22), 3.0, glow)
	draw_circle(Vector2(6, -22), 3.0, glow)
	draw_rect(Rect2(Vector2(-8, -12), Vector2(16, 4)), Color(0.1, 0.05, 0.05))
	draw_set_transform(Vector2.ZERO)
	draw_health_bar(44.0)
