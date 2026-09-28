extends "res://scripts/enemies/mountain_troll.gd"
## Ice Troll (OSRS, Trollheim): a frost-bitten Mountain Troll hurling blocks
## of ice.


func _init() -> void:
	super()
	display_name = "Ice Troll"
	skin_color = Color(0.55, 0.68, 0.75)
	boulder_color = Color(0.7, 0.88, 1.0)
	max_hp = 200.0
	xp = 30
