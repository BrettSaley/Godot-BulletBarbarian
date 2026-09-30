class_name Projectiles
extends Node2D
## Every projectile of one side lives in these arrays instead of being its own
## node, so the screen can fill up without slowing the game down.
## Two instances exist: enemy rocks (hit the player) and the player's axes
## (hit anything in the "enemies" group).

signal player_hit(damage: float, source: String)
## Emitted by the player's shots when they damage an enemy.
signal enemy_hit(damage: float)

const ROCK_SHAPES := 4
const OUTLINE := Color(0.16, 0.13, 0.1)
const HANDLE := Color(0.5, 0.32, 0.15)

enum Style { ROCK, AXE, ARROW, MAUL, CLAW, ORB, BLADE }
## The player's weapons are drawn this much bigger than their base art.
const PLAYER_SHOT_SCALE := 1.35

@export var targets_player := true

var positions := PackedVector2Array()
var velocities := PackedVector2Array()
var radii := PackedFloat32Array()
var colors := PackedColorArray()
var damages := PackedFloat32Array()
var lifetimes := PackedFloat32Array()
var angles := PackedFloat32Array()
var spins := PackedFloat32Array()
var shapes := PackedInt32Array()
var styles := PackedInt32Array()
var sources: Array[String] = []

## Set by the main scene.
var player: Node2D
## Inside a raid or dungeon: the open floor. A shot that leaves it has hit a
## wall and is destroyed. Empty in the overworld, which has no walls.
var open_areas: Array[Rect2] = []

## Lumpy unit-radius outlines, picked at random for each rock.
var rock_shapes: Array[PackedVector2Array] = []


func _ready() -> void:
	for s in ROCK_SHAPES:
		var points := PackedVector2Array()
		var corners := randi_range(6, 8)
		for i in corners:
			var angle := TAU * i / corners + randf_range(-0.25, 0.25)
			points.append(Vector2.from_angle(angle) * randf_range(0.8, 1.15))
		rock_shapes.append(points)


func spawn(pos: Vector2, vel: Vector2, radius: float, color: Color, damage: float, lifetime: float, source := "", style := -1) -> void:
	positions.append(pos)
	velocities.append(vel)
	radii.append(radius)
	colors.append(color)
	damages.append(damage)
	lifetimes.append(lifetime)
	if style < 0:
		style = Style.ROCK if targets_player else Style.AXE
	# Arrows and orbs fly straight; everything else tumbles.
	var straight := style == Style.ARROW or style == Style.ORB
	angles.append(vel.angle() if straight else randf() * TAU)
	var spin := randf_range(-4.0, 4.0) if targets_player else 18.0
	spins.append(0.0 if straight else spin)
	shapes.append(randi() % ROCK_SHAPES)
	sources.append(source)
	styles.append(style)


func clear_all() -> void:
	for i in range(positions.size() - 1, -1, -1):
		_remove(i)
	queue_redraw()


func _physics_process(delta: float) -> void:
	var enemies := [] if targets_player else get_tree().get_nodes_in_group("enemies")
	var i := positions.size() - 1
	while i >= 0:
		positions[i] += velocities[i] * delta
		angles[i] += spins[i] * delta
		lifetimes[i] -= delta
		if lifetimes[i] <= 0.0 or _in_wall(positions[i]):
			_remove(i)
		elif targets_player:
			if player.is_alive() and positions[i].distance_to(player.position) < radii[i] + player.hitbox_radius:
				player_hit.emit(damages[i], sources[i])
				_remove(i)
		else:
			for enemy in enemies:
				if enemy.can_be_hit_by_player() and enemy.touches(positions[i], radii[i]):
					enemy.take_damage(damages[i])
					if not enemy.invulnerable or enemy.player_is_god():
						enemy_hit.emit(damages[i])
					_remove(i)
					break
		i -= 1
	queue_redraw()


func _in_wall(pos: Vector2) -> bool:
	if open_areas.is_empty():
		return false
	for rect in open_areas:
		if rect.has_point(pos):
			return false
	return true


func _remove(i: int) -> void:
	var last := positions.size() - 1
	positions[i] = positions[last]
	velocities[i] = velocities[last]
	radii[i] = radii[last]
	colors[i] = colors[last]
	damages[i] = damages[last]
	lifetimes[i] = lifetimes[last]
	angles[i] = angles[last]
	spins[i] = spins[last]
	shapes[i] = shapes[last]
	sources[i] = sources[last]
	styles[i] = styles[last]
	positions.resize(last)
	velocities.resize(last)
	radii.resize(last)
	colors.resize(last)
	damages.resize(last)
	lifetimes.resize(last)
	angles.resize(last)
	spins.resize(last)
	shapes.resize(last)
	sources.resize(last)
	styles.resize(last)


func _draw() -> void:
	for i in positions.size():
		match styles[i]:
			Style.ROCK:
				_draw_rock(i)
			Style.AXE:
				_draw_axe(i)
			Style.ARROW:
				_draw_arrow(i)
			Style.MAUL:
				_draw_maul(i)
			Style.CLAW:
				_draw_claw(i)
			Style.BLADE:
				_draw_blade(i)
			Style.ORB:
				_draw_orb(i)
	draw_set_transform(Vector2.ZERO)


func _draw_arrow(i: int) -> void:
	draw_set_transform(positions[i], angles[i], Vector2.ONE * PLAYER_SHOT_SCALE)
	draw_line(Vector2(-14, 0), Vector2(8, 0), Color(0.35, 0.5, 0.3), 2.0)
	draw_colored_polygon(PackedVector2Array([Vector2(8, -4), Vector2(15, 0), Vector2(8, 4)]), colors[i])
	draw_line(Vector2(-14, 0), Vector2(-18, -4), Color(0.9, 0.9, 0.9), 1.5)
	draw_line(Vector2(-14, 0), Vector2(-18, 4), Color(0.9, 0.9, 0.9), 1.5)


func _draw_maul(i: int) -> void:
	draw_set_transform(positions[i], angles[i], Vector2.ONE * PLAYER_SHOT_SCALE)
	draw_line(Vector2(-14, 0), Vector2(6, 0), HANDLE, 3.5)
	draw_rect(Rect2(Vector2(4, -9), Vector2(12, 18)), OUTLINE)
	draw_rect(Rect2(Vector2(5, -8), Vector2(10, 16)), colors[i])


func _draw_claw(i: int) -> void:
	draw_set_transform(positions[i], angles[i], Vector2.ONE * PLAYER_SHOT_SCALE)
	for k in 3:
		var y := (k - 1) * 5.0
		draw_colored_polygon(PackedVector2Array([Vector2(-6, y - 1.5), Vector2(8, y - 3), Vector2(-6, y + 1.5)]), colors[i])


func _draw_orb(i: int) -> void:
	draw_set_transform(positions[i])
	var r := radii[i]
	draw_circle(Vector2.ZERO, r * 1.6, Color(colors[i], 0.3))
	draw_circle(Vector2.ZERO, r, colors[i])
	draw_circle(Vector2(-r * 0.3, -r * 0.3), r * 0.4, colors[i].lightened(0.6))


func _draw_rock(i: int) -> void:
	var r := radii[i] * 1.15
	var shape := rock_shapes[shapes[i]]
	var color := colors[i]
	draw_set_transform(positions[i], angles[i], Vector2(r + 1.5, r + 1.5))
	draw_colored_polygon(shape, OUTLINE)
	draw_set_transform(positions[i], angles[i], Vector2(r, r))
	draw_colored_polygon(shape, color)
	# Lighting stays fixed (top-left) while the rock spins.
	draw_set_transform(positions[i], 0.0, Vector2(r, r))
	draw_circle(Vector2(-0.3, -0.3), 0.35, color.lightened(0.35))
	draw_circle(Vector2(0.35, 0.4), 0.2, color.darkened(0.3))


## A spinning throwing axe; the blade takes the weapon's tier colour.
func _draw_axe(i: int) -> void:
	# Heavy axes (bigger hit area) are drawn bigger too.
	draw_set_transform(positions[i], angles[i], Vector2.ONE * PLAYER_SHOT_SCALE * maxf(radii[i] / 12.0, 1.0))
	draw_line(Vector2(-9, 0), Vector2(7, 0), HANDLE, 2.5)
	draw_colored_polygon(PackedVector2Array([Vector2(3, -2), Vector2(9, -8), Vector2(12, 0), Vector2(9, 8), Vector2(3, 2)]), OUTLINE)
	draw_colored_polygon(PackedVector2Array([Vector2(4, -1.5), Vector2(9, -6.5), Vector2(11, 0), Vector2(9, 6.5), Vector2(4, 1.5)]), colors[i])


## A spinning godsword: long blade, crossguard and a gem in the hilt.
func _draw_blade(i: int) -> void:
	draw_set_transform(positions[i], angles[i], Vector2.ONE * PLAYER_SHOT_SCALE * maxf(radii[i] / 12.0, 1.0))
	draw_colored_polygon(PackedVector2Array([Vector2(-4, -2.5), Vector2(16, -2.5), Vector2(21, 0), Vector2(16, 2.5), Vector2(-4, 2.5)]), OUTLINE)
	draw_colored_polygon(PackedVector2Array([Vector2(-3, -1.5), Vector2(16, -1.5), Vector2(19.5, 0), Vector2(16, 1.5), Vector2(-3, 1.5)]), Color(0.85, 0.87, 0.92))
	draw_line(Vector2(-4, -7), Vector2(-4, 7), colors[i], 3.0)
	draw_line(Vector2(-12, 0), Vector2(-4, 0), HANDLE, 3.0)
	draw_circle(Vector2(-4, 0), 2.2, colors[i].lightened(0.3))
