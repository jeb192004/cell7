@tool
class_name Stairs
extends Node2D
## A staircase between floors. Origin = the foot of the stairs, on the lower floor. They climb `rise` px toward `dir` (1 right, -1 left),
## `rise * run_ratio` px long. You just walk up or down: the collision is a thin one-way slope, so you can also walk along the floor underneath (the steps are see-through to the floor). Put a Deck starting at the top end.
## top_end() gives the world point where it meets the upper floor.
@export_range(20, 400, 2, "or_greater") var rise := 92:
	set(v):
		rise = v; _rebuild()
@export_range(1.0, 2.5, 0.05) var run_ratio := 1.25:
	set(v):
		run_ratio = v; _rebuild()
@export_enum("Up to the right:1", "Up to the left:-1") var dir := 1:
	set(v):
		dir = v; _rebuild()

func run_len() -> float:
	return rise * run_ratio

func top_end() -> Vector2:
	return global_position + Vector2(dir * run_len(), -rise)

func _ready() -> void:
	z_index = -2
	_rebuild()

func _rebuild() -> void:
	if not is_inside_tree(): return
	for ch in get_children(): ch.queue_free()
	var body := StaticBody2D.new()
	body.collision_layer = 1; body.collision_mask = 0
	var cs := CollisionPolygon2D.new()
	var r := run_len()
	cs.polygon = PackedVector2Array([Vector2(0, 0), Vector2(dir * r, -rise), Vector2(dir * r, -rise + 4), Vector2(0, 4)])
	cs.one_way_collision = true
	body.add_child(cs); add_child(body)
	queue_redraw()

func _draw() -> void:
	var r := run_len()
	var n := maxi(int(rise / 11.0), 2)
	var sw := r / n; var sh := float(rise) / n
	# open frame under the steps (dark, see-through look)
	draw_colored_polygon(PackedVector2Array([Vector2(0, 0), Vector2(dir * r, -rise), Vector2(dir * r, 0)]), Color(0.07, 0.08, 0.12, 0.55))
	for i in n:
		var x0 := dir * sw * i
		var top := -sh * (i + 1)
		var rect := Rect2(minf(x0, x0 + dir * sw), top, sw, sh)
		draw_rect(rect, Color(0.2, 0.22, 0.29))
		draw_rect(Rect2(rect.position.x, top, sw, 2), Color(0.45, 0.48, 0.6))           # tread
		draw_rect(Rect2(rect.position.x, top + 2, sw, 1), Color(0.07, 0.08, 0.11))
	# handrail along the slope
	var a := Vector2(0, -26); var b := Vector2(dir * r, -rise - 26)
	draw_line(a, b, Color(0.85, 0.7, 0.25), 1.0)
	for t in [0.0, 0.5, 1.0]:
		var p := a.lerp(b, t)
		draw_line(p, p + Vector2(0, 26), Color(0.55, 0.45, 0.2), 1.0)
