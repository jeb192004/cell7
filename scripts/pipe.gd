@tool
class_name Pipe
extends Deck
## A big pipe you can walk along (or set `solid` off and it is only scenery, like pipes along the ceiling). Origin = the TOP of the pipe,
## in the middle. One-way like a Deck: jump up onto it, Down + Jump to drop off. Brackets hold it up from the ceiling; `steam` adds a leaking joint.
@export var solid := true:
	set(v):
		solid = v; _rebuild()
@export var steam := false:
	set(v):
		steam = v; queue_redraw()
const THICK := 10

func _init() -> void:
	legs = false; skirt = 0; width = 240

func _rebuild() -> void:
	super._rebuild()
	if not solid:
		for ch in get_children():
			if ch is StaticBody2D: ch.queue_free()

func _process(_d: float) -> void:
	if steam or Engine.is_editor_hint(): queue_redraw()

func _draw() -> void:
	var hw := width / 2.0
	var up := global_position.y if is_inside_tree() else 90.0
	# brackets up to the ceiling
	var x := -hw + 20.0
	while x < hw - 8.0:
		draw_rect(Rect2(x, -up, 4, up), Color(0.12, 0.14, 0.19))
		draw_rect(Rect2(x - 2, 0, 8, THICK + 2), Color(0.2, 0.22, 0.3))
		x += 110.0
	# the pipe: a lit top edge, body, shaded bottom
	draw_rect(Rect2(-hw, 0, width, THICK), Color(0.2, 0.27, 0.32))
	draw_rect(Rect2(-hw, 0, width, 2), Color(0.5, 0.62, 0.68))
	draw_rect(Rect2(-hw, 2, width, 2), Color(0.3, 0.4, 0.46))
	draw_rect(Rect2(-hw, THICK - 2, width, 2), Color(0.1, 0.14, 0.18))
	# flanges and an amber band
	var fx := -hw + 40.0
	while fx < hw - 6.0:
		draw_rect(Rect2(fx, -2, 5, THICK + 4), Color(0.34, 0.38, 0.46))
		draw_rect(Rect2(fx, -2, 5, 1), Color(0.6, 0.64, 0.72))
		draw_rect(Rect2(fx + 7, 0, 2, THICK), Color(0.78, 0.58, 0.28))
		fx += 70.0
	draw_rect(Rect2(-hw - 3, -2, 4, THICK + 4), Color(0.34, 0.38, 0.46))
	draw_rect(Rect2(hw - 1, -2, 4, THICK + 4), Color(0.34, 0.38, 0.46))
	if steam and is_inside_tree():
		var jx := -hw + 40.0 + 70.0 * floorf(width / 140.0)   # leak at a middle flange
		var tt := Time.get_ticks_msec() / 1000.0
		for i in 5:
			var ph := fposmod(tt * 1.4 + i * 0.2, 1.0)
			draw_circle(Vector2(jx + 2.0 + sin(ph * 6.0 + i) * 3.0, THICK + 2.0 + ph * 22.0), 1.5 + ph * 3.0, Color(0.85, 0.9, 0.95, 0.5 * (1.0 - ph)))
