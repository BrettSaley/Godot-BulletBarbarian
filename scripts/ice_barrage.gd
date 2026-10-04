class_name IceBarrage
extends Node2D
## The Mage's Ice Barrage, as in OSRS: a burst of frost that blooms out over
## the target area - a pale flash, a ring of jagged ice crystals bursting up,
## and drifting frost shards - then melts away. Purely visual; the damage and
## freeze are dealt by the player when it's cast.

const LIFETIME := 0.7
const ICE := Color(0.6, 0.88, 1.0)
const DEEP := Color(0.3, 0.55, 0.95)

var radius := 110.0
var time := 0.0
var spikes: Array[Vector3] = []  # x, y = direction, z = length


static func spawn(parent: Node, at: Vector2, area_radius: float) -> IceBarrage:
	var effect := IceBarrage.new()
	effect.position = at
	effect.radius = area_radius
	parent.add_child(effect)
	return effect


func _ready() -> void:
	z_index = 5
	for i in 14:
		var dir := Vector2.from_angle(TAU * i / 14.0 + randf_range(-0.15, 0.15))
		spikes.append(Vector3(dir.x, dir.y, randf_range(0.45, 0.9)))


func _process(delta: float) -> void:
	time += delta
	if time >= LIFETIME:
		queue_free()
		return
	queue_redraw()


func _draw() -> void:
	var t := time / LIFETIME
	var grow := clampf(t / 0.25, 0.0, 1.0)  # bursts out over the first quarter
	var fade := 1.0 - clampf((t - 0.5) / 0.5, 0.0, 1.0)  # melts over the second half
	# Frosted ground and a bright flash at the start
	draw_circle(Vector2.ZERO, radius * grow, Color(ICE, 0.25 * fade))
	draw_circle(Vector2.ZERO, radius * grow * 0.6, Color(1, 1, 1, 0.5 * (1.0 - clampf(t / 0.2, 0.0, 1.0))))
	draw_arc(Vector2.ZERO, radius * grow, 0.0, TAU, 40, Color(1, 1, 1, 0.8 * fade), 2.0)
	# Jagged ice crystals bursting up around the ring and in the middle
	for s in spikes:
		var dir := Vector2(s.x, s.y)
		var base := dir * radius * grow * 0.75
		var tip := base + Vector2(dir.x * 0.3, -1.0).normalized() * radius * 0.45 * s.z * grow
		var side := dir.orthogonal() * 7.0
		draw_colored_polygon(PackedVector2Array([base - side, tip, base + side]), Color(DEEP, 0.85 * fade))
		draw_colored_polygon(PackedVector2Array([base - side * 0.3, tip, base + side]), Color(ICE.lightened(0.4), 0.9 * fade))
	for k in 3:
		var tip := Vector2((k - 1) * 14.0, -radius * 0.55 * grow)
		draw_colored_polygon(PackedVector2Array([Vector2((k - 1) * 14.0 - 9, 0), tip, Vector2((k - 1) * 14.0 + 9, 0)]),
				Color(ICE.lightened(0.3), 0.9 * fade))
	# Frost shards drifting outward
	for i in 10:
		var dir := Vector2.from_angle(i * 0.63 + 0.3)
		var at := dir * radius * (0.3 + t * 0.9)
		draw_circle(at, 3.0 * fade + 0.5, Color(1, 1, 1, 0.8 * fade))
