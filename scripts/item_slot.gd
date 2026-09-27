class_name ItemSlot
extends Control
## One square in the equipment, inventory or loot bag panels.

signal clicked(slot: ItemSlot, button: int)

const SIZE := Vector2(40, 40)

## "equip", "inventory" or "bag", plus which slot within that group.
var group: String
var key  # equipment slot name (String) or index (int)
var placeholder := ""
var item = null


func _init(slot_group: String, slot_key, empty_label := "") -> void:
	group = slot_group
	key = slot_key
	placeholder = empty_label
	custom_minimum_size = SIZE
	mouse_filter = Control.MOUSE_FILTER_STOP


func set_item(new_item) -> void:
	item = new_item
	tooltip_text = Items.describe(item) if item != null else ""
	queue_redraw()


func _gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.pressed:
		clicked.emit(self, event.button_index)
		accept_event()


func _draw() -> void:
	var rect := Rect2(Vector2.ZERO, size)
	draw_rect(rect, Color(0.12, 0.1, 0.09, 0.85))
	var border := Color(0.45, 0.4, 0.33)
	if item != null:
		border = Items.color_of(item)
	draw_rect(rect, border, false, 2.0)
	if item != null:
		Items.draw_icon(self, item, size / 2.0)
		draw_string(ThemeDB.fallback_font, Vector2(size.x - 18, size.y - 3), Items.tier_label(item),
				HORIZONTAL_ALIGNMENT_LEFT, -1, 10, Color(1, 1, 1, 0.8))
	elif placeholder != "":
		draw_string(ThemeDB.fallback_font, Vector2(0, size.y / 2.0 + 5), placeholder,
				HORIZONTAL_ALIGNMENT_CENTER, size.x, 11, Color(1, 1, 1, 0.3))
