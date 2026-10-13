@tool
class_name Roof
extends Node2D
## A building you can stand on. Place it with its origin on the street (y = 222); `height` is how far the roof is above the street.
## Solid: Kesh can't walk through it. Jump onto the roof from a lower one (keep steps up to ~44 px) or step off the edge to fall.
@export_range(40, 400, 1, "or_greater") var width := 140:
	set(v):
		width = v; _rebuild()
@export_range(30, 600, 2, "or_greater") var height := 40:
	set(v):
		height = v; _rebuild()
@export_range(0, 400, 1, "or_greater") var depth := 0:        # extra building below the street line (for levels with no street under it)
	set(v):
		depth = v; _rebuild()
@export var look := 1:                 # change for a different window / clutter pattern
	set(v):
		look = v; queue_redraw()

func _ready() -> void:
	z_index = -4
	if not Engine.is_editor_hint(): add_to_group("roofs")
	_rebuild()

func _rebuild() -> void:
	if not is_inside_tree(): return
	for ch in get_children(): ch.queue_free()
	# solid building: you can't walk through it, only stand on top of it or fall past it
	var body := StaticBody2D.new()
	body.collision_layer = 1
	body.collision_mask = 0
	var cs := CollisionShape2D.new()
	var rs := RectangleShape2D.new()
	rs.size = Vector2(width, height + depth)
	cs.shape = rs
	cs.position = Vector2(0, (-height + depth) / 2.0)
	body.add_child(cs)
	add_child(body)
	queue_redraw()

func _draw() -> void:
	var hw := width / 2.0
	var h := float(height)
	var body := Color(0.27, 0.22, 0.40)
	draw_rect(Rect2(-hw, -h, width, h + depth), body)
	draw_rect(Rect2(-hw, -h, 3, h + depth), Color(0.19, 0.15, 0.30))          # shaded edge
	draw_rect(Rect2(hw - 3, -h, 3, h + depth), Color(0.19, 0.15, 0.30))
	draw_rect(Rect2(-hw - 2, -h - 2, width + 4, 4), Color(0.47, 0.41, 0.58))   # parapet
	draw_rect(Rect2(-hw - 2, -h + 2, width + 4, 1), Color(0.78, 0.58, 0.28))    # amber trim
	var rng := RandomNumberGenerator.new()
	rng.seed = look * 7919 + width * 31 + height
	for wy in range(int(-h + 10), -6 + depth, 12):
		for wx in range(int(-hw + 8), int(hw - 10), 12):
			var lit := rng.randf() < 0.3
			draw_rect(Rect2(wx, wy, 6, 7), Color(1.0, 0.76, 0.38) if lit else Color(0.13, 0.11, 0.22))
			if lit: draw_rect(Rect2(wx, wy, 6, 2), Color(1.0, 0.9, 0.6))
	draw_rect(Rect2(-6, -14, 12, 14), Color(0.16, 0.13, 0.26))   # door
	# rooftop clutter (just scenery)
	var cx := -hw + 12.0
	while cx < hw - 22.0:
		match rng.randi() % 4:
			0:
				draw_rect(Rect2(cx, -h - 10, 14, 8), Color(0.34, 0.30, 0.46)); draw_rect(Rect2(cx + 3, -h - 9, 8, 5), Color(0.2, 0.18, 0.3))
			1:
				draw_rect(Rect2(cx + 6, -h - 18, 1, 16), Color(0.3, 0.26, 0.4)); draw_rect(Rect2(cx + 2, -h - 14, 9, 1), Color(0.3, 0.26, 0.4))
			2:
				draw_rect(Rect2(cx, -h - 13, 12, 9), Color(0.4, 0.3, 0.3)); draw_rect(Rect2(cx + 1, -h - 4, 2, 2), Color(0.3, 0.26, 0.4)); draw_rect(Rect2(cx + 9, -h - 4, 2, 2), Color(0.3, 0.26, 0.4))
			_:
				pass
		cx += 20.0 + rng.randi() % 14
