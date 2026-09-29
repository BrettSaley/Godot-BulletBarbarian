class_name LootBag
extends Node2D
## A sack of items on the ground, coloured like RotMG bags by the best item
## inside: brown, pink, purple, then big sparkling white (dungeon UT) or gold
## (raid GIGA) bags.
## Walk onto it to see its contents in the HUD. Vanishes after a while.

const CAPACITY := 8
const LIFETIME := 90.0
const PICKUP_RADIUS := 26.0

var items: Array = []
var time_left := LIFETIME


func _ready() -> void:
	add_to_group("loot_bags")


func take(index: int) -> Dictionary:
	var item: Dictionary = items[index]
	items.remove_at(index)
	queue_redraw()
	if items.is_empty():
		queue_free()
	return item


func _process(delta: float) -> void:
	time_left -= delta
	if time_left <= 0.0:
		queue_free()
	if _is_special():
		queue_redraw()  # pulsing glow
	if time_left < 10.0:
		visible = int(time_left * 4.0) % 2 == 0


func _draw() -> void:
	var sack := Items.bag_color(items)
	var unique := _best_tier() >= Items.UT
	var t := Time.get_ticks_msec() / 1000.0
	if unique:
		# RotMG-style unique bag: bigger, bright, glowing and sparkling.
		draw_rect(Rect2(Vector2(-6, -60), Vector2(12, 60)), Color(sack, 0.18 + 0.08 * sin(t * 4.0)))
		draw_circle(Vector2(0, 2), 22.0 + 2.0 * sin(t * 5.0), Color(sack, 0.25))
		draw_circle(Vector2(0, 2), 16.0, Color(sack, 0.35))
	draw_set_transform(Vector2(0, 9 * (1.4 if unique else 1.0)), 0.0, Vector2(1.0, 0.35) * (1.4 if unique else 1.0))
	draw_circle(Vector2.ZERO, 10.0, Color(0, 0, 0, 0.3))
	draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE * (1.4 if unique else 1.0))
	var outline := Color(0.15, 0.1, 0.05) if not unique else sack.darkened(0.5)
	draw_circle(Vector2(0, 2), 9.5, outline)
	draw_circle(Vector2(0, 2), 8.0, sack)
	draw_colored_polygon(PackedVector2Array([Vector2(-4, -5), Vector2(4, -5), Vector2(6, -11), Vector2(-6, -11)]), sack.darkened(0.15))
	draw_line(Vector2(-4, -5), Vector2(4, -5), Color(0.9, 0.8, 0.5), 2.0)
	if unique:
		# Shine on the sack and twinkling stars around it.
		draw_circle(Vector2(-3, -1), 2.5, Color(1, 1, 1, 0.9))
		for k in 4:
			var angle := t * 1.5 + k * TAU / 4.0
			var p := Vector2.from_angle(angle) * 15.0
			var s := 2.0 + 1.5 * absf(sin(t * 6.0 + k))
			draw_line(p - Vector2(s, 0), p + Vector2(s, 0), Color(1, 1, 1, 0.9), 1.2)
			draw_line(p - Vector2(0, s), p + Vector2(0, s), Color(1, 1, 1, 0.9), 1.2)
	elif _is_special():
		draw_circle(Vector2(0, 2), 12.0 + sin(t * 5.0), Color(sack, 0.3))
	draw_set_transform(Vector2.ZERO)


func _best_tier() -> int:
	var best := 0
	for item in items:
		best = maxi(best, item.tier)
	return best


## Purple and better bags glow so good loot stands out.
func _is_special() -> bool:
	return _best_tier() >= 8
