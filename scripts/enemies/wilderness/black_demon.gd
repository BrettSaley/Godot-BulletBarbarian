extends "res://scripts/enemies/lesser_demon.gd"
## Black Demon (OSRS, the Wilderness): a bigger, darker Lesser Demon.


func _init() -> void:
	super()
	display_name = "Black Demon"
	body_tint = Color(0.18, 0.16, 0.2)
	wing_tint = Color(0.08, 0.06, 0.1)
	max_hp = 340.0
	xp = 55
	radius = 19.0
