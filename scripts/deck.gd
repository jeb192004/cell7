@tool
class_name Deck
extends Node2D
## A floor you can stand on above the street (multi-floor levels). Origin = the middle of its TOP surface; `width` is how long it is.
## One-way: jump up through it from below, land on it, Down + Jump to drop through. `legs` draws support struts down to the street.
## Put Stairs or an Elevator at its ends to get on and off. Wardens placed on it should sit at this node's y.
@export_range(40, 2400, 2, "or_greater") var width := 300:
	set(v):
		width = v; _rebuild()
@export var legs := true:
	set(v):
		legs = v; queue_redraw()
@export_range(0, 60, 1) var skirt := 8:           # depth of the steel plate under the walking surface
	set(v):
		skirt = v; queue_redraw()
const STREET_Y := 222.0

func _ready() -> void:
	z_index = -1
	if not Engine.is_editor_hint(): add_to_group("decks")
	_rebuild()

func _rebuild() -> void:
	if not is_inside_tree(): return
	for ch in get_children(): ch.queue_free()
	var body := StaticBody2D.new()
	body.collision_layer = 4          # layer 3: the same one-way "rooftop" layer the Player's drop-through already handles
	body.collision_mask = 0
	var cs := CollisionShape2D.new()
	var rs := RectangleShape2D.new(); rs.size = Vector2(width, 6.0)
	cs.shape = rs; cs.one_way_collision = true; cs.position = Vector2(0, 3.0)
	body.add_child(cs); add_child(body)
	queue_redraw()

func _process(_d: float) -> void:
	if Engine.is_editor_hint(): queue_redraw()

func _draw() -> void:
	var hw := width / 2.0
	draw_rect(Rect2(-hw, 0, width, skirt + 3), Color(0.17, 0.19, 0.25))              # plate
	draw_rect(Rect2(-hw, 0, width, 3), Color(0.42, 0.45, 0.56))                      # walking surface
	draw_rect(Rect2(-hw, 3, width, 1), Color(0.07, 0.08, 0.11))
	draw_rect(Rect2(-hw, skirt + 2, width, 1), Color(0.07, 0.08, 0.11))
	var x := -hw + 6.0
	while x < hw - 3.0:
		draw_rect(Rect2(x, 5, 2, 2), Color(0.3, 0.33, 0.42)); x += 14.0                # rivets
	for e in [-hw, hw - 10]:                                                         # hazard stripes at both ends
		for i in 5: draw_rect(Rect2(e + i * 2, 1, 1, 2), Color(0.95, 0.75, 0.2))
	if legs:
		var drop := STREET_Y - global_position.y if is_inside_tree() else 90.0
		if drop > skirt + 6.0:
			for lx in [-hw + 10.0, hw - 14.0]:
				draw_rect(Rect2(lx, skirt + 3, 4, drop - skirt - 3), Color(0.13, 0.15, 0.2))
				draw_rect(Rect2(lx, skirt + 3, 1, drop - skirt - 3), Color(0.26, 0.29, 0.37))
