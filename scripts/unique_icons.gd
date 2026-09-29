class_name UniqueIcons
extends RefCounted
## Hand-drawn inventory icons for every UT and GIGA item, each modelled on
## its OSRS counterpart. Icons are about 30px across, centred on `c`.

const GOLD := Color(0.95, 0.78, 0.3)
const DARK := Color(0.1, 0.08, 0.08)
const STEEL := Color(0.78, 0.8, 0.85)
const WOOD := Color(0.45, 0.3, 0.15)


static func has_icon(id: String) -> bool:
	return id in [
		"twisted_bow", "elder_maul", "dragon_claws", "ancestral_robe_top", "ancestral_hat", "twisted_buckler",
		"scythe_of_vitur", "sanguinesti_staff", "ghrazi_rapier", "justiciar_chestguard", "justiciar_faceguard", "avernic_defender",
		"tumekens_shadow", "osmumtens_fang", "keris_partisan", "masori_body", "masori_mask", "lightbearer",
		"dragon_chainbody", "sarachnis_chitin_helm", "trident_of_the_seas", "fire_cape",
		"crystal_helm", "dragon_hunter_lance", "primordial_boots", "inquisitors_hauberk",
		"dragonfire_shield", "craws_bow", "abyssal_crown", "malediction_ward",
	]


static func draw(ci: CanvasItem, id: String, c: Vector2) -> void:
	match id:
		# --- Chambers of Xeric ---
		"twisted_bow":
			# Dark green recurve with pale green tips and a gold grip.
			var limb := PackedVector2Array()
			for i in 13:
				var t := -1.0 + i / 6.0
				limb.append(c + Vector2(-6 + 5 * t * t + (2.0 if absf(t) > 0.8 else 0.0), t * 13))
			ci.draw_polyline(limb, Color(0.18, 0.35, 0.22), 3.5)
			ci.draw_circle(limb[0], 2.0, Color(0.6, 0.9, 0.6))
			ci.draw_circle(limb[12], 2.0, Color(0.6, 0.9, 0.6))
			ci.draw_line(limb[0], limb[12], Color(0.9, 0.9, 0.85), 1.0)
			ci.draw_rect(Rect2(c + Vector2(-8, -3), Vector2(4, 6)), GOLD)
		"elder_maul":
			ci.draw_line(c + Vector2(-10, 12), c + Vector2(4, -2), Color(0.3, 0.25, 0.22), 3.0)
			ci.draw_colored_polygon(PackedVector2Array([c + Vector2(-2, -8), c + Vector2(8, -14), c + Vector2(14, -4), c + Vector2(4, 2)]),
					Color(0.55, 0.55, 0.58))
			ci.draw_colored_polygon(PackedVector2Array([c + Vector2(-2, -8), c + Vector2(8, -14), c + Vector2(10, -11), c + Vector2(0, -5)]),
					Color(0.75, 0.75, 0.78))
		"dragon_claws":
			ci.draw_rect(Rect2(c + Vector2(-9, 4), Vector2(18, 7)), Color(0.4, 0.25, 0.15))
			for k in 3:
				var x := -7.0 + k * 7.0
				ci.draw_colored_polygon(PackedVector2Array([c + Vector2(x - 2.5, 4), c + Vector2(x + 2, -13 + k), c + Vector2(x + 2.5, 4)]),
						Color(0.85, 0.15, 0.12))
		"ancestral_robe_top":
			_robe(ci, c, Color(0.18, 0.2, 0.42), GOLD, Color(0.5, 0.2, 0.55))
		"ancestral_hat":
			ci.draw_colored_polygon(PackedVector2Array([c + Vector2(-11, 8), c + Vector2(11, 8), c + Vector2(4, -6), c + Vector2(-2, -14)]),
					Color(0.18, 0.2, 0.42))
			ci.draw_rect(Rect2(c + Vector2(-12, 6), Vector2(24, 4)), GOLD)
			ci.draw_circle(c + Vector2(0, 2), 2.0, Color(0.5, 0.2, 0.55))
		"twisted_buckler":
			ci.draw_circle(c, 12.0, Color(0.25, 0.32, 0.25))
			ci.draw_circle(c, 9.0, Color(0.4, 0.5, 0.38))
			for k in 6:
				var a := Vector2.from_angle(TAU * k / 6.0)
				ci.draw_line(c + a * 3.0, c + a.rotated(0.6) * 12.0, Color(0.7, 0.85, 0.65), 1.5)
			ci.draw_circle(c, 2.5, GOLD)
		# --- Theatre of Blood ---
		"scythe_of_vitur":
			# Long dark haft with a crimson crescent blade sweeping back from the top.
			ci.draw_line(c + Vector2(-6, 13), c + Vector2(6, -11), Color(0.3, 0.12, 0.12), 2.5)
			ci.draw_colored_polygon(PackedVector2Array([c + Vector2(6, -11), c + Vector2(0, -13), c + Vector2(-7, -11), c + Vector2(-12, -5),
					c + Vector2(-6, -8), c + Vector2(0, -9), c + Vector2(5, -8)]), Color(0.75, 0.12, 0.15))
		"sanguinesti_staff":
			ci.draw_line(c + Vector2(-8, 13), c + Vector2(5, -6), Color(0.2, 0.1, 0.12), 3.0)
			ci.draw_arc(c + Vector2(6, -8), 6.0, PI * 0.8, PI * 2.2, 10, Color(0.35, 0.1, 0.12), 2.0)
			ci.draw_circle(c + Vector2(6, -8), 4.0, Color(0.9, 0.1, 0.15))
			ci.draw_circle(c + Vector2(5, -9), 1.3, Color(1, 0.6, 0.6))
		"ghrazi_rapier":
			ci.draw_line(c + Vector2(-5, 7), c + Vector2(11, -13), Color(0.85, 0.87, 0.92), 2.0)
			ci.draw_arc(c + Vector2(-5, 7), 5.0, 0.0, TAU, 10, Color(0.75, 0.12, 0.15), 2.0)
			ci.draw_line(c + Vector2(-5, 7), c + Vector2(-10, 12), Color(0.3, 0.12, 0.12), 3.0)
		"justiciar_chestguard":
			_robe(ci, c, Color(0.9, 0.88, 0.8), GOLD, Color(0.95, 0.8, 0.3))
		"justiciar_faceguard":
			ci.draw_circle(c + Vector2(0, 0), 11.0, GOLD)
			ci.draw_rect(Rect2(c + Vector2(-9, 2), Vector2(18, 10)), GOLD.darkened(0.1))
			ci.draw_rect(Rect2(c + Vector2(-6, -3), Vector2(12, 3)), DARK)
			ci.draw_line(c + Vector2(0, -3), c + Vector2(0, 10), DARK, 1.5)
			ci.draw_colored_polygon(PackedVector2Array([c + Vector2(-3, -11), c + Vector2(0, -16), c + Vector2(3, -11)]), Color(0.95, 0.95, 0.95))
		"avernic_defender":
			ci.draw_colored_polygon(PackedVector2Array([c + Vector2(-8, -12), c + Vector2(8, -12), c + Vector2(10, 2), c + Vector2(0, 13),
					c + Vector2(-10, 2)]), Color(0.45, 0.08, 0.1))
			ci.draw_colored_polygon(PackedVector2Array([c + Vector2(-2, -12), c + Vector2(2, -12), c + Vector2(0, -17)]), STEEL)
			ci.draw_circle(c + Vector2(0, -2), 3.0, Color(0.9, 0.2, 0.25))
		# --- Tombs of Amascut ---
		"tumekens_shadow":
			ci.draw_line(c + Vector2(-7, 13), c + Vector2(3, -5), GOLD, 3.0)
			ci.draw_arc(c + Vector2(5, -9), 6.0, 0.0, TAU, 12, GOLD, 2.0)
			ci.draw_circle(c + Vector2(5, -9), 4.0, Color(0.35, 0.2, 0.7))
			ci.draw_circle(c + Vector2(5, -9), 7.5, Color(0.5, 0.3, 0.9, 0.35))
		"osmumtens_fang":
			ci.draw_colored_polygon(PackedVector2Array([c + Vector2(-4, 6), c + Vector2(2, -4), c + Vector2(12, -13), c + Vector2(6, 0),
					c + Vector2(-1, 8)]), Color(0.92, 0.88, 0.78))
			ci.draw_line(c + Vector2(-4, 6), c + Vector2(-10, 12), GOLD, 3.0)
			ci.draw_line(c + Vector2(-7, 4), c + Vector2(-1, 10), Color(0.25, 0.45, 0.8), 2.0)
		"keris_partisan":
			ci.draw_line(c + Vector2(-11, 13), c + Vector2(3, -3), WOOD, 2.5)
			var wave := PackedVector2Array()
			for i in 7:
				wave.append(c + Vector2(3, -3) + Vector2(i * 1.6, -i * 1.6) + Vector2(1, 1) * sin(i * 1.8) * 1.5)
			ci.draw_polyline(wave, GOLD, 3.0)
			ci.draw_circle(c + Vector2(3, -3), 2.0, Color(0.25, 0.45, 0.8))
		"masori_body":
			_robe(ci, c, Color(0.2, 0.35, 0.65), GOLD, Color(0.85, 0.7, 0.3))
		"masori_mask":
			ci.draw_colored_polygon(PackedVector2Array([c + Vector2(-10, -8), c + Vector2(10, -8), c + Vector2(8, 8), c + Vector2(0, 13),
					c + Vector2(-8, 8)]), GOLD)
			ci.draw_rect(Rect2(c + Vector2(-7, -3), Vector2(5, 3)), Color(0.2, 0.35, 0.65))
			ci.draw_rect(Rect2(c + Vector2(2, -3), Vector2(5, 3)), Color(0.2, 0.35, 0.65))
			ci.draw_colored_polygon(PackedVector2Array([c + Vector2(-10, -8), c + Vector2(0, -15), c + Vector2(10, -8)]), Color(0.2, 0.35, 0.65))
		"lightbearer":
			ci.draw_arc(c + Vector2(0, 3), 8.0, 0.0, TAU, 20, GOLD, 3.0)
			ci.draw_circle(c + Vector2(0, -6), 6.0, Color(1, 0.95, 0.6, 0.35))
			ci.draw_circle(c + Vector2(0, -6), 3.5, Color(1, 1, 0.85))
		# --- Lumbridge dungeons ---
		"dragon_chainbody":
			_robe(ci, c, Color(0.75, 0.15, 0.12), Color(0.55, 0.1, 0.08), Color(0.75, 0.15, 0.12))
			for y in 4:
				for x in 4:
					ci.draw_circle(c + Vector2(-6 + x * 4, -4 + y * 4), 1.1, Color(0.45, 0.06, 0.05))
		"sarachnis_chitin_helm":
			ci.draw_circle(c + Vector2(0, 1), 11.0, Color(0.42, 0.32, 0.25))
			ci.draw_rect(Rect2(c + Vector2(-7, 0), Vector2(14, 3)), DARK)
			for side in [-1.0, 1.0]:
				ci.draw_line(c + Vector2(side * 7, -6), c + Vector2(side * 13, -14), Color(0.3, 0.22, 0.18), 2.0)
			for e in 3:
				ci.draw_circle(c + Vector2(-3 + e * 3, -5), 1.3, Color(0.9, 0.25, 0.2))
		"trident_of_the_seas":
			ci.draw_line(c + Vector2(-9, 13), c + Vector2(5, -5), Color(0.25, 0.55, 0.6), 2.5)
			for k in 3:
				var base := c + Vector2(5, -5) + Vector2(k - 1, k - 1) * Vector2(-3, 3)
				ci.draw_line(base, base + Vector2(6, -6), Color(0.5, 0.9, 0.9), 2.0)
			ci.draw_line(c + Vector2(2, -8), c + Vector2(8, -2), Color(0.5, 0.9, 0.9), 2.0)
		"fire_cape":
			ci.draw_colored_polygon(PackedVector2Array([c + Vector2(-6, -12), c + Vector2(6, -12), c + Vector2(12, 12), c + Vector2(-12, 12)]),
					Color(0.85, 0.3, 0.05))
			for k in 4:
				var x := -8.0 + k * 5.5
				ci.draw_colored_polygon(PackedVector2Array([c + Vector2(x - 2, 12), c + Vector2(x, 0 - k % 2 * 4), c + Vector2(x + 2, 12)]),
						Color(1, 0.8, 0.2))
			ci.draw_line(c + Vector2(-6, -12), c + Vector2(6, -12), Color(1, 0.6, 0.1), 2.0)
		# --- God Wars dungeons ---
		"crystal_helm":
			ci.draw_colored_polygon(PackedVector2Array([c + Vector2(-10, 10), c + Vector2(-11, -2), c + Vector2(-5, -12), c + Vector2(5, -12),
					c + Vector2(11, -2), c + Vector2(10, 10)]), Color(0.55, 0.9, 0.85, 0.9))
			ci.draw_line(c + Vector2(-5, -12), c + Vector2(0, 10), Color(0.85, 1, 0.95), 1.5)
			ci.draw_line(c + Vector2(5, -12), c + Vector2(0, 10), Color(0.85, 1, 0.95), 1.5)
			ci.draw_rect(Rect2(c + Vector2(-7, 1), Vector2(14, 3)), Color(0.2, 0.4, 0.4))
		"dragon_hunter_lance":
			ci.draw_line(c + Vector2(-11, 12), c + Vector2(2, -1), Color(0.35, 0.2, 0.15), 3.0)
			ci.draw_colored_polygon(PackedVector2Array([c + Vector2(0, 1), c + Vector2(13, -13), c + Vector2(4, 3)]), STEEL)
			ci.draw_line(c + Vector2(-3, -2), c + Vector2(5, 6), Color(0.8, 0.15, 0.1), 2.5)
		"primordial_boots":
			for side in [-1.0, 1.0]:
				ci.draw_rect(Rect2(c + Vector2(side * 6 - 3, -11), Vector2(6, 15)), Color(0.25, 0.2, 0.22))
				ci.draw_rect(Rect2(c + Vector2(side * 6 - 3 + side * 2, 3), Vector2(8, 6)), Color(0.2, 0.15, 0.18))
				ci.draw_circle(c + Vector2(side * 6, -4), 2.2, Color(0.9, 0.2, 0.2))
		"inquisitors_hauberk":
			_robe(ci, c, Color(0.5, 0.5, 0.52), Color(0.35, 0.33, 0.3), Color(0.65, 0.12, 0.12))
		# --- Wilderness dungeons ---
		"dragonfire_shield":
			ci.draw_colored_polygon(PackedVector2Array([c + Vector2(-11, -12), c + Vector2(11, -12), c + Vector2(10, 4), c + Vector2(0, 14),
					c + Vector2(-10, 4)]), Color(0.45, 0.45, 0.48))
			# The draconic visage: horns, eyes and snout.
			ci.draw_colored_polygon(PackedVector2Array([c + Vector2(-7, -8), c + Vector2(-4, -3), c + Vector2(-8, -3)]), Color(0.25, 0.25, 0.27))
			ci.draw_colored_polygon(PackedVector2Array([c + Vector2(7, -8), c + Vector2(4, -3), c + Vector2(8, -3)]), Color(0.25, 0.25, 0.27))
			ci.draw_circle(c + Vector2(-3, 0), 1.6, Color(1, 0.5, 0.1))
			ci.draw_circle(c + Vector2(3, 0), 1.6, Color(1, 0.5, 0.1))
			ci.draw_colored_polygon(PackedVector2Array([c + Vector2(-3, 4), c + Vector2(3, 4), c + Vector2(0, 10)]), Color(0.3, 0.3, 0.32))
		"craws_bow":
			var limb := PackedVector2Array()
			for i in 11:
				var t := -1.0 + i / 5.0
				limb.append(c + Vector2(-5 + 6 * t * t, t * 12))
			ci.draw_polyline(limb, Color(0.2, 0.3, 0.25), 3.0)
			ci.draw_line(limb[0], limb[10], Color(0.55, 0.95, 0.85), 1.5)
			ci.draw_circle(c + Vector2(-5, 0), 3.0, Color(0.45, 0.95, 0.85, 0.7))
		"abyssal_crown":
			ci.draw_rect(Rect2(c + Vector2(-11, -2), Vector2(22, 10)), Color(0.45, 0.1, 0.15))
			for k in 5:
				var x := -10.0 + k * 5.0
				ci.draw_colored_polygon(PackedVector2Array([c + Vector2(x - 2, -2), c + Vector2(x, -12 + (k % 2) * 4), c + Vector2(x + 2, -2)]),
						Color(0.55, 0.12, 0.18))
			for e in 4:
				ci.draw_circle(c + Vector2(-7.5 + e * 5, 3), 1.6, Color(1, 0.8, 0.3))
		"malediction_ward":
			ci.draw_colored_polygon(PackedVector2Array([c + Vector2(-10, -12), c + Vector2(10, -12), c + Vector2(9, 4), c + Vector2(0, 13),
					c + Vector2(-9, 4)]), Color(0.25, 0.15, 0.3))
			ci.draw_arc(c + Vector2(0, -1), 6.0, PI * 1.1, PI * 1.9, 8, Color(0.5, 0.85, 0.3), 2.0)
			ci.draw_circle(c + Vector2(0, -1), 2.5, Color(0.5, 0.85, 0.3))
			ci.draw_line(c + Vector2(-8, 6), c + Vector2(8, 6), Color(0.5, 0.85, 0.3), 1.5)


## A chest piece with shoulders, a trim line and a central emblem.
static func _robe(ci: CanvasItem, c: Vector2, body: Color, trim: Color, emblem: Color) -> void:
	ci.draw_colored_polygon(PackedVector2Array([c + Vector2(-12, -9), c + Vector2(-5, -12), c + Vector2(0, -8), c + Vector2(5, -12),
			c + Vector2(12, -9), c + Vector2(9, 12), c + Vector2(-9, 12)]), body)
	ci.draw_line(c + Vector2(0, -8), c + Vector2(0, 12), trim, 2.0)
	ci.draw_line(c + Vector2(-9, 10), c + Vector2(9, 10), trim, 2.0)
	ci.draw_circle(c + Vector2(0, -1), 2.5, emblem)
