extends Node2D
## The player character: a Barbarian, Archer or Mage (they only look different
## for now; see ClassArt). Moves with WASD/arrows and throws
## axes at the mouse while the left button is held. Stats grow with level
## (max 20) and from equipped items; death is permanent.

signal died(killer: String)
signal changed  # stats, hp, xp, equipment or inventory changed
signal leveled_up(new_level: int)

## The level cap starts at 20 and rises as raids are completed (see main.gd).
const START_LEVEL_CAP := 20
const MAX_LEVEL := 60
const INVENTORY_SIZE := 8
const BASE_STATS := {"hp": 200, "mp": 100, "attack": 12, "defense": 0, "speed": 12, "dexterity": 12, "vitality": 12}
const PER_LEVEL := {"hp": 25, "mp": 5, "attack": 1, "defense": 0, "speed": 1, "dexterity": 1, "vitality": 1}
## Levels past 20 grow more slowly, so the later realms stay a challenge.
const PER_LEVEL_LATE := {"hp": 12, "mp": 3, "attack": 0.25, "defense": 0.1, "speed": 0.1, "dexterity": 0.25, "vitality": 0.25}
const AXE_SPEED := 560.0
const AXE_SPREAD := 0.15
## Class specials (see use_ability): damage is this many average volleys of the
## equipped weapon, raised further by the helm's power.
const ICE_BARRAGE_DAMAGE := 4.0
const ICE_BARRAGE_RADIUS := 110.0
const ICE_BARRAGE_RANGE := 420.0
const POWER_SHOT_DAMAGE := 7.0
const POWER_SHOT_SPEED := 1150.0
const POWER_SHOT_RANGE := 800.0
const TILE := 48.0
## The sprite is drawn this much bigger; the hitbox stays small for dodging.
const ART_SCALE := 1.3

var hitbox_radius := 8.0
var level := 1
var xp := 0
## Every point of XP ever earned; at level 60 the HUD shows it as a score.
var total_xp := 0
var level_cap := START_LEVEL_CAP
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
## Seconds since the player last took damage.
var since_hit := 99.0
const OUT_OF_COMBAT_DELAY := 3.0
const OUT_OF_COMBAT_REGEN := 0.08  # of max HP per second
## Protection from the hub's safe zone lasts this long after leaving it.
const SAFE_LINGER := 1.0
var safe_timer := 0.0
var slow_timer := 0.0
## Testing aid cycled with 9: Normal, Strong (10x damage dealt), and God
## (every hit kills, no damage taken).
enum DevMode { NORMAL, STRONG, GOD }
const DEV_MODE_NAMES := ["Normal", "Strong mode: 10x damage", "God mode: insta-kill, no damage taken, 3x speed"]
var dev_mode := DevMode.NORMAL
const DEV_DAMAGE := [1.0, 10.0, 1e9]
const DEV_SPEED := [1.0, 1.0, 3.0]
var warcry_timer := 0.0
var warcry := {}
## Chosen on the character design screen.
var character_name := "Barbarian"
## "barbarian", "archer" or "mage" (see ClassArt). Only the look differs for now.
var character_class := "barbarian"
var look := {}
var palette := BarbarianArt.HERO
## Dev tools this character has ever used. Permanent: saved with the
## character and shown on screen for good.
var dev_marks: Array[String] = []


func _ready() -> void:
	inventory.resize(INVENTORY_SIZE)
	hp = max_hp()
	mp = max_mp()


# --- Saving ---

## Permanently mark this character as having used a dev tool.
func mark_dev(tool_name: String) -> void:
	if tool_name not in dev_marks:
		dev_marks.append(tool_name)
		changed.emit()


func set_look(new_name: String, new_look: Dictionary, new_class := "barbarian") -> void:
	character_name = new_name
	look = new_look
	character_class = new_class
	palette = ClassArt.palette_for(character_class, look)
	queue_redraw()


func to_save() -> Dictionary:
	return {"name": character_name, "class": character_class, "look": look, "level": level, "xp": xp, "total_xp": total_xp,
			"level_cap": level_cap, "equipment": equipment.duplicate(true), "inventory": inventory.duplicate(true),
			"dev_marks": dev_marks.duplicate()}


func load_save(data: Dictionary) -> void:
	set_look(data.name, data.look, data.get("class", "barbarian"))
	level = data.level
	xp = data.xp
	total_xp = data.total_xp
	level_cap = data.level_cap
	equipment = data.equipment
	inventory = data.inventory
	dev_marks.assign(data.get("dev_marks", []))
	inventory.resize(INVENTORY_SIZE)
	hp = max_hp()
	mp = max_mp()
	changed.emit()


# --- Stats ---

func stat(stat_name: String) -> int:
	var early := mini(level, START_LEVEL_CAP) - 1
	var late := maxi(level - START_LEVEL_CAP, 0)
	var total: int = BASE_STATS[stat_name] + PER_LEVEL[stat_name] * early + int(PER_LEVEL_LATE[stat_name] * late)
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
	return (4.0 + 5.6 * stat("speed") / 75.0) * TILE * warcry_speed() * DEV_SPEED[dev_mode]


## Warcry speeds up throwing by its speed bonus plus the helm's power (it
## never adds damage).
func shots_per_second() -> float:
	var frenzy: float = warcry.damage_bonus if warcry_timer > 0.0 else 0.0
	return (1.5 + 6.5 * stat("dexterity") / 75.0) * (warcry_speed() + frenzy)


func damage_multiplier() -> float:
	return (0.5 + stat("attack") / 50.0) * DEV_DAMAGE[dev_mode]


## Normal regen from Vitality, plus a fast out-of-combat regen once you have
## gone OUT_OF_COMBAT_DELAY seconds without taking a hit.
func regen_per_second() -> float:
	var out_of_combat := OUT_OF_COMBAT_REGEN * max_hp() if since_hit >= OUT_OF_COMBAT_DELAY else 0.0
	return 1.0 + 0.24 * stat("vitality") + out_of_combat


func mp_regen_per_second() -> float:
	return 4.0 + 0.1 * level


## The class special (Space), powered by the equipped helm: its "warcry"
## stats give the power (damage_bonus), duration and MP cost.
##   Barbarian - Warcry: faster movement and much faster throwing for a while
##   Mage      - Ice Barrage: an icy blast at the cursor that hits and freezes
##               every enemy caught in it
##   Archer    - Power Shot: one big, fast arrow that hits very hard
func use_ability() -> void:
	var helm = equipment.ability
	if helm == null or not helm.has("warcry") or is_safe():
		return
	var cry: Dictionary = helm.warcry
	if mp < cry.mp_cost:
		DamageText.spawn(get_parent(), position + Vector2(0, -34), "Not enough MP", Color(0.5, 0.7, 1), 12)
		return
	mp -= cry.mp_cost
	if cry.has("heal"):
		hp = minf(hp + cry.heal, max_hp())
	match character_class:
		"mage":
			_ice_barrage(cry)
		"archer":
			_power_shot(cry)
		_:
			warcry = cry
			warcry_timer = cry.duration
			DamageText.spawn(get_parent(), position + Vector2(0, -40), "WARCRY!", Color(1, 0.5, 0.3), 16)
	changed.emit()


## One average volley from the equipped weapon, before specials.
func _volley_damage() -> float:
	var weapon = equipment.weapon
	if weapon == null:
		return 0.0
	return (weapon.damage_min + weapon.damage_max) / 2.0 * weapon.shots * damage_multiplier()


func _ice_barrage(cry: Dictionary) -> void:
	var aim := get_global_mouse_position() - position
	var at := position + aim.limit_length(ICE_BARRAGE_RANGE)
	var damage: float = _volley_damage() * ICE_BARRAGE_DAMAGE * (1.0 + cry.damage_bonus)
	var freeze: float = 1.0 + cry.duration * 0.25
	for enemy in get_tree().get_nodes_in_group("enemies"):
		if enemy.position.distance_to(at) < ICE_BARRAGE_RADIUS + enemy.radius and enemy.can_be_hit_by_player():
			if not enemy.invulnerable:
				enemy.freeze(freeze)
			enemy.take_damage(damage)
	IceBarrage.spawn(get_parent(), at, ICE_BARRAGE_RADIUS)
	DamageText.spawn(get_parent(), position + Vector2(0, -40), "ICE BARRAGE!", Color(0.6, 0.9, 1), 16)


func _power_shot(cry: Dictionary) -> void:
	var aim := get_global_mouse_position() - position
	var dir := aim.normalized() if aim.length() > 1.0 else Vector2.RIGHT * facing
	facing = 1.0 if dir.x >= 0.0 else -1.0
	var damage: float = _volley_damage() * POWER_SHOT_DAMAGE * (1.0 + cry.damage_bonus)
	shots.spawn(position, dir * POWER_SHOT_SPEED, 18.0, Color(1.0, 0.9, 0.5), damage,
			POWER_SHOT_RANGE / POWER_SHOT_SPEED, "", Projectiles.Style.ARROW)
	DamageText.spawn(get_parent(), position + Vector2(0, -40), "POWER SHOT!", Color(1, 0.9, 0.5), 16)


func xp_to_next() -> int:
	return 30 + 30 * level


func is_max_level() -> bool:
	return level >= level_cap


## In the hub's safe zone, or just left it: can't attack or be hurt.
func is_safe() -> bool:
	return safe_timer > 0.0


func is_alive() -> bool:
	return alive


func add_xp(amount: int) -> void:
	total_xp += amount
	if level < level_cap:
		xp += amount
		while level < level_cap and xp >= xp_to_next():
			xp -= xp_to_next()
			level += 1
			hp = max_hp()
			mp = max_mp()
			leveled_up.emit(level)
		if level >= level_cap:
			xp = 0
	changed.emit()


## Final score once level 60 is reached.
func at_final_level() -> bool:
	return level >= MAX_LEVEL


func score() -> int:
	return total_xp / 10


## Completing a raid raises the level cap (never lowers it).
func raise_level_cap(new_cap: int) -> void:
	level_cap = maxi(level_cap, mini(new_cap, MAX_LEVEL))
	changed.emit()


func take_damage(amount: float, source: String, ignore_defense := false) -> void:
	if not alive or dev_mode == DevMode.GOD or is_safe():
		return
	var dealt := amount if ignore_defense else maxf(amount - stat("defense"), amount * 0.15)
	hp = maxf(hp - dealt, 0.0)
	hurt_timer = 0.12
	since_hit = 0.0
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
	safe_timer = SAFE_LINGER if World.in_safe_zone(position) else safe_timer - delta
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
	since_hit += delta
	modulate = Color(1, 0.5, 0.5) if hurt_timer > 0.0 else (Color(1, 0.85, 0.75) if warcry_timer > 0.0 else Color(1, 1, 1))
	if is_safe():
		# Greyed out while protected by the hub (and briefly after leaving it).
		modulate = Color(0.62, 0.62, 0.66)
	queue_redraw()


func _wants_to_shoot() -> bool:
	# Clicking on inventory slots shouldn't throw axes, and no attacking while safe.
	return Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT) and get_viewport().gui_get_hovered_control() == null \
			and not is_safe()


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
	ClassArt.draw(self, character_class, palette, bob, waddle, facing, ART_SCALE)
	_draw_overhead_bars()


## A health bar over the barbarian's head, and a Warcry timer under it while
## Warcry is active.
func _draw_overhead_bars() -> void:
	var width := 40.0
	var top := Vector2(-width / 2.0, -48.0)
	draw_rect(Rect2(top - Vector2(1, 1), Vector2(width + 2, 7)), Color(0, 0, 0, 0.75))
	var fraction := clampf(hp / max_hp(), 0.0, 1.0)
	var health_color := Color(0.3, 0.85, 0.3) if fraction > 0.5 else (Color(0.95, 0.75, 0.2) if fraction > 0.25 else Color(0.95, 0.25, 0.2))
	draw_rect(Rect2(top, Vector2(width * fraction, 5)), health_color)
	if warcry_timer > 0.0 and not warcry.is_empty():
		var left: float = clampf(warcry_timer / warcry.duration, 0.0, 1.0)
		var bar := top + Vector2(0, 8)
		draw_rect(Rect2(bar - Vector2(1, 1), Vector2(width + 2, 5)), Color(0, 0, 0, 0.75))
		draw_rect(Rect2(bar, Vector2(width * left, 3)), Color(1.0, 0.5, 0.2))


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
