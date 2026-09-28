class_name Enemy
extends Node2D
## Base for every enemy and boss. Idles around its home spot until the player
## comes close, then cycles attacks (attack for a few seconds, rest, pick
## another). Subclasses set their stats in _init() and override:
##   _attacks()      which attack names it can use
##   _fire(name)     fire one volley, return seconds until the next
##   _move(delta)    how it moves (default: circle the player at a distance)
##   _draw()         how it looks
## `tier` (0-6, from the zone it spawned in) scales health, damage and speed.
## Monsters are leashed: they give up the chase once you get a little past
## their aggro range or drag them too far from home, then walk back.

signal died(enemy: Enemy)

const ATTACK_DURATION := 3.0
## Enemies farther than this from the player don't think at all.
const SLEEP_DISTANCE := 1100.0
## Per-realm power (Lumbridge, God Wars, Wilderness): later realms hit harder
## and have far more health, to match their higher-tier gear.
const REALM_HP := [1.0, 2.2, 4.5]
const REALM_DAMAGE := [1.0, 1.6, 2.2]
const REALM_XP := [1.0, 2.0, 3.0]
## After giving up a chase, a monster ignores the player this long.
const CALM_TIME := 2.0

var display_name := "Enemy"
var radius := 14.0
var move_speed := 80.0
var max_hp := 100.0
var hp := 100.0
var xp := 10
var bullet_damage := 15.0
var contact_damage := 20.0
var aggro_range := 480.0
var preferred_range := 220.0
var wander_radius := 200.0
## How far from home a monster will chase before giving up.
var leash_range := 500.0
var is_boss := false
## Drawn and hit-tested this much bigger than the art is authored, so
## monsters are easy to see and hit. Bosses are already large.
var size_scale := 1.4
## Raid bosses give XP but no loot bags; the raid chest pays out instead.
var drops_loot := true
## Burrowed, dived or shielded: projectiles pass through and touching is safe.
var untargetable := false
## Shielded: shots still hit (and are used up) but deal no damage.
var invulnerable := false
## Projectiles.Style used by shoot() (rocks by default).
var projectile_style := 0

var tier := 0
## 0 Lumbridge, 1 God Wars, 2 Wilderness.
var realm := 0
## 0-1 blend used by attack patterns to get denser and faster.
var difficulty := 0.0

## Set by setup().
var shots: Node2D
var player: Node2D
var home: Vector2

var target: Vector2
var aggro := false
var calm_timer := 0.0
var attack := ""
var attack_timer := 0.0
var rest_timer := 1.0
var fire_timer := 0.0
var contact_timer := 0.0
var flash_timer := 0.0
var time := 0.0
var orbit_dir := 1.0


func setup(zone_tier: int, shot_layer: Node2D, target_player: Node2D, realm_index := 0) -> void:
	tier = zone_tier
	realm = realm_index
	shots = shot_layer
	player = target_player
	difficulty = clampf(tier / 6.0, 0.0, 1.0)
	max_hp *= (1.0 + 0.6 * tier) * REALM_HP[realm]
	hp = max_hp
	xp = roundi(xp * (1.0 + 0.6 * tier) * REALM_XP[realm])
	bullet_damage *= (1.0 + 0.25 * tier) * REALM_DAMAGE[realm]
	contact_damage *= (1.0 + 0.25 * tier) * REALM_DAMAGE[realm]
	move_speed *= 1.0 + 0.05 * tier
	if is_boss:
		leash_range = maxf(leash_range, 900.0)
		size_scale = minf(size_scale, 1.15)
	scale = Vector2.ONE * size_scale
	radius *= size_scale
	home = position
	target = pick_wander_target()
	orbit_dir = 1.0 if randf() < 0.5 else -1.0
	time = randf() * 10.0
	add_to_group("enemies")
	_on_setup()


func is_active() -> bool:
	return hp > 0.0 and not untargetable


func is_attacking() -> bool:
	return rest_timer <= 0.0 and attack_timer > 0.0


func touches(point: Vector2, other_radius: float) -> bool:
	return position.distance_to(point) < radius + other_radius


func take_damage(amount: float) -> void:
	if not is_active():
		return
	if invulnerable:
		DamageText.spawn(get_parent(), position + Vector2(0, -radius - 8), "IMMUNE", Color(0.6, 0.85, 1.0))
		return
	hp -= amount
	flash_timer = 0.08
	aggro = true
	DamageText.spawn(get_parent(), position + Vector2(0, -radius - 8), str(roundi(amount)), Color(1, 0.95, 0.6))
	if hp <= 0.0:
		died.emit(self)
		queue_free()


func _physics_process(delta: float) -> void:
	var to_player := position.distance_to(player.position)
	if to_player > SLEEP_DISTANCE or not player.is_alive():
		return
	time += delta
	flash_timer -= delta
	modulate = Color(1, 0.55, 0.55) if flash_timer > 0.0 else Color(1, 1, 1)
	contact_timer -= delta
	queue_redraw()

	calm_timer -= delta
	if not aggro and calm_timer <= 0.0 and to_player < aggro_range:
		aggro = true
		target = pick_wander_target()
	elif aggro and (to_player > aggro_range * 1.25 or position.distance_to(home) > leash_range):
		aggro = false
		attack = ""
		calm_timer = CALM_TIME
		target = home
	_move(delta)

	if contact_damage > 0.0 and contact_timer <= 0.0 and not untargetable and touches(player.position, player.hitbox_radius):
		player.take_damage(contact_damage, display_name)
		contact_timer = 0.5

	if not aggro:
		return
	if rest_timer > 0.0:
		rest_timer -= delta
		if rest_timer <= 0.0:
			var options := _attacks()
			attack = options[randi() % options.size()]
			attack_timer = ATTACK_DURATION
			fire_timer = 0.0
			_on_attack_started(attack)
		return

	attack_timer -= delta
	if attack_timer <= 0.0:
		rest_timer = lerpf(1.2, 0.5, difficulty)
		attack = ""
		return

	fire_timer -= delta
	if fire_timer <= 0.0:
		fire_timer = _fire(attack)


# --- Overridable hooks ---

func _on_setup() -> void:
	pass


func _attacks() -> Array:
	return ["aimed"]


func _on_attack_started(_attack_name: String) -> void:
	pass


func _fire(_attack_name: String) -> float:
	return 1.0


## Default movement: idle around home; once aggro, circle the player at
## `preferred_range`.
func _move(delta: float) -> void:
	if aggro:
		var away := (position - player.position).normalized()
		if away == Vector2.ZERO:
			away = Vector2.RIGHT
		var desired := player.position + away.rotated(0.35 * orbit_dir) * preferred_range
		position = position.move_toward(desired, move_speed * delta)
	else:
		# Hurry home after giving up a chase, otherwise amble about.
		var pace := 1.0 if calm_timer > 0.0 else 0.4
		position = position.move_toward(target, move_speed * pace * delta)
		if position.distance_to(target) < 4.0:
			target = pick_wander_target()


# --- Helpers ---

## Idle: somewhere near home. Aggro: somewhere around the player, not on top of them.
func pick_wander_target() -> Vector2:
	if aggro:
		return player.position + Vector2.from_angle(randf() * TAU) * randf_range(160, 320)
	return home + Vector2.from_angle(randf() * TAU) * randf() * wander_radius


func shoot(from: Vector2, velocity: Vector2, size: float, color: Color, damage_mult := 1.0) -> void:
	shots.spawn(from, velocity, size, color, bullet_damage * damage_mult, 4.0, display_name, projectile_style)


func ring(from: Vector2, count: int, speed: float, size: float, color: Color) -> void:
	var offset := randf() * TAU
	for i in count:
		shoot(from, Vector2.from_angle(offset + TAU * i / count) * speed, size, color)


## A spread of `2 * side + 1` projectiles centred on `dir`.
func fan(from: Vector2, dir: Vector2, side: int, spread: float, speed: float, size: float, color: Color) -> void:
	for i in range(-side, side + 1):
		shoot(from, dir.rotated(i * spread) * speed, size, color)


func dir_to_player(from: Vector2) -> Vector2:
	return (player.position - from).normalized()


## Health bar under the enemy, shown once it has taken damage.
func draw_health_bar(offset_y: float) -> void:
	if hp >= max_hp:
		return
	var width := radius / size_scale * 2.0 + 8.0
	var top_left := Vector2(-width / 2.0, offset_y)
	draw_rect(Rect2(top_left - Vector2(1, 1), Vector2(width + 2, 6)), Color(0, 0, 0, 0.7))
	draw_rect(Rect2(top_left, Vector2(width * hp / max_hp, 4)), Color(0.9, 0.2, 0.2))


## Ground hazard layer (telegraphed blasts, acid pools, fire walls).
func hazards() -> Node2D:
	return get_tree().get_first_node_in_group("hazards")


## Summon an add (same tier and realm) next to this enemy. Adds summoned in a
## raid are cleaned up with the room.
func summon(add: Enemy, pos: Vector2) -> Enemy:
	add.position = pos
	add.setup(tier, shots, player, realm)
	if is_in_group("raid_enemies"):
		add.add_to_group("raid_enemies")
		add.leash_range = INF
	get_parent().add_child(add)
	return add
