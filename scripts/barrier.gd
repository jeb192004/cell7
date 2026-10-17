@tool
class_name Barrier
extends Node2D
## A solid crate you can't walk through: jump over it (or stand on top). Origin = its feet, like Cover.
## Wardens can't see through it and shots stop on it. (The hide-behind crates are still the Cover scene.)
@export_enum("crate", "cargo") var skin := "crate":
	set(v):
		skin = v
		if is_inside_tree(): _build()
var half_w := 17.0
var tall := 31.0

func _ready() -> void:
	_build()
	if not Engine.is_editor_hint():
		add_to_group("barriers")

func _build() -> void:
	for ch in get_children():
		remove_child(ch); ch.queue_free()
	var tex: Texture2D = load("res://assets/cover_%s.png" % skin)
	half_w = tex.get_width() / 2.0
	var s := Sprite2D.new()
	s.texture = tex; s.centered = false
	s.position = Vector2(-half_w, -tex.get_height() + 1.0)
	add_child(s)
	tall = tex.get_height() - 3.0
	var body := StaticBody2D.new()
	body.collision_layer = 1; body.collision_mask = 0
	var cs := CollisionShape2D.new()
	var rs := RectangleShape2D.new()
	rs.size = Vector2(half_w * 2.0 - 2.0, tall)
	cs.shape = rs
	cs.position = Vector2(0, -tall / 2.0 + 1.0)
	body.add_child(cs); add_child(body)

func rect() -> Rect2:
	return Rect2(global_position + Vector2(-half_w, -tall), Vector2(half_w * 2.0, tall))

## True if this crate blocks a straight line from a to b (both near its height band).
static func blocks_line(tree: SceneTree, a: Vector2, b: Vector2) -> bool:
	for c in tree.get_nodes_in_group("barriers"):
		var r: Rect2 = c.rect()
		var lo := minf(a.x, b.x); var hi := maxf(a.x, b.x)
		if r.end.x < lo or r.position.x > hi: continue
		if a.y < r.position.y + 6.0 and b.y < r.position.y + 6.0: continue   # both well above the top: clear shot
		if absf(a.y - r.end.y) > 60.0 and absf(b.y - r.end.y) > 60.0: continue   # a different floor
		return true
	return false
