extends Enemy
## Sotetseg (Theatre of Blood). A hulking red beast at the top of its room.
## Fires red and blue orbs and hurls a slow death ball that hits very hard.
## At 66% and 33% health it drags you into the maze: the floor becomes a grid
## of small red tiles that burn while you stand on them, with one winding path
## of plain floor snaking up to a green exit tile. The maze is timed - get to
## the exit before the countdown ends, or its collapse hits you hard wherever
## you're standing, safe tile or not.

const RED := Color(0.9, 0.15, 0.15)
const BLUE := Color(0.3, 0.5, 1.0)
const EXIT := Color(0.35, 0.95, 0.45)
const MAZE_AT := [0.66, 0.33]
const CELL := 60.0
const MAZE_TIME := 9.0
## The path sidesteps at least this many tiles between rows, so it winds.
const MIN_SWING := 3
## Running out of time costs this share of the player's max health.
const FAIL_DAMAGE := 0.6

## Set by the raid.
var room: Rect2
var mazes_left := MAZE_AT.duplicate()
var red_next := true
var maze_time := 0.0
var exit_rect := Rect2()


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


func in_maze() -> bool:
	return maze_time > 0.0


func _attacks() -> Array:
	return ["orbs", "orbs", "death_ball"]


func _move(delta: float) -> void:
	if in_maze():
		maze_time -= delta
		rest_timer = 1.0  # no attacks while the maze is up
		if exit_rect.has_point(player.position):
			_end_maze()
			DamageText.spawn(get_parent(), player.position + Vector2(0, -40), "Made it!", EXIT, 18)
		elif maze_time <= 0.0:
			_end_maze()
			player.take_damage(player.max_hp() * FAIL_DAMAGE, "Sotetseg's maze", true)
			DamageText.spawn(get_parent(), player.position + Vector2(0, -40), "The maze collapses!", RED.lightened(0.3), 18)
		return
	if not mazes_left.is_empty() and hp / max_hp < mazes_left[0]:
		mazes_left.pop_front()
		_start_maze()


## A snaking path from the bottom row to an exit on the top row: across each
## row it swings well to one side, then climbs a row. Every other tile burns.
func _start_maze() -> void:
	var cols := int(room.size.x / CELL)
	var rows := int((room.size.y - 110.0) / CELL)
	var origin := Vector2(room.position.x + (room.size.x - cols * CELL) / 2.0, room.end.y - rows * CELL)
	var safe := {}
	var col := randi() % cols
	var start_col := col
	for row in range(rows - 1, -1, -1):
		safe[Vector2i(col, row)] = true
		var next_col := col
		for attempt in 12:
			next_col = randi() % cols
			if absi(next_col - col) >= MIN_SWING:
				break
		while col != next_col:
			col += signi(next_col - col)
			safe[Vector2i(col, row)] = true
	exit_rect = Rect2(origin + Vector2(col, 0) * CELL, Vector2(CELL, CELL))
	for c in cols:
		for r in rows:
			if not safe.has(Vector2i(c, r)):
				hazards().rect_pool(Rect2(origin + Vector2(c, r) * CELL, Vector2(CELL, CELL)).grow(-2), MAZE_TIME,
						bullet_damage * 6.0, "Sotetseg's maze", RED)
	player.position = origin + Vector2(start_col + 0.5, rows - 0.5) * CELL
	shots.clear_all()
	attack = ""
	attack_timer = 0.0
	maze_time = MAZE_TIME
	DamageText.spawn(get_parent(), position + Vector2(0, 70), "THE MAZE! Reach the green exit in time.", RED.lightened(0.4), 18)


func _end_maze() -> void:
	maze_time = 0.0
	hazards().clear_all()
	rest_timer = 1.5


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
	if in_maze():
		# The green exit tile and the countdown, in world space.
		var exit := Rect2((exit_rect.position - position) / size_scale, exit_rect.size / size_scale)
		draw_rect(exit, Color(EXIT, 0.35 + 0.2 * sin(time * 8.0)))
		draw_rect(exit, EXIT, false, 2.0)
		draw_string(ThemeDB.fallback_font, exit.position + Vector2(0, -6), "EXIT", HORIZONTAL_ALIGNMENT_CENTER,
				exit.size.x, 12, EXIT)
		var urgent := maze_time < 3.0
		draw_string(ThemeDB.fallback_font, Vector2(-80, 74), "%.1f" % maze_time, HORIZONTAL_ALIGNMENT_CENTER, 160,
				30, RED.lightened(0.5) if urgent else Color(1, 1, 1))
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
