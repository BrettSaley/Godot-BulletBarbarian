class_name LootBag
extends Node2D
## A sack of items on the ground, coloured like RotMG bags by the best item
## inside: brown, pink, purple, or glowing white for untiered uniques.
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
	draw_set_transform(Vector2(0, 9), 0.0, Vector2(1.0, 0.35))
	draw_circle(Vector2.ZERO, 10.0, Color(0, 0, 0, 0.3))
	draw_set_transform(Vector2.ZERO)
	draw_circle(Vector2(0, 2), 9.5, Color(0.15, 0.1, 0.05))
	draw_circle(Vector2(0, 2), 8.0, sack)
	draw_colored_polygon(PackedVector2Array([Vector2(-4, -5), Vector2(4, -5), Vector2(6, -11), Vector2(-6, -11)]), sack.darkened(0.15))
	draw_line(Vector2(-4, -5), Vector2(4, -5), Color(0.9, 0.8, 0.5), 2.0)
	if _is_special():
		draw_circle(Vector2(0, 2), 12.0 + sin(Time.get_ticks_msec() / 200.0), Color(sack, 0.3))


## Purple and white bags pulse so good loot stands out.
func _is_special() -> bool:
	for item in items:
		if item.tier >= 8:
			return true
	return false
