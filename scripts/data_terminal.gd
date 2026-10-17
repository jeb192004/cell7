@tool
class_name DataTerminal
extends Node2D
## A computer terminal Kesh steals data from (2-3). Origin is where he stands, on the deck. Hold UP next to it until the bar fills.
@export var hold_time := 2.5
var progress := 0.0
var done := false
var near := false
var t := 0.0
var hint: PixLabel

func _ready() -> void:
	z_index = -1
	if Engine.is_editor_hint(): return
	add_to_group("terminals")
	hint = PixLabel.new("HOLD UP: DOWNLOAD", 1, Color(1.0, 0.85, 0.35))
	hint.position = Vector2(0, -78); hint.visible = false; hint.z_index = 5
	add_child(hint)

func _process(d: float) -> void:
	t += d
	if not Engine.is_editor_hint() and not done:
		var p := get_tree().get_first_node_in_group("player") as Node2D
		near = p != null and absf(p.global_position.x - global_position.x) < 20.0 and absf(p.global_position.y - global_position.y) < 14.0
		hint.visible = near and progress <= 0.0
		if near and Input.is_action_pressed("up") and not p.get("is_back"):
			progress += d
			if progress >= hold_time: _finish()
		else:
			progress = maxf(progress - d * 2.0, 0.0)
	queue_redraw()

func _finish() -> void:
	done = true
	Sfx.play("pickup")
	var lv: Node = self
	while lv != null and not (lv is Level): lv = lv.get_parent()
	if lv is Level:
		lv.freed += 1
		lv._toast("DATA STOLEN")

func _draw() -> void:
	var blink := int(t * 3.0) % 2 == 0
	draw_rect(Rect2(-16, -64, 32, 64), Color(0.14, 0.15, 0.2)); draw_rect(Rect2(-16, -64, 32, 3), Color(0.32, 0.34, 0.42))
	draw_rect(Rect2(-12, -56, 24, 22), Color(0.05, 0.07, 0.1))
	var scr := Color(0.3, 1.0, 0.6, 0.9) if done else Color(0.25, 0.75, 0.9, 0.85 if blink else 0.6)
	for i in 4: draw_rect(Rect2(-10, -53 + i * 5, 20 - (i % 2) * 6, 2), scr)
	draw_rect(Rect2(-12, -28, 24, 6), Color(0.08, 0.09, 0.12))
	for i in 5: draw_rect(Rect2(-10 + i * 5, -27, 3, 4), Color(0.35, 0.37, 0.45))
	if progress > 0.0 and not done:
		draw_rect(Rect2(-14, -72, 28, 5), Color(0, 0, 0, 0.7)); draw_rect(Rect2(-13, -71, 26.0 * progress / hold_time, 3), Color(0.3, 1.0, 0.6))
