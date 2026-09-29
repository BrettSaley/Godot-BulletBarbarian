class_name SaveGame
## The one character save, RotMG style: written automatically and deleted on
## death, so permadeath still means permadeath.

const PATH := "user://character.save"
const VERSION := 1


static func exists() -> bool:
	return FileAccess.file_exists(PATH)


static func write(data: Dictionary) -> void:
	data.version = VERSION
	var file := FileAccess.open(PATH, FileAccess.WRITE)
	if file:
		file.store_var(data)


## The saved character, or an empty dictionary if there is none (or it's unreadable).
static func read() -> Dictionary:
	if not exists():
		return {}
	var file := FileAccess.open(PATH, FileAccess.READ)
	if file == null:
		return {}
	var data = file.get_var()
	if not (data is Dictionary) or data.get("version", 0) != VERSION:
		return {}
	return data


static func erase() -> void:
	if exists():
		DirAccess.remove_absolute(ProjectSettings.globalize_path(PATH))
