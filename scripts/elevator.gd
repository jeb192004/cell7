@tool
class_name Elevator
extends Node2D
## A lift platform in a shaft. Origin = the middle of the car's TOP surface at its LOWER or START position; `travel` is how far it goes
## (negative = up, positive = down). Place a Deck or the street at each stop, flush with the car's top there.
## mode loop: shuttles up and down forever, pausing at each end.  mode on_step: waits at an end until someone stands on it, then
## carries them to the other end.
@export var travel := -92.0:
	set(v):
		travel = v; queue_redraw()
@export_range(10, 200, 1) var speed := 45.0
@export_enum("loop", "on_step") var mode := "loop"
@export_range(0.0, 6.0, 0.1) var pause := 1.0     # wait at each end (loop mode) / before leaving (on_step)
@export_range(24, 120, 2) var width := 44:
	set(v):
		width = v; _rebuild()
var car: AnimatableBody2D
var y_now := 0.0          # car offset from the start, 0..travel
var target := 0.0
var wait_t := 0.0
var riding := false

func _ready() -> void:
	z_index = 0
	_rebuild()
	set_physics_process(not Engine.is_editor_hint())

func _rebuild() -> void:
	if not is_inside_tree(): return
	for ch in get_children(): ch.queue_free()
	car = AnimatableBody2D.new()
	car.sync_to_physics = true
	car.collision_layer = 4; car.collision_mask = 0
	var cs := CollisionShape2D.new()
	var rs := RectangleShape2D.new(); rs.size = Vector2(width, 6.0)
	cs.shape = rs; cs.one_way_collision = true; cs.position = Vector2(0, 3.0)
	car.add_child(cs)
	var art := CarArt.new(); art.w = width; car.add_child(art)
	add_child(car)
	car.position = Vector2(0, y_now)
	queue_redraw()

func _physics_process(d: float) -> void:
	if car == null: return
	var p := get_tree().get_first_node_in_group("player") as Node2D
	riding = p != null and absf(p.global_position.x - car.global_position.x) < width / 2.0 + 1.0 and absf(p.global_position.y - car.global_position.y) < 5.0
	var at_end := absf(y_now - target) < 0.5
	if mode == "loop":
		if at_end:
			wait_t += d
			if wait_t >= pause: target = travel if target == 0.0 else 0.0; wait_t = 0.0
	else:
		if at_end:
			if riding:
				wait_t += d
				if wait_t >= pause: target = travel if target == 0.0 else 0.0; wait_t = 0.0
			else:
				wait_t = 0.0
	if not at_end:
		y_now = move_toward(y_now, target, speed * d)
		car.position.y = y_now

func _draw() -> void:
	# the shaft: dark back panel, two rails, and housings at each end
	var y0 := minf(0.0, travel); var y1 := maxf(0.0, travel)
	var hw := width / 2.0 + 4.0
	draw_rect(Rect2(-hw, y0 - 6, hw * 2.0, y1 - y0 + 14), Color(0.06, 0.07, 0.1))
	for sx in [-hw, hw - 3]:
		draw_rect(Rect2(sx, y0 - 6, 3, y1 - y0 + 14), Color(0.2, 0.22, 0.3))
		draw_rect(Rect2(sx, y0 - 6, 1, y1 - y0 + 14), Color(0.35, 0.38, 0.48))
	draw_rect(Rect2(-hw - 2, y0 - 10, hw * 2.0 + 4, 5), Color(0.25, 0.27, 0.35))
	draw_rect(Rect2(-hw - 2, y1 + 8, hw * 2.0 + 4, 3), Color(0.25, 0.27, 0.35))
	var y := y0
	while y < y1 + 6:
		draw_rect(Rect2(-hw + 5, y, hw * 2.0 - 10, 1), Color(0.1, 0.11, 0.15)); y += 12.0

class CarArt extends Node2D:
	var w := 44
	func _draw() -> void:
		var hw := w / 2.0
		draw_rect(Rect2(-hw, 0, w, 8), Color(0.22, 0.24, 0.31))
		draw_rect(Rect2(-hw, 0, w, 3), Color(0.5, 0.53, 0.64))
		for i in int(w / 4):
			draw_rect(Rect2(-hw + i * 4, 3, 2, 2), Color(0.95, 0.75, 0.2) if i % 2 == 0 else Color(0.1, 0.1, 0.12))   # hazard stripe
		draw_rect(Rect2(-hw, 8, w, 1), Color(0.05, 0.06, 0.08))
		draw_rect(Rect2(-hw + 2, 9, 3, 6), Color(0.14, 0.15, 0.2)); draw_rect(Rect2(hw - 5, 9, 3, 6), Color(0.14, 0.15, 0.2))   # undercarriage
		draw_rect(Rect2(-1, 10, 2, 2), Color(0.3, 1.0, 0.5))
