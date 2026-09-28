extends Node2D
## Ground hazards used by OSRS-style boss mechanics:
##   blasts  - a telegraphed circle or rectangle that fills up, then hurts
##             the player if they're still inside (falling crystals, bombs)
##   pools   - lingering circles or rectangles that hurt every tick while
##             the player stands in them (acid, venom, fire walls)
## Enemies reach this node through the "hazards" group.

const TICK := 0.3
const FLASH_TIME := 0.2

## Set by the main scene.
var player: Node2D

var blasts: Array[Dictionary] = []
var pools: Array[Dictionary] = []


func _ready() -> void:
	add_to_group("hazards")


func blast(pos: Vector2, radius: float, delay: float, damage: float, source: String, color := Color(1, 0.4, 0.2), slow := 0.0) -> void:
	blasts.append({"shape": "circle", "pos": pos, "radius": radius, "delay": delay, "timer": delay,
			"damage": damage, "source": source, "color": color, "flash": 0.0, "slow": slow})


func rect_blast(rect: Rect2, delay: float, damage: float, source: String, color := Color(0.6, 0.8, 1)) -> void:
	blasts.append({"shape": "rect", "rect": rect, "delay": delay, "timer": delay,
			"damage": damage, "source": source, "color": color, "flash": 0.0})


func pool(pos: Vector2, radius: float, lifetime: float, dps: float, source: String, color := Color(0.4, 0.8, 0.2), slow := 0.0) -> void:
	pools.append({"shape": "circle", "pos": pos, "radius": radius, "time": lifetime, "lifetime": lifetime,
			"dps": dps, "source": source, "color": color, "tick": 0.0, "slow": slow})


func rect_pool(rect: Rect2, lifetime: float, dps: float, source: String, color := Color(1, 0.45, 0.1)) -> void:
	pools.append({"shape": "rect", "rect": rect, "time": lifetime, "lifetime": lifetime,
			"dps": dps, "source": source, "color": color, "tick": 0.0})


func clear_all() -> void:
	blasts.clear()
	pools.clear()
	queue_redraw()


func _inside(h: Dictionary, point: Vector2, margin: float) -> bool:
	if h.shape == "circle":
		return point.distance_to(h.pos) < h.radius + margin
	return h.rect.grow(margin).has_point(point)


func _physics_process(delta: float) -> void:
	var alive: bool = player != null and player.is_alive()
	for i in range(blasts.size() - 1, -1, -1):
		var b := blasts[i]
		if b.timer > 0.0:
			b.timer -= delta
			if b.timer <= 0.0:
				b.flash = FLASH_TIME
				if alive and _inside(b, player.position, player.hitbox_radius):
					player.take_damage(b.damage, b.source)
					if b.get("slow", 0.0) > 0.0:
						player.apply_slow(b.slow)
		else:
			b.flash -= delta
			if b.flash <= 0.0:
				blasts.remove_at(i)

	for i in range(pools.size() - 1, -1, -1):
		var p := pools[i]
		p.time -= delta
		if p.time <= 0.0:
			pools.remove_at(i)
			continue
		p.tick -= delta
		if p.tick <= 0.0 and alive and _inside(p, player.position, player.hitbox_radius * 0.5):
			p.tick = TICK
			if p.dps > 0.0:
				player.take_damage(p.dps * TICK, p.source, true)
			if p.get("slow", 0.0) > 0.0:
				player.apply_slow(p.slow)
	queue_redraw()


func _draw() -> void:
	for p in pools:
		var fade := clampf(p.time / 0.5, 0.0, 1.0) * clampf((p.lifetime - p.time) / 0.3, 0.0, 1.0)
		var color: Color = p.color
		if p.shape == "circle":
			draw_circle(p.pos, p.radius, Color(color, 0.45 * fade))
			draw_circle(p.pos, p.radius * 0.6, Color(color.lightened(0.2), 0.35 * fade))
			for k in 3:
				var bubble: Vector2 = p.pos + Vector2.from_angle(p.time * 1.5 + k * 2.1) * p.radius * 0.5
				draw_circle(bubble, 3.0, Color(color.lightened(0.5), 0.6 * fade))
		else:
			draw_rect(p.rect, Color(color, 0.55 * fade))
			draw_rect(p.rect.grow(-3), Color(color.lightened(0.3), 0.35 * fade))

	for b in blasts:
		var color: Color = b.color
		if b.timer > 0.0:
			var progress: float = 1.0 - b.timer / b.delay
			if b.shape == "circle":
				draw_circle(b.pos, b.radius, Color(color, 0.12))
				draw_arc(b.pos, b.radius, 0.0, TAU, 40, Color(color, 0.8), 2.0)
				draw_circle(b.pos, b.radius * progress, Color(color, 0.3))
			else:
				draw_rect(b.rect, Color(color, 0.12))
				draw_rect(b.rect, Color(color, 0.8), false, 2.0)
				var inner: Rect2 = b.rect
				draw_rect(Rect2(inner.get_center() - inner.size * progress / 2.0, inner.size * progress), Color(color, 0.3))
		else:
			var alpha: float = b.flash / FLASH_TIME
			if b.shape == "circle":
				draw_circle(b.pos, b.radius, Color(color.lightened(0.4), 0.8 * alpha))
			else:
				draw_rect(b.rect, Color(color.lightened(0.4), 0.8 * alpha))
