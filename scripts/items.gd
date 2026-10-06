class_name Items
extends RefCounted
## Item definitions and loot rolls. Items are plain Dictionaries:
##   {name, slot ("weapon" | "ability" | "armor" | "ring"), tier, ...stats}
## Tiers follow OSRS: the metals Bronze (0) to Dragon (8) with White between
## Black and Mithril, then Barrows, the Guthix, Saradomin and Zamorak god
## armours, Armadyl, Bandos, Oathplate and Torva (16), with real OSRS names.
## Bronze is starting gear only and never drops. Each realm drops a band:
##   Lumbridge   monsters Iron-Dragon,    bosses Barrows-Guthix,  CoX chest Guthix
##   God Wars    monsters Rune-Zamorak,   bosses Armadyl-Bandos,  ToB chest Bandos
##   Wilderness  monsters Zamorak-Bandos, bosses Oathplate-Torva, ToA chest Torva
## Bosses (world and dungeon) drop the two tiers above their realm's best monster drop.
## Dungeon uniques (UT, white bags) drop from dungeon bosses and sit just above
## their realm's best tier. Raid uniques are their own GIGA tier (gold bags),
## only from raid chests, better than anything else and all equally strong.

const TIER_NAMES := ["Bronze", "Iron", "Steel", "Black", "White", "Mithril", "Adamant", "Rune", "Dragon",
		"Barrows", "Guthix", "Saradomin", "Zamorak", "Armadyl", "Bandos", "Oathplate", "Torva"]
const MAX_TIER := 16
## Dungeon uniques (one per dungeon, white bag).
const UT := 17
## Raid uniques: a tier of their own above everything (gold bag).
const GIGA := 18
## First tier past the metals; those items have their own OSRS names.
const FIRST_NAMED_TIER := 9
## Rune and Dragon thrownaxes throw two at a time.
const TWIN_AXE_TIER := 7
const TIER_COLORS := [
	Color(0.8, 0.52, 0.28),   # Bronze
	Color(0.58, 0.58, 0.6),   # Iron
	Color(0.78, 0.8, 0.84),   # Steel
	Color(0.25, 0.25, 0.28),  # Black
	Color(0.9, 0.9, 0.86),    # White
	Color(0.42, 0.45, 0.85),  # Mithril
	Color(0.35, 0.62, 0.38),  # Adamant
	Color(0.35, 0.75, 0.85),  # Rune
	Color(0.9, 0.22, 0.16),   # Dragon
	Color(0.5, 0.47, 0.42),   # Barrows
	Color(0.55, 0.78, 0.3),   # Guthix
	Color(0.55, 0.72, 1.0),   # Saradomin
	Color(0.62, 0.12, 0.28),  # Zamorak
	Color(0.92, 0.9, 0.78),   # Armadyl
	Color(0.7, 0.55, 0.3),    # Bandos
	Color(0.85, 0.7, 0.35),   # Oathplate
	Color(0.55, 0.28, 0.2),   # Torva
	Color(1, 1, 1),           # UT: dungeon unique
	Color(1.0, 0.8, 0.25),    # GIGA: raid unique
]
const WEAPON_NAMES := ["Dharok's Greataxe", "Guthix Mjolnir", "Saradomin Godsword", "Zamorak Godsword",
		"Armadyl Godsword", "Bandos Godsword", "Soulreaper Axe", "Ancient Godsword"]
## Weapon types and the class that uses each (see ClassArt.WEAPON_TYPE).
const WEAPON_TYPES := ["axe", "bow", "staff"]
## Bows and staves for every tier, Bronze to Torva.
const BOW_NAMES := ["Shortbow", "Oak Shortbow", "Willow Shortbow", "Maple Shortbow", "Maple Longbow",
		"Yew Shortbow", "Yew Longbow", "Magic Shortbow", "Dark Bow", "Karil's Crossbow", "Guthix Bow",
		"Saradomin Bow", "Zamorak Bow", "Armadyl Crossbow", "Heavy Ballista", "Venator Bow", "Zaryte Crossbow"]
const STAFF_NAMES := ["Staff", "Magic Staff", "Staff of Air", "Staff of Water", "Staff of Earth",
		"Staff of Fire", "Battlestaff", "Mystic Staff", "Ancient Staff", "Ahrim's Staff", "Guthix Staff",
		"Saradomin Staff", "Zamorak Staff", "Staff of Light", "Nightmare Staff", "Warped Sceptre", "Ancient Sceptre"]
const HELM_NAMES := ["Dharok's Helm", "Guthix Full Helm", "Saradomin Full Helm", "Zamorak Full Helm",
		"Armadyl Helmet", "Neitiznot Faceguard", "Oathplate Helm", "Torva Full Helm"]
const ARMOR_NAMES := ["Dharok's Platebody", "Guthix Platebody", "Saradomin Platebody", "Zamorak Platebody",
		"Armadyl Chestplate", "Bandos Chestplate", "Oathplate Chest", "Torva Platebody"]
## Rings: OSRS gem rings, then the Fremennik and boss rings past Zenyte.
const RING_NAMES := ["Opal", "Jade", "Sapphire", "Emerald", "Ruby", "Diamond", "Dragonstone", "Onyx", "Zenyte",
		"Berserker", "Seers", "Archers", "Warrior", "Venator", "Brimstone", "Bellator", "Ultor"]
const RING_COLORS := [
	Color(0.95, 0.85, 0.9), Color(0.45, 0.75, 0.45), Color(0.25, 0.4, 0.95), Color(0.25, 0.8, 0.35),
	Color(0.9, 0.2, 0.25), Color(0.92, 0.95, 1.0), Color(0.7, 0.3, 0.9), Color(0.25, 0.22, 0.28),
	Color(1.0, 0.6, 0.2), Color(0.85, 0.2, 0.2), Color(0.4, 0.8, 0.9), Color(0.4, 0.75, 0.3),
	Color(0.8, 0.5, 0.3), Color(0.45, 0.85, 0.35), Color(0.95, 0.45, 0.1), Color(0.4, 0.6, 1.0), Color(0.95, 0.9, 0.7),
]

## Thrownaxes throw two at a time from Rune; the named heavy weapons throw
## one huge spinning blade instead.
const WEAPON_DAMAGE := [[20, 35], [30, 50], [45, 70], [55, 80], [60, 88], [65, 95], [85, 120], [110, 150], [140, 185],
		[340, 440], [370, 475], [400, 510], [435, 550], [470, 590], [505, 630], [540, 670], [620, 760]]
const ARMOR_DEFENSE := [2, 5, 8, 10, 11, 12, 15, 18, 22, 26, 28, 30, 32, 34, 36, 38, 42]
const ARMOR_HP := [0, 10, 20, 25, 30, 35, 45, 60, 80, 100, 110, 120, 132, 145, 158, 170, 200]
## How strong each tier's helms and rings are, on a 0 (Bronze) to 12 (Torva) scale.
const POWER := [0, 1, 2, 3, 3.5, 4, 5, 6, 7, 8, 8.4, 8.8, 9.2, 9.6, 10, 11, 12]
const RING_STATS := ["hp", "mp", "attack", "defense", "speed", "dexterity", "vitality"]
const STAT_LABELS := {
	"hp": "HP", "mp": "MP", "attack": "Attack", "defense": "Defense",
	"speed": "Speed", "dexterity": "Dexterity", "vitality": "Vitality",
}

## Tier bands each realm drops: [monster min, monster max, boss min, boss max, chest].
const REALM_TIERS := [[1, 8, 9, 10, 10], [7, 12, 13, 14, 14], [12, 14, 15, 16, 16]]
const PURPLE_CHANCE := 0.5
## Each raid: one weapon per class (axe, bow, staff), then one armour, helm
## and accessory.
## Unique weapons that aren't axes. (Elder Maul, Ghrazi Rapier and Keris Partisan
## no longer drop but still load from older saves, as axes.)
const UNIQUE_WEAPON_TYPES := {"twisted_bow": "bow", "sanguine_longbow": "bow", "masori_longbow": "bow",
		"craws_bow": "bow", "kodai_wand": "staff", "sanguinesti_staff": "staff", "tumekens_shadow": "staff",
		"trident_of_the_seas": "staff"}
const RAID_UNIQUES := {
	"cox": ["twisted_bow", "dragon_claws", "kodai_wand", "ancestral_robe_top", "ancestral_hat", "twisted_buckler"],
	"tob": ["scythe_of_vitur", "sanguine_longbow", "sanguinesti_staff", "justiciar_chestguard", "justiciar_faceguard", "avernic_defender"],
	"toa": ["osmumtens_fang", "masori_longbow", "tumekens_shadow", "masori_body", "masori_mask", "lightbearer"],
}

## RotMG-style bag colours: brown, pink, purple, white for dungeon UTs and
## gold for raid GIGA items.
const BAG_COLORS := {"brown": Color(0.55, 0.38, 0.22), "pink": Color(0.95, 0.5, 0.75),
		"purple": Color(0.6, 0.3, 0.85), "white": Color(1, 1, 1), "gold": Color(1.0, 0.82, 0.3)}


## A tiered weapon of one type: axes for Barbarians, bows for Archers, staves
## for Mages. Every type deals the same damage at a tier; bows reach further
## with fast arrows, staves fire glowing orbs.
static func weapon(tier: int, type := "axe") -> Dictionary:
	var item := {
		"name": "%s Thrownaxe" % TIER_NAMES[tier], "slot": "weapon", "tier": tier, "weapon_type": type,
		"damage_min": WEAPON_DAMAGE[tier][0], "damage_max": WEAPON_DAMAGE[tier][1],
		"shots": 2 if tier >= TWIN_AXE_TIER else 1,
		"range": 360.0 + minf(POWER[tier], 10.0) * 18.0,
	}
	if tier >= FIRST_NAMED_TIER:
		item.shots = 1
		item.size = 16.0
	match type:
		"bow":
			item.name = BOW_NAMES[tier]
			item.style = Projectiles.Style.ARROW
			item.speed = 820.0
			item.range *= 1.2
			item.size = 12.0 if tier < FIRST_NAMED_TIER else 14.0
		"staff":
			item.name = STAFF_NAMES[tier]
			item.style = Projectiles.Style.ORB
			item.speed = 560.0
			item.size = 10.0 if tier < FIRST_NAMED_TIER else 14.0
		_:
			if tier >= FIRST_NAMED_TIER:
				var named: String = WEAPON_NAMES[tier - FIRST_NAMED_TIER]
				item.name = named
				item.style = Projectiles.Style.BLADE if "Godsword" in named else Projectiles.Style.AXE
	return item


## "axe", "bow" or "staff" (weapons from before types existed are axes).
static func weapon_type_of(item: Dictionary) -> String:
	return item.get("weapon_type", "axe")


## Helms power the class special (Warcry, Ice Barrage or Power Shot).
static func helm(tier: int) -> Dictionary:
	var helm_name := "%s Full Helm" % TIER_NAMES[tier]
	if tier >= FIRST_NAMED_TIER:
		helm_name = HELM_NAMES[tier - FIRST_NAMED_TIER]
	var p: float = POWER[tier]
	return {
		"name": helm_name, "slot": "ability", "tier": tier,
		"stats": {"defense": int(p / 2.0)},
		"warcry": {"duration": 3.0 + 0.3 * p, "damage_bonus": 0.2 + 0.035 * p, "speed_bonus": 0.2, "mp_cost": 40 + roundi(3 * p)},
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
	var p := roundi(POWER[tier])
	var amount := 20 * (p + 1) if stat in ["hp", "mp"] else p + 1
	return {
		"name": "%s Ring (%s)" % [RING_NAMES[tier], STAT_LABELS[stat]], "slot": "ring", "tier": tier,
		"stats": {stat: amount}, "color": RING_COLORS[tier],
	}


## Any drop is at least Iron (tier 1); Bronze is reserved for starting gear.
static func random_item(tier: int) -> Dictionary:
	tier = clampi(tier, 1, MAX_TIER)
	match randi() % 4:
		0:
			return weapon(tier, WEAPON_TYPES.pick_random())
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
		"ancestral_robe_top":
			item = {"name": "Ancestral Robe Top", "slot": "armor", "stats": {"defense": 62, "hp": 380, "attack": 10},
					"note": "Chambers of Xeric. Robes woven with ancient power."}
		"kodai_wand":
			item = {"name": "Kodai Wand", "slot": "weapon", "style": Projectiles.Style.ORB,
					"damage_min": 1250, "damage_max": 1350, "shots": 1, "range": 600.0, "speed": 600.0,
					"size": 15.0, "color": Color(0.45, 0.55, 1.0),
					"note": "Chambers of Xeric. Crackling ancient magic."}
		"twisted_buckler":
			item = {"name": "Twisted Buckler", "slot": "ring", "stats": {"dexterity": 22, "defense": 16, "hp": 250},
					"note": "Chambers of Xeric. A light, deadly off-hand."}
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
		"justiciar_faceguard":
			item = {"name": "Justiciar Faceguard", "slot": "ability", "stats": {"mp": 150, "defense": 14},
					"warcry": {"duration": 9.0, "damage_bonus": 1.1, "speed_bonus": 0.45, "mp_cost": 60, "heal": 300},
					"note": "Theatre of Blood. A guardian's Warcry."}
		"sanguine_longbow":
			item = {"name": "Sanguine Longbow", "slot": "weapon", "style": Projectiles.Style.ARROW,
					"damage_min": 860, "damage_max": 997, "shots": 1, "range": 660.0, "speed": 860.0, "rate": 1.4,
					"color": Color(0.85, 0.12, 0.15),
					"note": "Theatre of Blood. Arrows tipped in Verzik's blood."}
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
		"masori_longbow":
			item = {"name": "Masori Longbow", "slot": "weapon", "style": Projectiles.Style.ARROW,
					"damage_min": 485, "damage_max": 555, "shots": 2, "spread": 0.05, "range": 640.0, "speed": 840.0,
					"rate": 1.25, "color": Color(0.95, 0.8, 0.35),
					"note": "Tombs of Amascut. Twin arrows blessed by the sun."}
		"tumekens_shadow":
			item = {"name": "Tumeken's Shadow", "slot": "weapon", "style": Projectiles.Style.ORB,
					"damage_min": 1098, "damage_max": 1264, "shots": 1, "range": 620.0, "speed": 560.0, "rate": 1.1,
					"size": 20.0, "color": Color(0.4, 0.3, 0.9),
					"note": "Tombs of Amascut. Enormous orbs of shadow magic."}
		"osmumtens_fang":
			item = {"name": "Osmumten's Fang", "slot": "weapon", "style": Projectiles.Style.ARROW,
					"damage_min": 375, "damage_max": 436, "shots": 2, "spread": 0.05, "range": 400.0, "speed": 850.0, "rate": 1.6,
					"note": "Tombs of Amascut. Twin fangs that rarely miss."}
		"keris_partisan":
			item = {"name": "Keris Partisan of Breaching", "slot": "weapon", "style": Projectiles.Style.BLADE,
					"damage_min": 800, "damage_max": 935, "shots": 1, "range": 440.0, "speed": 760.0, "rate": 1.5,
					"color": Color(0.95, 0.8, 0.3),
					"note": "Tombs of Amascut. Breaches any defence."}
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
	if item.slot == "weapon":
		item.weapon_type = UNIQUE_WEAPON_TYPES.get(id, "axe")
	item.icon = id
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
	if best >= FIRST_NAMED_TIER:
		return BAG_COLORS.purple
	if best >= 6:
		return BAG_COLORS.pink
	return BAG_COLORS.brown


static func describe(item: Dictionary) -> String:
	var tier_text := "Tier %d, %s" % [item.tier, TIER_NAMES[item.tier]] if item.tier <= MAX_TIER else ("GIGA, raid unique" if item.tier == GIGA else "UT, dungeon unique")
	var lines: Array[String] = ["%s  (%s)" % [item.name, tier_text]]
	if item.has("note"):
		lines.append(item.note)
	if item.slot == "weapon":
		var type := weapon_type_of(item)
		lines.append("%s - %ss only" % [type.capitalize(), ClassArt.class_name_of(ClassArt.class_for_weapon(type))])
		lines.append("Damage: %d-%d" % [item.damage_min, item.damage_max])
		if item.get("rate", 1.0) != 1.0:
			lines.append("Attack speed: x%.2f" % item.rate)
		if item.shots > 1:
			lines.append("Shots: %d" % item.shots)
		lines.append("Range: %d" % item.range)
	if item.has("warcry"):
		var w: Dictionary = item.warcry
		lines.append("Special (Space, %d MP): power +%d%%, %.1fs" % [w.mp_cost, roundi(w.damage_bonus * 100), w.duration])
		lines.append("  Barbarian: Warcry - faster moving and throwing")
		lines.append("  Mage: Ice Barrage - blast and freeze an area")
		lines.append("  Archer: Power Shot - one huge, fast arrow")
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
	if UniqueIcons.has_icon(item.get("icon", "")):
		UniqueIcons.draw(ci, item.icon, center)
		return
	var color := color_of(item)
	match item.slot:
		"weapon" when weapon_type_of(item) == "staff":
			# A staff: a shaft with a glowing orb set in a little crown
			ci.draw_line(center + Vector2(-8, 12), center + Vector2(5, -7), Color(0.5, 0.32, 0.15), 3.0)
			ci.draw_line(center + Vector2(3, -5), center + Vector2(10, -12), Color(0.5, 0.32, 0.15), 1.5)
			ci.draw_line(center + Vector2(7, -9), center + Vector2(2, -13), Color(0.5, 0.32, 0.15), 1.5)
			ci.draw_circle(center + Vector2(6, -9), 5.5, Color(color, 0.35))
			ci.draw_circle(center + Vector2(6, -9), 3.5, color)
			ci.draw_circle(center + Vector2(5, -10), 1.2, Color(1, 1, 1, 0.8))
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
		"ring" when "Cape" in item.name:
			ci.draw_colored_polygon(PackedVector2Array([center + Vector2(-6, -11), center + Vector2(6, -11),
					center + Vector2(11, 11), center + Vector2(-11, 11)]), color)
			ci.draw_line(center + Vector2(-6, -11), center + Vector2(6, -11), color.lightened(0.4), 2.0)
		"ring" when "Boots" in item.name:
			for side in [-1.0, 1.0]:
				ci.draw_rect(Rect2(center + Vector2(side * 6 - 3, -10), Vector2(6, 14)), color)
				ci.draw_rect(Rect2(center + Vector2(side * 6 - 3 + side * 2, 2), Vector2(8, 5)), color.darkened(0.2))
		"ring" when item.tier >= UT and not "Ring" in item.name and item.name != "Lightbearer":
			# Off-hands: wards, bucklers, defenders.
			ci.draw_colored_polygon(PackedVector2Array([center + Vector2(-9, -10), center + Vector2(9, -10),
					center + Vector2(8, 4), center + Vector2(0, 12), center + Vector2(-8, 4)]), color)
			ci.draw_line(center + Vector2(0, -8), center + Vector2(0, 9), color.lightened(0.4), 2.0)
		"ring":
			ci.draw_arc(center + Vector2(0, 2), 8.0, 0.0, TAU, 20, Color(0.95, 0.8, 0.3), 3.0)
			ci.draw_circle(center + Vector2(0, -7), 4.0, color)


## Each dungeon's one unique, and how likely its boss is to drop it.
const DUNGEON_UNIQUE_CHANCE := 0.5


## Dungeon uniques (UT): one per dungeon, a little better than their realm's
## best tiered gear. Lumbridge's beat Guthix, God Wars' beat Bandos, and the
## Wilderness's beat Torva - but none reach the raids' GIGA items.
static func dungeon_unique(id: String) -> Dictionary:
	var item: Dictionary
	match id:
		# --- Lumbridge dungeons ---
		"dragon_chainbody":
			item = {"name": "Dragon Chainbody", "slot": "armor", "stats": {"defense": 30, "hp": 118, "dexterity": 2},
					"note": "Kalphite Queen. Light, strong dragon mail."}
		"sarachnis_chitin_helm":
			item = {"name": "Sarachnis Chitin Helm", "slot": "ability", "stats": {"defense": 5, "hp": 30},
					"warcry": {"duration": 6.0, "damage_bonus": 0.53, "speed_bonus": 0.2, "mp_cost": 60},
					"color": Color(0.45, 0.35, 0.3),
					"note": "Sarachnis. Carved from her shed carapace."}
		"trident_of_the_seas":
			item = {"name": "Trident of the Seas", "slot": "weapon", "style": Projectiles.Style.ORB,
					"damage_min": 350, "damage_max": 410, "shots": 1, "range": 520.0, "speed": 640.0, "rate": 1.2,
					"size": 13.0, "color": Color(0.3, 0.8, 0.85),
					"note": "Kraken. Bolts of tidal magic."}
		"fire_cape":
			item = {"name": "Fire Cape", "slot": "ring", "stats": {"attack": 8, "hp": 120},
					"color": Color(1.0, 0.45, 0.1),
					"note": "TzTok-Jad. Proof you survived the Fight Caves."}
		# --- God Wars dungeons ---
		"crystal_helm":
			item = {"name": "Crystal Helm", "slot": "ability", "stats": {"defense": 6, "dexterity": 3},
					"warcry": {"duration": 6.5, "damage_bonus": 0.6, "speed_bonus": 0.25, "mp_cost": 60},
					"color": Color(0.55, 0.95, 0.85),
					"note": "Corrupted Hunllef. Singing crystal, light as air."}
		"dragon_hunter_lance":
			item = {"name": "Dragon Hunter Lance", "slot": "weapon", "style": Projectiles.Style.ARROW,
					"damage_min": 275, "damage_max": 330, "shots": 2, "spread": 0.06, "range": 420.0, "speed": 760.0,
					"note": "Alchemical Hydra. Twin lance thrusts."}
		"primordial_boots":
			item = {"name": "Primordial Boots", "slot": "ring", "stats": {"attack": 9, "speed": 5},
					"color": Color(0.85, 0.25, 0.2),
					"note": "Cerberus. Boots set with a primordial crystal."}
		"inquisitors_hauberk":
			item = {"name": "Inquisitor's Hauberk", "slot": "armor", "stats": {"defense": 38, "hp": 168, "attack": 3},
					"note": "The Nightmare. A zealot's armour."}
		# --- Wilderness dungeons ---
		"dragonfire_shield":
			item = {"name": "Dragonfire Shield", "slot": "armor", "stats": {"defense": 44, "hp": 215, "vitality": 4},
					"note": "King Black Dragon. Forged from a draconic visage."}
		"craws_bow":
			item = {"name": "Craw's Bow", "slot": "weapon", "style": Projectiles.Style.ARROW,
					"damage_min": 485, "damage_max": 560, "shots": 1, "range": 600.0, "speed": 820.0, "rate": 1.4,
					"note": "Revenant Maledictus. Thrums with revenant ether."}
		"abyssal_crown":
			item = {"name": "Abyssal Crown", "slot": "ability", "stats": {"defense": 7, "hp": 60},
					"warcry": {"duration": 7.0, "damage_bonus": 0.66, "speed_bonus": 0.25, "mp_cost": 60},
					"color": Color(0.6, 0.25, 0.3),
					"note": "Abyssal Sire. Its many eyes still watch."}
		"malediction_ward":
			item = {"name": "Malediction Ward", "slot": "ring", "stats": {"defense": 10, "hp": 150, "attack": 6},
					"note": "Scorpia. A cursed off-hand ward."}
		_:
			return weapon(0)
	item.tier = UT
	if item.slot == "weapon":
		item.weapon_type = UNIQUE_WEAPON_TYPES.get(id, "axe")
	item.icon = id
	return item


## A dungeon boss's drop: loot from the realm's boss band, plus sometimes the
## dungeon's unique in its own white bag.
static func roll_dungeon_drop(unique_id: String, realm: int) -> Dictionary:
	var unique_item = dungeon_unique(unique_id) if randf() < DUNGEON_UNIQUE_CHANCE else null
	return {"loot": roll_boss_drop(realm), "unique": unique_item}
