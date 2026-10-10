extends Enemy
## TzKal-Zuk, the Inferno's tenth and final wave. Zuk sits on his ledge at
## the top of the arena and never moves. Below him the Ancestral Glyph, a
## shield, slides back and forth: every few seconds Zuk charges (his eyes
## blaze and the glyph glows) and unleashes a blast that only the glyph can
## stop - stand under it or lose most of your health. Between blasts he rains
## magma, rings of fire and walls of flame across the arena, and as he weakens
## he calls for help:
##   80%  a Jal-Xil and a Jal-Zek
##   50%  JalTok-Jad (who brings his own healers)
##   25%  four Jal-MejJak that heal him, and he enrages: faster blasts and a
##        faster glyph

const Jad := preload("res://scripts/enemies/dungeon/jad.gd")

const FIRE := Color(1.0, 0.45, 0.1)
const BLAST := Color(1.0, 0.85, 0.4)
const SHIELD_WIDTH := 150.0
const SHIELD_SPEED := 80.0
const ENRAGED_SHIELD_SPEED := 120.0
## The glyph floats this far below the top of the floor.
const SHIELD_DEPTH := 55.0
const CHARGE_TIME := 1.6
const TYPHOON_EVERY := 5.0
const ENRAGED_TYPHOON_EVERY := 3.4
## An unblocked blast takes this fraction of your max HP, ignoring Defence.
const TYPHOON_DAMAGE := 0.85
const LANE := 40.0

## Set by the raid.
var room: Rect2
var floor_rect: Rect2

var shield_x := 0.0
var shield_dir := 1.0
var typhoon_timer := 4.0
var charge_timer := 0.0
var beam_timer := 0.0
var beam_to := Vector2.ZERO
var beam_blocked := false
var warned := false
## HP thresholds already passed (0.8, 0.5, 0.25).
var sets_called := 0


func _init() -> void:
	display_name = "TzKal-Zuk"
	radius = 46.0
	move_speed = 0.0
	max_hp = 5500.0
	xp = 5000
	bullet_damage = 34.0
	contact_damage = 0.0
	is_boss = true
	drops_loot = false
	aggro_range = 3000.0
	projectile_style = Projectiles.Style.ORB


func _on_setup() -> void:
	shield_x = floor_rect.get_center().x


func _ready() -> void:
	add_ground_decor(_draw_glyph)


func is_enraged() -> bool:
	return hp / max_hp < 0.25


## Nothing holds Zuk still.
func freeze(_duration: float) -> void:
	pass


func shield_y() -> float:
	return floor_rect.position.y + SHIELD_DEPTH


## Is the player hiding below the glyph?
func is_shielded() -> bool:
	return player.position.y > shield_y() and absf(player.position.x - shield_x) < SHIELD_WIDTH / 2.0


func _attacks() -> Array:
	return ["magma", "embers", "flame_wall"] if not is_enraged() else ["magma", "embers", "flame_wall", "magma"]


func _move(delta: float) -> void:
	# The glyph slides from wall to wall.
	var speed := ENRAGED_SHIELD_SPEED if is_enraged() else SHIELD_SPEED
	var left := floor_rect.position.x + SHIELD_WIDTH / 2.0 + 30.0
	var right := floor_rect.end.x - SHIELD_WIDTH / 2.0 - 30.0
	shield_x += shield_dir * speed * delta
	if shield_x > right or shield_x < left:
		shield_x = clampf(shield_x, left, right)
		shield_dir = -shield_dir
	beam_timer -= delta
	_update_typhoon(delta)
	_call_sets()


func _update_typhoon(delta: float) -> void:
	if charge_timer > 0.0:
		charge_timer -= delta
		if charge_timer <= 0.0:
			_unleash()
		return
	typhoon_timer -= delta
	if typhoon_timer <= 0.0:
		typhoon_timer = ENRAGED_TYPHOON_EVERY if is_enraged() else TYPHOON_EVERY
		charge_timer = CHARGE_TIME
		if not warned:
			warned = true
			DamageText.spawn(get_parent(), position + Vector2(0, 70), "Get behind the glyph!", BLAST, 20)


func _unleash() -> void:
	beam_blocked = is_shielded()
	beam_to = Vector2(player.position.x, shield_y()) if beam_blocked else player.position
	beam_timer = 0.3
	if not beam_blocked:
		player.take_damage(player.max_hp() * TYPHOON_DAMAGE, display_name, true)


## Zuk calls for help as his health falls.
func _call_sets() -> void:
	var fraction := hp / max_hp
	if sets_called == 0 and fraction <= 0.8:
		sets_called = 1
		_call(InfernoMonster.make("ranger"), Vector2(floor_rect.position.x + 120, floor_rect.get_center().y))
		_call(InfernoMonster.make("mager"), Vector2(floor_rect.end.x - 120, floor_rect.get_center().y))
		_shout("Zuk calls his guardians!")
	elif sets_called == 1 and fraction <= 0.5:
		sets_called = 2
		var jad: Enemy = Jad.new()
		jad.display_name = "JalTok-Jad"
		jad.room = floor_rect
		_call(jad, floor_rect.get_center() + Vector2(0, 120))
		_shout("JalTok-Jad answers Zuk's call!")
	elif sets_called == 2 and fraction <= 0.25:
		sets_called = 3
		for i in 4:
			var healer := InfernoMonster.make("healer")
			healer.master = self
			var spot := position + Vector2(-210.0 + i * 140.0, 40.0)
			healer.position = spot
			summon(healer, spot)
		_shout("Zuk is enraged! The Jal-MejJak mend him - kill them!")


## Adds fight on the arena floor, not up on Zuk's ledge.
func _call(add: Enemy, pos: Vector2) -> void:
	summon(add, pos)
	add.bounds = floor_rect
	add.position = add.position.clamp(floor_rect.position + Vector2.ONE * add.radius, floor_rect.end - Vector2.ONE * add.radius)
	add.aggro = true


func _shout(text: String) -> void:
	DamageText.spawn(get_parent(), position + Vector2(0, 80), text, FIRE, 20)


func _fire(attack_name: String) -> float:
	var pace := 0.7 if is_enraged() else 1.0
	match attack_name:
		"magma":
			for i in 5:
				hazards().blast(player.position + Vector2.from_angle(randf() * TAU) * randf_range(0, 120), 50.0, 1.1,
						bullet_damage * 2.2, "Zuk's magma", FIRE)
			return 1.4 * pace
		"embers":
			ring(position, 20, 170.0, 8.0, FIRE)
			fan(position, dir_to_player(position), 2, 0.12, 260.0, 9.0, FIRE.lightened(0.2))
			return 1.1 * pace
		"flame_wall":
			# Flames roll across the floor from the west wall, with a gap to slip through.
			var lanes := int(floor_rect.size.y / LANE)
			var gap := randi() % (lanes - 3)
			var rows := range(lanes).filter(func(lane): return lane < gap or lane >= gap + 3)
			lane_attack(floor_rect, LANE, rows, 230.0, 13.0, FIRE, 1.6)
			return 3.0 * pace
	return 1.0


func _draw_glyph(ci: Node2D) -> void:
	if hp <= 0.0:
		return
	var y := shield_y()
	var charging := charge_timer > 0.0
	var glow := Color(0.6, 0.9, 1.0, 0.35 + (0.3 * sin(time * 16.0) if charging else 0.0))
	# The safe column below the glyph, shown while Zuk charges.
	if charging:
		ci.draw_rect(Rect2(shield_x - SHIELD_WIDTH / 2.0, y, SHIELD_WIDTH, floor_rect.end.y - y), Color(0.5, 0.85, 1.0, 0.12))
	ci.draw_rect(Rect2(shield_x - SHIELD_WIDTH / 2.0, y - 14, SHIELD_WIDTH, 28), glow)
	ci.draw_rect(Rect2(shield_x - SHIELD_WIDTH / 2.0, y - 8, SHIELD_WIDTH, 16), Color(0.35, 0.55, 0.75))
	for k in 5:
		var gx := shield_x - SHIELD_WIDTH / 2.0 + 15.0 + k * (SHIELD_WIDTH - 30.0) / 4.0
		ci.draw_circle(Vector2(gx, y), 4.0, Color(0.85, 0.95, 1.0))


func _draw() -> void:
	var obsidian := Color(0.12, 0.08, 0.08)
	var charging := charge_timer > 0.0
	var eyes := BLAST if charging else FIRE
	var heave := sin(time * 1.5) * 3.0
	# Charging aura
	if charging:
		var t := 1.0 - charge_timer / CHARGE_TIME
		draw_circle(Vector2.ZERO, 50.0 + 30.0 * t, Color(BLAST, 0.15 + 0.25 * t))
	# Massive shoulders, arms and a molten crown
	for side in [-1.0, 1.0]:
		draw_colored_polygon(PackedVector2Array([Vector2(side * 20, -10 + heave), Vector2(side * 70, -30 + heave),
				Vector2(side * 78, 20), Vector2(side * 30, 30)]), obsidian.lightened(0.08))
		draw_line(Vector2(side * 30, -14 + heave), Vector2(side * 70, 10), Color(1, 0.4, 0.05, 0.8), 2.5)
	draw_circle(Vector2(0, 6), 40.0, obsidian)
	for k in 5:
		draw_line(Vector2(-28 + k * 14, -16), Vector2(-24 + k * 14, 34), Color(1, 0.45, 0.1, 0.75), 2.0)
	draw_circle(Vector2(0, -30 + heave), 22.0, obsidian.lightened(0.05))
	for k in 5:
		var x := -20.0 + k * 10.0
		draw_colored_polygon(PackedVector2Array([Vector2(x - 5, -44 + heave), Vector2(x, -62 - (6 if k == 2 else 0) + heave),
				Vector2(x + 5, -44 + heave)]), FIRE)
	draw_circle(Vector2(-8, -32 + heave), 4.0, eyes)
	draw_circle(Vector2(8, -32 + heave), 4.0, eyes)
	draw_rect(Rect2(Vector2(-10, -22 + heave), Vector2(20, 4)), Color(1, 0.5, 0.1))
	# The blast itself, for a moment after it fires.
	if beam_timer > 0.0:
		var end := (beam_to - position) / scale.x
		draw_line(Vector2.ZERO, end, Color(BLAST, 0.9), 14.0)
		draw_line(Vector2.ZERO, end, Color(1, 1, 1, 0.9), 5.0)
		draw_circle(end, 24.0, Color(0.6, 0.9, 1.0, 0.6) if beam_blocked else Color(FIRE, 0.8))
	draw_health_bar(48.0)
