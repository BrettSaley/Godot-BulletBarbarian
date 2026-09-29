class_name Dungeons
extends RefCounted
## RotMG-style dungeons, themed on OSRS: a winding path of rooms full of the
## dungeon's monsters, then a boss at the end who can drop the dungeon's one
## unique (UT). World bosses open them: two dungeons, then the realm's raid.

const Skeleton := preload("res://scripts/enemies/wilderness/skeleton.gd")
const Revenant := preload("res://scripts/enemies/wilderness/revenant.gd")
const Hellhound := preload("res://scripts/enemies/godwars/hellhound.gd")
const BlackDemon := preload("res://scripts/enemies/wilderness/black_demon.gd")
const LavaDragon := preload("res://scripts/enemies/wilderness/lava_dragon.gd")

## Each dungeon: realm, name, boss script, unique, floor/wall colours, and
## the monsters on the path (Minion kinds as strings, or enemy scripts).
const DATA := {
	# --- Lumbridge ---
	"kalphite_lair": {"realm": 0, "name": "Kalphite Lair", "boss": preload("res://scripts/enemies/dungeon/kalphite_queen.gd"),
			"unique": "dragon_chainbody", "floor": Color(0.45, 0.38, 0.25), "wall": Color(0.2, 0.16, 0.1),
			"monsters": ["kalphite_worker", "kalphite_worker", "kalphite_soldier", "kalphite_guardian"]},
	"sarachnis_lair": {"realm": 0, "name": "Sarachnis's Lair", "boss": preload("res://scripts/enemies/dungeon/sarachnis.gd"),
			"unique": "sarachnis_cudgel", "floor": Color(0.3, 0.28, 0.25), "wall": Color(0.12, 0.1, 0.1),
			"monsters": ["spiderling", "temple_spider", "temple_spider", Skeleton]},
	"kraken_cove": {"realm": 0, "name": "Kraken Cove", "boss": preload("res://scripts/enemies/dungeon/kraken.gd"),
			"unique": "trident_of_the_seas", "floor": Color(0.2, 0.3, 0.35), "wall": Color(0.08, 0.12, 0.16),
			"monsters": ["cave_kraken", "waterfiend", "waterfiend", "cave_kraken"]},
	"fight_caves": {"realm": 0, "name": "The Fight Caves", "boss": preload("res://scripts/enemies/dungeon/jad.gd"),
			"unique": "toktz_xil_ul", "floor": Color(0.3, 0.18, 0.12), "wall": Color(0.12, 0.05, 0.03),
			"monsters": ["tz_kih", "tz_kih", "tok_xil", "yt_mejkot"]},
	# --- God Wars ---
	"corrupted_gauntlet": {"realm": 1, "name": "The Corrupted Gauntlet", "boss": preload("res://scripts/enemies/dungeon/corrupted_hunllef.gd"),
			"unique": "blade_of_saeldor", "floor": Color(0.3, 0.15, 0.18), "wall": Color(0.12, 0.04, 0.06),
			"monsters": ["corrupted_wolf", "corrupted_wolf", "corrupted_bear", "corrupted_dragon"]},
	"karuulm_dungeon": {"realm": 1, "name": "Karuulm Slayer Dungeon", "boss": preload("res://scripts/enemies/dungeon/alchemical_hydra.gd"),
			"unique": "dragon_hunter_lance", "floor": Color(0.32, 0.3, 0.25), "wall": Color(0.12, 0.12, 0.1),
			"monsters": ["wyrm", "wyrm", "drake", LavaDragon]},
	"cerberus_lair": {"realm": 1, "name": "Cerberus's Lair", "boss": preload("res://scripts/enemies/dungeon/cerberus.gd"),
			"unique": "infernal_axe", "floor": Color(0.3, 0.18, 0.15), "wall": Color(0.1, 0.05, 0.04),
			"monsters": [Hellhound, Hellhound, BlackDemon, "ghost"]},
	"nightmare_lair": {"realm": 1, "name": "The Nightmare's Lair", "boss": preload("res://scripts/enemies/dungeon/nightmare.gd"),
			"unique": "inquisitors_great_helm", "floor": Color(0.22, 0.18, 0.26), "wall": Color(0.08, 0.06, 0.1),
			"monsters": ["husk", "sleepwalker", "sleepwalker", "parasite"]},
	# --- Wilderness ---
	"kbd_lair": {"realm": 2, "name": "King Black Dragon's Lair", "boss": preload("res://scripts/enemies/dungeon/king_black_dragon.gd"),
			"unique": "dragonfire_shield", "floor": Color(0.25, 0.2, 0.2), "wall": Color(0.1, 0.06, 0.06),
			"monsters": ["baby_black_dragon", "baby_black_dragon", LavaDragon, BlackDemon]},
	"revenant_caves": {"realm": 2, "name": "The Revenant Caves", "boss": preload("res://scripts/enemies/dungeon/revenant_maledictus.gd"),
			"unique": "craws_bow", "floor": Color(0.2, 0.24, 0.24), "wall": Color(0.06, 0.09, 0.09),
			"monsters": [Revenant, Revenant, Skeleton, "ghost"]},
	"abyssal_nexus": {"realm": 2, "name": "The Abyssal Nexus", "boss": preload("res://scripts/enemies/dungeon/abyssal_sire.gd"),
			"unique": "abyssal_bludgeon", "floor": Color(0.3, 0.14, 0.18), "wall": Color(0.1, 0.03, 0.05),
			"monsters": ["abyssal_leech", "abyssal_leech", "abyssal_walker", BlackDemon]},
	"scorpia_cave": {"realm": 2, "name": "Scorpia's Cave", "boss": preload("res://scripts/enemies/dungeon/scorpia.gd"),
			"unique": "malediction_ward", "floor": Color(0.36, 0.3, 0.2), "wall": Color(0.14, 0.1, 0.06),
			"monsters": ["scorpion", "scorpion", "king_scorpion", Skeleton]},
}


static func info(id: String) -> Dictionary:
	return DATA[id]


static func for_realm(realm: int) -> Array:
	return DATA.keys().filter(func(id): return DATA[id].realm == realm)
