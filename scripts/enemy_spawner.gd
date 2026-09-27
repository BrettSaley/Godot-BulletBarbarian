extends Node
## Keeps every zone stocked with packs of enemies, spawned out of the
## player's sight, and keeps one boss roaming the outer zones. A slain boss
## is replaced after a delay, never by the same kind twice in a row.

signal enemy_died(enemy: Enemy)
signal boss_spawned(boss: Enemy)

const Goblin := preload("res://scripts/enemies/goblin.gd")
const GiantRat := preload("res://scripts/enemies/giant_rat.gd")
const Wolf := preload("res://scripts/enemies/wolf.gd")
const DarkWizard := preload("res://scripts/enemies/dark_wizard.gd")
const HillGiant := preload("res://scripts/enemies/hill_giant.gd")
const GreenDragon := preload("res://scripts/enemies/green_dragon.gd")
const LesserDemon := preload("res://scripts/enemies/lesser_demon.gd")
const MountainTroll := preload("res://scripts/enemies/mountain_troll.gd")
const BOSSES := [
	preload("res://scripts/enemies/bosses/zulrah.gd"),
	preload("res://scripts/enemies/bosses/vorkath.gd"),
	preload("res://scripts/enemies/bosses/giant_mole.gd"),
]

## Enemies to keep alive per zone tier (outer rings are bigger).
const TARGET_PER_ZONE := [12, 14, 16, 18, 18, 18, 20]
## OSRS monsters for each zone (repeats make a kind more common). Each zone
## mixes in some of the previous zone's monsters so difficulty ramps smoothly.
const ZONE_ROSTERS := [
	[Goblin, Goblin, GiantRat],                            # Lumbridge Fields
	[Goblin, GiantRat, Wolf],                              # Draynor Woods
	[Wolf, Wolf, DarkWizard, Goblin],                      # Barbarian Village
	[HillGiant, HillGiant, DarkWizard, Wolf],              # Giants' Plateau
	[MountainTroll, MountainTroll, HillGiant],             # Troll Country
	[GreenDragon, MountainTroll, DarkWizard],              # Low Wilderness
	[GreenDragon, LesserDemon, LesserDemon, MountainTroll],  # Deep Wilderness
]
const MIN_SPAWN_DISTANCE := 700.0
const BOSS_RESPAWN_DELAY := 45.0
const BOSS_TIER := 6

## Set by the main scene.
var enemy_parent: Node2D
var shots: Node2D
var player: Node2D

var counts := [0, 0, 0, 0, 0, 0, 0]
var boss: Enemy
var last_boss := -1
var boss_timer := 5.0
var check_timer := 0.0
## Stops spawning while the player is off in a raid.
var paused := false


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
	var kind: GDScript = ZONE_ROSTERS[tier].pick_random()
	for i in randi_range(2, 4):
		var offset := Vector2.from_angle(randf() * TAU) * randf_range(20, 70)
		_spawn(kind, center + offset, tier)


func _spawn_boss() -> void:
	var options := range(BOSSES.size())
	options.erase(last_boss)
	last_boss = options.pick_random()
	boss = _spawn(BOSSES[last_boss], _spawn_point(BOSS_TIER), BOSS_TIER)
	boss_spawned.emit(boss)


func _spawn(kind: GDScript, pos: Vector2, tier: int) -> Enemy:
	var enemy: Enemy = kind.new()
	enemy.position = pos
	enemy.setup(tier, shots, player)
	enemy.died.connect(_on_enemy_died)
	enemy_parent.add_child(enemy)
	if not enemy.is_boss:
		counts[tier] += 1
	return enemy


func _on_enemy_died(enemy: Enemy) -> void:
	if enemy == boss:
		boss = null
		boss_timer = BOSS_RESPAWN_DELAY
	else:
		counts[enemy.tier] -= 1
	enemy_died.emit(enemy)


## A point in the zone that's well away from the player.
func _spawn_point(tier: int) -> Vector2:
	var point := World.random_point_in_zone(tier)
	for attempt in 10:
		if point.distance_to(player.position) > MIN_SPAWN_DISTANCE:
			break
		point = World.random_point_in_zone(tier)
	return point
