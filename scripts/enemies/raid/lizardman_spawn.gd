extends Enemy
## Lizardman spawn: a little lizard that runs at you and explodes after a few
## seconds or when it gets close. Kill it first or get out of the way.

const FUSE := 3.5
const BLAST_DELAY := 0.5

var fuse := FUSE
var exploding := false


func _init() -> void:
	display_name = "Lizardman spawn"
	radius = 9.0
	move_speed = 120.0
	max_hp = 50.0
	xp = 5
	bullet_damage = 22.0
	contact_damage = 0.0
	drops_loot = false
	size_scale = 1.4
	aggro_range = 2000.0


func _move(delta: float) -> void:
	fuse -= delta
	if exploding:
		return
	position = position.move_toward(player.position, move_speed * delta)
	if fuse <= 0.0 or position.distance_to(player.position) < 30.0:
		exploding = true
		hazards().blast(position, 55.0, BLAST_DELAY, bullet_damage * 2.0, display_name, Color(0.6, 0.9, 0.2))
		get_tree().create_timer(BLAST_DELAY).timeout.connect(queue_free)


func _fire(_attack_name: String) -> float:
	return 99.0


func _draw() -> void:
	var blink := exploding and int(time * 12.0) % 2 == 0
	var color := Color(0.95, 0.95, 0.5) if blink else Color(0.45, 0.7, 0.25)
	draw_circle(Vector2(0, 2), 7.0, color)
	draw_circle(Vector2(5, -3), 4.5, color)
	draw_circle(Vector2(6, -4), 1.2, Color(0.1, 0.1, 0.1))
	draw_line(Vector2(-6, 4), Vector2(-12, 8), color, 2.0)
	draw_health_bar(12.0)
