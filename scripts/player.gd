extends Node2D
## The Barbarian, the first playable class. Moves with WASD/arrows and throws
## axes at the mouse while the left button is held. Stats grow with level
## (max 20) and from equipped items; death is permanent.

signal died(killer: String)
signal changed  # stats, hp, xp, equipment or inventory changed
signal leveled_up(new_level: int)

const MAX_LEVEL := 20
const INVENTORY_SIZE := 8
const BASE_STATS := {"hp": 200, "mp": 100, "attack": 12, "defense": 0, "speed": 12, "dexterity": 12, "vitality": 12}
const PER_LEVEL := {"hp": 25, "mp": 5, "attack": 1, "defense": 0, "speed": 1, "dexterity": 1, "vitality": 1}
const AXE_SPEED := 560.0
const AXE_SPREAD := 0.15
const TILE := 48.0
## The sprite is drawn this much bigger; the hitbox stays small for dodging.
const ART_SCALE := 1.3

var hitbox_radius := 8.0
var level := 1
var xp := 0
var hp := 0.0
var mp := 0.0
var alive := true
## The four RotMG-style slots.
var equipment := {"weapon": Items.weapon(0), "ability": Items.helm(0), "armor": Items.armor(0), "ring": null}
var inventory: Array = []

## Set by the main scene.
var shots: Node2D
## Areas the player may stand in (the realm, or the open rooms of a raid).
var walkable: Array[Rect2] = []

var fire_cooldown := 0.0
var facing := 1.0
var walk_time := 0.0
var moving := false
var hurt_timer := 0.0
var slow_timer := 0.0
## Testing aid cycled with 9: Normal, Strong (10x damage dealt), and God
## (every hit kills, no damage taken).
enum DevMode { NORMAL, STRONG, GOD }
const DEV_MODE_NAMES := ["Normal", "Strong mode: 10x damage", "God mode: insta-kill, no damage taken"]
var dev_mode := DevMode.NORMAL
const DEV_DAMAGE := [1.0, 10.0, 1e9]
var warcry_timer := 0.0
var warcry := {}


func _ready() -> void:
	inventory.resize(INVENTORY_SIZE)
	hp = max_hp()
	mp = max_mp()


# --- Stats ---

func stat(stat_name: String) -> int:
	var total: int = BASE_STATS[stat_name] + PER_LEVEL[stat_name] * (level - 1)
	for slot in ["ability", "armor", "ring"]:
		var item = equipment[slot]
		if item != null:
			total += item.stats.get(stat_name, 0)
	return total


func max_hp() -> float:
	return float(stat("hp"))


func max_mp() -> float:
	return float(stat("mp"))


## Extra speed (movement and attacks) while Warcry is active.
func warcry_speed() -> float:
	return 1.0 + (warcry.speed_bonus if warcry_timer > 0.0 else 0.0)


func move_speed() -> float:
	return (4.0 + 5.6 * stat("speed") / 75.0) * TILE * warcry_speed()


func shots_per_second() -> float:
	return (1.5 + 6.5 * stat("dexterity") / 75.0) * warcry_speed()


func damage_multiplier() -> float:
	var bonus: float = warcry.damage_bonus if warcry_timer > 0.0 else 0.0
	return (0.5 + stat("attack") / 50.0) * (1.0 + bonus) * DEV_DAMAGE[dev_mode]


func regen_per_second() -> float:
	return 1.0 + 0.24 * stat("vitality")


func mp_regen_per_second() -> float:
	return 4.0 + 0.1 * level


## Warcry from the equipped helm: spend MP for a burst of damage and speed.
func use_ability() -> void:
	var helm = equipment.ability
	if helm == null or not helm.has("warcry"):
		return
	var cry: Dictionary = helm.warcry
	if mp < cry.mp_cost:
		DamageText.spawn(get_parent(), position + Vector2(0, -34), "Not enough MP", Color(0.5, 0.7, 1), 12)
		return
	mp -= cry.mp_cost
	warcry = cry
	warcry_timer = cry.duration
	if cry.has("heal"):
		hp = minf(hp + cry.heal, max_hp())
	DamageText.spawn(get_parent(), position + Vector2(0, -40), "WARCRY!", Color(1, 0.5, 0.3), 16)
	changed.emit()


func xp_to_next() -> int:
	return 30 + 30 * level


func is_max_level() -> bool:
	return level >= MAX_LEVEL


func is_alive() -> bool:
	return alive


func add_xp(amount: int) -> void:
	if level >= MAX_LEVEL:
		return
	xp += amount
	while level < MAX_LEVEL and xp >= xp_to_next():
		xp -= xp_to_next()
		level += 1
		hp = max_hp()
		mp = max_mp()
		leveled_up.emit(level)
	if level >= MAX_LEVEL:
		xp = 0
	changed.emit()


func take_damage(amount: float, source: String, ignore_defense := false) -> void:
	if not alive or dev_mode == DevMode.GOD:
		return
	var dealt := amount if ignore_defense else maxf(amount - stat("defense"), amount * 0.15)
	hp = maxf(hp - dealt, 0.0)
	hurt_timer = 0.12
	DamageText.spawn(get_parent(), position + Vector2(0, -30), "-%d" % roundi(dealt), Color(1, 0.3, 0.3))
	changed.emit()
	if hp <= 0.0:
		alive = false
		died.emit(source)


# --- Equipment and inventory ---

func first_free_slot() -> int:
	return inventory.find(null)


func add_to_inventory(item: Dictionary) -> bool:
	var slot := first_free_slot()
	if slot == -1:
		return false
	inventory[slot] = item
	changed.emit()
	return true


func take_from_inventory(index: int) -> Dictionary:
	var item: Dictionary = inventory[index]
	inventory[index] = null
	changed.emit()
	return item


## Swap an inventory item with whatever is equipped in its slot.
func equip_from_inventory(index: int) -> void:
	var item = inventory[index]
	if item == null:
		return
	inventory[index] = equipment[item.slot]
	equipment[item.slot] = item
	hp = minf(hp, max_hp())
	changed.emit()


func unequip(slot: String) -> bool:
	var free := first_free_slot()
	if equipment[slot] == null or free == -1:
		return false
	inventory[free] = equipment[slot]
	equipment[slot] = null
	hp = minf(hp, max_hp())
	changed.emit()
	return true


# --- Per-frame ---

func _physics_process(delta: float) -> void:
	if not alive:
		return
	var input := Vector2(
		Input.get_axis("move_left", "move_right") + Input.get_axis("ui_left", "ui_right"),
		Input.get_axis("move_up", "move_down") + Input.get_axis("ui_up", "ui_down")
	).limit_length(1.0)
	slow_timer -= delta
	var speed := move_speed() * (0.4 if slow_timer > 0.0 else 1.0)
	_move_within_walls(input * speed * delta)

	moving = input != Vector2.ZERO
	walk_time = walk_time + delta if moving else 0.0
	if input.x != 0.0:
		facing = signf(input.x)

	var old_hp := hp
	var old_mp := mp
	hp = minf(hp + regen_per_second() * delta, max_hp())
	mp = minf(mp + mp_regen_per_second() * delta, max_mp())
	if roundi(hp) != roundi(old_hp) or roundi(mp) != roundi(old_mp):
		changed.emit()
	warcry_timer -= delta
	if Input.is_action_just_pressed("ability"):
		use_ability()

	fire_cooldown -= delta
	if _wants_to_shoot():
		var aim := get_global_mouse_position() - position
		facing = 1.0 if aim.x >= 0.0 else -1.0
		if fire_cooldown <= 0.0:
			_throw_axes(aim.normalized() if aim.length() > 1.0 else Vector2.RIGHT * facing)
			var weapon = equipment.weapon
			fire_cooldown = 1.0 / (shots_per_second() * (weapon.get("rate", 1.0) if weapon else 1.0))

	hurt_timer -= delta
	modulate = Color(1, 0.5, 0.5) if hurt_timer > 0.0 else (Color(1, 0.85, 0.75) if warcry_timer > 0.0 else Color(1, 1, 1))
	queue_redraw()


func _wants_to_shoot() -> bool:
	# Clicking on inventory slots shouldn't throw axes.
	return Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT) and get_viewport().gui_get_hovered_control() == null


func _throw_axes(dir: Vector2) -> void:
	var weapon = equipment.weapon
	if weapon == null:
		return
	var count: int = weapon.shots
	var speed: float = weapon.get("speed", AXE_SPEED)
	var spread: float = weapon.get("spread", AXE_SPREAD)
	var style: int = weapon.get("style", Projectiles.Style.AXE)
	for i in count:
		var damage := randi_range(weapon.damage_min, weapon.damage_max) * damage_multiplier()
		var angle := (i - (count - 1) / 2.0) * spread
		shots.spawn(position, dir.rotated(angle) * speed, weapon.get("size", 12.0), Items.color_of(weapon),
				damage, weapon.range / speed, "", style)


## Slide along walls: try the full move, then each axis on its own.
func _move_within_walls(motion: Vector2) -> void:
	for step in [motion, Vector2(motion.x, 0), Vector2(0, motion.y)]:
		if _is_walkable(position + step):
			position += step
			return


func _is_walkable(point: Vector2) -> bool:
	for rect in walkable:
		if rect.has_point(point):
			return true
	return false


## Frozen / slowed by an attack (e.g. Vorkath's ice breath).
func apply_slow(duration: float) -> void:
	slow_timer = maxf(slow_timer, duration)


func _draw() -> void:
	var bob := -absf(sin(walk_time * 14.0)) * 2.5 if moving else sin(Time.get_ticks_msec() / 400.0) * 0.6
	var waddle := sin(walk_time * 14.0) * 0.08 if moving else 0.0
	BarbarianArt.draw(self, BarbarianArt.HERO, bob, waddle, facing, ART_SCALE)


## Called when one of our shots lands; lifesteal weapons heal a share of it.
func on_hit_enemy(damage: float) -> void:
	var weapon = equipment.weapon
	if weapon != null and weapon.get("lifesteal", 0.0) > 0.0 and alive:
		hp = minf(hp + damage * weapon.lifesteal, max_hp())
		changed.emit()


## Shove the player (gusts, teleports), stopping short of any wall.
func knock_back(offset: Vector2) -> void:
	for t in [1.0, 0.75, 0.5, 0.25]:
		if _is_walkable(position + offset * t):
			position += offset * t
			return


## Step to the next dev mode (Normal -> Strong -> God -> Normal); returns its name.
func cycle_dev_mode() -> String:
	dev_mode = (dev_mode + 1) % DEV_MODE_NAMES.size()
	return DEV_MODE_NAMES[dev_mode]


func is_god_mode() -> bool:
	return dev_mode == DevMode.GOD
