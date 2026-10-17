@tool
class_name Cage
extends Node2D
## A cage with an Ursk inside. Stand at it and press Up to open it. Placeholder art is drawn in code until real sprites exist.
@export var skin := "ursk"
var freed := false
var prompt := false
var t := 0.0
var run := 0.0
var player: Player

var spr: UrskAnim

func _ready() -> void:
	z_index = -1
	if Engine.is_editor_hint():
		queue_redraw(); return   # shows the bars in the editor so you can see where it is
	add_to_group("cages")
	spr = UrskAnim.new(); spr.show_behind_parent = true; spr.position.y = -3.0; add_child(spr)

func _process(d: float) -> void:
	if Engine.is_editor_hint(): return
	t += d
	if freed:
		run += d; queue_redraw()
		spr.moving = true; spr.face = 1; spr.position.x = 0.0 + run * 90.0
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
	var bar := Color(0.55, 0.57, 0.62, 0.85) if not freed else Color(0.35, 0.36, 0.4)
	draw_rect(Rect2(-18, -3, 36, 3), Color(0.3, 0.3, 0.34))
	draw_rect(Rect2(-18, -66, 36, 3), Color(0.3, 0.3, 0.34))
	if not freed:
		for i in 6: draw_rect(Rect2(-17 + i * 6.6, -64, 2, 62), bar)
		draw_rect(Rect2(-18, -34, 36, 3), Color(0.4, 0.4, 0.45))
	else:
		draw_rect(Rect2(-18, -64, 3, 62), bar); draw_rect(Rect2(15, -64, 3, 62), bar)
	if prompt:
		var bob := int(Time.get_ticks_msec() / 250.0) % 2
		var y := -82.0 - bob
		draw_rect(Rect2(-7, y - 2, 14, 13), Color(0.1, 0.07, 0.12))
		draw_colored_polygon(PackedVector2Array([Vector2(0, y), Vector2(-5, y + 5), Vector2(5, y + 5)]), Color(1, 0.93, 0.6))
		draw_rect(Rect2(-2, y + 5, 4, 5), Color(1, 0.93, 0.6))
