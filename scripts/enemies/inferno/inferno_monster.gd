class_name InfernoMonster
extends Enemy
## The Inferno's monsters, configured by `kind` via make(). In wave order:
##   nibbler  Jal-Nib     - swarms of tiny biters that run you down
##   bat      Jal-MejRah  - darts about firing quick bursts of embers
##   blob     Jal-Ak      - glows blue (magic bolt) or green (falling spines)
##                          before each attack; splits into three Jal-AkRek
##   blobling Jal-AkRek   - the blob's small offspring
##   meleer   Jal-ImKot   - huge and tough; if you keep away it burrows and
##                          erupts beneath you
##   ranger   Jal-Xil     - hangs back and fires volleys of spines
##   mager    Jal-Zek     - heavy fire orbs, and raises the wave's fallen
##                          monsters at half health
##   healer   Jal-MejJak  - Zuk's healers: mend him and hurl magma at you

const KINDS := {
	"nibbler": {"name": "Jal-Nib", "radius": 9.0, "hp": 70.0, "speed": 150.0, "color": Color(0.38, 0.3, 0.28)},
	"bat": {"name": "Jal-MejRah", "radius": 13.0, "hp": 260.0, "speed": 160.0, "color": Color(0.45, 0.2, 0.18)},
	"blob": {"name": "Jal-Ak", "radius": 20.0, "hp": 520.0, "speed": 55.0, "color": Color(0.6, 0.28, 0.15)},
	"blobling": {"name": "Jal-AkRek", "radius": 10.0, "hp": 110.0, "speed": 90.0, "color": Color(0.75, 0.4, 0.2)},
	"meleer": {"name": "Jal-ImKot", "radius": 22.0, "hp": 950.0, "speed": 80.0, "color": Color(0.35, 0.22, 0.2)},
	"ranger": {"name": "Jal-Xil", "radius": 18.0, "hp": 700.0, "speed": 60.0, "color": Color(0.62, 0.48, 0.3)},
	"mager": {"name": "Jal-Zek", "radius": 20.0, "hp": 820.0, "speed": 50.0, "color": Color(0.32, 0.15, 0.38)},
	"healer": {"name": "Jal-MejJak", "radius": 14.0, "hp": 400.0, "speed": 0.0, "color": Color(0.8, 0.32, 0.15)},
}
## Monsters Jal-Zek can raise when they fall.
const REVIVABLE := ["bat", "blob", "meleer", "ranger"]
const FIRE := Color(1.0, 0.5, 0.1)
const MAGIC := Color(0.45, 0.55, 1.0)
const RANGED := Color(0.45, 0.9, 0.35)
const TELL_TIME := 0.8
const REVIVE_EVERY := 9.0
## Jal-ImKot burrows after you stay this far away for BURROW_AFTER seconds.
const BURROW_RANGE := 240.0
const BURROW_AFTER := 3.0
const BURROW_TIME := 1.4
const HEAL_EVERY := 1.5
## Each Jal-MejJak heals Zuk this fraction of his max HP every HEAL_EVERY.
const HEAL_FRACTION := 0.01

var kind := "nibbler"
var body_color := Color.WHITE
## Shared by every monster of one wave: kinds that have died, for Jal-Zek to raise.
var fallen: Array = []
## Raised by Jal-Zek: won't be raised a second time.
var revived := false
## Healers: the boss they mend.
var master: Enemy
var tell := ""
var tell_timer := 0.0
var next_tell := "magic"
var revive_timer := REVIVE_EVERY
var far_timer := 0.0
var burrow_timer := 0.0
var burrow_spot := Vector2.ZERO
var heal_timer := HEAL_EVERY
var volleys := 0


static func make(monster_kind: String, wave_fallen: Array = []) -> InfernoMonster:
	var m := InfernoMonster.new()
	var info: Dictionary = KINDS[monster_kind]
	m.kind = monster_kind
	m.display_name = info.name
	m.radius = info.radius
	m.max_hp = info.hp
	m.move_speed = info.speed
	m.body_color = info.color
	m.fallen = wave_fallen
	match monster_kind:
		"nibbler":
			m.contact_damage = 26.0
		"bat":
			m.preferred_range = 170.0
		"meleer":
			m.contact_damage = 60.0
		"ranger":
			m.preferred_range = 380.0
		"mager":
			m.preferred_range = 320.0
	return m


func _init() -> void:
	xp = 120
	bullet_damage = 30.0
	contact_damage = 30.0
	aggro_range = 2500.0
	drops_loot = false
	size_scale = 1.3
	projectile_style = Projectiles.Style.ORB


func _on_setup() -> void:
	died.connect(_on_died)


func _on_died(_me: Enemy) -> void:
	if kind in REVIVABLE and not revived:
		fallen.append(kind)
	if kind == "blob":
		for i in 3:
			var child := InfernoMonster.make("blobling", fallen)
			summon(child, position + Vector2.from_angle(TAU * i / 3.0) * 30.0)


## Zek's ice can't hold Inferno creatures long.
func freeze(duration: float) -> void:
	super.freeze(duration * 0.5)


func _attacks() -> Array:
	match kind:
		"nibbler":
			return ["none"]
	return ["shoot"]


func _move(delta: float) -> void:
	match kind:
		"nibbler", "blobling":
			if aggro:
				position = position.move_toward(player.position, move_speed * delta)
			else:
				super._move(delta)
		"meleer":
			_move_meleer(delta)
		"healer":
			_heal_master(delta)
		"bat":
			# Erratic: swap orbit direction now and then.
			if randf() < delta * 0.6:
				orbit_dir = -orbit_dir
			super._move(delta)
		_:
			super._move(delta)
	_update_tell(delta)
	if kind == "mager":
		_try_revive(delta)


func _move_meleer(delta: float) -> void:
	if burrow_timer > 0.0:
		burrow_timer -= delta
		if burrow_timer <= 0.0:
			untargetable = false
			position = burrow_spot
		return
	if not aggro:
		super._move(delta)
		return
	position = position.move_toward(player.position, move_speed * delta)
	far_timer = far_timer + delta if position.distance_to(player.position) > BURROW_RANGE else 0.0
	if far_timer >= BURROW_AFTER:
		# Dig under the floor and come up where you're standing.
		far_timer = 0.0
		untargetable = true
		burrow_timer = BURROW_TIME
		burrow_spot = player.position
		hazards().blast(burrow_spot, 85.0, BURROW_TIME, bullet_damage * 3.0, "Jal-ImKot's eruption", FIRE)


func _heal_master(delta: float) -> void:
	if not is_instance_valid(master) or master.hp <= 0.0:
		queue_free()
		return
	heal_timer -= delta
	if heal_timer <= 0.0:
		heal_timer = HEAL_EVERY
		master.hp = minf(master.hp + master.max_hp * HEAL_FRACTION, master.max_hp)
		DamageText.spawn(get_parent(), master.position + Vector2(randf_range(-40, 40), -master.radius - 20), "+HEAL",
				Color(0.4, 1, 0.4), 14)


func _update_tell(delta: float) -> void:
	if tell_timer <= 0.0:
		return
	tell_timer -= delta
	if tell_timer > 0.0:
		return
	if tell == "magic":
		shoot(position, dir_to_player(position) * 300.0, 13.0, MAGIC, 2.6)
	else:
		for i in 3:
			hazards().blast(player.position + Vector2.from_angle(randf() * TAU) * randf_range(0, 70), 45.0, 0.7,
					bullet_damage * 2.2, "Jal-Ak's spines", RANGED)
	tell = ""


## Jal-Zek raises one fallen monster of its wave at a time, at half health.
func _try_revive(delta: float) -> void:
	revive_timer -= delta
	if revive_timer > 0.0 or fallen.is_empty():
		return
	revive_timer = REVIVE_EVERY
	var risen := InfernoMonster.make(fallen.pop_back(), fallen)
	risen.revived = true
	summon(risen, position + Vector2(randf_range(-60, 60), randf_range(40, 80)))
	risen.hp = risen.max_hp * 0.5
	risen.aggro = true
	DamageText.spawn(get_parent(), position + Vector2(0, -50), "Jal-Zek raises a %s!" % risen.display_name, Color(0.8, 0.5, 1), 16)


func _fire(_attack_name: String) -> float:
	if untargetable:
		return 0.5
	var from := position
	match kind:
		"bat":
			fan(from, dir_to_player(from), 1, 0.14, 330.0, 6.0, FIRE)
			return 0.85
		"blob":
			tell = next_tell
			next_tell = "ranged" if next_tell == "magic" else "magic"
			tell_timer = TELL_TIME
			return 2.0
		"blobling":
			shoot(from, dir_to_player(from) * 240.0, 6.0, [MAGIC, RANGED, FIRE].pick_random())
			return 1.2
		"meleer":
			if from.distance_to(player.position) < radius + 70.0:
				hazards().blast(from, radius + 60.0, 0.45, bullet_damage * 2.5, "Jal-ImKot", FIRE)
			return 1.4
		"ranger":
			volleys += 1
			fan(from, dir_to_player(from), 2, 0.1, 400.0, 7.0, RANGED)
			if volleys % 2 == 0:
				hazards().blast(player.position, 55.0, 0.9, bullet_damage * 2.0, "Jal-Xil's spines", RANGED)
			return 1.0
		"mager":
			volleys += 1
			shoot(from, dir_to_player(from) * 270.0, 14.0, MAGIC, 2.4)
			if volleys % 3 == 0:
				ring(from, 12, 170.0, 8.0, FIRE)
			return 1.3
		"healer":
			hazards().blast(player.position, 45.0, 1.0, bullet_damage * 1.8, "Jal-MejJak's magma", FIRE)
			return 1.8
	return 99.0


func _draw() -> void:
	if untargetable and kind == "meleer":
		# Burrowed: just a churning mound of rock.
		draw_circle(Vector2.ZERO, 14.0, Color(0.25, 0.15, 0.1, 0.8))
		return
	var c := body_color
	var dark := c.darkened(0.5)
	var ember := Color(1, 0.55, 0.15)
	var glow := MAGIC if tell == "magic" else RANGED
	match kind:
		"nibbler":
			for side in [-1.0, 1.0]:
				for leg in 2:
					var base := Vector2(side * 4, -1 + leg * 4)
					draw_line(base, base + Vector2(side * 6, sin(time * 14.0 + leg) * 2.0), dark, 1.5)
			draw_circle(Vector2.ZERO, 7.0, c)
			draw_circle(Vector2(0, -4), 3.0, ember)
		"bat":
			var flap := sin(time * 14.0)
			for side in [-1.0, 1.0]:
				draw_colored_polygon(PackedVector2Array([Vector2(side * 4, -2), Vector2(side * 22, -12 - flap * 7),
						Vector2(side * 20, 3), Vector2(side * 9, 5)]), c.darkened(0.15))
			draw_circle(Vector2.ZERO, 8.0, c)
			draw_circle(Vector2(-2.5, -2), 1.8, ember)
			draw_circle(Vector2(2.5, -2), 1.8, ember)
		"blob", "blobling":
			var r := 16.0 if kind == "blob" else 8.0
			if tell != "":
				draw_circle(Vector2.ZERO, r + 8.0, Color(glow, 0.3 + 0.15 * sin(time * 14.0)))
			draw_circle(Vector2(0, 2), r + sin(time * 4.0), c)
			draw_circle(Vector2(0, -r * 0.3), r * 0.6, c.lightened(0.15))
			for k in 3:
				draw_circle(Vector2(-r * 0.4 + k * r * 0.4, -r * 0.35), r * 0.12, ember)
		"meleer":
			for side in [-1.0, 1.0]:
				draw_colored_polygon(PackedVector2Array([Vector2(side * 10, -4), Vector2(side * 26, 6),
						Vector2(side * 20, 12), Vector2(side * 8, 6)]), c.lightened(0.1))
			draw_circle(Vector2(0, 2), 15.0, c)
			for k in 4:
				draw_line(Vector2(-10 + k * 7, -8), Vector2(-8 + k * 7, 10), Color(1, 0.45, 0.1, 0.7), 1.5)
			draw_circle(Vector2(0, -12), 7.0, c.lightened(0.05))
			draw_circle(Vector2(-3, -13), 1.8, ember)
			draw_circle(Vector2(3, -13), 1.8, ember)
		"ranger":
			for k in 5:
				var a := -PI * 0.85 + k * PI * 0.17
				draw_line(Vector2.from_angle(a) * 10.0, Vector2.from_angle(a) * 22.0, RANGED.darkened(0.2), 2.0)
			draw_circle(Vector2(0, 2), 13.0, c)
			draw_circle(Vector2(0, -6), 6.0, c.darkened(0.1))
			draw_circle(Vector2(0, -7), 2.0, RANGED)
		"mager":
			draw_colored_polygon(PackedVector2Array([Vector2(-14, 14), Vector2(0, -20), Vector2(14, 14)]), c)
			draw_circle(Vector2(0, -10), 7.0, c.lightened(0.1))
			draw_circle(Vector2(0, -10), 3.0 + sin(time * 6.0), MAGIC)
			draw_circle(Vector2(12, -4), 4.0, Color(FIRE, 0.6 + 0.3 * sin(time * 8.0)))
		"healer":
			draw_circle(Vector2.ZERO, 11.0, c)
			draw_circle(Vector2.ZERO, 6.0 + sin(time * 5.0), Color(1, 0.8, 0.3, 0.8))
			draw_line(Vector2(-4, 0), Vector2(4, 0), Color(0.3, 1, 0.3), 2.0)
			draw_line(Vector2(0, -4), Vector2(0, 4), Color(0.3, 1, 0.3), 2.0)
	draw_health_bar(radius / size_scale + 4.0)
