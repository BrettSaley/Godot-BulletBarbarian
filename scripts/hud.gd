extends CanvasLayer
## Everything on screen that isn't the world: HP/XP bars, stats, zone name,
## equipment + inventory, the loot bag you're standing on, an arrow to the
## current boss, messages, and the death screen. Built in code.

signal slot_clicked(slot: ItemSlot, button: int)
signal restart_requested

const PANEL_BG := Color(0.1, 0.08, 0.07, 0.75)

var player: Node2D
var boss: Node2D
## Name shown top-left: the realm zone or the raid room (set by the main scene).
var area_name := ""

var zone_label: Label
var level_label: Label
var hp_bar: ProgressBar
var hp_text: Label
var mp_bar: ProgressBar
var mp_text: Label
var xp_bar: ProgressBar
var xp_text: Label
var stats_label: Label
var equip_slots := {}
var inventory_slots: Array[ItemSlot] = []
var bag_panel: PanelContainer
var bag_slots: Array[ItemSlot] = []
var message_label: Label
var message_timer := 0.0
var boss_arrow: Control
var death_panel: Control


func _ready() -> void:
	_build_zone_label()
	_build_status_panel()
	_build_item_panel()
	_build_message()
	boss_arrow = Control.new()
	boss_arrow.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	boss_arrow.mouse_filter = Control.MOUSE_FILTER_IGNORE
	boss_arrow.draw.connect(_draw_boss_arrow)
	add_child(boss_arrow)


func bind_player(p: Node2D) -> void:
	player = p
	player.changed.connect(refresh)
	refresh()


func _process(delta: float) -> void:
	zone_label.text = area_name
	if message_timer > 0.0:
		message_timer -= delta
		message_label.visible = message_timer > 0.0
	boss_arrow.queue_redraw()


func refresh() -> void:
	level_label.text = "Barbarian   Lv %d" % player.level
	hp_bar.max_value = player.max_hp()
	hp_bar.value = player.hp
	hp_text.text = "%d / %d" % [ceili(player.hp), player.max_hp()]
	mp_bar.max_value = player.max_mp()
	mp_bar.value = player.mp
	mp_text.text = "MP %d / %d" % [floori(player.mp), player.max_mp()]
	if player.is_max_level():
		xp_bar.max_value = 1
		xp_bar.value = 1
		xp_text.text = "MAX LEVEL"
	else:
		xp_bar.max_value = player.xp_to_next()
		xp_bar.value = player.xp
		xp_text.text = "XP %d / %d" % [player.xp, player.xp_to_next()]
	stats_label.text = "ATT %d   DEF %d   SPD %d\nDEX %d   VIT %d" % [
		player.stat("attack"), player.stat("defense"), player.stat("speed"),
		player.stat("dexterity"), player.stat("vitality")]
	for slot_name in equip_slots:
		equip_slots[slot_name].set_item(player.equipment[slot_name])
	for i in inventory_slots.size():
		inventory_slots[i].set_item(player.inventory[i])


func show_bag(bag: LootBag) -> void:
	bag_panel.visible = bag != null
	for i in bag_slots.size():
		bag_slots[i].set_item(bag.items[i] if bag != null and i < bag.items.size() else null)


func show_message(text: String, duration := 2.0) -> void:
	message_label.text = text
	message_label.visible = true
	message_timer = duration


func show_death(killer: String, level: int) -> void:
	death_panel = ColorRect.new()
	death_panel.color = Color(0, 0, 0, 0.7)
	death_panel.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(death_panel)
	var center := CenterContainer.new()
	center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	death_panel.add_child(center)
	var column := VBoxContainer.new()
	column.add_theme_constant_override("separation", 16)
	center.add_child(column)
	var title := _label("Your Barbarian has died", 36, Color(1, 0.35, 0.3))
	column.add_child(title)
	column.add_child(_label("Level %d, slain by %s" % [level, killer], 20, Color(1, 1, 1)))
	column.add_child(_label("Death is permanent. Their gear is lost.", 16, Color(0.8, 0.8, 0.8)))
	var button := Button.new()
	button.text = "Play a new Barbarian"
	button.add_theme_font_size_override("font_size", 20)
	button.pressed.connect(restart_requested.emit)
	column.add_child(button)
	button.grab_focus()


# --- Building the layout ---

func _build_zone_label() -> void:
	zone_label = _label("", 18, Color(1, 1, 1))
	zone_label.position = Vector2(12, 8)
	add_child(zone_label)


func _build_status_panel() -> void:
	var panel := _panel()
	panel.anchor_top = 1.0
	panel.anchor_bottom = 1.0
	panel.offset_left = 10
	panel.offset_top = -142
	panel.offset_right = 270
	panel.offset_bottom = -10
	add_child(panel)
	var column := VBoxContainer.new()
	column.add_theme_constant_override("separation", 4)
	panel.add_child(column)

	level_label = _label("", 16, Color(1, 0.9, 0.6))
	column.add_child(level_label)
	var hp := _bar(Color(0.85, 0.2, 0.2))
	hp_bar = hp[0]
	hp_text = hp[1]
	column.add_child(hp_bar)
	var mp := _bar(Color(0.3, 0.45, 0.95))
	mp_bar = mp[0]
	mp_text = mp[1]
	column.add_child(mp_bar)
	var xp := _bar(Color(0.3, 0.75, 0.3))
	xp_bar = xp[0]
	xp_text = xp[1]
	column.add_child(xp_bar)
	stats_label = _label("", 13, Color(0.9, 0.9, 0.9))
	column.add_child(stats_label)


func _build_item_panel() -> void:
	var column := VBoxContainer.new()
	column.anchor_left = 1.0
	column.anchor_right = 1.0
	column.anchor_top = 1.0
	column.anchor_bottom = 1.0
	column.offset_left = -196
	column.offset_right = -10
	column.offset_top = -330
	column.offset_bottom = -10
	column.alignment = BoxContainer.ALIGNMENT_END
	column.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(column)

	bag_panel = _panel()
	bag_panel.visible = false
	var bag_column := VBoxContainer.new()
	bag_panel.add_child(bag_column)
	bag_column.add_child(_label("Loot", 13, Color(1, 0.9, 0.6)))
	var bag_grid := _grid()
	bag_column.add_child(bag_grid)
	for i in LootBag.CAPACITY:
		var slot := _slot("bag", i)
		bag_grid.add_child(slot)
		bag_slots.append(slot)
	column.add_child(bag_panel)

	var panel := _panel()
	column.add_child(panel)
	var items_column := VBoxContainer.new()
	panel.add_child(items_column)
	var equip_row := HBoxContainer.new()
	items_column.add_child(equip_row)
	for slot_name in ["weapon", "ability", "armor", "ring"]:
		var slot := _slot("equip", slot_name, slot_name.capitalize())
		equip_row.add_child(slot)
		equip_slots[slot_name] = slot
	var inventory_grid := _grid()
	items_column.add_child(inventory_grid)
	for i in 8:
		var slot := _slot("inventory", i)
		inventory_grid.add_child(slot)
		inventory_slots.append(slot)


func _build_message() -> void:
	message_label = _label("", 26, Color(1, 1, 1))
	message_label.anchor_left = 0.5
	message_label.anchor_right = 0.5
	message_label.offset_left = -330
	message_label.offset_right = 330
	message_label.offset_top = 60
	message_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	message_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	message_label.visible = false
	add_child(message_label)


func _slot(group: String, key, placeholder := "") -> ItemSlot:
	var slot := ItemSlot.new(group, key, placeholder)
	slot.clicked.connect(func(s: ItemSlot, button: int): slot_clicked.emit(s, button))
	return slot


func _grid() -> GridContainer:
	var grid := GridContainer.new()
	grid.columns = 4
	grid.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return grid


func _panel() -> PanelContainer:
	var panel := PanelContainer.new()
	var style := StyleBoxFlat.new()
	style.bg_color = PANEL_BG
	style.set_corner_radius_all(6)
	style.set_content_margin_all(8)
	panel.add_theme_stylebox_override("panel", style)
	panel.mouse_filter = Control.MOUSE_FILTER_STOP
	return panel


## Returns [ProgressBar, Label] where the label is centred over the bar.
func _bar(color: Color) -> Array:
	var bar := ProgressBar.new()
	bar.custom_minimum_size = Vector2(240, 18)
	bar.show_percentage = false
	var fill := StyleBoxFlat.new()
	fill.bg_color = color
	fill.set_corner_radius_all(3)
	var bg := StyleBoxFlat.new()
	bg.bg_color = Color(0, 0, 0, 0.6)
	bg.set_corner_radius_all(3)
	bar.add_theme_stylebox_override("fill", fill)
	bar.add_theme_stylebox_override("background", bg)
	var text := _label("", 12, Color(1, 1, 1))
	text.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	text.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	text.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	bar.add_child(text)
	return [bar, text]


func _label(text: String, font_size: int, color: Color) -> Label:
	var label := Label.new()
	label.text = text
	label.add_theme_font_size_override("font_size", font_size)
	label.add_theme_color_override("font_color", color)
	label.add_theme_color_override("font_outline_color", Color(0, 0, 0))
	label.add_theme_constant_override("outline_size", 4)
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return label


## When the boss is off screen, an arrow at the screen edge points to it.
func _draw_boss_arrow() -> void:
	if not is_instance_valid(boss) or not player:
		return
	var screen := boss_arrow.get_viewport_rect().size
	var boss_on_screen: Vector2 = boss.get_global_transform_with_canvas().origin
	if Rect2(Vector2.ZERO, screen).grow(-20).has_point(boss_on_screen):
		return
	var center := screen / 2.0
	var dir := (boss_on_screen - center).normalized()
	var edge := center + dir * minf(absf((center.x - 40) / dir.x) if dir.x != 0.0 else INF,
			absf((center.y - 40) / dir.y) if dir.y != 0.0 else INF)
	var color := Color(1, 0.3, 0.25)
	boss_arrow.draw_colored_polygon(PackedVector2Array([
		edge + dir * 14, edge + dir.orthogonal() * 9, edge - dir.orthogonal() * 9]), color)
	boss_arrow.draw_string(ThemeDB.fallback_font, edge - dir * 18 + Vector2(-60, 5), boss.display_name,
			HORIZONTAL_ALIGNMENT_CENTER, 120, 13, color)
