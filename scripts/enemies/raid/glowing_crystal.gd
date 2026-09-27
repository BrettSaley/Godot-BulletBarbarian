extends Enemy
## One of the four crystals in Vasa Nistirio's room. Harmless on its own,
## but Vasa heals from it until it's destroyed.

const CRYSTAL := Color(0.55, 0.8, 1.0)


func _init() -> void:
	display_name = "Glowing Crystal"
	radius = 18.0
	move_speed = 0.0
	max_hp = 300.0
	xp = 20
	contact_damage = 0.0
	drops_loot = false
	size_scale = 1.2
	aggro_range = 2000.0


func _move(_delta: float) -> void:
	pass


func _fire(_attack_name: String) -> float:
	return 99.0


func _draw() -> void:
	var pulse := 0.5 + 0.5 * sin(time * 3.0)
	draw_circle(Vector2(0, 4), 22.0, Color(CRYSTAL, 0.15 + 0.15 * pulse))
	draw_colored_polygon(PackedVector2Array([Vector2(0, -26), Vector2(12, -2), Vector2(6, 16), Vector2(-6, 16), Vector2(-12, -2)]), CRYSTAL.darkened(0.2))
	draw_colored_polygon(PackedVector2Array([Vector2(0, -26), Vector2(12, -2), Vector2(0, 2)]), CRYSTAL.lightened(0.3))
	draw_colored_polygon(PackedVector2Array([Vector2(-14, 4), Vector2(-8, -10), Vector2(-4, 14)]), CRYSTAL)
	draw_health_bar(22.0)
