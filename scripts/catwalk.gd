@tool
class_name Catwalk
extends Deck
## A steel grating walkway hung from the ceiling on rods, with handrails. Same rules as a Deck: origin = middle of the walking surface,
## one-way (jump up through it, Down + Jump to drop). Good for bridging gaps above the Wardens' heads.
@export var rails := true:
	set(v):
		rails = v; queue_redraw()

func _init() -> void:
	legs = false; skirt = 4

func _draw() -> void:
	var hw := width / 2.0
	var steel := Color(0.33, 0.36, 0.46); var dark := Color(0.08, 0.09, 0.13)
	# hanging rods up to the ceiling
	var up := global_position.y if is_inside_tree() else 90.0
	var x := -hw + 14.0
	while x < hw - 6.0:
		draw_rect(Rect2(x, -up, 2, up), Color(0.14, 0.16, 0.22))
		draw_rect(Rect2(x, -up, 1, up), Color(0.24, 0.27, 0.35))
		x += 90.0
	# grating: a thin plate with a lattice underneath
	draw_rect(Rect2(-hw, 0, width, 3), steel)
	draw_rect(Rect2(-hw, 3, width, 1), dark)
	var gx := -hw
	while gx < hw - 8.0:
		draw_line(Vector2(gx, 4), Vector2(gx + 8, 9), Color(0.22, 0.24, 0.32), 1.0)
		draw_line(Vector2(gx + 8, 9), Vector2(gx + 16, 4), Color(0.22, 0.24, 0.32), 1.0)
		gx += 16.0
	draw_rect(Rect2(-hw, 9, width, 1), Color(0.22, 0.24, 0.32))
	for e in [-hw, hw - 10]:
		for i in 5: draw_rect(Rect2(e + i * 2, 1, 1, 2), Color(0.95, 0.75, 0.2))
	if rails:
		var rx := -hw + 2.0
		while rx <= hw - 1.0:
			draw_rect(Rect2(rx, -18, 2, 18), steel)
			rx += 36.0
		draw_rect(Rect2(-hw + 2, -18, width - 2, 2), Color(0.85, 0.7, 0.25))     # top rail
		draw_rect(Rect2(-hw + 2, -9, width - 2, 1), Color(0.5, 0.52, 0.62))      # mid rail
