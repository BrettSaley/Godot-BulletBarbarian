class_name CharacterCreator
extends CanvasLayer
## Character design screen shown when starting a new character: a class, a name and
## colour choices with a live preview. Built in code, runs while the game is
## paused underneath.

signal finished(character_name: String, look: Dictionary, character_class: String)
signal cancelled

const NAMES := ["Grom", "Ulfrik", "Bjorn", "Hilda", "Ragna", "Thrak", "Sigrun", "Korg", "Brunhild",
		"Olaf", "Freya", "Durgan", "Astrid", "Magnar", "Ingrid", "Torvald"]
const MAX_NAME_LENGTH := 16

var look := {}
var character_class := "barbarian"
var class_label: Label
var option_labels := {}
var name_edit: LineEdit
var preview: Control
var swatches := {}
var time := 0.0


func _ready() -> void:
	layer = 10
	process_mode = Node.PROCESS_MODE_ALWAYS
	look = {}
	for option in BarbarianArt.LOOK_OPTIONS:
		look[option] = 0
	_build()


func _process(delta: float) -> void:
	time += delta
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
	column.add_theme_constant_override("separation", 20)
	center.add_child(column)

	var title := _label("Create your Character", 40, Color(1, 0.85, 0.45))
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	column.add_child(title)

	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 48)
	column.add_child(row)

	preview = Control.new()
	preview.custom_minimum_size = Vector2(280, 360)
	preview.draw.connect(_draw_preview)
	row.add_child(preview)

	var options := VBoxContainer.new()
	options.add_theme_constant_override("separation", 14)
	options.alignment = BoxContainer.ALIGNMENT_CENTER
	row.add_child(options)

	# Class: < Barbarian >
	var class_row := HBoxContainer.new()
	class_row.add_theme_constant_override("separation", 12)
	options.add_child(class_row)
	var class_title := _label("Class", 20, Color(1, 0.9, 0.6))
	class_title.custom_minimum_size.x = 80
	class_row.add_child(class_title)
	var prev_class := _button("<", 44)
	prev_class.pressed.connect(_step_class.bind(-1))
	class_row.add_child(prev_class)
	class_label = _label("", 20, Color(1, 0.9, 0.6))
	class_label.custom_minimum_size.x = 118
	class_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	class_row.add_child(class_label)
	var next_class := _button(">", 44)
	next_class.pressed.connect(_step_class.bind(1))
	class_row.add_child(next_class)

	var name_row := HBoxContainer.new()
	name_row.add_theme_constant_override("separation", 12)
	options.add_child(name_row)
	var name_label := _label("Name", 20, Color(1, 1, 1))
	name_label.custom_minimum_size.x = 80
	name_row.add_child(name_label)
	name_edit = LineEdit.new()
	name_edit.text = NAMES.pick_random()
	name_edit.max_length = MAX_NAME_LENGTH
	name_edit.custom_minimum_size = Vector2(230, 36)
	name_edit.add_theme_font_size_override("font_size", 20)
	name_edit.text_submitted.connect(func(_text): _begin())
	name_row.add_child(name_edit)

	for option in BarbarianArt.LOOK_OPTIONS:
		options.add_child(_option_row(option))
	_refresh_class()

	var buttons := HBoxContainer.new()
	buttons.add_theme_constant_override("separation", 16)
	buttons.alignment = BoxContainer.ALIGNMENT_CENTER
	column.add_child(buttons)
	var back := _button("Back", 120)
	back.pressed.connect(func() -> void:
		cancelled.emit()
		queue_free())
	buttons.add_child(back)
	var randomize_button := _button("Randomize", 180)
	randomize_button.pressed.connect(_randomize)
	buttons.add_child(randomize_button)
	var begin := _button("Begin Adventure", 240)
	begin.pressed.connect(_begin)
	buttons.add_child(begin)
	begin.grab_focus()


## "Skin   <  [swatch]  >"
func _option_row(option: String) -> Control:
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 12)
	var label := _label(ClassArt.label(character_class, option), 20, Color(1, 1, 1))
	option_labels[option] = label
	label.custom_minimum_size.x = 80
	row.add_child(label)
	var back := _button("<", 44)
	back.pressed.connect(_step.bind(option, -1))
	row.add_child(back)
	var swatch := ColorRect.new()
	swatch.custom_minimum_size = Vector2(118, 36)
	swatches[option] = swatch
	row.add_child(swatch)
	var forward := _button(">", 44)
	forward.pressed.connect(_step.bind(option, 1))
	row.add_child(forward)
	_refresh_swatch(option)
	return row


func _step(option: String, direction: int) -> void:
	var count: int = ClassArt.options(character_class, option).size()
	look[option] = posmod(look[option] + direction, count)
	_refresh_swatch(option)


func _step_class(direction: int) -> void:
	var i := ClassArt.ORDER.find(character_class)
	character_class = ClassArt.ORDER[posmod(i + direction, ClassArt.ORDER.size())]
	_refresh_class()


## Class name, and each colour row's name and swatch for the current class.
func _refresh_class() -> void:
	class_label.text = ClassArt.class_name_of(character_class)
	for option in option_labels:
		option_labels[option].text = ClassArt.label(character_class, option)
		_refresh_swatch(option)


func _randomize() -> void:
	character_class = ClassArt.ORDER.pick_random()
	look = ClassArt.random_look(character_class)
	_refresh_class()
	name_edit.text = NAMES.pick_random()
	for option in look:
		_refresh_swatch(option)


func _refresh_swatch(option: String) -> void:
	var choices := ClassArt.options(character_class, option)
	look[option] = clampi(look[option], 0, choices.size() - 1)
	swatches[option].color = choices[look[option]]


func _begin() -> void:
	var chosen_name := name_edit.text.strip_edges()
	if chosen_name == "":
		chosen_name = NAMES.pick_random()
	finished.emit(chosen_name, look.duplicate(), character_class)
	queue_free()


func _draw_preview() -> void:
	var bob := sin(time * 3.0) * 1.5
	ClassArt.draw(preview, character_class, ClassArt.palette_for(character_class, look), bob, 0.0, 1.0, 5.5,
			preview.size / 2.0 + Vector2(0, 40))


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
