class_name BikeBolt
extends Node2D
## Kesh's shot on the bike: flies straight along its lane and hits whatever is in that lane.
const SPEED := 360.0
func _ready() -> void:
	var s := Sprite2D.new()
	s.texture = load("res://assets/bolt.png")
	s.position = Vector2(0, -17)
	add_child(s)
	z_index = int(position.y)
func _process(d: float) -> void:
	position.x += SPEED * d
	for f in get_tree().get_nodes_in_group("foes"):
		if f.accepts(position.x, position.y):
			f.hurt(1); queue_free(); return
	if position.x > 520.0: queue_free()
