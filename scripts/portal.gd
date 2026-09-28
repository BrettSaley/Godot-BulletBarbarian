class_name Portal
extends Node2D
## A swirling portal the player walks into. World bosses drop one leading to
## their realm's raid, each raid's final room has one leading home, and each
## realm's hub has one to every other realm (locked until unlocked).

const RADIUS := 26.0

var label := "Portal"
var color := Color(0.6, 0.4, 1.0)
## What entering does, read by the main scene ("raid:cox", "realm:1", ...).
var destination := "raid:cox"
## Locked portals are greyed out and say what unlocks them.
var locked := false
var lock_hint := ""
## Seconds before it closes; 0 means it stays open.
var lifetime := 0.0
var time := 0.0


func _ready() -> void:
	add_to_group("portals")


func _process(delta: float) -> void:
	time += delta
	if lifetime > 0.0:
		lifetime -= delta
		if lifetime <= 0.0:
			queue_free()
	queue_redraw()


func _draw() -> void:
	draw_set_transform(Vector2(0, 8), 0.0, Vector2(1.0, 0.4))
	draw_circle(Vector2.ZERO, RADIUS + 4, Color(0, 0, 0, 0.35))
	draw_set_transform(Vector2.ZERO, 0.0, Vector2(1.0, 0.75))
	var tint := Color(0.4, 0.4, 0.42) if locked else color
	draw_circle(Vector2.ZERO, RADIUS + 3, tint.darkened(0.5))
	draw_circle(Vector2.ZERO, RADIUS, tint.darkened(0.2))
	for k in 3:
		var r := RADIUS * (0.35 + 0.22 * k)
		var start := (0.0 if locked else time) * (2.0 + k) + k
		draw_arc(Vector2.ZERO, r, start, start + PI * 1.3, 16, tint.lightened(0.3 + 0.15 * k), 2.5)
	draw_circle(Vector2.ZERO, 5.0, Color(1, 1, 1, 0.8))
	draw_set_transform(Vector2.ZERO)
	var text := label if lifetime <= 0.0 else "%s (%ds)" % [label, ceili(lifetime)]
	draw_string(ThemeDB.fallback_font, Vector2(-100, -RADIUS - 8), text, HORIZONTAL_ALIGNMENT_CENTER, 200, 13, Color(1, 1, 1))
	if locked:
		# A padlock over the portal, and what it takes to open it.
		draw_rect(Rect2(Vector2(-8, -4), Vector2(16, 12)), Color(0.85, 0.7, 0.3))
		draw_arc(Vector2(0, -4), 6.0, PI, TAU, 10, Color(0.85, 0.7, 0.3), 2.5)
		draw_string(ThemeDB.fallback_font, Vector2(-120, RADIUS + 18), lock_hint, HORIZONTAL_ALIGNMENT_CENTER, 240, 11, Color(1, 0.8, 0.6))
