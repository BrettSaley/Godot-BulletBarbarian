class_name Items
extends RefCounted
## Item definitions and loot rolls. Items are plain Dictionaries:
##   {name, slot ("weapon" | "ability" | "armor" | "ring"), tier, ...stats}
## Tiers follow OSRS metals: Bronze (0) to Dragon (6). Bronze is starting gear
## only and never drops. Open-world monsters drop Iron-Adamant (better further
## from Lumbridge); world bosses and the Chambers of Xeric drop Rune/Dragon and
## untiered uniques (UT, white bags).

const TIER_NAMES := ["Bronze", "Iron", "Steel", "Mithril", "Adamant", "Rune", "Dragon"]
const MAX_TIER := 6
const UT := 7
const TIER_COLORS := [
	Color(0.8, 0.52, 0.28),   # Bronze
	Color(0.58, 0.58, 0.6),   # Iron
	Color(0.78, 0.8, 0.84),   # Steel
	Color(0.42, 0.45, 0.85),  # Mithril
	Color(0.35, 0.62, 0.38),  # Adamant
	Color(0.35, 0.75, 0.85),  # Rune
	Color(0.9, 0.22, 0.16),   # Dragon
	Color(1, 1, 1),           # Untiered unique
]
## Rings use OSRS gems instead of metals.
const GEM_NAMES := ["Sapphire", "Emerald", "Ruby", "Diamond", "Dragonstone", "Onyx", "Zenyte"]
const GEM_COLORS := [
	Color(0.25, 0.4, 0.95), Color(0.25, 0.8, 0.35), Color(0.9, 0.2, 0.25), Color(0.92, 0.95, 1.0),
	Color(0.7, 0.3, 0.9), Color(0.25, 0.22, 0.28), Color(1.0, 0.6, 0.2),
]

const WEAPON_DAMAGE := [[20, 35], [30, 50], [45, 70], [60, 90], [80, 115], [105, 145], [135, 180]]
const ARMOR_DEFENSE := [2, 5, 8, 11, 14, 18, 22]
const ARMOR_HP := [0, 10, 20, 30, 45, 60, 80]
const RING_STATS := ["hp", "mp", "attack", "defense", "speed", "dexterity", "vitality"]
const STAT_LABELS := {
	"hp": "HP", "mp": "MP", "attack": "Attack", "defense": "Defense",
	"speed": "Speed", "dexterity": "Dexterity", "vitality": "Vitality",
}

## RotMG-style bag colours: brown, pink, purple, then white for uniques.
const BAG_COLORS := {"brown": Color(0.55, 0.38, 0.22), "pink": Color(0.95, 0.5, 0.75),
		"purple": Color(0.6, 0.3, 0.85), "white": Color(0.97, 0.97, 1.0)}


static func weapon(tier: int) -> Dictionary:
	return {
		"name": "%s Thrownaxe" % TIER_NAMES[tier], "slot": "weapon", "tier": tier,
		"damage_min": WEAPON_DAMAGE[tier][0], "damage_max": WEAPON_DAMAGE[tier][1],
		"shots": 2 if tier >= 5 else 1,
		"range": 360.0 + tier * 20.0,
	}


## Full helms hold the barbarian's Warcry ability.
static func helm(tier: int) -> Dictionary:
	return {
		"name": "%s Full Helm" % TIER_NAMES[tier], "slot": "ability", "tier": tier,
		"stats": {"defense": tier / 2},
		"warcry": {"duration": 3.0 + 0.5 * tier, "damage_bonus": 0.2 + 0.05 * tier, "speed_bonus": 0.2, "mp_cost": 40 + 5 * tier},
	}


static func armor(tier: int) -> Dictionary:
	return {
		"name": "%s Platebody" % TIER_NAMES[tier], "slot": "armor", "tier": tier,
		"stats": {"defense": ARMOR_DEFENSE[tier], "hp": ARMOR_HP[tier]},
	}


static func ring(tier: int, stat: String = "") -> Dictionary:
	if stat == "":
		stat = RING_STATS.pick_random()
	var amount := 20 * (tier + 1) if stat in ["hp", "mp"] else tier + 1
	return {
		"name": "%s Ring (%s)" % [GEM_NAMES[tier], STAT_LABELS[stat]], "slot": "ring", "tier": tier,
		"stats": {stat: amount}, "color": GEM_COLORS[tier],
	}


## Any drop is at least Iron (tier 1); Bronze is reserved for starting gear.
static func random_item(tier: int) -> Dictionary:
	tier = clampi(tier, 1, MAX_TIER)
	match randi() % 4:
		0:
			return weapon(tier)
		1:
			return helm(tier)
		2:
			return armor(tier)
	return ring(tier)


## Open-world monster drops over the seven zones (0-6): Iron around Lumbridge,
## Steel and Mithril through the middle, Adamant in the Deep Wilderness, with a
## 25% chance of one tier better (never above Adamant).
static func roll_monster_drop(zone_tier: int) -> Array:
	if randf() > 0.3 + 0.03 * zone_tier:
		return []
	var tier := 1 + zone_tier / 2 + (1 if randf() < 0.25 else 0)
	return [random_item(clampi(tier, 1, 4))]


## World boss drops: Rune/Dragon gear, plus a chance at that boss's unique.
static func roll_boss_drop(boss_name: String) -> Array:
	var drops := []
	for i in randi_range(2, 3):
		drops.append(random_item(randi_range(4, 6)))
	var boss_uniques: Array = BOSS_UNIQUES.get(boss_name, [])
	if not boss_uniques.is_empty() and randf() < 0.3:
		drops.push_front(unique(boss_uniques.pick_random()))
	return drops


## The Chambers of Xeric chest: Rune/Dragon gear and a chance at a purple.
static func raid_chest_loot() -> Array:
	var loot := []
	for i in randi_range(2, 3):
		loot.append(random_item(randi_range(5, 6)))
	if randf() < PURPLE_CHANCE:
		loot.push_front(unique(COX_UNIQUES.pick_random()))
	return loot


const PURPLE_CHANCE := 0.25
const COX_UNIQUES := ["twisted_bow", "elder_maul", "dragon_claws", "dinhs_bulwark", "ancestral_hat"]
const BOSS_UNIQUES := {
	"Zulrah": ["toxic_blowpipe", "serpentine_helm"],
	"Vorkath": ["dragonfire_shield", "vorkaths_head"],
	"Giant Mole": ["mole_claws"],
}


## Untiered uniques from world bosses and the raid. Weapons change how the
## barbarian attacks; helms change the Warcry.
static func unique(id: String) -> Dictionary:
	var item: Dictionary
	match id:
		"twisted_bow":
			item = {"name": "Twisted Bow", "slot": "weapon", "style": Projectiles.Style.ARROW,
					"damage_min": 85, "damage_max": 120, "shots": 1, "range": 640.0, "speed": 820.0, "rate": 1.3,
					"note": "Chambers of Xeric. Long range, fast arrows."}
		"elder_maul":
			item = {"name": "Elder Maul", "slot": "weapon", "style": Projectiles.Style.MAUL,
					"damage_min": 280, "damage_max": 360, "shots": 1, "range": 300.0, "speed": 480.0, "rate": 0.45,
					"note": "Chambers of Xeric. Slow, crushing blows."}
		"dragon_claws":
			item = {"name": "Dragon Claws", "slot": "weapon", "style": Projectiles.Style.CLAW,
					"damage_min": 45, "damage_max": 60, "shots": 4, "spread": 0.07, "range": 320.0,
					"note": "Chambers of Xeric. Four slashes at once."}
		"dinhs_bulwark":
			item = {"name": "Dinh's Bulwark", "slot": "armor", "stats": {"defense": 28, "hp": 120, "speed": -3},
					"note": "Chambers of Xeric. A wall of dragon metal."}
		"ancestral_hat":
			item = {"name": "Ancestral Hat", "slot": "ability", "stats": {"mp": 60, "defense": 3},
					"warcry": {"duration": 5.0, "damage_bonus": 0.4, "speed_bonus": 0.25, "mp_cost": 60, "heal": 120},
					"note": "Chambers of Xeric. Warcry also heals."}
		"toxic_blowpipe":
			item = {"name": "Toxic Blowpipe", "slot": "weapon", "style": Projectiles.Style.ARROW,
					"damage_min": 30, "damage_max": 42, "shots": 1, "range": 420.0, "speed": 760.0, "rate": 2.4,
					"note": "Zulrah. Sprays darts very quickly."}
		"serpentine_helm":
			item = {"name": "Serpentine Helm", "slot": "ability", "stats": {"defense": 5, "vitality": 4},
					"warcry": {"duration": 6.0, "damage_bonus": 0.35, "speed_bonus": 0.2, "mp_cost": 55},
					"note": "Zulrah. A long, venomous Warcry."}
		"dragonfire_shield":
			item = {"name": "Dragonfire Shield", "slot": "armor", "stats": {"defense": 22, "hp": 80, "vitality": 5},
					"note": "Vorkath. Wards off dragonfire."}
		"vorkaths_head":
			item = {"name": "Vorkath's Head", "slot": "ring", "stats": {"attack": 6, "dexterity": 4},
					"note": "Vorkath. A grim trophy that sharpens your aim."}
		"mole_claws":
			item = {"name": "Mole Claws", "slot": "weapon", "style": Projectiles.Style.CLAW,
					"damage_min": 55, "damage_max": 75, "shots": 3, "spread": 0.1, "range": 300.0,
					"note": "Giant Mole. Dig in and tear."}
		_:
			return weapon(0)
	item.tier = UT
	return item


static func color_of(item: Dictionary) -> Color:
	return item.get("color", TIER_COLORS[item.tier])


static func tier_label(item: Dictionary) -> String:
	return "UT" if item.tier == UT else "T%d" % item.tier


## RotMG bag colour for the best item inside.
static func bag_color(items: Array) -> Color:
	var best := 0
	for item in items:
		best = maxi(best, item.tier)
	if best >= UT:
		return BAG_COLORS.white
	if best >= 5:
		return BAG_COLORS.purple
	if best >= 3:
		return BAG_COLORS.pink
	return BAG_COLORS.brown


static func describe(item: Dictionary) -> String:
	var tier_text := "Untiered" if item.tier == UT else "Tier %d, %s" % [item.tier, TIER_NAMES[item.tier]]
	var lines: Array[String] = ["%s  (%s)" % [item.name, tier_text]]
	if item.has("note"):
		lines.append(item.note)
	if item.slot == "weapon":
		lines.append("Damage: %d-%d" % [item.damage_min, item.damage_max])
		if item.get("rate", 1.0) != 1.0:
			lines.append("Attack speed: x%.2f" % item.rate)
		if item.shots > 1:
			lines.append("Shots: %d" % item.shots)
		lines.append("Range: %d" % item.range)
	if item.has("warcry"):
		var w: Dictionary = item.warcry
		lines.append("Warcry (Space, %d MP): +%d%% damage, +%d%% speed for %.1fs" % [
			w.mp_cost, roundi(w.damage_bonus * 100), roundi(w.speed_bonus * 100), w.duration])
		if w.has("heal"):
			lines.append("  and heals %d HP" % w.heal)
	for stat in item.get("stats", {}):
		var amount: int = item.stats[stat]
		if amount != 0:
			lines.append("%+d %s" % [amount, STAT_LABELS[stat]])
	lines.append("")
	lines.append("Click: equip / take    Right-click: drop")
	return "\n".join(lines)


## Small drawn icon for an item, centred at `center`, roughly 32px across.
static func draw_icon(ci: CanvasItem, item: Dictionary, center: Vector2) -> void:
	var color := color_of(item)
	match item.slot:
		"weapon" when item.get("style") == Projectiles.Style.ARROW:
			ci.draw_arc(center + Vector2(-4, 0), 13.0, -1.2, 1.2, 12, color, 3.0)
			ci.draw_line(center + Vector2(0.8, -12), center + Vector2(0.8, 12), Color(0.9, 0.9, 0.9), 1.0)
			ci.draw_line(center + Vector2(-10, 0), center + Vector2(10, 0), Color(0.5, 0.32, 0.15), 1.5)
		"weapon" when item.get("style") == Projectiles.Style.MAUL:
			ci.draw_line(center + Vector2(-9, 11), center + Vector2(4, -4), Color(0.5, 0.32, 0.15), 3.0)
			ci.draw_rect(Rect2(center + Vector2(-1, -13), Vector2(14, 11)), color)
		"weapon" when item.get("style") == Projectiles.Style.CLAW:
			for k in 3:
				ci.draw_colored_polygon(PackedVector2Array([center + Vector2(-8 + k * 6, 10),
						center + Vector2(-4 + k * 6, -12), center + Vector2(-3 + k * 6, 10)]), color)
		"weapon":
			ci.draw_line(center + Vector2(-9, 11), center + Vector2(5, -7), Color(0.5, 0.32, 0.15), 3.0)
			ci.draw_colored_polygon(PackedVector2Array([
				center + Vector2(1, -12), center + Vector2(12, -9), center + Vector2(10, 3), center + Vector2(4, -3)]), color)
		"ability":
			var dome := PackedVector2Array()
			for i in 11:
				dome.append(center + Vector2(0, 4) + Vector2.from_angle(PI + PI * i / 10.0) * 11.0)
			dome.append(center + Vector2(11, 10))
			dome.append(center + Vector2(-11, 10))
			ci.draw_colored_polygon(dome, color)
			ci.draw_rect(Rect2(center + Vector2(-7, 1), Vector2(14, 3)), Color(0.1, 0.1, 0.1))
			ci.draw_line(center + Vector2(0, 4), center + Vector2(0, 10), Color(0.1, 0.1, 0.1), 2.0)
		"armor":
			ci.draw_colored_polygon(PackedVector2Array([
				center + Vector2(-11, -9), center + Vector2(-4, -11), center + Vector2(0, -7), center + Vector2(4, -11),
				center + Vector2(11, -9), center + Vector2(9, 11), center + Vector2(-9, 11)]), color.darkened(0.2))
			ci.draw_line(center + Vector2(-9, 3), center + Vector2(9, 3), color.lightened(0.3), 2.0)
		"ring":
			ci.draw_arc(center + Vector2(0, 2), 8.0, 0.0, TAU, 20, Color(0.95, 0.8, 0.3), 3.0)
			ci.draw_circle(center + Vector2(0, -7), 4.0, color)
