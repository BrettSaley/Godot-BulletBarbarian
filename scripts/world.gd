class_name World
extends Node2D
## The open world: a square map with a safe campfire clearing in Lumbridge.
## Danger rises in seven rings moving outward, like Realm of the Mad God's
## beach-to-godlands, themed on OSRS regions from Lumbridge out to the Deep
## Wilderness. The zone colours are drawn here; grass, flowers and trees are
## drawn in chunks so only the ones on screen cost anything.

const SIZE := Vector2(7000, 7000)
const CENTER := SIZE / 2.0
const SAFE_RADIUS := 350.0
## Outer edge of each tier's ring; everything beyond the last is the top tier.
const ZONE_EDGES := [900.0, 1350.0, 1800.0, 2250.0, 2700.0, 3150.0]
const MAX_TIER := 6
const ZONE_NAMES := ["Lumbridge Fields", "Draynor Woods", "Barbarian Village", "Giants' Plateau",
		"Troll Country", "Low Wilderness", "Deep Wilderness"]
const ZONE_COLORS := [
	Color(0.38, 0.6, 0.28),
	Color(0.3, 0.52, 0.25),
	Color(0.35, 0.5, 0.26),
	Color(0.32, 0.43, 0.23),
	Color(0.4, 0.42, 0.34),
	Color(0.4, 0.37, 0.33),
	Color(0.33, 0.29, 0.27),
]
const CHUNK := 1000.0


static func bounds() -> Rect2:
	return Rect2(Vector2(20, 20), SIZE - Vector2(40, 40))


## -1 inside the safe clearing, otherwise 0 to MAX_TIER.
static func zone_tier(pos: Vector2) -> int:
	var d := pos.distance_to(CENTER)
	if d < SAFE_RADIUS:
		return -1
	for i in ZONE_EDGES.size():
		if d < ZONE_EDGES[i]:
			return i
	return MAX_TIER


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


func _ready() -> void:
	var cells := Vector2i(ceili(SIZE.x / CHUNK), ceili(SIZE.y / CHUNK))
	for cx in cells.x:
		for cy in cells.y:
			var chunk := Node2D.new()
			var rect := Rect2(Vector2(cx, cy) * CHUNK, Vector2(CHUNK, CHUNK))
			var chunk_seed := cx * 1000 + cy
			chunk.draw.connect(_draw_chunk.bind(chunk, rect, chunk_seed))
			add_child(chunk)


func _draw() -> void:
	# Zone rings, outermost first.
	draw_rect(Rect2(Vector2.ZERO, SIZE), ZONE_COLORS[MAX_TIER])
	for tier in range(ZONE_EDGES.size() - 1, -1, -1):
		draw_circle(CENTER, ZONE_EDGES[tier], ZONE_COLORS[tier])
	_draw_campfire_clearing()


## Decorations for one chunk, seeded so they look the same every redraw.
func _draw_chunk(ci: Node2D, rect: Rect2, chunk_seed: int) -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = chunk_seed
	var point := func() -> Vector2:
		return rect.position + Vector2(rng.randf() * rect.size.x, rng.randf() * rect.size.y)

	# Patches blur the ring edges and break up the flat colour.
	for i in 30:
		var p: Vector2 = point.call()
		if zone_tier(p) < 0:
			continue
		var base: Color = ZONE_COLORS[zone_tier(p)]
		var shade := base.lightened(0.07) if rng.randf() < 0.5 else base.darkened(0.08)
		ci.draw_set_transform(p, rng.randf() * TAU, Vector2(1.0, rng.randf_range(0.5, 0.9)))
		ci.draw_circle(Vector2.ZERO, rng.randf_range(40, 110), shade)
	ci.draw_set_transform(Vector2.ZERO)

	# Grass tufts, sparser and browner toward the Wilderness.
	for i in 220:
		var p: Vector2 = point.call()
		var tier := zone_tier(p)
		if tier < 0 or (tier >= 5 and rng.randf() < 0.6):
			continue
		var base: Color = ZONE_COLORS[tier]
		var color := base.darkened(rng.randf_range(0.15, 0.3)) if rng.randf() < 0.6 else base.lightened(0.2)
		for blade in [-1.0, 0.0, 1.0]:
			ci.draw_line(p, p + Vector2(blade * 2.5 + rng.randf_range(-1, 1), -rng.randf_range(4, 7)), color, 1.2)

	# Flowers only in the gentle fields around Lumbridge.
	var petals := [Color(1, 1, 1), Color(1, 0.85, 0.3), Color(1, 0.6, 0.75)]
	for i in 30:
		var p: Vector2 = point.call()
		if zone_tier(p) != 0 and zone_tier(p) != 1:
			continue
		var petal: Color = petals[rng.randi() % petals.size()]
		for k in 5:
			ci.draw_circle(p + Vector2.from_angle(TAU * k / 5.0) * 2.2, 1.6, petal)
		ci.draw_circle(p, 1.2, Color(0.95, 0.7, 0.2))

	# Trees: pines through the middle zones, dead snags in the Wilderness.
	for i in 14:
		var p: Vector2 = point.call()
		var tier := zone_tier(p)
		if tier < 0 or (tier == 0 and rng.randf() < 0.7):
			continue
		if tier >= 5:
			_draw_dead_tree(ci, p)
		else:
			_draw_pine(ci, p, rng.randf_range(0.8, 1.3), ZONE_COLORS[tier].darkened(0.35))


func _draw_pine(ci: Node2D, p: Vector2, s: float, color: Color) -> void:
	ci.draw_set_transform(p + Vector2(0, 26 * s), 0.0, Vector2(1.0, 0.35))
	ci.draw_circle(Vector2.ZERO, 18 * s, Color(0, 0, 0, 0.25))
	ci.draw_set_transform(Vector2.ZERO)
	ci.draw_rect(Rect2(p + Vector2(-3, 14) * s, Vector2(6, 12) * s), Color(0.35, 0.22, 0.12))
	for layer in 3:
		var w := (20 - layer * 5) * s
		var top := p + Vector2(0, (-24 + layer * 2) * s)
		var y := (16 - layer * 12) * s
		ci.draw_colored_polygon(PackedVector2Array([p + Vector2(-w, y), top + Vector2(0, -layer * 8 * s), p + Vector2(w, y)]),
				color.lightened(layer * 0.08))


func _draw_dead_tree(ci: Node2D, p: Vector2) -> void:
	var wood := Color(0.28, 0.23, 0.2)
	ci.draw_line(p + Vector2(0, 20), p + Vector2(0, -16), wood, 4.0)
	ci.draw_line(p + Vector2(0, -2), p + Vector2(-12, -14), wood, 2.5)
	ci.draw_line(p + Vector2(0, -8), p + Vector2(10, -20), wood, 2.5)
	ci.draw_line(p + Vector2(-12, -14), p + Vector2(-16, -13), wood, 1.5)


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
