class_name Cage
extends Node2D
## A cage with an Ursk inside. Stand at it and press Up to open it. Placeholder art is drawn in code until real sprites exist.
@export var skin := "ursk"
var freed := false
var prompt := false
var t := 0.0
var run := 0.0
var player: Player

func _ready() -> void:
	add_to_group("cages")
	z_index = -1

func _process(d: float) -> void:
	t += d
	if freed:
		run += d; queue_redraw()
		if run > 2.0: queue_free()
		return
	if player == null: player = get_tree().get_first_node_in_group("player") as Player
	if player == null: return
	var near := player.hp > 0 and absf(player.global_position.x - global_position.x) < 26.0 and absf(player.global_position.y - global_position.y) < 40.0
	prompt = near
	if near and Input.is_action_just_pressed("up"): _free()
	queue_redraw()

func _free() -> void:
	freed = true
	Sfx.play("pickup"); Sfx.play("shield_break", 1.4)
	var lv: Node = self
	while lv != null and not (lv is Level): lv = lv.get_parent()
	if lv is Level:
		lv.freed += 1
		lv._toast("FREED %d/%d" % [lv.freed, maxi(lv.free_required, lv.freed)])

func _draw() -> void:
	var fur := Color(0.46, 0.31, 0.2); var dark := Color(0.28, 0.18, 0.12)
	if not freed or run < 0.6:
		var ox := 0.0 if not freed else run * 90.0
		draw_rect(Rect2(-9 + ox, -50, 18, 30), fur)               # body
		draw_rect(Rect2(-7 + ox, -62, 14, 14), fur)               # head
		draw_rect(Rect2(-5 + ox, -22, 4, 22), dark); draw_rect(Rect2(1 + ox, -22, 4, 22), dark)   # legs
		draw_rect(Rect2(1 + ox, -58, 3, 3), Color(0.95, 0.9, 0.6))   # eye
		draw_rect(Rect2(-13 + ox, -48, 4, 22), dark); draw_rect(Rect2(9 + ox, -48, 4, 22), dark)   # arms
	var bar := Color(0.55, 0.57, 0.62) if not freed else Color(0.35, 0.36, 0.4)
	draw_rect(Rect2(-18, -3, 36, 3), Color(0.3, 0.3, 0.34))
	draw_rect(Rect2(-18, -66, 36, 3), Color(0.3, 0.3, 0.34))
	if not freed:
		for i in 6: draw_rect(Rect2(-17 + i * 6.6, -64, 3, 62), bar)
		draw_rect(Rect2(-18, -34, 36, 3), Color(0.4, 0.4, 0.45))
	else:
		draw_rect(Rect2(-18, -64, 3, 62), bar); draw_rect(Rect2(15, -64, 3, 62), bar)
	if prompt:
		var bob := int(Time.get_ticks_msec() / 250.0) % 2
		var y := -82.0 - bob
		draw_rect(Rect2(-7, y - 2, 14, 13), Color(0.1, 0.07, 0.12))
		draw_colored_polygon(PackedVector2Array([Vector2(0, y), Vector2(-5, y + 5), Vector2(5, y + 5)]), Color(1, 0.93, 0.6))
		draw_rect(Rect2(-2, y + 5, 4, 5), Color(1, 0.93, 0.6))
