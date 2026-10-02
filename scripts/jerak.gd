class_name Jerak
extends Node2D
## Jerak, a friendly adventurer who waits by the raid chest once the final
## boss falls, standing proud with a smile. He's not a monster: he does
## nothing, can't be hit, and shots pass straight through him. Chibi like the
## Barbarian and the same size: swept-up auburn hair, a short ginger beard,
## angry brows over a smile, and dragon armour (platebody, platelegs,
## boots) with a dragon battleaxe resting on his shoulder.

const SIZE := 1.3  # the same scale the Barbarian is drawn at
const SKIN := Color(1.0, 0.84, 0.74)
const HAIR := Color(0.62, 0.32, 0.17)
const BEARD := Color(0.74, 0.42, 0.22)
const DRAGON := Color(0.78, 0.13, 0.11)
const DRAGON_DARK := Color(0.5, 0.07, 0.07)
const TRIM := Color(0.75, 0.74, 0.7)
const DARK := Color(0.16, 0.1, 0.08)
const MESSAGE := "Well done Adventurer!"

func _draw() -> void:
	draw_set_transform(Vector2(0, 17) * SIZE, 0.0, Vector2(SIZE, SIZE * 0.35))
	draw_circle(Vector2.ZERO, 11.0, Color(0, 0, 0, 0.3))
	draw_set_transform(Vector2.ZERO, 0.0, Vector2(SIZE, SIZE))

	# Dragon battleaxe resting on his left shoulder, behind him
	var grip := Vector2(-9, 4)
	var head := Vector2(-15, -21)
	draw_line(grip + Vector2(1.5, 5), head, Color(0.45, 0.28, 0.12), 2.0)
	var across := (head - grip).normalized().orthogonal()
	for side in [-1.0, 1.0]:
		# Two red crescent blades either side of the haft
		var out: Vector2 = across * side
		draw_colored_polygon(PackedVector2Array([head - out.orthogonal() * 4.0, head + out * 8.0 - out.orthogonal() * 7.0,
				head + out * 10.0, head + out * 8.0 + out.orthogonal() * 7.0, head + out.orthogonal() * 4.0]), DRAGON)
		draw_line(head + out * 8.5 - out.orthogonal() * 6.0, head + out * 9.6, Color(1, 0.55, 0.5), 1.2)
	draw_circle(head, 2.0, TRIM)

	# Dragon boots and platelegs
	for side in [-1.0, 1.0]:
		draw_rect(Rect2(Vector2(side * 4.5 - 3, 6), Vector2(6, 8)), DRAGON)
		draw_line(Vector2(side * 4.5 - 3, 9), Vector2(side * 4.5 + 3, 9), DRAGON_DARK, 1.0)
		draw_circle(Vector2(side * 4.5, 14), 3.2, DARK)

	# Dragon platebody with silver trim
	draw_circle(Vector2(0, 2), 9.0, DRAGON)
	draw_colored_polygon(PackedVector2Array([Vector2(-9, 0), Vector2(9, 0), Vector2(7, 9), Vector2(-7, 9)]), DRAGON)
	draw_line(Vector2(0, -6), Vector2(0, 8), DRAGON_DARK, 1.5)
	draw_line(Vector2(-7, 8), Vector2(7, 8), TRIM, 1.5)
	for rivet in [Vector2(-5, -2), Vector2(5, -2), Vector2(-4, 4), Vector2(4, 4)]:
		draw_circle(rivet, 0.9, TRIM)

	# Left arm down at his side, gripping the axe
	draw_line(Vector2(-7, -3), grip, DRAGON, 5.0)
	draw_circle(Vector2(-7, -3), 3.2, DRAGON_DARK)
	draw_circle(grip, 2.8, SKIN)
	# Right arm hanging at his other side
	draw_line(Vector2(7, -3), Vector2(9, 4), DRAGON, 5.0)
	draw_circle(Vector2(7, -3), 3.2, DRAGON_DARK)
	draw_circle(Vector2(9, 4), 2.8, SKIN)

	# Head
	draw_circle(Vector2(0, -13), 11.0, SKIN)
	# Auburn hair swept up into a quiff, with a lighter streak
	draw_colored_polygon(PackedVector2Array([Vector2(-11, -12), Vector2(-11.6, -18), Vector2(-8.5, -23.5), Vector2(-3, -26.5),
			Vector2(3, -27.5), Vector2(8.5, -25), Vector2(11.6, -19), Vector2(11, -12), Vector2(9.5, -15), Vector2(8, -17.8),
			Vector2(3, -18.6), Vector2(-2, -18), Vector2(-7, -17.4), Vector2(-9.5, -15)]), HAIR)
	draw_polyline(PackedVector2Array([Vector2(-6, -21), Vector2(-1, -24.5), Vector2(5, -25)]), HAIR.lightened(0.25), 1.2)

	# Short ginger beard along the jaw and chin
	draw_colored_polygon(PackedVector2Array([Vector2(-10.8, -13), Vector2(-9.5, -7.5), Vector2(-5.5, -3.2),
			Vector2(0, -1.8), Vector2(5.5, -3.2), Vector2(9.5, -7.5), Vector2(10.8, -13), Vector2(8.5, -11),
			Vector2(6.5, -7.5), Vector2(0, -6.3), Vector2(-6.5, -7.5), Vector2(-8.5, -11)]), BEARD)
	# Eyes under angry brows slanting down toward the nose
	for side in [-1.0, 1.0]:
		draw_circle(Vector2(side * 4.2, -12), 1.6, DARK)
		draw_circle(Vector2(side * 4.2 + 0.6, -12.5), 0.5, Color(1, 1, 1))
		draw_line(Vector2(side * 1.8, -13.6), Vector2(side * 6.6, -15.6), HAIR, 1.8)
	# A plain, friendly smile under the mustache
	draw_arc(Vector2(0, -9.6), 3.6, 0.45, PI - 0.45, 12, DARK, 1.2)
	draw_colored_polygon(PackedVector2Array([Vector2(-5, -8.4), Vector2(0, -9.6), Vector2(5, -8.4), Vector2(3.5, -7.4),
			Vector2(0, -8.2), Vector2(-3.5, -7.4)]), BEARD)
	draw_set_transform(Vector2.ZERO)

	_draw_bubble(Vector2(0, -62))
	draw_string(ThemeDB.fallback_font, Vector2(-40, 34), "Jerak", HORIZONTAL_ALIGNMENT_CENTER, 80, 13, Color(1, 0.9, 0.6))

## A white speech bubble with a little tail pointing down at him.
func _draw_bubble(bottom: Vector2) -> void:
	var font := ThemeDB.fallback_font
	var text_size := font.get_string_size(MESSAGE, HORIZONTAL_ALIGNMENT_LEFT, -1, 14)
	var box := Rect2(bottom - Vector2(text_size.x / 2.0 + 10, text_size.y + 12), Vector2(text_size.x + 20, text_size.y + 10))
	var outline := Color(0.15, 0.12, 0.1)
	draw_colored_polygon(PackedVector2Array([bottom + Vector2(-6, -3), bottom + Vector2(6, -3), bottom + Vector2(0, 7)]), outline)
	draw_rect(box.grow(2), outline)
	draw_rect(box, Color(1, 1, 0.97))
	draw_colored_polygon(PackedVector2Array([bottom + Vector2(-4, -4), bottom + Vector2(4, -4), bottom + Vector2(0, 3)]), Color(1, 1, 0.97))
	draw_string(font, Vector2(box.position.x + 10, box.end.y - 8), MESSAGE, HORIZONTAL_ALIGNMENT_LEFT, -1, 14, outline)
