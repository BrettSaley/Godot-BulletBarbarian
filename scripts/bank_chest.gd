class_name BankChest
extends Node2D
## The bank chest by the hub campfire. Standing next to it opens the bank
## panel (see Bank and the main scene).

const RADIUS := 48.0

var time := 0.0
var open := false


func _process(delta: float) -> void:
	time += delta
	queue_redraw()


func _draw() -> void:
	var wood := Color(0.42, 0.27, 0.14)
	var trim := Color(0.95, 0.78, 0.3)
	draw_set_transform(Vector2(0, 16), 0.0, Vector2(1.0, 0.3))
	draw_circle(Vector2.ZERO, 30.0, Color(0, 0, 0, 0.3))
	draw_set_transform(Vector2.ZERO)
	# Iron-bound chest; the lid swings up while you're at it
	draw_rect(Rect2(-26, -6, 52, 22), wood)
	draw_rect(Rect2(-26, -6, 52, 22), trim, false, 2.0)
	for x in [-18.0, 18.0]:
		draw_line(Vector2(x, -6), Vector2(x, 16), trim.darkened(0.3), 3.0)
	if open:
		draw_colored_polygon(PackedVector2Array([Vector2(-26, -6), Vector2(26, -6), Vector2(22, -24), Vector2(-22, -24)]), wood.darkened(0.2))
		draw_circle(Vector2(0, -8), 6.0 + sin(time * 4.0), Color(1, 0.85, 0.35, 0.6))
	else:
		draw_colored_polygon(PackedVector2Array([Vector2(-27, -6), Vector2(27, -6), Vector2(24, -16), Vector2(-24, -16)]), wood.lightened(0.1))
		draw_rect(Rect2(-4, -9, 8, 8), trim)
	draw_string(ThemeDB.fallback_font, Vector2(-40, -32), "Bank", HORIZONTAL_ALIGNMENT_CENTER, 80, 15, Color(1, 0.9, 0.6))
