class_name DamageText
extends Label
## Floating number that drifts up and fades out, e.g. damage dealt or "LEVEL UP".


static func spawn(parent: Node, pos: Vector2, text_value: String, color: Color, font_size := 14) -> void:
	var label := DamageText.new()
	label.text = text_value
	label.z_index = 50
	label.add_theme_color_override("font_color", color)
	label.add_theme_color_override("font_outline_color", Color(0, 0, 0))
	label.add_theme_constant_override("outline_size", 4)
	label.add_theme_font_size_override("font_size", font_size)
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.size = Vector2(120, 20)
	label.position = pos - Vector2(60, 10) + Vector2(randf_range(-6, 6), 0)
	parent.add_child(label)
	var tween := label.create_tween()
	tween.tween_property(label, "position:y", label.position.y - 30, 0.7)
	tween.parallel().tween_property(label, "modulate:a", 0.0, 0.7).set_delay(0.3)
	tween.tween_callback(label.queue_free)
