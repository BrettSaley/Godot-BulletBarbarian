class_name SaveGame
## Character saves, one per slot, RotMG style: written automatically and
## deleted on death, so permadeath still means permadeath.

const SLOTS := 3
const VERSION := 1
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
	if not (data is Dictionary) or data.get("version", 0) != VERSION:
		return {}
	return data


static func erase(slot: int) -> void:
	if exists(slot):
		DirAccess.remove_absolute(ProjectSettings.globalize_path(path(slot)))


static func migrate_old_save() -> void:
	if FileAccess.file_exists(OLD_PATH) and not exists(0):
		DirAccess.rename_absolute(ProjectSettings.globalize_path(OLD_PATH), ProjectSettings.globalize_path(path(0)))
