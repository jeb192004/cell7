@tool
class_name Vent
extends Node2D
## A crawl space. Origin = left end, at the vent floor. Kesh only gets in through a Grate (press Up at it).
## Nothing shows from outside; once he's inside, the shaft fades in see-through so you can watch him crawl.
## While inside he is hidden from Wardens and drones. Put it anywhere: street level, up high, or below the floor.
@export_range(60, 1600, 1, "or_greater") var width := 300.0:
	set(v):
		width = v; queue_redraw()
@export_range(30, 80, 1) var height := 34.0:
	set(v):
		height = v; queue_redraw()
var amount := 0.0
var trim: Node2D

func _ready() -> void:
	if Engine.is_editor_hint(): return
	add_to_group("vents")
	z_index = 1
	modulate.a = 0.0
	trim = Trim.new(); trim.z_index = 1; add_child(trim)
	_body(Vector2(width / 2.0, 4.0), Vector2(width + 12.0, 8.0))           # floor
	_body(Vector2(width / 2.0, -height - 4.0), Vector2(width + 12.0, 8.0))  # ceiling
	_body(Vector2(-3.0, -height / 2.0), Vector2(6.0, height + 16.0))        # ends
	_body(Vector2(width + 3.0, -height / 2.0), Vector2(6.0, height + 16.0))

func _body(pos: Vector2, size: Vector2) -> void:
	var b := StaticBody2D.new(); b.collision_layer = 8; b.collision_mask = 0
	var cs := CollisionShape2D.new(); var r := RectangleShape2D.new(); r.size = size
	cs.shape = r; cs.position = pos; b.add_child(cs); add_child(b)

func holds(p: Vector2) -> bool:
	var o := global_position
	return p.x >= o.x - 2.0 and p.x <= o.x + width + 2.0 and p.y >= o.y - height - 4.0 and p.y <= o.y + 8.0

func _process(d: float) -> void:
	if Engine.is_editor_hint(): return
	var p := get_tree().get_first_node_in_group("player") as Player
	var on := p != null and p.vent == self
	amount = move_toward(amount, 1.0 if on else 0.0, d * 5.0)
	modulate.a = amount
	visible = amount > 0.01

func _draw() -> void:
	var w := width; var h := height
	if Engine.is_editor_hint():
		draw_rect(Rect2(0, -h, w, h), Color(0.3, 0.8, 1.0, 0.25))
		draw_rect(Rect2(0, -h, w, h), Color(0.3, 0.8, 1.0, 0.9), false, 1.0)
		return
	draw_rect(Rect2(-400, -h - 300, w + 800, h + 600), Color(0.0, 0.0, 0.02, 0.5))   # dims everything else while you're inside
	draw_rect(Rect2(0, -h, w, h), Color(0.07, 0.08, 0.12, 0.55))
	var x := 10.0
	while x < w:
		draw_rect(Rect2(x, -h, 2, h), Color(0.2, 0.22, 0.3, 0.45)); x += 18.0

class Trim extends Node2D:
	func _draw() -> void:
		var v := get_parent() as Vent
		var w := v.width; var h := v.height
		draw_rect(Rect2(0, 0, w, 3), Color(0.32, 0.34, 0.42, 0.9))
		draw_rect(Rect2(0, -h - 3, w, 3), Color(0.32, 0.34, 0.42, 0.9))
		draw_rect(Rect2(-4, -h - 3, 4, h + 6), Color(0.32, 0.34, 0.42, 0.9))
		draw_rect(Rect2(w, -h - 3, 4, h + 6), Color(0.32, 0.34, 0.42, 0.9))
