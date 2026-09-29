class_name Items
extends RefCounted
## Item definitions and loot rolls. Items are plain Dictionaries:
##   {name, slot ("weapon" | "ability" | "armor" | "ring"), tier, ...stats}
## Tiers follow OSRS: the metals Bronze (0) to Dragon (7), then Barrows,
## Bandos, Armadyl, Oathplate and Torva (12), with real OSRS item names.
## Bronze is starting gear only and never drops. Each realm drops a band:
##   Lumbridge   monsters Iron-Adamant,     bosses Adamant-Dragon,   CoX chest Dragon
##   God Wars    monsters Rune-Barrows,     bosses Barrows-Armadyl,  ToB chest Armadyl
##   Wilderness  monsters Bandos-Oathplate, bosses Oathplate-Torva,  ToA chest Torva
## Dungeon uniques (UT, white bags) drop from dungeon bosses and sit just above
## their realm's best tier. Raid uniques are their own GIGA tier (gold bags),
## only from raid chests, better than anything else and all equally strong.

const TIER_NAMES := ["Bronze", "Iron", "Steel", "Black", "Mithril", "Adamant", "Rune", "Dragon",
		"Barrows", "Bandos", "Armadyl", "Oathplate", "Torva"]
const MAX_TIER := 12
## Dungeon uniques (one per dungeon, white bag).
const UT := 13
## Raid uniques: a tier of their own above everything (gold bag).
const GIGA := 14
## First tier past the metals; those items have their own OSRS names.
const FIRST_NAMED_TIER := 8
const TIER_COLORS := [
	Color(0.8, 0.52, 0.28),   # Bronze
	Color(0.58, 0.58, 0.6),   # Iron
	Color(0.78, 0.8, 0.84),   # Steel
	Color(0.25, 0.25, 0.28),  # Black
	Color(0.42, 0.45, 0.85),  # Mithril
	Color(0.35, 0.62, 0.38),  # Adamant
	Color(0.35, 0.75, 0.85),  # Rune
	Color(0.9, 0.22, 0.16),   # Dragon
	Color(0.5, 0.47, 0.42),   # Barrows
	Color(0.7, 0.55, 0.3),    # Bandos
	Color(0.92, 0.9, 0.78),   # Armadyl
	Color(0.85, 0.7, 0.35),   # Oathplate
	Color(0.55, 0.28, 0.2),   # Torva
	Color(1, 1, 1),           # UT: dungeon unique
	Color(1.0, 0.8, 0.25),    # GIGA: raid unique
]
const WEAPON_NAMES := ["Dharok's Greataxe", "Bandos Godsword", "Armadyl Godsword", "Soulreaper Axe", "Ancient Godsword"]
const HELM_NAMES := ["Dharok's Helm", "Neitiznot Faceguard", "Armadyl Helmet", "Oathplate Helm", "Torva Full Helm"]
const ARMOR_NAMES := ["Dharok's Platebody", "Bandos Chestplate", "Armadyl Chestplate", "Oathplate Chest", "Torva Platebody"]
## Rings: OSRS gem rings, then the boss rings past Zenyte.
const RING_NAMES := ["Opal", "Sapphire", "Emerald", "Ruby", "Diamond", "Dragonstone", "Onyx", "Zenyte",
		"Berserker", "Brimstone", "Venator", "Bellator", "Ultor"]
const RING_COLORS := [
	Color(0.95, 0.85, 0.9), Color(0.25, 0.4, 0.95), Color(0.25, 0.8, 0.35), Color(0.9, 0.2, 0.25),
	Color(0.92, 0.95, 1.0), Color(0.7, 0.3, 0.9), Color(0.25, 0.22, 0.28), Color(1.0, 0.6, 0.2),
	Color(0.85, 0.2, 0.2), Color(0.95, 0.45, 0.1), Color(0.45, 0.85, 0.35), Color(0.4, 0.6, 1.0), Color(0.95, 0.9, 0.7),
]

## Thrownaxes throw two at a time from Rune; the named heavy weapons throw
## one huge spinning blade instead.
const WEAPON_DAMAGE := [[20, 35], [30, 50], [45, 70], [55, 80], [65, 95], [85, 120], [110, 150], [140, 185],
		[340, 440], [400, 510], [470, 590], [540, 670], [620, 760]]
const ARMOR_DEFENSE := [2, 5, 8, 10, 12, 15, 18, 22, 26, 30, 34, 38, 42]
const ARMOR_HP := [0, 10, 20, 25, 35, 45, 60, 80, 100, 120, 145, 170, 200]
const RING_STATS := ["hp", "mp", "attack", "defense", "speed", "dexterity", "vitality"]
const STAT_LABELS := {
	"hp": "HP", "mp": "MP", "attack": "Attack", "defense": "Defense",
	"speed": "Speed", "dexterity": "Dexterity", "vitality": "Vitality",
}

## Tier bands each realm drops: [monster min, monster max, boss min, boss max, chest].
const REALM_TIERS := [[1, 5, 5, 7, 7], [6, 8, 8, 10, 10], [9, 11, 11, 12, 12]]
const PURPLE_CHANCE := 0.25
const RAID_UNIQUES := {
	"cox": ["twisted_bow", "elder_maul", "dragon_claws", "dinhs_bulwark", "ancestral_hat"],
	"tob": ["scythe_of_vitur", "ghrazi_rapier", "sanguinesti_staff", "justiciar_chestguard", "avernic_defender"],
	"toa": ["tumekens_shadow", "osmumtens_fang", "masori_body", "masori_mask", "lightbearer"],
}

## RotMG-style bag colours: brown, pink, purple, white for dungeon UTs and
## gold for raid GIGA items.
const BAG_COLORS := {"brown": Color(0.55, 0.38, 0.22), "pink": Color(0.95, 0.5, 0.75),
		"purple": Color(0.6, 0.3, 0.85), "white": Color(1, 1, 1), "gold": Color(1.0, 0.82, 0.3)}


static func weapon(tier: int) -> Dictionary:
	var item := {
		"name": "%s Thrownaxe" % TIER_NAMES[tier], "slot": "weapon", "tier": tier,
		"damage_min": WEAPON_DAMAGE[tier][0], "damage_max": WEAPON_DAMAGE[tier][1],
		"shots": 2 if tier >= 6 else 1,
		"range": 360.0 + mini(tier, 10) * 18.0,
	}
	if tier >= FIRST_NAMED_TIER:
		var named: String = WEAPON_NAMES[tier - FIRST_NAMED_TIER]
		item.name = named
		item.shots = 1
		item.size = 16.0
		item.style = Projectiles.Style.BLADE if "Godsword" in named else Projectiles.Style.AXE
	return item


## Helms hold the barbarian's Warcry ability.
static func helm(tier: int) -> Dictionary:
	var helm_name := "%s Full Helm" % TIER_NAMES[tier]
	if tier >= FIRST_NAMED_TIER:
		helm_name = HELM_NAMES[tier - FIRST_NAMED_TIER]
	return {
		"name": helm_name, "slot": "ability", "tier": tier,
		"stats": {"defense": tier / 2},
		"warcry": {"duration": 3.0 + 0.3 * tier, "damage_bonus": 0.2 + 0.035 * tier, "speed_bonus": 0.2, "mp_cost": 40 + 3 * tier},
	}


static func armor(tier: int) -> Dictionary:
	var armor_name := "%s Platebody" % TIER_NAMES[tier]
	if tier >= FIRST_NAMED_TIER:
		armor_name = ARMOR_NAMES[tier - FIRST_NAMED_TIER]
	return {
		"name": armor_name, "slot": "armor", "tier": tier,
		"stats": {"defense": ARMOR_DEFENSE[tier], "hp": ARMOR_HP[tier]},
	}


static func ring(tier: int, stat: String = "") -> Dictionary:
	if stat == "":
		stat = RING_STATS.pick_random()
	var amount := 20 * (tier + 1) if stat in ["hp", "mp"] else tier + 1
	return {
		"name": "%s Ring (%s)" % [RING_NAMES[tier], STAT_LABELS[stat]], "slot": "ring", "tier": tier,
		"stats": {stat: amount}, "color": RING_COLORS[tier],
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


## Open-world monster drops: the realm's monster band, climbing across the
## seven zones (0-6), with a 25% chance of one tier better.
static func roll_monster_drop(zone_tier: int, realm := 0) -> Array:
	if randf() > 0.3 + 0.03 * zone_tier:
		return []
	var band: Array = REALM_TIERS[realm]
	var span: int = band[1] - band[0]
	var tier: int = band[0] + roundi(span * zone_tier / 6.0) + (1 if randf() < 0.25 else 0)
	return [random_item(clampi(tier, band[0], band[1]))]


## World boss drops: two or three items from the realm's boss band. World
## bosses never drop uniques; those only come from raid chests.
static func roll_boss_drop(realm := 0) -> Array:
	var band: Array = REALM_TIERS[realm]
	var drops := []
	for i in randi_range(2, 3):
		drops.append(random_item(randi_range(band[2], band[3])))
	return drops


## A raid chest: the realm's top tier, and a chance at one of that raid's
## GIGA uniques (the "purple").
static func raid_chest_loot(raid_id: String, realm: int) -> Array:
	var loot := []
	for i in randi_range(2, 3):
		loot.append(random_item(REALM_TIERS[realm][4]))
	if randf() < PURPLE_CHANCE:
		loot.push_front(unique(RAID_UNIQUES[raid_id].pick_random()))
	return loot


## Raid uniques. Weapons change how the barbarian attacks; helms change the
## Warcry. GIGA items are a huge step up - roughly double Torva, the best
## tiered gear - and all equally strong: weapons deal the same damage per second,
## armours and helms share one stat budget. They differ in how they play.
static func unique(id: String) -> Dictionary:
	var item: Dictionary
	match id:
		# --- Chambers of Xeric ---
		"twisted_bow":
			item = {"name": "Twisted Bow", "slot": "weapon", "style": Projectiles.Style.ARROW,
					"damage_min": 925, "damage_max": 1075, "shots": 1, "range": 640.0, "speed": 820.0, "rate": 1.3,
					"note": "Chambers of Xeric. Long range, fast arrows."}
		"elder_maul":
			item = {"name": "Elder Maul", "slot": "weapon", "style": Projectiles.Style.MAUL,
					"damage_min": 2670, "damage_max": 3105, "shots": 1, "range": 300.0, "speed": 480.0, "rate": 0.45,
					"note": "Chambers of Xeric. Slow, crushing blows."}
		"dragon_claws":
			item = {"name": "Dragon Claws", "slot": "weapon", "style": Projectiles.Style.CLAW,
					"damage_min": 303, "damage_max": 347, "shots": 4, "spread": 0.07, "range": 320.0,
					"note": "Chambers of Xeric. Four slashes at once."}
		"dinhs_bulwark":
			item = {"name": "Dinh's Bulwark", "slot": "armor", "stats": {"defense": 62, "hp": 380, "attack": 10},
					"note": "Chambers of Xeric. A wall of dragon metal that hits back."}
		"ancestral_hat":
			item = {"name": "Ancestral Hat", "slot": "ability", "stats": {"mp": 150, "defense": 14},
					"warcry": {"duration": 9.0, "damage_bonus": 1.1, "speed_bonus": 0.45, "mp_cost": 60, "heal": 300},
					"note": "Chambers of Xeric. Warcry also heals."}
		# --- Theatre of Blood ---
		"scythe_of_vitur":
			item = {"name": "Scythe of Vitur", "slot": "weapon", "style": Projectiles.Style.CLAW,
					"damage_min": 397, "damage_max": 469, "shots": 3, "spread": 0.3, "range": 330.0, "size": 18.0,
					"note": "Theatre of Blood. Three wide, sweeping slashes."}
		"ghrazi_rapier":
			item = {"name": "Ghrazi Rapier", "slot": "weapon", "style": Projectiles.Style.ARROW,
					"damage_min": 664, "damage_max": 780, "shots": 1, "range": 420.0, "speed": 900.0, "rate": 1.8,
					"note": "Theatre of Blood. Lightning-fast thrusts."}
		"sanguinesti_staff":
			item = {"name": "Sanguinesti Staff", "slot": "weapon", "style": Projectiles.Style.ORB,
					"damage_min": 1011, "damage_max": 1155, "shots": 1, "range": 560.0, "speed": 620.0, "rate": 1.2,
					"size": 14.0, "lifesteal": 0.08, "color": Color(0.85, 0.1, 0.15),
					"note": "Theatre of Blood. Blood magic heals you for 8% of damage dealt."}
		"justiciar_chestguard":
			item = {"name": "Justiciar Chestguard", "slot": "armor", "stats": {"defense": 62, "hp": 380, "vitality": 10},
					"note": "Theatre of Blood. Nearly impenetrable."}
		"avernic_defender":
			item = {"name": "Avernic Defender", "slot": "ring", "stats": {"attack": 22, "defense": 16, "hp": 250},
					"note": "Theatre of Blood. Hits harder, takes less."}
		# --- Tombs of Amascut ---
		"tumekens_shadow":
			item = {"name": "Tumeken's Shadow", "slot": "weapon", "style": Projectiles.Style.ORB,
					"damage_min": 1098, "damage_max": 1264, "shots": 1, "range": 620.0, "speed": 560.0, "rate": 1.1,
					"size": 20.0, "color": Color(0.4, 0.3, 0.9),
					"note": "Tombs of Amascut. Enormous orbs of shadow magic."}
		"osmumtens_fang":
			item = {"name": "Osmumten's Fang", "slot": "weapon", "style": Projectiles.Style.ARROW,
					"damage_min": 375, "damage_max": 436, "shots": 2, "spread": 0.05, "range": 400.0, "speed": 850.0, "rate": 1.6,
					"note": "Tombs of Amascut. Twin fangs that rarely miss."}
		"masori_body":
			item = {"name": "Masori Body", "slot": "armor", "stats": {"defense": 62, "hp": 380, "dexterity": 10},
					"note": "Tombs of Amascut. Armour of the gods' chosen."}
		"masori_mask":
			item = {"name": "Masori Mask", "slot": "ability", "stats": {"mp": 150, "defense": 14},
					"warcry": {"duration": 9.0, "damage_bonus": 1.1, "speed_bonus": 0.45, "mp_cost": 60, "heal": 300},
					"note": "Tombs of Amascut. The mightiest Warcry."}
		"lightbearer":
			item = {"name": "Lightbearer", "slot": "ring", "stats": {"mp": 250, "dexterity": 22, "attack": 16},
					"note": "Tombs of Amascut. Radiant, and quick to recover."}
		_:
			return weapon(0)
	item.tier = GIGA
	return item


static func color_of(item: Dictionary) -> Color:
	return item.get("color", TIER_COLORS[item.tier])


static func tier_label(item: Dictionary) -> String:
	match item.tier:
		GIGA:
			return "GIGA"
		UT:
			return "UT"
	return "T%d" % item.tier


## RotMG bag colour for the best item inside.
static func bag_color(items: Array) -> Color:
	var best := 0
	for item in items:
		best = maxi(best, item.tier)
	if best >= GIGA:
		return BAG_COLORS.gold
	if best >= UT:
		return BAG_COLORS.white
	if best >= 8:
		return BAG_COLORS.purple
	if best >= 5:
		return BAG_COLORS.pink
	return BAG_COLORS.brown


static func describe(item: Dictionary) -> String:
	var tier_text := "Tier %d, %s" % [item.tier, TIER_NAMES[item.tier]] if item.tier <= MAX_TIER else ("GIGA, raid unique" if item.tier == GIGA else "UT, dungeon unique")
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
		"weapon" when item.get("style") == Projectiles.Style.BLADE:
			ci.draw_line(center + Vector2(-9, 11), center + Vector2(9, -11), Color(0.85, 0.87, 0.92), 4.0)
			ci.draw_line(center + Vector2(-8, 3), center + Vector2(-2, 9), color, 3.0)
			ci.draw_circle(center + Vector2(-5, 6), 2.5, color.lightened(0.3))
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


## Each dungeon's one unique, and how likely its boss is to drop it.
const DUNGEON_UNIQUE_CHANCE := 0.2


## Dungeon uniques (UT): one per dungeon, a little better than their realm's
## best tiered gear. Lumbridge's beat Dragon, God Wars' beat Armadyl, and the
## Wilderness's beat Torva - but none reach the raids' GIGA items.
static func dungeon_unique(id: String) -> Dictionary:
	var item: Dictionary
	match id:
		# --- Lumbridge dungeons ---
		"dragon_chainbody":
			item = {"name": "Dragon Chainbody", "slot": "armor", "stats": {"defense": 24, "hp": 90, "dexterity": 2},
					"note": "Kalphite Queen. Light, strong dragon mail."}
		"sarachnis_cudgel":
			item = {"name": "Sarachnis Cudgel", "slot": "weapon", "style": Projectiles.Style.MAUL,
					"damage_min": 430, "damage_max": 505, "shots": 1, "range": 320.0, "speed": 500.0, "rate": 0.75,
					"note": "Sarachnis. A heavy spider-leg club."}
		"trident_of_the_seas":
			item = {"name": "Trident of the Seas", "slot": "weapon", "style": Projectiles.Style.ORB,
					"damage_min": 270, "damage_max": 315, "shots": 1, "range": 520.0, "speed": 640.0, "rate": 1.2,
					"size": 13.0, "color": Color(0.3, 0.8, 0.85),
					"note": "Kraken. Bolts of tidal magic."}
		"toktz_xil_ul":
			item = {"name": "Toktz-xil-ul", "slot": "weapon", "style": Projectiles.Style.AXE,
					"damage_min": 105, "damage_max": 128, "shots": 3, "spread": 0.12, "range": 400.0,
					"color": Color(0.95, 0.45, 0.1),
					"note": "TzTok-Jad. A fan of obsidian throwing rings."}
		# --- God Wars dungeons ---
		"blade_of_saeldor":
			item = {"name": "Blade of Saeldor", "slot": "weapon", "style": Projectiles.Style.BLADE,
					"damage_min": 370, "damage_max": 430, "shots": 1, "range": 380.0, "speed": 700.0, "rate": 1.4,
					"color": Color(0.55, 0.95, 0.85),
					"note": "Corrupted Hunllef. A crystal blade that never dulls."}
		"dragon_hunter_lance":
			item = {"name": "Dragon Hunter Lance", "slot": "weapon", "style": Projectiles.Style.ARROW,
					"damage_min": 255, "damage_max": 305, "shots": 2, "spread": 0.06, "range": 420.0, "speed": 760.0,
					"note": "Alchemical Hydra. Twin lance thrusts."}
		"infernal_axe":
			item = {"name": "Infernal Axe", "slot": "weapon", "style": Projectiles.Style.AXE,
					"damage_min": 510, "damage_max": 610, "shots": 1, "range": 420.0, "size": 16.0,
					"color": Color(1.0, 0.45, 0.1),
					"note": "Cerberus. Forged with a smouldering stone."}
		"inquisitors_great_helm":
			item = {"name": "Inquisitor's Great Helm", "slot": "ability", "stats": {"defense": 6, "hp": 40},
					"warcry": {"duration": 6.5, "damage_bonus": 0.6, "speed_bonus": 0.25, "mp_cost": 60},
					"note": "The Nightmare. A zealot's Warcry."}
		# --- Wilderness dungeons ---
		"dragonfire_shield":
			item = {"name": "Dragonfire Shield", "slot": "armor", "stats": {"defense": 44, "hp": 215, "vitality": 4},
					"note": "King Black Dragon. Forged from a draconic visage."}
		"craws_bow":
			item = {"name": "Craw's Bow", "slot": "weapon", "style": Projectiles.Style.ARROW,
					"damage_min": 485, "damage_max": 560, "shots": 1, "range": 600.0, "speed": 820.0, "rate": 1.4,
					"note": "Revenant Maledictus. Thrums with revenant ether."}
		"abyssal_bludgeon":
			item = {"name": "Abyssal Bludgeon", "slot": "weapon", "style": Projectiles.Style.MAUL,
					"damage_min": 1130, "damage_max": 1300, "shots": 1, "range": 300.0, "speed": 480.0, "rate": 0.6,
					"color": Color(0.6, 0.25, 0.3),
					"note": "Abyssal Sire. Crushes with abyssal force."}
		"malediction_ward":
			item = {"name": "Malediction Ward", "slot": "armor", "stats": {"defense": 43, "hp": 210, "attack": 5},
					"note": "Scorpia. A cursed ward."}
		_:
			return weapon(0)
	item.tier = UT
	return item


## A dungeon boss's drop: loot from the realm's boss band, plus sometimes the
## dungeon's unique in its own white bag.
static func roll_dungeon_drop(unique_id: String, realm: int) -> Dictionary:
	var unique_item = dungeon_unique(unique_id) if randf() < DUNGEON_UNIQUE_CHANCE else null
	return {"loot": roll_boss_drop(realm), "unique": unique_item}
