@tool
class_name ChargeSpot
extends Node2D
## A place Fuse can plant a charge (2-1C). Origin is where she stands, on the deck. Walk up and press SHOOT.
## ground: a charge on the floor plate. wall: a charge on the bulkhead / console on the `face` side.
@export_enum("ground", "wall") var kind := "ground":
	set(v):
		kind = v; queue_redraw()
@export_enum("Left:-1", "Right:1") var face := 1:
	set(v):
		face = v; queue_redraw()
var planted := false
var near := false
var t := 0.0
var hint: PixLabel

func _ready() -> void:
	z_index = -1
	if Engine.is_editor_hint(): return
	add_to_group("charge_spots")
	hint = PixLabel.new("SHOOT: PLANT", 1, Color(1.0, 0.85, 0.35))
	hint.position = Vector2(0, -62); hint.visible = false; hint.z_index = 5
	add_child(hint)

func can_plant(p: Vector2) -> bool:
	return not planted and absf(p.x - global_position.x) < 14.0 and absf(p.y - global_position.y) < 12.0

func plant() -> void:
	planted = true
	Sfx.play("pickup")
	var lv: Node = self
	while lv != null and not (lv is Level): lv = lv.get_parent()
	if lv is Level:
		lv.freed += 1
		lv._toast("CHARGE SET %d/%d" % [lv.freed, maxi(lv.free_required, lv.freed)])
	queue_redraw()

func _process(d: float) -> void:
	t += d
	if Engine.is_editor_hint():
		queue_redraw(); return
	var p := get_tree().get_first_node_in_group("player") as Node2D
	near = p != null and can_plant(p.global_position)
	hint.visible = near
	queue_redraw()

func _draw() -> void:
	var blink := int(t * 3.0) % 2 == 0
	if kind == "ground":
		draw_rect(Rect2(-14, -2, 28, 3), Color(0.14, 0.15, 0.19))
		for i in 7: draw_rect(Rect2(-14 + i * 4, -2, 2, 3), Color(0.85, 0.7, 0.2) if not planted else Color(0.35, 0.3, 0.12))
		if planted:
			draw_rect(Rect2(-5, -8, 10, 6), Color(0.3, 0.32, 0.36)); draw_rect(Rect2(-5, -8, 10, 1), Color(0.5, 0.52, 0.56))
			draw_rect(Rect2(-1, -7, 2, 2), Color(1, 0.2, 0.15) if blink else Color(0.4, 0.05, 0.05))
		elif not Engine.is_editor_hint() or true:
			draw_rect(Rect2(-1, -14 - (2 if blink else 0), 2, 6), Color(1.0, 0.85, 0.35, 0.9))
	else:
		var x := face * 14.0
		draw_rect(Rect2(x - 12, -86, 24, 86), Color(0.16, 0.17, 0.22)); draw_rect(Rect2(x - 12, -86, 24, 3), Color(0.3, 0.32, 0.4))
		draw_rect(Rect2(x - 8, -56, 16, 24), Color(0.08, 0.09, 0.12)); draw_rect(Rect2(x - 7, -55, 14, 8), Color(0.2, 0.6, 0.7, 0.8 if blink else 0.5))
		if planted:
			draw_rect(Rect2(x - 5 - face * 0, -44, 10, 8), Color(0.3, 0.32, 0.36))
			draw_rect(Rect2(x - 1, -42, 2, 2), Color(1, 0.2, 0.15) if blink else Color(0.4, 0.05, 0.05))
		else:
			draw_rect(Rect2(x - 1, -72 - (2 if blink else 0), 2, 6), Color(1.0, 0.85, 0.35, 0.9))
