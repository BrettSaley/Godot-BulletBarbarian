class_name Bank
## The bank: 12 item slots shared by every character on this computer, kept
## in its own save file. Death never touches it, so items left here survive
## for your next character.

const PATH := "user://bank.save"
const SIZE := 12


## The banked items (null for empty slots), always SIZE long.
static func read() -> Array:
	var items: Array = []
	if FileAccess.file_exists(PATH):
		var file := FileAccess.open(PATH, FileAccess.READ)
		var data = file.get_var() if file else null
		if data is Dictionary and data.get("version", 0) == SaveGame.VERSION:
			items = data.items
	items.resize(SIZE)
	return items


static func write(items: Array) -> void:
	var file := FileAccess.open(PATH, FileAccess.WRITE)
	if file:
		file.store_var({"version": SaveGame.VERSION, "items": items})


static func first_free(items: Array) -> int:
	return items.find(null)
