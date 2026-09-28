extends Enemy
## Sotetseg (Theatre of Blood). A hulking red beast at the top of its room.
## Fires red and blue orbs and hurls a slow death ball that hits very hard.
## At 66% and 33% health it drags you into the maze: the floor fills with red
## tiles that explode after a few seconds - only a single winding path of
## plain floor is safe, so trace it before the red tiles go off.

const RED := Color(0.9, 0.15, 0.15)
const BLUE := Color(0.3, 0.5, 1.0)
const MAZE_AT := [0.66, 0.33]
const CELL := 90.0
const MAZE_DELAY := 3.2

## Set by the raid.
var room: Rect2
var mazes_left := MAZE_AT.duplicate()
var red_next := true


func _init() -> void:
	display_name = "Sotetseg"
	radius = 34.0
	move_speed = 0.0
	max_hp = 1800.0
	xp = 700
	bullet_damage = 28.0
	contact_damage = 45.0
	is_boss = true
	drops_loot = false
	aggro_range = 2000.0
	projectile_style = Projectiles.Style.ORB


func _attacks() -> Array:
	return ["orbs", "orbs", "death_ball"]


func _move(_delta: float) -> void:
	if not mazes_left.is_empty() and hp / max_hp < mazes_left[0]:
		mazes_left.pop_front()
		_start_maze()


## Every floor cell explodes except a random path from the bottom row to the top.
func _start_maze() -> void:
	var cols := int(room.size.x / CELL)
	var rows := int((room.size.y - 110.0) / CELL)
	var origin := Vector2(room.position.x + (room.size.x - cols * CELL) / 2.0, room.end.y - rows * CELL)
	var safe := {}
	var col := randi() % cols
	var start_col := col
	for row in range(rows - 1, -1, -1):
		safe[Vector2i(col, row)] = true
		var next_col := clampi(col + randi_range(-2, 2), 0, cols - 1)
		while col != next_col:
			col += signi(next_col - col)
			safe[Vector2i(col, row)] = true
	for c in cols:
		for r in rows:
			if not safe.has(Vector2i(c, r)):
				hazards().rect_blast(Rect2(origin + Vector2(c, r) * CELL, Vector2(CELL, CELL)), MAZE_DELAY,
						bullet_damage * 3.5, "Sotetseg's maze", RED)
	player.position = origin + Vector2(start_col + 0.5, rows - 0.5) * CELL
	shots.clear_all()
	attack_timer = 0.0
	rest_timer = MAZE_DELAY + 0.5
	DamageText.spawn(get_parent(), position + Vector2(0, 70), "THE MAZE! Follow the plain floor.", RED.lightened(0.4), 18)


func _fire(attack_name: String) -> float:
	match attack_name:
		"orbs":
			red_next = not red_next
			fan(position, dir_to_player(position), 2, 0.2, 180.0, 7.0, RED if red_next else BLUE)
			return 0.7
		"death_ball":
			shoot(position, dir_to_player(position) * 95.0, 22.0, Color(0.95, 0.4, 0.4), 4.0)
			return 2.0
	return 1.0


func _draw() -> void:
	var body := Color(0.45, 0.06, 0.08)
	draw_set_transform(Vector2(0, 36), 0.0, Vector2(1.4, 0.3))
	draw_circle(Vector2.ZERO, 32.0, Color(0, 0, 0, 0.3))
	draw_set_transform(Vector2(0, sin(time * 2.0) * 2.0))
	# Spiked, hunched bulk
	for k in 7:
		var angle := PI + PI * k / 6.0
		draw_colored_polygon(PackedVector2Array([Vector2.from_angle(angle - 0.2) * 28.0, Vector2.from_angle(angle) * 46.0,
				Vector2.from_angle(angle + 0.2) * 28.0]), body.darkened(0.3))
	draw_circle(Vector2(0, 4), 32.0, body)
	draw_circle(Vector2(0, 10), 20.0, body.lightened(0.1))
	# One great eye and a toothy maw
	draw_circle(Vector2(0, -8), 12.0, Color(0.1, 0.02, 0.02))
	draw_circle(Vector2(0, -8), 8.0, RED.lightened(0.2 if is_attacking() else 0.0))
	draw_circle(Vector2(0, -8), 3.0, Color(0.1, 0.02, 0.02))
	for t in 6:
		var x := -15.0 + t * 6.0
		draw_colored_polygon(PackedVector2Array([Vector2(x, 14), Vector2(x + 4, 14), Vector2(x + 2, 21)]), Color(0.95, 0.9, 0.85))
	draw_set_transform(Vector2.ZERO)
	draw_health_bar(46.0)
