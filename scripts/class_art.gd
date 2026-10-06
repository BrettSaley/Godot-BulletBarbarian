class_name ClassArt
extends RefCounted
## The playable classes and how each one looks. For now every class plays the
## same as the Barbarian; only the art differs:
##   Barbarian - horned helmet, fur tunic, tiny axe (BarbarianArt)
##   Archer    - a hooded ranger with a longbow and a quiver of arrows
##   Mage      - a wizard in a pointed hat and robe, long beard, gem-topped staff
## A look is {option: index} into that class's colour choices; all classes
## share the same five options under class-specific names.

const ORDER := ["barbarian", "archer", "mage"]
const CLASSES := {
	"barbarian": {"name": "Barbarian",
			"labels": {"skin": "Skin", "beard": "Beard", "tunic": "Tunic", "helmet": "Helmet", "horns": "Horns"},
			"options": {}},
	"archer": {"name": "Archer",
			"labels": {"skin": "Skin", "beard": "Hair", "tunic": "Tunic", "helmet": "Hood", "horns": "Fletching"},
			"options": {
				"tunic": [Color(0.55, 0.38, 0.22), Color(0.3, 0.45, 0.25), Color(0.4, 0.4, 0.42), Color(0.22, 0.2, 0.2),
						Color(0.6, 0.2, 0.18), Color(0.3, 0.35, 0.55)],
				"helmet": [Color(0.25, 0.5, 0.22), Color(0.45, 0.3, 0.18), Color(0.4, 0.42, 0.45), Color(0.15, 0.15, 0.17),
						Color(0.65, 0.15, 0.15), Color(0.2, 0.3, 0.6)],
				"horns": [Color(0.95, 0.95, 0.92), Color(0.9, 0.25, 0.2), Color(0.95, 0.8, 0.3), Color(0.3, 0.5, 0.95),
						Color(0.15, 0.15, 0.15), Color(0.4, 0.8, 0.35)],
			}},
	"mage": {"name": "Mage",
			"labels": {"skin": "Skin", "beard": "Beard", "tunic": "Robe", "helmet": "Hat", "horns": "Gem"},
			"options": {
				"beard": [Color(0.92, 0.92, 0.9), Color(0.6, 0.6, 0.62), Color(0.93, 0.47, 0.16), Color(0.45, 0.28, 0.14),
						Color(0.15, 0.12, 0.1), Color(0.98, 0.85, 0.45)],
				"tunic": [Color(0.22, 0.3, 0.7), Color(0.45, 0.22, 0.6), Color(0.65, 0.15, 0.15), Color(0.2, 0.45, 0.3),
						Color(0.15, 0.13, 0.18), Color(0.88, 0.86, 0.8)],
				"helmet": [Color(0.22, 0.3, 0.7), Color(0.45, 0.22, 0.6), Color(0.65, 0.15, 0.15), Color(0.2, 0.45, 0.3),
						Color(0.15, 0.13, 0.18), Color(0.88, 0.86, 0.8)],
				"horns": [Color(0.4, 0.9, 1.0), Color(1.0, 0.3, 0.3), Color(0.4, 1.0, 0.45), Color(1.0, 0.85, 0.3),
						Color(0.8, 0.45, 1.0), Color(1, 1, 1)],
			}},
}
const WOOD := Color(0.5, 0.32, 0.15)
## The one weapon type each class can wield.
const WEAPON_TYPE := {"barbarian": "axe", "archer": "bow", "mage": "staff"}


static func weapon_type(cls: String) -> String:
	return WEAPON_TYPE.get(cls, "axe")


## The one ability item type each class can use (it powers that class's special).
const ABILITY_TYPE := {"barbarian": "helm", "archer": "ammo", "mage": "runes"}
const SPECIAL_NAMES := {"barbarian": "Warcry", "archer": "Power Shot", "mage": "Ice Barrage"}


static func ability_type(cls: String) -> String:
	return ABILITY_TYPE.get(cls, "helm")


static func class_for_ability(type: String) -> String:
	for cls in ABILITY_TYPE:
		if ABILITY_TYPE[cls] == type:
			return cls
	return "barbarian"


static func class_for_weapon(type: String) -> String:
	for cls in WEAPON_TYPE:
		if WEAPON_TYPE[cls] == type:
			return cls
	return "barbarian"


static func class_name_of(cls: String) -> String:
	return CLASSES.get(cls, CLASSES.barbarian).name


static func label(cls: String, option: String) -> String:
	return CLASSES.get(cls, CLASSES.barbarian).labels[option]


## The colour choices for one option of a class (falling back to the Barbarian's).
static func options(cls: String, option: String) -> Array:
	return CLASSES.get(cls, CLASSES.barbarian).options.get(option, BarbarianArt.LOOK_OPTIONS[option])


static func palette_for(cls: String, look: Dictionary) -> Dictionary:
	var p := BarbarianArt.HERO.duplicate()
	var pick := func(option: String) -> Color:
		var choices := options(cls, option)
		return choices[clampi(int(look.get(option, 0)), 0, choices.size() - 1)]
	p.skin = pick.call("skin")
	p.beard = pick.call("beard")
	p.fur = pick.call("tunic")
	p.helmet = pick.call("helmet")
	p.rim = p.helmet.darkened(0.25)
	p.horn = pick.call("horns")
	return p


static func random_look(cls: String) -> Dictionary:
	var look := {}
	for option in BarbarianArt.LOOK_OPTIONS:
		look[option] = randi() % options(cls, option).size()
	return look


## Draw a class at `origin`, the same way BarbarianArt.draw does.
static func draw(ci: CanvasItem, cls: String, palette: Dictionary, bob: float, tilt: float, facing: float,
		size := 1.0, origin := Vector2.ZERO) -> void:
	if not palette.has("helmet"):
		palette = palette_for(cls, {})
	match cls:
		"archer":
			_begin(ci, bob, tilt, facing, size, origin)
			_draw_archer(ci, palette)
		"mage":
			_begin(ci, bob, tilt, facing, size, origin)
			_draw_mage(ci, palette)
		_:
			BarbarianArt.draw(ci, palette, bob, tilt, facing, size, origin)
			return
	ci.draw_set_transform(Vector2.ZERO)


## Ground shadow, then the body transform (drawn facing right).
static func _begin(ci: CanvasItem, bob: float, tilt: float, facing: float, size: float, origin: Vector2) -> void:
	ci.draw_set_transform(origin + Vector2(0, 17) * size, 0.0, Vector2(size, size * 0.35))
	ci.draw_circle(Vector2.ZERO, 11.0, Color(0, 0, 0, 0.3))
	ci.draw_set_transform(origin + Vector2(0, bob) * size, tilt, Vector2(facing * size, size))


## Big sparkly chibi eyes with determined brows, shared by both classes.
static func _face(ci: CanvasItem, p: Dictionary, y: float) -> void:
	ci.draw_circle(Vector2(-3, y), 2.8, p.dark)
	ci.draw_circle(Vector2(5, y), 2.8, p.dark)
	ci.draw_circle(Vector2(-2.2, y - 1), 1.0, p.eye_shine)
	ci.draw_circle(Vector2(5.8, y - 1), 1.0, p.eye_shine)
	ci.draw_line(Vector2(-6.5, y - 4.5), Vector2(-1, y - 3), p.dark, 1.6)
	ci.draw_line(Vector2(8.5, y - 4.5), Vector2(3, y - 3), p.dark, 1.6)
	ci.draw_circle(Vector2(-6.5, y + 3), 1.7, p.cheeks)
	ci.draw_circle(Vector2(8.5, y + 3), 1.7, p.cheeks)


static func _draw_archer(ci: CanvasItem, p: Dictionary) -> void:
	var leather := Color(0.35, 0.22, 0.12)
	# Quiver on the back, arrows poking up behind the shoulder
	ci.draw_colored_polygon(PackedVector2Array([Vector2(-12, -6), Vector2(-7, -8), Vector2(-3, 8), Vector2(-8, 10)]), leather)
	for k in 3:
		var tip := Vector2(-12.5 + k * 2.2, -13 + k * 0.8)
		ci.draw_line(tip + Vector2(1.5, 5), tip, WOOD.lightened(0.2), 1.0)
		ci.draw_colored_polygon(PackedVector2Array([tip + Vector2(-1.5, 0), tip + Vector2(0, -3.5), tip + Vector2(1.5, 0)]), p.horn)
	# Boots and tunic with a belt
	ci.draw_circle(Vector2(-4, 14), 3.2, leather)
	ci.draw_circle(Vector2(4, 14), 3.2, leather)
	ci.draw_circle(Vector2(0, 7), 8.0, p.fur)
	ci.draw_line(Vector2(-7.5, 9), Vector2(7.5, 9), leather, 2.0)
	ci.draw_line(Vector2(-6, 0), Vector2(5, 9), leather, 1.5)  # quiver strap
	ci.draw_circle(Vector2(0, 9), 1.4, p.gold)
	# Longbow held out in front, string pulled taut
	ci.draw_arc(Vector2(6, 4), 14.0, -1.15, 1.15, 16, WOOD, 2.2)
	ci.draw_line(Vector2(6, 4) + Vector2.from_angle(-1.15) * 14.0, Vector2(6, 4) + Vector2.from_angle(1.15) * 14.0,
			Color(0.9, 0.9, 0.85), 0.8)
	ci.draw_circle(Vector2(-8, 7), 3.0, p.skin)
	ci.draw_circle(Vector2(19, 4), 3.0, p.skin)
	# Hood draping to the shoulders, with a point at the back
	ci.draw_colored_polygon(PackedVector2Array([Vector2(-13, -2), Vector2(-14, -12), Vector2(-17, -16), Vector2(-9, -17),
			Vector2(-2, -19), Vector2(7, -18), Vector2(12, -11), Vector2(13, -2), Vector2(9, 1), Vector2(-9, 1)]), p.helmet)
	# Face peeking out of the hood
	ci.draw_circle(Vector2(1, -5), 9.0, p.skin)
	ci.draw_colored_polygon(PackedVector2Array([Vector2(-7, -9), Vector2(-4, -13), Vector2(2, -14.5), Vector2(8, -12),
			Vector2(9, -9), Vector2(5, -11), Vector2(1, -10.5), Vector2(-3, -11)]), p.beard)  # hair fringe
	ci.draw_arc(Vector2(1, -5), 9.5, -PI * 1.05, 0.05, 20, p.rim, 1.5)
	_face(ci, p, -5.5)
	ci.draw_arc(Vector2(1, -1.5), 2.2, 0.3, PI - 0.3, 8, p.dark, 1.2)  # small smile


static func _draw_mage(ci: CanvasItem, p: Dictionary) -> void:
	var robe_dark: Color = p.fur.darkened(0.25)
	# Staff in the front hand, topped with a glowing gem
	ci.draw_line(Vector2(12, 15), Vector2(15, -22), WOOD, 2.2)
	ci.draw_circle(Vector2(15.2, -24), 5.0, Color(p.horn, 0.3))
	ci.draw_circle(Vector2(15.2, -24), 3.0, p.horn)
	ci.draw_circle(Vector2(14.4, -25), 1.0, Color(1, 1, 1, 0.9))
	# Long robe down to the feet, with trim and a rope belt
	ci.draw_colored_polygon(PackedVector2Array([Vector2(-7, -1), Vector2(7, -1), Vector2(11, 16), Vector2(-11, 16)]), p.fur)
	ci.draw_line(Vector2(-11, 15.5), Vector2(11, 15.5), p.horn.lerp(p.gold, 0.5), 1.5)
	ci.draw_line(Vector2(0, 0), Vector2(0, 15), robe_dark, 1.2)
	ci.draw_line(Vector2(-7.5, 6), Vector2(7.5, 6), p.gold.darkened(0.2), 1.5)
	# Sleeves and hands
	ci.draw_circle(Vector2(-8, 5), 3.6, robe_dark)
	ci.draw_circle(Vector2(-8.5, 7.5), 2.6, p.skin)
	ci.draw_circle(Vector2(12, 4), 3.0, p.skin)
	# Head
	ci.draw_circle(Vector2(0, -6), 10.0, p.skin)
	# Long wizard beard over the chest
	ci.draw_colored_polygon(PackedVector2Array([Vector2(-9, -4), Vector2(-7, 4), Vector2(-3, 10), Vector2(0, 14),
			Vector2(3, 10), Vector2(7, 4), Vector2(9, -4), Vector2(5, -1), Vector2(-5, -1)]), p.beard)
	ci.draw_line(Vector2(-2, 1), Vector2(-1, 9), p.beard.darkened(0.15), 1.0)
	ci.draw_line(Vector2(2.5, 1), Vector2(1.5, 9), p.beard.darkened(0.15), 1.0)
	_face(ci, p, -6)
	# Pointed hat with a wide brim, a band and a star
	ci.draw_colored_polygon(PackedVector2Array([Vector2(-16, -12), Vector2(-10, -15.5), Vector2(10, -15.5), Vector2(16, -12),
			Vector2(10, -10.5), Vector2(-10, -10.5)]), p.rim)
	ci.draw_colored_polygon(PackedVector2Array([Vector2(-9, -14), Vector2(-4, -26), Vector2(3, -34), Vector2(10, -36),
			Vector2(5, -29), Vector2(8, -14)]), p.helmet)
	ci.draw_line(Vector2(-8.5, -15.5), Vector2(8, -15.5), p.horn.lerp(p.gold, 0.5), 2.0)
	ci.draw_circle(Vector2(0, -22), 1.6, p.gold)
