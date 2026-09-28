class_name Realms
extends RefCounted
## The three overworlds. Each has its own zones, monsters, world bosses and
## raid; completing a realm's raid unlocks the next realm. Monsters and
## bosses in later realms are scaled up (see Enemy.REALM_HP) and drop higher
## tiers (see Items.REALM_TIERS).

const LUMBRIDGE := 0
const GOD_WARS := 1
const WILDERNESS := 2

const Goblin := preload("res://scripts/enemies/goblin.gd")
const GiantRat := preload("res://scripts/enemies/giant_rat.gd")
const Wolf := preload("res://scripts/enemies/wolf.gd")
const DarkWizard := preload("res://scripts/enemies/dark_wizard.gd")
const HillGiant := preload("res://scripts/enemies/hill_giant.gd")
const MountainTroll := preload("res://scripts/enemies/mountain_troll.gd")
const GreenDragon := preload("res://scripts/enemies/green_dragon.gd")
const LesserDemon := preload("res://scripts/enemies/lesser_demon.gd")
const Icefiend := preload("res://scripts/enemies/godwars/icefiend.gd")
const IceTroll := preload("res://scripts/enemies/godwars/ice_troll.gd")
const SpiritualMage := preload("res://scripts/enemies/godwars/spiritual_mage.gd")
const Aviansie := preload("res://scripts/enemies/godwars/aviansie.gd")
const Ork := preload("res://scripts/enemies/godwars/ork.gd")
const Hellhound := preload("res://scripts/enemies/godwars/hellhound.gd")
const Skeleton := preload("res://scripts/enemies/wilderness/skeleton.gd")
const ChaosDruid := preload("res://scripts/enemies/wilderness/chaos_druid.gd")
const Revenant := preload("res://scripts/enemies/wilderness/revenant.gd")
const BlackDemon := preload("res://scripts/enemies/wilderness/black_demon.gd")
const LavaDragon := preload("res://scripts/enemies/wilderness/lava_dragon.gd")

const DATA := [
	{
		"name": "Lumbridge", "hub": "Lumbridge", "style": "grass",
		"zones": ["Lumbridge Fields", "Draynor Woods", "Barbarian Village", "Giants' Plateau",
				"Troll Country", "Kourend Woodland", "Mount Quidamortem"],
		"colors": [Color(0.38, 0.6, 0.28), Color(0.3, 0.52, 0.25), Color(0.35, 0.5, 0.26), Color(0.32, 0.43, 0.23),
				Color(0.4, 0.42, 0.34), Color(0.36, 0.4, 0.3), Color(0.38, 0.36, 0.34)],
		"hub_color": Color(0.45, 0.62, 0.32),
		"rosters": [
			[Goblin, Goblin, GiantRat],
			[Goblin, GiantRat, Wolf],
			[Wolf, Wolf, DarkWizard, Goblin],
			[HillGiant, HillGiant, DarkWizard, Wolf],
			[MountainTroll, MountainTroll, HillGiant],
			[GreenDragon, MountainTroll, DarkWizard],
			[GreenDragon, LesserDemon, LesserDemon, MountainTroll],
		],
		"bosses": [
			preload("res://scripts/enemies/bosses/zulrah.gd"),
			preload("res://scripts/enemies/bosses/vorkath.gd"),
			preload("res://scripts/enemies/bosses/giant_mole.gd"),
		],
		"raid": "cox", "raid_name": "Chambers of Xeric", "portal_color": Color(0.6, 0.4, 1.0),
	},
	{
		"name": "God Wars", "hub": "God Wars Camp", "style": "snow",
		"zones": ["Trollheim Foothills", "Frozen Pass", "Saradomin Encampment", "Armadyl's Eyrie",
				"Bandos Stronghold", "Zamorak Fortress", "Ancient Prison"],
		"colors": [Color(0.8, 0.84, 0.88), Color(0.72, 0.78, 0.85), Color(0.78, 0.8, 0.9), Color(0.7, 0.74, 0.8),
				Color(0.55, 0.52, 0.45), Color(0.45, 0.3, 0.3), Color(0.35, 0.33, 0.4)],
		"hub_color": Color(0.88, 0.9, 0.94),
		"rosters": [
			[Icefiend, Icefiend, IceTroll],
			[IceTroll, Icefiend, Hellhound],
			[SpiritualMage, SpiritualMage, IceTroll],
			[Aviansie, Aviansie, SpiritualMage],
			[Ork, Ork, Aviansie],
			[Hellhound, Hellhound, Ork, SpiritualMage],
			[Ork, Aviansie, Hellhound, SpiritualMage],
		],
		"bosses": [
			preload("res://scripts/enemies/bosses/graardor.gd"),
			preload("res://scripts/enemies/bosses/kreearra.gd"),
			preload("res://scripts/enemies/bosses/zilyana.gd"),
			preload("res://scripts/enemies/bosses/kril.gd"),
		],
		"raid": "tob", "raid_name": "Theatre of Blood", "portal_color": Color(0.85, 0.15, 0.2),
	},
	{
		"name": "Wilderness", "hub": "Ferox Enclave", "style": "ash",
		"zones": ["Ferox Outskirts", "Dark Warriors' Fortress", "Chaos Temple", "Revenant Caves",
				"Lava Maze", "Demonic Ruins", "Deep Wilderness"],
		"colors": [Color(0.4, 0.38, 0.3), Color(0.36, 0.33, 0.28), Color(0.34, 0.3, 0.28), Color(0.3, 0.28, 0.3),
				Color(0.38, 0.22, 0.16), Color(0.3, 0.2, 0.18), Color(0.24, 0.18, 0.18)],
		"hub_color": Color(0.5, 0.48, 0.4),
		"rosters": [
			[Skeleton, Skeleton, ChaosDruid],
			[Skeleton, ChaosDruid, Revenant],
			[ChaosDruid, ChaosDruid, Revenant],
			[Revenant, Revenant, BlackDemon],
			[LavaDragon, LavaDragon, Revenant],
			[BlackDemon, BlackDemon, LavaDragon],
			[LavaDragon, BlackDemon, Revenant, BlackDemon],
		],
		"bosses": [
			preload("res://scripts/enemies/bosses/callisto.gd"),
			preload("res://scripts/enemies/bosses/venenatis.gd"),
			preload("res://scripts/enemies/bosses/vetion.gd"),
			preload("res://scripts/enemies/bosses/chaos_elemental.gd"),
		],
		"raid": "toa", "raid_name": "Tombs of Amascut", "portal_color": Color(0.95, 0.75, 0.3),
	},
]


static func info(realm: int) -> Dictionary:
	return DATA[realm]


static func count() -> int:
	return DATA.size()


## Which realm's raid is this ("cox", "tob", "toa")?
static func realm_of_raid(raid_id: String) -> int:
	for i in DATA.size():
		if DATA[i].raid == raid_id:
			return i
	return 0
