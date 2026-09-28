extends "res://scripts/enemies/green_dragon.gd"
## Lava Dragon (OSRS, the Lava Maze): a Green Dragon's fiery cousin whose
## fireballs leave burning lava pools behind.

const LAVA := Color(1.0, 0.35, 0.05)


func _init() -> void:
	super()
	display_name = "Lava Dragon"
	scale_tint = Color(0.35, 0.12, 0.1)
	belly_tint = Color(0.95, 0.5, 0.15)
	max_hp = 380.0
	xp = 60


func _fire(attack_name: String) -> float:
	if attack_name == "fireball":
		hazards().pool(player.position, 40.0, 5.0, bullet_damage, "Lava Dragon's lava", LAVA)
	return super._fire(attack_name)
