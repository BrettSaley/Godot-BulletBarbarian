class_name World
extends Node2D
## The open world: a square map with a safe campfire clearing in Lumbridge.
## Danger rises in rings moving outward, like Realm of the Mad God's
## beach-to-godlands, themed on OSRS: Lumbridge fields (tier 0), Draynor Woods (1),
## Giants' Plateau (2), and the Wilderness (3) at the edges. Drawn once.

const SIZE := Vector2(4000, 4000)
const CENTER := SIZE / 2.0
const SAFE_RADIUS := 350.0
## Outer edge of each tier's ring; everything beyond the last is tier 3.
const ZONE_EDGES := [900.0, 1350.0, 1750.0]
const ZONE_NAMES := ["Lumbridge Fields", "Draynor Woods", "Giants' Plateau", "The Wilderness"]
const ZONE_COLORS := [
	Color(0.38, 0.6, 0.28),
	Color(0.27, 0.48, 0.24),
	Color(0.3, 0.4, 0.22),
	Color(0.4, 0.37, 0.33),
]


static func bounds() -> Rect2:
	return Rect2(Vector2(20, 20), SIZE - Vector2(40, 40))


## -1 inside the safe clearing, otherwise 0-3.
static func zone_tier(pos: Vector2) -> int:
	var d := pos.distance_to(CENTER)
	if d < SAFE_RADIUS:
		return -1
	for i in ZONE_EDGES.size():
		if d < ZONE_EDGES[i]:
			return i
	return 3


static func zone_name(pos: Vector2) -> String:
	var tier := zone_tier(pos)
	return "Lumbridge" if tier < 0 else ZONE_NAMES[tier]


## Random point inside the ring for `tier` (and inside the map).
static func random_point_in_zone(tier: int) -> Vector2:
	var inner: float = SAFE_RADIUS + 50.0 if tier == 0 else ZONE_EDGES[tier - 1]
	var outer: float = ZONE_EDGES[tier] if tier < ZONE_EDGES.size() else SIZE.x * 0.7
	for attempt in 20:
		var p := CENTER + Vector2.from_angle(randf() * TAU) * randf_range(inner, outer)
		if bounds().grow(-60).has_point(p):
			return p
	return CENTER + Vector2(inner, 0)


func _draw() -> void:
	# Zone rings, outermost first.
	draw_rect(Rect2(Vector2.ZERO, SIZE), ZONE_COLORS[3])
	for tier in [2, 1, 0]:
		draw_circle(CENTER, ZONE_EDGES[tier], ZONE_COLORS[tier])

	# Patches blur the ring edges and break up the flat colour.
	for i in 500:
		var p := _random_point()
		var base: Color = ZONE_COLORS[maxi(zone_tier(p), 0)]
		var shade := base.lightened(0.07) if randf() < 0.5 else base.darkened(0.08)
		_draw_blob(p, randf_range(40, 110), shade)

	# Grass tufts, sparser and browner in the badlands.
	for i in 3500:
		var p := _random_point()
		var tier := maxi(zone_tier(p), 0)
		if tier == 3 and randf() < 0.6:
			continue
		var base: Color = ZONE_COLORS[tier]
		var color := base.darkened(randf_range(0.15, 0.3)) if randf() < 0.6 else base.lightened(0.2)
		for blade in [-1.0, 0.0, 1.0]:
			draw_line(p, p + Vector2(blade * 2.5 + randf_range(-1, 1), -randf_range(4, 7)), color, 1.2)

	# Flowers only in the gentle meadow.
	var petals := [Color(1, 1, 1), Color(1, 0.85, 0.3), Color(1, 0.6, 0.75)]
	for i in 500:
		var p := _random_point()
		if zone_tier(p) > 0:
			continue
		var petal: Color = petals[randi() % petals.size()]
		for k in 5:
			draw_circle(p + Vector2.from_angle(TAU * k / 5.0) * 2.2, 1.6, petal)
		draw_circle(p, 1.2, Color(0.95, 0.7, 0.2))

	# Trees: pines in the forests, dead snags in the badlands.
	for i in 260:
		var p := _random_point()
		var tier := zone_tier(p)
		if tier < 0 or (tier == 0 and randf() < 0.7):
			continue
		if tier == 3:
			_draw_dead_tree(p)
		else:
			_draw_pine(p, randf_range(0.8, 1.3), ZONE_COLORS[tier].darkened(0.35))

	_draw_campfire_clearing()


func _draw_pine(p: Vector2, s: float, color: Color) -> void:
	draw_set_transform(p + Vector2(0, 26 * s), 0.0, Vector2(1.0, 0.35))
	draw_circle(Vector2.ZERO, 18 * s, Color(0, 0, 0, 0.25))
	draw_set_transform(Vector2.ZERO)
	draw_rect(Rect2(p + Vector2(-3, 14) * s, Vector2(6, 12) * s), Color(0.35, 0.22, 0.12))
	for layer in 3:
		var w := (20 - layer * 5) * s
		var top := p + Vector2(0, (-24 + layer * 2) * s)
		var y := (16 - layer * 12) * s
		draw_colored_polygon(PackedVector2Array([p + Vector2(-w, y), top + Vector2(0, -layer * 8 * s), p + Vector2(w, y)]),
				color.lightened(layer * 0.08))


func _draw_dead_tree(p: Vector2) -> void:
	var wood := Color(0.28, 0.23, 0.2)
	draw_line(p + Vector2(0, 20), p + Vector2(0, -16), wood, 4.0)
	draw_line(p + Vector2(0, -2), p + Vector2(-12, -14), wood, 2.5)
	draw_line(p + Vector2(0, -8), p + Vector2(10, -20), wood, 2.5)
	draw_line(p + Vector2(-12, -14), p + Vector2(-16, -13), wood, 1.5)


func _draw_campfire_clearing() -> void:
	draw_circle(CENTER, SAFE_RADIUS, Color(0.45, 0.62, 0.32))
	draw_arc(CENTER, SAFE_RADIUS, 0.0, TAU, 96, Color(0.55, 0.5, 0.4), 6.0)
	# Standing stones around the edge
	for i in 12:
		var p := CENTER + Vector2.from_angle(TAU * i / 12.0) * (SAFE_RADIUS - 20)
		draw_rect(Rect2(p - Vector2(7, 14), Vector2(14, 22)), Color(0.35, 0.35, 0.38))
		draw_rect(Rect2(p - Vector2(5, 12), Vector2(10, 18)), Color(0.6, 0.6, 0.63))
	# Campfire
	for i in 8:
		var p := CENTER + Vector2.from_angle(TAU * i / 8.0) * 22
		draw_circle(p, 6, Color(0.5, 0.5, 0.52))
	draw_line(CENTER + Vector2(-14, 8), CENTER + Vector2(14, -8), Color(0.4, 0.25, 0.12), 5.0)
	draw_line(CENTER + Vector2(-14, -8), CENTER + Vector2(14, 8), Color(0.4, 0.25, 0.12), 5.0)
	draw_circle(CENTER, 11, Color(1, 0.5, 0.1))
	draw_circle(CENTER + Vector2(0, -3), 7, Color(1, 0.8, 0.25))


func _draw_blob(center: Vector2, radius: float, color: Color) -> void:
	draw_set_transform(center, randf() * TAU, Vector2(1.0, randf_range(0.5, 0.9)))
	draw_circle(Vector2.ZERO, radius, color)
	draw_set_transform(Vector2.ZERO)


func _random_point() -> Vector2:
	return Vector2(randf() * SIZE.x, randf() * SIZE.y)
