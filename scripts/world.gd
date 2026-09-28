class_name World
extends Node2D
## An overworld: a square map with a safe hub in the middle, where the realm
## portals stand. Danger rises in seven rings moving outward, like Realm of
## the Mad God's beach-to-godlands. Which realm it is (Lumbridge, God Wars,
## Wilderness) decides the zone names, colours and scenery; see Realms.
## Ground colours are drawn here; grass, snow drifts, flowers and trees are
## drawn in chunks so only the ones on screen cost anything.

const SIZE := Vector2(7000, 7000)
const CENTER := SIZE / 2.0
const SAFE_RADIUS := 350.0
## Outer edge of each tier's ring; everything beyond the last is the top tier.
const ZONE_EDGES := [900.0, 1350.0, 1800.0, 2250.0, 2700.0, 3150.0]
const MAX_TIER := 6
const CHUNK := 1000.0

var realm := Realms.LUMBRIDGE
var chunks: Array[Node2D] = []


static func bounds() -> Rect2:
	return Rect2(Vector2(20, 20), SIZE - Vector2(40, 40))


## -1 inside the safe hub, otherwise 0 to MAX_TIER.
static func zone_tier(pos: Vector2) -> int:
	var d := pos.distance_to(CENTER)
	if d < SAFE_RADIUS:
		return -1
	for i in ZONE_EDGES.size():
		if d < ZONE_EDGES[i]:
			return i
	return MAX_TIER


static func zone_name(pos: Vector2, realm_index: int) -> String:
	var tier := zone_tier(pos)
	var data := Realms.info(realm_index)
	return data.hub if tier < 0 else data.zones[tier]


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
			chunk.draw.connect(_draw_chunk.bind(chunk, rect, cx * 1000 + cy))
			add_child(chunk)
			chunks.append(chunk)


func set_realm(realm_index: int) -> void:
	realm = realm_index
	queue_redraw()
	for chunk in chunks:
		chunk.queue_redraw()


func _colors() -> Array:
	return Realms.info(realm).colors


func _draw() -> void:
	var colors := _colors()
	# Zone rings, outermost first.
	draw_rect(Rect2(Vector2.ZERO, SIZE), colors[MAX_TIER])
	for tier in range(ZONE_EDGES.size() - 1, -1, -1):
		draw_circle(CENTER, ZONE_EDGES[tier], colors[tier])
	_draw_hub()


## Decorations for one chunk, seeded so they look the same every redraw.
func _draw_chunk(ci: Node2D, rect: Rect2, chunk_seed: int) -> void:
	var colors := _colors()
	var style: String = Realms.info(realm).style
	var rng := RandomNumberGenerator.new()
	rng.seed = chunk_seed + realm * 7919
	var point := func() -> Vector2:
		return rect.position + Vector2(rng.randf() * rect.size.x, rng.randf() * rect.size.y)

	# Patches blur the ring edges and break up the flat colour.
	for i in 30:
		var p: Vector2 = point.call()
		if zone_tier(p) < 0:
			continue
		var base: Color = colors[zone_tier(p)]
		var shade := base.lightened(0.07) if rng.randf() < 0.5 else base.darkened(0.08)
		ci.draw_set_transform(p, rng.randf() * TAU, Vector2(1.0, rng.randf_range(0.5, 0.9)))
		ci.draw_circle(Vector2.ZERO, rng.randf_range(40, 110), shade)
	ci.draw_set_transform(Vector2.ZERO)

	# Ground detail: grass tufts, snow drifts, or ash and embers.
	for i in 220:
		var p: Vector2 = point.call()
		var tier := zone_tier(p)
		if tier < 0:
			continue
		var base: Color = colors[tier]
		match style:
			"grass":
				if tier >= 5 and rng.randf() < 0.6:
					continue
				var color := base.darkened(rng.randf_range(0.15, 0.3)) if rng.randf() < 0.6 else base.lightened(0.2)
				for blade in [-1.0, 0.0, 1.0]:
					ci.draw_line(p, p + Vector2(blade * 2.5 + rng.randf_range(-1, 1), -rng.randf_range(4, 7)), color, 1.2)
			"snow":
				if rng.randf() < 0.5:
					ci.draw_arc(p, rng.randf_range(4, 9), PI, TAU, 6, base.lightened(0.35), 1.5)
				else:
					ci.draw_circle(p, 1.3, Color(1, 1, 1, 0.8))
			"ash":
				if tier >= 4 and rng.randf() < 0.15:
					# Glowing lava cracks deep in the Wilderness.
					var end := p + Vector2.from_angle(rng.randf() * TAU) * rng.randf_range(10, 22)
					ci.draw_line(p, end, Color(1, 0.4, 0.1, 0.8), 2.0)
				else:
					ci.draw_circle(p, rng.randf_range(1, 2.5), base.darkened(0.3))

	# Flowers only in Lumbridge's gentle fields.
	if style == "grass":
		var petals := [Color(1, 1, 1), Color(1, 0.85, 0.3), Color(1, 0.6, 0.75)]
		for i in 30:
			var p: Vector2 = point.call()
			if zone_tier(p) != 0 and zone_tier(p) != 1:
				continue
			var petal: Color = petals[rng.randi() % petals.size()]
			for k in 5:
				ci.draw_circle(p + Vector2.from_angle(TAU * k / 5.0) * 2.2, 1.6, petal)
			ci.draw_circle(p, 1.2, Color(0.95, 0.7, 0.2))

	# Trees: pines (snow-capped in God Wars), dead snags in the harsh zones.
	for i in 14:
		var p: Vector2 = point.call()
		var tier := zone_tier(p)
		if tier < 0 or (tier == 0 and rng.randf() < 0.7):
			continue
		if style == "ash" or (style == "grass" and tier >= 5) or (style == "snow" and tier >= 4):
			_draw_dead_tree(ci, p)
		else:
			var pine_color: Color = Color(0.2, 0.35, 0.3) if style == "snow" else colors[tier].darkened(0.35)
			_draw_pine(ci, p, rng.randf_range(0.8, 1.3), pine_color, style == "snow")


func _draw_pine(ci: Node2D, p: Vector2, s: float, color: Color, snowy: bool) -> void:
	ci.draw_set_transform(p + Vector2(0, 26 * s), 0.0, Vector2(1.0, 0.35))
	ci.draw_circle(Vector2.ZERO, 18 * s, Color(0, 0, 0, 0.25))
	ci.draw_set_transform(Vector2.ZERO)
	ci.draw_rect(Rect2(p + Vector2(-3, 14) * s, Vector2(6, 12) * s), Color(0.35, 0.22, 0.12))
	for layer in 3:
		var w := (20 - layer * 5) * s
		var top := p + Vector2(0, (-24 + layer * 2) * s) + Vector2(0, -layer * 8 * s)
		var y := (16 - layer * 12) * s
		ci.draw_colored_polygon(PackedVector2Array([p + Vector2(-w, y), top, p + Vector2(w, y)]), color.lightened(layer * 0.08))
		if snowy:
			ci.draw_colored_polygon(PackedVector2Array([top + (p + Vector2(-w, y) - top) * 0.4, top,
					top + (p + Vector2(w, y) - top) * 0.4]), Color(0.95, 0.97, 1.0))


func _draw_dead_tree(ci: Node2D, p: Vector2) -> void:
	var wood := Color(0.28, 0.23, 0.2)
	ci.draw_line(p + Vector2(0, 20), p + Vector2(0, -16), wood, 4.0)
	ci.draw_line(p + Vector2(0, -2), p + Vector2(-12, -14), wood, 2.5)
	ci.draw_line(p + Vector2(0, -8), p + Vector2(10, -20), wood, 2.5)
	ci.draw_line(p + Vector2(-12, -14), p + Vector2(-16, -13), wood, 1.5)


## The safe hub: a clearing ringed by standing stones, with a campfire.
func _draw_hub() -> void:
	var data := Realms.info(realm)
	draw_circle(CENTER, SAFE_RADIUS, data.hub_color)
	draw_arc(CENTER, SAFE_RADIUS, 0.0, TAU, 96, data.hub_color.darkened(0.3), 6.0)
	for i in 12:
		var p := CENTER + Vector2.from_angle(TAU * i / 12.0) * (SAFE_RADIUS - 20)
		draw_rect(Rect2(p - Vector2(7, 14), Vector2(14, 22)), Color(0.35, 0.35, 0.38))
		draw_rect(Rect2(p - Vector2(5, 12), Vector2(10, 18)), Color(0.6, 0.6, 0.63))
	for i in 8:
		var p := CENTER + Vector2.from_angle(TAU * i / 8.0) * 22
		draw_circle(p, 6, Color(0.5, 0.5, 0.52))
	draw_line(CENTER + Vector2(-14, 8), CENTER + Vector2(14, -8), Color(0.4, 0.25, 0.12), 5.0)
	draw_line(CENTER + Vector2(-14, -8), CENTER + Vector2(14, 8), Color(0.4, 0.25, 0.12), 5.0)
	draw_circle(CENTER, 11, Color(1, 0.5, 0.1))
	draw_circle(CENTER + Vector2(0, -3), 7, Color(1, 0.8, 0.25))
	draw_string(ThemeDB.fallback_font, CENTER + Vector2(-150, -SAFE_RADIUS + 50), data.hub,
			HORIZONTAL_ALIGNMENT_CENTER, 300, 22, Color(1, 1, 1, 0.7))
