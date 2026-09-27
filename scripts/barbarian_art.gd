class_name BarbarianArt
extends RefCounted
## Chibi barbarian drawing (palettes let other classes or enemies reuse it):
## big head, horned helmet, angry brows over sparkly eyes, tiny axe.
## Drawn facing right; `facing` mirrors it, `size` scales the whole figure.

const HERO := {
	"skin": Color(1.0, 0.8, 0.63),
	"fur": Color(0.55, 0.36, 0.2),
	"dark": Color(0.2, 0.11, 0.07),
	"beard": Color(0.93, 0.47, 0.16),
	"steel": Color(0.72, 0.74, 0.8),
	"rim": Color(0.55, 0.57, 0.63),
	"horn": Color(0.97, 0.93, 0.8),
	"gold": Color(0.95, 0.8, 0.3),
	"eye_shine": Color(1, 1, 1),
	"cheeks": Color(1, 0.45, 0.5, 0.65),
}


static func draw(ci: CanvasItem, palette: Dictionary, bob: float, tilt: float, facing: float, size := 1.0) -> void:
	var p := palette
	# Shadow stays on the ground while the body bobs.
	ci.draw_set_transform(Vector2(0, 17) * size, 0.0, Vector2(size, size * 0.35))
	ci.draw_circle(Vector2.ZERO, 11.0, Color(0, 0, 0, 0.3))
	ci.draw_set_transform(Vector2(0, bob) * size, tilt, Vector2(facing * size, size))

	# Feet
	ci.draw_circle(Vector2(-4, 14), 3.2, p.dark)
	ci.draw_circle(Vector2(4, 14), 3.2, p.dark)
	# Fur tunic body and belt
	ci.draw_circle(Vector2(0, 7), 8.0, p.fur)
	ci.draw_line(Vector2(-7.5, 9), Vector2(7.5, 9), p.dark, 2.0)
	ci.draw_circle(Vector2(0, 9), 1.5, p.gold)
	# Tiny axe held up in the front hand
	ci.draw_line(Vector2(10, 11), Vector2(12, -4), Color(0.45, 0.28, 0.12), 2.0)
	ci.draw_colored_polygon(PackedVector2Array([Vector2(11.5, -6), Vector2(18, -9), Vector2(18.5, -1), Vector2(12.5, -2)]), p.steel)
	# Arms
	ci.draw_circle(Vector2(-8, 7), 3.0, p.skin)
	ci.draw_circle(Vector2(10, 7), 3.0, p.skin)

	# Horns (behind the helmet)
	ci.draw_colored_polygon(PackedVector2Array([Vector2(-8, -12), Vector2(-15, -15), Vector2(-17, -23), Vector2(-12, -16), Vector2(-6, -15)]), p.horn)
	ci.draw_colored_polygon(PackedVector2Array([Vector2(8, -12), Vector2(15, -15), Vector2(17, -23), Vector2(12, -16), Vector2(6, -15)]), p.horn)
	# Head
	ci.draw_circle(Vector2(0, -6), 10.5, p.skin)
	# Helmet dome and rim
	var dome := PackedVector2Array()
	for i in 13:
		dome.append(Vector2(0, -8) + Vector2.from_angle(PI + PI * i / 12.0) * 11.0)
	ci.draw_colored_polygon(dome, p.steel)
	ci.draw_line(Vector2(-11, -8), Vector2(11, -8), p.rim, 2.5)
	ci.draw_circle(Vector2(0, -15), 1.4, p.gold)

	# Beard wraps the chin
	ci.draw_colored_polygon(PackedVector2Array([
		Vector2(-10, -4), Vector2(-9, 1), Vector2(-5, 5), Vector2(-2, 3.5), Vector2(0, 7),
		Vector2(2, 3.5), Vector2(5, 5), Vector2(9, 1), Vector2(10, -4), Vector2(6, -1), Vector2(-6, -1)]), p.beard)

	# Big sparkly eyes, looking slightly forward
	ci.draw_circle(Vector2(-3, -5), 2.8, p.dark)
	ci.draw_circle(Vector2(5, -5), 2.8, p.dark)
	ci.draw_circle(Vector2(-2.2, -6), 1.0, p.eye_shine)
	ci.draw_circle(Vector2(5.8, -6), 1.0, p.eye_shine)
	# Fierce eyebrows angled down toward the nose
	ci.draw_line(Vector2(-6.5, -9.5), Vector2(-1, -7.6), p.dark, 1.8)
	ci.draw_line(Vector2(8.5, -9.5), Vector2(3, -7.6), p.dark, 1.8)
	# Rosy cheeks
	ci.draw_circle(Vector2(-6.5, -2.2), 1.7, p.cheeks)
	ci.draw_circle(Vector2(8.5, -2.2), 1.7, p.cheeks)
	# Growly mouth with one little fang
	ci.draw_colored_polygon(PackedVector2Array([Vector2(-1, -1.5), Vector2(4, -1.5), Vector2(3, 0.8), Vector2(0, 0.8)]), p.dark)
	ci.draw_colored_polygon(PackedVector2Array([Vector2(2.2, -1.5), Vector2(3.6, -1.5), Vector2(2.9, 0.2)]), Color(1, 1, 1))

	ci.draw_set_transform(Vector2.ZERO)
