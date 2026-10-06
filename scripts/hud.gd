extends CanvasLayer
## Everything on screen that isn't the world: HP/XP bars, stats, zone name,
## equipment + inventory, the loot bag you're standing on, an arrow to the
## current boss, messages, and the death screen. Built in code.

signal slot_clicked(slot: ItemSlot, button: int)
signal character_select_requested
signal portal_confirmed
signal portal_declined

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
var portal_prompt: PanelContainer
var portal_prompt_label: Label
var portal_prompt_buttons: HBoxContainer
var bag_slots: Array[ItemSlot] = []
var bank_panel: PanelContainer
var bank_slots: Array[ItemSlot] = []
var message_label: Label
var message_timer := 0.0
var boss_arrow: Control
var death_panel: Control
var dev_label: Label
var dev_marks_label: Label
var pause_menu: ColorRect
var raid_progress: Control
var raid_progress_done := 0
var raid_progress_needed := 2
var raid_progress_name := ""


func _ready() -> void:
	# Keep working while the game is paused so the pause menu can be used.
	process_mode = Node.PROCESS_MODE_ALWAYS
	_build_zone_label()
	_build_status_panel()
	_build_portal_prompt()
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


## Permanent note in the top-right corner: which dev tools this character has
## ever used. It never goes away for that character.
func _refresh_dev_marks() -> void:
	if player.dev_marks.is_empty():
		if dev_marks_label:
			dev_marks_label.visible = false
		return
	if dev_marks_label == null:
		dev_marks_label = _label("", 13, Color(1, 0.45, 0.4))
		dev_marks_label.anchor_left = 1.0
		dev_marks_label.anchor_right = 1.0
		dev_marks_label.offset_left = -420
		dev_marks_label.offset_right = -12
		dev_marks_label.offset_top = 8
		dev_marks_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
		dev_marks_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		dev_marks_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
		add_child(dev_marks_label)
	dev_marks_label.text = "Dev tools used: %s" % ", ".join(player.dev_marks)
	dev_marks_label.visible = true


func refresh() -> void:
	if ItemSlot.viewer_class != player.character_class:
		ItemSlot.viewer_class = player.character_class
		for slot in bag_slots + bank_slots:
			slot.queue_redraw()
	_refresh_dev_marks()
	if player.at_final_level():
		level_label.text = "%s   Score %d" % [player.character_name, player.score()]
	else:
		level_label.text = "%s   Lv %d  (cap %d)" % [player.character_name, player.level, player.level_cap]
	hp_bar.max_value = player.max_hp()
	hp_bar.value = player.hp
	hp_text.text = "%d / %d" % [ceili(player.hp), player.max_hp()]
	mp_bar.max_value = player.max_mp()
	mp_bar.value = player.mp
	mp_text.text = "MP %d / %d" % [floori(player.mp), player.max_mp()]
	if player.is_max_level():
		xp_bar.max_value = 1
		xp_bar.value = 1
		xp_text.text = "SCORE %d" % player.score() if player.at_final_level() else "LEVEL CAP - complete a raid to raise it"
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


## The bank's items while standing at the bank chest, or null to hide it.
func show_bank(items) -> void:
	bank_panel.visible = items != null
	for i in bank_slots.size():
		bank_slots[i].set_item(items[i] if items != null else null)


func show_bag(bag: LootBag) -> void:
	bag_panel.visible = bag != null
	for i in bag_slots.size():
		bag_slots[i].set_item(bag.items[i] if bag != null and i < bag.items.size() else null)


func show_message(text: String, duration := 2.0) -> void:
	message_label.text = text
	message_label.visible = true
	message_timer = duration


func show_death(character_name: String, killer: String, level: int) -> void:
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
	var title := _label("%s has died" % character_name, 36, Color(1, 0.35, 0.3))
	column.add_child(title)
	column.add_child(_label("Level %d, slain by %s" % [level, killer], 20, Color(1, 1, 1)))
	column.add_child(_label("Death is permanent. Their gear and save are gone.", 16, Color(0.8, 0.8, 0.8)))
	var button := Button.new()
	button.text = "Character Select"
	button.add_theme_font_size_override("font_size", 20)
	button.pressed.connect(character_select_requested.emit)
	column.add_child(button)
	button.grab_focus()


## Esc pauses the game with Resume / Character Select / Quit buttons (not while dead).
func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo and event.keycode == KEY_ESCAPE:
		if pause_menu and pause_menu.visible:
			resume()
		elif death_panel == null:
			pause()
		get_viewport().set_input_as_handled()


func pause() -> void:
	if pause_menu == null:
		_build_pause_menu()
	pause_menu.visible = true
	get_tree().paused = true
	pause_menu.get_node("Center/Column/Resume").grab_focus()


func resume() -> void:
	pause_menu.visible = false
	get_tree().paused = false


func _build_pause_menu() -> void:
	pause_menu = ColorRect.new()
	pause_menu.color = Color(0, 0, 0, 0.6)
	pause_menu.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(pause_menu)
	var center := CenterContainer.new()
	center.name = "Center"
	center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	pause_menu.add_child(center)
	var column := VBoxContainer.new()
	column.name = "Column"
	column.add_theme_constant_override("separation", 14)
	center.add_child(column)
	var title := _label("Paused", 40, Color(1, 0.9, 0.6))
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	column.add_child(title)
	for entry in [["Resume", resume], ["Character Select", character_select_requested.emit], ["Quit", get_tree().quit]]:
		var button := Button.new()
		button.name = entry[0]
		button.text = entry[0]
		button.custom_minimum_size = Vector2(220, 44)
		button.add_theme_font_size_override("font_size", 22)
		button.pressed.connect(entry[1])
		column.add_child(button)


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


## "Enter <portal>?" with Yes/No, just above the status panel. Locked portals
## show what unlocks them instead.
func _build_portal_prompt() -> void:
	portal_prompt = _panel()
	portal_prompt.anchor_top = 1.0
	portal_prompt.anchor_bottom = 1.0
	portal_prompt.offset_left = 10
	portal_prompt.offset_right = 270
	portal_prompt.offset_bottom = -150
	portal_prompt.grow_vertical = Control.GROW_DIRECTION_BEGIN
	portal_prompt.visible = false
	add_child(portal_prompt)
	var column := VBoxContainer.new()
	column.add_theme_constant_override("separation", 6)
	portal_prompt.add_child(column)
	portal_prompt_label = _label("", 15, Color(1, 0.9, 0.6))
	portal_prompt_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	portal_prompt_label.custom_minimum_size.x = 244
	column.add_child(portal_prompt_label)
	portal_prompt_buttons = HBoxContainer.new()
	portal_prompt_buttons.add_theme_constant_override("separation", 8)
	column.add_child(portal_prompt_buttons)
	for entry in [["Yes (E)", portal_confirmed], ["No", portal_declined]]:
		var button := Button.new()
		button.text = entry[0]
		button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		# Never take keyboard focus, or Space (Warcry) would press it.
		button.focus_mode = Control.FOCUS_NONE
		button.pressed.connect(entry[1].emit)
		portal_prompt_buttons.add_child(button)


func show_portal_prompt(portal: Portal) -> void:
	if portal.locked:
		portal_prompt_label.text = "%s\n%s" % [portal.label, portal.lock_hint]
	else:
		portal_prompt_label.text = "Enter %s?" % portal.label
	portal_prompt_buttons.visible = not portal.locked
	portal_prompt.visible = true


func hide_portal_prompt() -> void:
	portal_prompt.visible = false


func _build_item_panel() -> void:
	var column := VBoxContainer.new()
	column.anchor_left = 1.0
	column.anchor_right = 1.0
	column.anchor_top = 1.0
	column.anchor_bottom = 1.0
	column.offset_left = -196
	column.offset_right = -10
	column.offset_top = -620
	column.offset_bottom = -10
	column.alignment = BoxContainer.ALIGNMENT_END
	column.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(column)

	bank_panel = _panel()
	bank_panel.visible = false
	var bank_column := VBoxContainer.new()
	bank_panel.add_child(bank_column)
	bank_column.add_child(_label("Bank", 13, Color(1, 0.9, 0.6)))
	bank_column.add_child(_label("Shared by all your characters.\nClick items to move them in or out.", 11, Color(1, 1, 1, 0.6)))
	var bank_grid := _grid()
	bank_column.add_child(bank_grid)
	for i in Bank.SIZE:
		var slot := _slot("bank", i)
		bank_grid.add_child(slot)
		bank_slots.append(slot)
	column.add_child(bank_panel)

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
		# The ring slot holds any accessory: rings, capes, boots, off-hands.
		var slot := _slot("equip", slot_name, "Acc" if slot_name == "ring" else slot_name.capitalize())
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


## Shows which dev mode is on (hidden in Normal).
func set_dev_mode(mode: int, mode_name: String) -> void:
	if dev_label == null:
		dev_label = _label("", 14, Color(1, 0.4, 0.9))
		dev_label.position = Vector2(12, 32)
		add_child(dev_label)
	dev_label.text = "DEV - %s  (9 to change)" % mode_name
	dev_label.add_theme_color_override("font_color", Color(1, 0.85, 0.2) if mode == 2 else Color(1, 0.4, 0.9))
	dev_label.visible = mode != 0


## Dungeons cleared toward the next raid portal, shown under the area name.
func set_raid_progress(done: int, needed: int, raid_title: String) -> void:
	raid_progress_done = done
	raid_progress_needed = needed
	raid_progress_name = raid_title
	if raid_progress == null:
		raid_progress = Control.new()
		raid_progress.position = Vector2(12, 56)
		raid_progress.size = Vector2(360, 40)
		raid_progress.mouse_filter = Control.MOUSE_FILTER_IGNORE
		raid_progress.draw.connect(_draw_raid_progress)
		add_child(raid_progress)
	raid_progress.queue_redraw()


func _draw_raid_progress() -> void:
	var font := ThemeDB.fallback_font
	var ready := raid_progress_done >= raid_progress_needed
	var label := "The %s portal is open in the hub!" % raid_progress_name if ready \
			else "Dungeons to unlock the %s:" % raid_progress_name
	var color := Color(1, 0.85, 0.3) if ready else Color(0.9, 0.9, 0.9)
	raid_progress.draw_string_outline(font, Vector2(0, 14), label, HORIZONTAL_ALIGNMENT_LEFT, -1, 14, 4, Color(0, 0, 0))
	raid_progress.draw_string(font, Vector2(0, 14), label, HORIZONTAL_ALIGNMENT_LEFT, -1, 14, color)
	# One pip per dungeon; filled pips are dungeons cleared.
	for i in raid_progress_needed:
		var pip := Rect2(Vector2(i * 34, 22), Vector2(28, 12))
		raid_progress.draw_rect(pip.grow(2), Color(0, 0, 0, 0.7))
		raid_progress.draw_rect(pip, Color(1, 0.8, 0.3) if i < raid_progress_done else Color(0.3, 0.3, 0.32))
