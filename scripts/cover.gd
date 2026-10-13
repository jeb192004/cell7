@tool
class_name Cover
extends Node2D
## Crate (or stack) in the background lane. Origin at its feet. Kesh steps behind it with Up.
## stack 1: he has to crouch to disappear. stack 2 or 3: he can stand.
@export_range(1, 3) var stack := 1:
	set(v):
		stack = clampi(v, 1, 3)
		if is_inside_tree():
			_build()
@export_enum("crate", "cargo") var skin := "crate":   # artwork: salt-flat crate or highway cargo container
	set(v):
		skin = v
		if is_inside_tree():
			_build()
var half_w := 17.0
var tall := 34.0
var prompt := false

func _ready() -> void:
	_build()
	if not Engine.is_editor_hint():
		add_to_group("cover")
		z_index = -2

func _build() -> void:
	for ch in get_children():
		if ch is Sprite2D or ch is StaticBody2D:
			remove_child(ch)
			ch.queue_free()
	var tex: Texture2D = load("res://assets/cover_%s.png" % skin)
	half_w = tex.get_width() / 2.0
	for i in stack:
		var s := Sprite2D.new()
		s.texture = tex
		s.centered = false
		s.position = Vector2(-half_w, -tex.get_height() * (i + 1) + 1.0 + i * 3.0)
		s.modulate = Color(0.86, 0.86, 0.92)   # sits a little back
		add_child(s)
	tall = (tex.get_height() - 3.0) * stack
	# the top is a one-way platform: jump up through it from below, land and stand on it, Down + jump to drop off
	var body := StaticBody2D.new()
	body.collision_layer = 2
	body.collision_mask = 0
	var cs := CollisionShape2D.new()
	var rs := RectangleShape2D.new()
	rs.size = Vector2(half_w * 2.0 - 4.0, 6.0)
	cs.shape = rs
	cs.one_way_collision = true
	cs.position = Vector2(0, -(tall - 1.0) + 3.0)
	body.add_child(cs)
	add_child(body)

func rect() -> Rect2:
	return Rect2(global_position + Vector2(-half_w, -tall), Vector2(half_w * 2.0, tall))

func _process(_d: float) -> void:
	if Engine.is_editor_hint():
		return
	var p := get_tree().get_first_node_in_group("player") as Player
	var want := p != null and not p.is_back and p.is_on_floor() and absf(p.global_position.x - global_position.x) < half_w - 2.0 and p.global_position.y > global_position.y - 8.0
	if want != prompt:
		prompt = want
		queue_redraw()
	elif prompt:
		queue_redraw()

func _draw() -> void:
	if not prompt: return
	var bob := int(Time.get_ticks_msec() / 250.0) % 2
	var y := -tall - 12.0 - bob
	var col := Color(1, 0.93, 0.6)
	var dark := Color(0.1, 0.07, 0.12)
	draw_rect(Rect2(-7, y - 2, 14, 13), dark)
	draw_colored_polygon(PackedVector2Array([Vector2(0, y), Vector2(-5, y + 5), Vector2(5, y + 5)]), col)
	draw_rect(Rect2(-2, y + 5, 4, 5), col)
