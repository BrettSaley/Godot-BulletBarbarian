class_name SaveGame
## Character saves, one per slot, RotMG style: written automatically and
## deleted on death, so permadeath still means permadeath.

const SLOTS := 3
## 2: White, the god armours and the Bandos/Armadyl swap renumbered the tiers.
const VERSION := 2
## Version 1 tier -> version 2 tier (13 and 14 were UT and GIGA).
const V1_TIERS := [0, 1, 2, 3, 5, 6, 7, 8, 9, 14, 13, 15, 16, Items.UT, Items.GIGA]
## Where the single save lived before there were slots; it becomes slot 1.
const OLD_PATH := "user://character.save"


static func path(slot: int) -> String:
	return "user://character_%d.save" % (slot + 1)


static func exists(slot: int) -> bool:
	return FileAccess.file_exists(path(slot))


static func write(slot: int, data: Dictionary) -> void:
	data.version = VERSION
	var file := FileAccess.open(path(slot), FileAccess.WRITE)
	if file:
		file.store_var(data)


## The saved character, or an empty dictionary if there is none (or it's unreadable).
static func read(slot: int) -> Dictionary:
	if not exists(slot):
		return {}
	var file := FileAccess.open(path(slot), FileAccess.READ)
	if file == null:
		return {}
	var data = file.get_var()
	if not (data is Dictionary):
		return {}
	if data.get("version", 0) == 1:
		_upgrade_from_v1(data)
	if data.get("version", 0) != VERSION:
		return {}
	return data


## Rebuild every saved item at its renumbered tier, so it gets the new tier's
## name and stats (uniques are rebuilt from their id).
static func _upgrade_from_v1(data: Dictionary) -> void:
	var hero: Dictionary = data.player
	for slot in hero.equipment:
		hero.equipment[slot] = _upgrade_item(hero.equipment[slot])
	for i in hero.inventory.size():
		hero.inventory[i] = _upgrade_item(hero.inventory[i])
	data.version = 2


static func _upgrade_item(item):
	if item == null:
		return null
	var tier: int = V1_TIERS[clampi(item.tier, 0, V1_TIERS.size() - 1)]
	if tier == Items.GIGA:
		return Items.unique(item.icon)
	if tier == Items.UT:
		return Items.dungeon_unique(item.icon)
	match item.slot:
		"weapon":
			return Items.weapon(tier)
		"ability":
			return Items.helm(tier)
		"armor":
			return Items.armor(tier)
	return Items.ring(tier, item.stats.keys()[0])


static func erase(slot: int) -> void:
	if exists(slot):
		DirAccess.remove_absolute(ProjectSettings.globalize_path(path(slot)))


static func migrate_old_save() -> void:
	if FileAccess.file_exists(OLD_PATH) and not exists(0):
		DirAccess.rename_absolute(ProjectSettings.globalize_path(OLD_PATH), ProjectSettings.globalize_path(path(0)))
