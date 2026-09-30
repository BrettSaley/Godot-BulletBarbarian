extends Node
## Keeps every zone of the current realm stocked with packs of that realm's
## monsters, spawned out of the player's sight, and keeps one of the realm's
## world bosses roaming the outermost zone. A slain boss is replaced after a
## delay, cycling through all the realm's bosses before any repeats.

signal enemy_died(enemy: Enemy)
signal boss_spawned(boss: Enemy)

## Enemies to keep alive per zone tier (outer rings are bigger).
const TARGET_PER_ZONE := [12, 14, 16, 18, 18, 18, 20]
const MIN_SPAWN_DISTANCE := 700.0
const BOSS_RESPAWN_DELAY := 22.5
const BOSS_TIER := 6
## Bosses that move around their spawn (like Zulrah's swamp spots) need room to
## stay inside the map.
const BOSS_EDGE_MARGIN := 350.0
## World boss health multiplier per realm: Lumbridge's are lighter so the
## first boss kill comes sooner.
const BOSS_HP := [0.75, 1.0, 1.0]

## Set by the main scene.
var enemy_parent: Node2D
var shots: Node2D
var player: Node2D

var realm := Realms.LUMBRIDGE
var counts := [0, 0, 0, 0, 0, 0, 0]
var spawned: Array[Enemy] = []
var boss: Enemy
## Per realm: bosses left in the current rotation, and the last one spawned.
var boss_queues := [[], [], []]
var last_bosses := [-1, -1, -1]
var boss_timer := 5.0
var check_timer := 0.0
## Stops spawning while the player is off in a raid.
var paused := false


## Switch to another realm: everything from the old realm is removed.
func set_realm(realm_index: int) -> void:
	for enemy in spawned:
		if is_instance_valid(enemy):
			enemy.queue_free()
	spawned.clear()
	counts = [0, 0, 0, 0, 0, 0, 0]
	realm = realm_index
	boss = null
	boss_timer = 5.0
	check_timer = 0.0


func _physics_process(delta: float) -> void:
	if paused or not player.is_alive():
		return
	check_timer -= delta
	if check_timer <= 0.0:
		check_timer = 1.0
		for tier in counts.size():
			if counts[tier] < TARGET_PER_ZONE[tier]:
				_spawn_pack(tier)

	if boss == null:
		boss_timer -= delta
		if boss_timer <= 0.0:
			_spawn_boss()


func _spawn_pack(tier: int) -> void:
	var center := _spawn_point(tier)
	var kind: GDScript = Realms.info(realm).rosters[tier].pick_random()
	for i in randi_range(2, 4):
		var offset := Vector2.from_angle(randf() * TAU) * randf_range(20, 70)
		_spawn(kind, center + offset, tier)


func _spawn_boss() -> void:
	var bosses: Array = Realms.info(realm).bosses
	var pick: int = ShuffleBag.next(boss_queues[realm], range(bosses.size()), last_bosses[realm])
	last_bosses[realm] = pick
	boss = _spawn(bosses[pick], _spawn_point(BOSS_TIER, BOSS_EDGE_MARGIN), BOSS_TIER)
	boss.max_hp *= BOSS_HP[realm]
	boss.hp = boss.max_hp
	boss_spawned.emit(boss)


func _spawn(kind: GDScript, pos: Vector2, tier: int) -> Enemy:
	var enemy: Enemy = kind.new()
	enemy.position = pos
	enemy.setup(tier, shots, player, realm)
	enemy.died.connect(_on_enemy_died)
	enemy_parent.add_child(enemy)
	spawned.append(enemy)
	if not enemy.is_boss:
		counts[tier] += 1
	return enemy


func _on_enemy_died(enemy: Enemy) -> void:
	spawned.erase(enemy)
	if enemy == boss:
		boss = null
		boss_timer = BOSS_RESPAWN_DELAY
	else:
		counts[enemy.tier] -= 1
	enemy_died.emit(enemy)


## A point in the zone that's well away from the player.
func _spawn_point(tier: int, margin := 60.0) -> Vector2:
	var point := World.random_point_in_zone(tier, margin)
	for attempt in 10:
		if point.distance_to(player.position) > MIN_SPAWN_DISTANCE:
			break
		point = World.random_point_in_zone(tier, margin)
	return point
