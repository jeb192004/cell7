@tool
class_name RoadProp
extends Node2D
## Road clutter from the bike level, for the on-foot highway: a wreck or a barrier. Solid: Kesh jumps over it or climbs onto it.
## Origin on the street (y = 222), centred. Pick the look in the Inspector.
@export_enum("barrier", "wreck", "burnt") var skin := "barrier":
	set(v):
		skin = v; _build()

var body: StaticBody2D

func _ready() -> void:
	_build()

func _build() -> void:
	if not is_inside_tree(): return
	for ch in get_children(): ch.queue_free()
	var file: String = {"barrier": "road_barrier", "wreck": "cover_wreck", "burnt": "road_wreck"}[skin]
	var tex: Texture2D = load("res://assets/%s.png" % file)
	var s := Sprite2D.new(); s.texture = tex; s.centered = false
	s.position = Vector2(-tex.get_width() / 2.0, -tex.get_height() + 1.0)
	add_child(s)
	var b := StaticBody2D.new(); b.collision_layer = 1; b.collision_mask = 0
	var cs := CollisionShape2D.new(); var r := RectangleShape2D.new()
	r.size = Vector2(tex.get_width() - 4.0, tex.get_height() - 6.0)
	cs.shape = r; cs.position = Vector2(0, -r.size.y / 2.0)
	b.add_child(cs); add_child(b)
