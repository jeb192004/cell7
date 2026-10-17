@tool
class_name Gantry
extends Deck
## A raised work platform on steel trusses that stand on the street. Same rules as a Deck: origin = middle of the walking surface, one-way.
## Taller and heavier looking than a Catwalk: cross-braced legs, a thick plate, a rail along the edge and a blinking warning lamp.
const LEG_EVERY := 150.0

func _init() -> void:
	legs = true; skirt = 10

func _process(_d: float) -> void:
	queue_redraw()

func _draw() -> void:
	var hw := width / 2.0
	var plate := Color(0.17, 0.19, 0.25); var edge := Color(0.42, 0.45, 0.56); var dark := Color(0.07, 0.08, 0.11)
	var drop := (STREET_Y - global_position.y) if is_inside_tree() else 90.0
	# trusses: two H-legs per bay with X bracing
	var n := maxi(int(width / LEG_EVERY), 1)
	for i in n + 1:
		var lx := -hw + 10.0 + (width - 28.0) * float(i) / float(n)
		if drop > skirt + 8.0:
			draw_rect(Rect2(lx, skirt + 3, 4, drop - skirt - 3), Color(0.13, 0.15, 0.2))
			draw_rect(Rect2(lx, skirt + 3, 1, drop - skirt - 3), Color(0.26, 0.29, 0.37))
			draw_rect(Rect2(lx + 9, skirt + 3, 4, drop - skirt - 3), Color(0.13, 0.15, 0.2))
			draw_rect(Rect2(lx + 9, skirt + 3, 1, drop - skirt - 3), Color(0.26, 0.29, 0.37))
			var y := float(skirt + 3)
			while y + 22.0 <= drop:
				draw_line(Vector2(lx + 4, y), Vector2(lx + 9, y + 22), Color(0.2, 0.22, 0.3), 1.0)
				draw_line(Vector2(lx + 9, y), Vector2(lx + 4, y + 22), Color(0.2, 0.22, 0.3), 1.0)
				draw_rect(Rect2(lx, y + 22, 13, 2), Color(0.2, 0.22, 0.3))
				y += 24.0
	# the deck: thick plate with rivets and hazard stripes
	draw_rect(Rect2(-hw, 0, width, skirt + 3), plate)
	draw_rect(Rect2(-hw, 0, width, 3), edge)
	draw_rect(Rect2(-hw, 3, width, 1), dark)
	draw_rect(Rect2(-hw, skirt + 2, width, 1), dark)
	var x := -hw + 6.0
	while x < hw - 3.0:
		draw_rect(Rect2(x, 6, 2, 2), Color(0.3, 0.33, 0.42)); x += 12.0
	for e in [-hw, hw - 14]:
		for i in 7: draw_rect(Rect2(e + i * 2, 1, 1, 2), Color(0.95, 0.75, 0.2))
	# back rail and a blinking lamp on a post
	draw_rect(Rect2(-hw + 2, -14, width - 4, 2), Color(0.5, 0.52, 0.62))
	var rx := -hw + 4.0
	while rx < hw - 2.0:
		draw_rect(Rect2(rx, -14, 2, 14), Color(0.33, 0.36, 0.46)); rx += 40.0
	var on := int(Time.get_ticks_msec() / 500.0) % 2 == 0
	draw_rect(Rect2(hw - 8, -26, 4, 12), Color(0.2, 0.22, 0.3))
	draw_rect(Rect2(hw - 9, -30, 6, 5), Color(1.0, 0.25, 0.2) if on else Color(0.4, 0.1, 0.1))
