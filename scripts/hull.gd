@tool
class_name Hull
extends Node2D
## A solid steel block: floors at any height, walls, pit sides, big steps. Origin = the middle of its TOP surface; `width` is how wide it is
## and `thick` is how far it goes down. You can't walk through it or jump up through it (use Deck for one-way ledges you can jump up through).
## Use it to build bays with sunken floors, raised floors and walls. Keep step-ups to ~44 px so Kesh can hop onto them.
@export_range(20, 4800, 2, "or_greater") var width := 300:
	set(v):
		width = v; _rebuild()
@export_range(10, 800, 2, "or_greater") var thick := 80:
	set(v):
		thick = v; _rebuild()
@export var hazard_edge := false:              # yellow-black stripe along the top, for a drop edge
	set(v):
		hazard_edge = v; queue_redraw()

func _ready() -> void:
	z_index = -2
	if not Engine.is_editor_hint(): add_to_group("hulls")
	_rebuild()

func _rebuild() -> void:
	if not is_inside_tree(): return
	for ch in get_children(): ch.queue_free()
	var body := StaticBody2D.new()
	body.collision_layer = 1
	body.collision_mask = 0
	var cs := CollisionShape2D.new()
	var rs := RectangleShape2D.new(); rs.size = Vector2(width, thick)
	cs.shape = rs; cs.position = Vector2(0, thick / 2.0)
	body.add_child(cs); add_child(body)
	queue_redraw()

func _process(_d: float) -> void:
	if Engine.is_editor_hint(): queue_redraw()

func _draw() -> void:
	var hw := width / 2.0
	var h := float(thick)
	draw_rect(Rect2(-hw, 0, width, h), Color(0.15, 0.17, 0.23))                      # plating
	draw_rect(Rect2(-hw, 0, width, 4), Color(0.42, 0.45, 0.56))                      # walking surface
	draw_rect(Rect2(-hw, 4, width, 1), Color(0.07, 0.08, 0.11))
	draw_rect(Rect2(-hw, 0, 2, h), Color(0.24, 0.27, 0.35))                          # lit left edge
	draw_rect(Rect2(hw - 3, 0, 3, h), Color(0.09, 0.1, 0.14))                        # shaded right edge
	var y := 18.0
	while y < h - 2.0:                                                               # panel seams
		draw_rect(Rect2(-hw + 2, y, width - 5, 1), Color(0.09, 0.1, 0.14))
		y += 18.0
	var x := -hw + 8.0
	while x < hw - 4.0:                                                              # rivets
		var yy := 9.0
		while yy < h - 4.0:
			draw_rect(Rect2(x, yy, 2, 2), Color(0.3, 0.33, 0.42)); yy += 18.0
		x += 24.0
	if hazard_edge:
		var sx := -hw
		var k := 0
		while sx < hw:
			if k % 2 == 0: draw_rect(Rect2(sx, 0, minf(6.0, hw - sx), 3), Color(0.95, 0.75, 0.2))
			sx += 6.0; k += 1
