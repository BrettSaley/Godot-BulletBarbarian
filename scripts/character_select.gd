class_name CharacterSelect
extends CanvasLayer
## RotMG-style character select: one card per save slot showing the
## character, their level, realm and weapon. Empty slots make a new character.
## Built in code, runs while the game is paused underneath.

signal chosen(slot: int)

const CARD_SIZE := Vector2(290, 330)
## Level 80 is the cap, where the level is replaced by a score.
const FINAL_LEVEL := 80

var cards: HBoxContainer
var confirm: ConfirmationDialog
var pending_delete := -1
var time := 0.0
var previews: Array[Control] = []


func _ready() -> void:
	layer = 10
	process_mode = Node.PROCESS_MODE_ALWAYS
	_build()


func _process(delta: float) -> void:
	time += delta
	for preview in previews:
		preview.queue_redraw()


## Esc would open the pause menu underneath, so swallow it here.
func _input(event: InputEvent) -> void:
	if event is InputEventKey and event.keycode == KEY_ESCAPE:
		get_viewport().set_input_as_handled()


func _build() -> void:
	var background := ColorRect.new()
	background.color = Color(0.07, 0.06, 0.06)
	background.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(background)
	var center := CenterContainer.new()
	center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	background.add_child(center)
	var column := VBoxContainer.new()
	column.add_theme_constant_override("separation", 22)
	center.add_child(column)

	var title := _label("Choose your Character", 40, Color(1, 0.85, 0.45))
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	column.add_child(title)

	cards = HBoxContainer.new()
	cards.add_theme_constant_override("separation", 24)
	column.add_child(cards)

	var quit := _button("Quit", 160)
	quit.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	quit.pressed.connect(get_tree().quit)
	column.add_child(quit)

	confirm = ConfirmationDialog.new()
	confirm.ok_button_text = "Delete forever"
	confirm.confirmed.connect(_delete_confirmed)
	add_child(confirm)

	_refresh_cards()


func _refresh_cards() -> void:
	for child in cards.get_children():
		child.queue_free()
	previews.clear()
	for slot in SaveGame.SLOTS:
		cards.add_child(_card(slot, SaveGame.read(slot)))


func _card(slot: int, save: Dictionary) -> Control:
	var panel := PanelContainer.new()
	panel.custom_minimum_size = CARD_SIZE
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.13, 0.11, 0.1)
	style.border_color = Color(0.45, 0.4, 0.33) if save.is_empty() else Color(0.95, 0.8, 0.35)
	style.set_border_width_all(2)
	style.set_corner_radius_all(6)
	style.set_content_margin_all(16)
	panel.add_theme_stylebox_override("panel", style)
	var column := VBoxContainer.new()
	column.add_theme_constant_override("separation", 6)
	panel.add_child(column)

	if save.is_empty():
		var spacer := Control.new()
		spacer.size_flags_vertical = Control.SIZE_EXPAND_FILL
		column.add_child(spacer)
		var empty := _label("Empty slot", 24, Color(1, 1, 1, 0.45))
		empty.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		column.add_child(empty)
		var spacer_2 := Control.new()
		spacer_2.size_flags_vertical = Control.SIZE_EXPAND_FILL
		column.add_child(spacer_2)
		var create := _button("New Character", 0)
		create.pressed.connect(_choose.bind(slot))
		column.add_child(create)
		return panel

	var hero: Dictionary = save.player
	var preview := Control.new()
	preview.custom_minimum_size = Vector2(0, 150)
	var hero_class: String = hero.get("class", "barbarian")
	var palette := ClassArt.palette_for(hero_class, hero.look)
	preview.draw.connect(func() -> void:
		ClassArt.draw(preview, hero_class, palette, sin(time * 3.0 + slot) * 1.2, 0.0, 1.0, 3.0,
				preview.size / 2.0 + Vector2(0, 30)))
	previews.append(preview)
	column.add_child(preview)

	var name_label := _label(hero.name, 26, Color(1, 0.9, 0.6))
	name_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	column.add_child(name_label)
	var class_line := _label(ClassArt.class_name_of(hero_class), 16, Color(0.85, 0.75, 0.55))
	class_line.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	column.add_child(class_line)
	var progress := "Score %d" % (hero.total_xp / 10) if hero.level >= FINAL_LEVEL else "Level %d" % hero.level
	var info := _label("%s  -  %s" % [progress, Realms.info(save.realm).name], 18, Color(1, 1, 1, 0.8))
	info.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	column.add_child(info)
	if not hero.get("dev_marks", []).is_empty():
		var dev := _label("Dev tools used", 14, Color(1, 0.45, 0.4))
		dev.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		column.add_child(dev)

	var weapon = hero.equipment.get("weapon")
	if weapon != null:
		var weapon_row := HBoxContainer.new()
		weapon_row.alignment = BoxContainer.ALIGNMENT_CENTER
		weapon_row.add_theme_constant_override("separation", 8)
		var icon := ItemSlot.new("preview", 0)
		icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
		icon.set_item(weapon)
		weapon_row.add_child(icon)
		# Dark tiers like Black would vanish against the card.
		var tint := Items.color_of(weapon)
		if tint.get_luminance() < 0.35:
			tint = tint.lightened(0.45)
		var weapon_name := _label(weapon.name, 16, tint)
		weapon_name.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		weapon_row.add_child(weapon_name)
		column.add_child(weapon_row)

	var spacer := Control.new()
	spacer.size_flags_vertical = Control.SIZE_EXPAND_FILL
	column.add_child(spacer)
	var buttons := HBoxContainer.new()
	buttons.add_theme_constant_override("separation", 10)
	column.add_child(buttons)
	var play := _button("Play", 0)
	play.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	play.pressed.connect(_choose.bind(slot))
	buttons.add_child(play)
	var delete := _button("Delete", 90)
	delete.add_theme_color_override("font_color", Color(1, 0.5, 0.45))
	delete.pressed.connect(_ask_delete.bind(slot, hero.name))
	buttons.add_child(delete)
	return panel


func _choose(slot: int) -> void:
	chosen.emit(slot)
	queue_free()


func _ask_delete(slot: int, hero_name: String) -> void:
	pending_delete = slot
	confirm.dialog_text = "Delete %s forever? Their gear is lost." % hero_name
	confirm.popup_centered()


func _delete_confirmed() -> void:
	SaveGame.erase(pending_delete)
	pending_delete = -1
	_refresh_cards()


func _label(text: String, font_size: int, color: Color) -> Label:
	var label := Label.new()
	label.text = text
	label.add_theme_font_size_override("font_size", font_size)
	label.add_theme_color_override("font_color", color)
	return label


func _button(text: String, width: float) -> Button:
	var button := Button.new()
	button.text = text
	button.custom_minimum_size = Vector2(width, 40)
	button.add_theme_font_size_override("font_size", 20)
	return button
