class_name SpaceBolt
extends Node2D
## Kesh's shot in space: straight right, hits the first thing it touches.
const SPEED := 380.0
func _ready() -> void:
	z_index = 5
func _process(d: float) -> void:
	position.x += SPEED * d
	for f in get_tree().get_nodes_in_group("sfoes"):
		if f.shootable and f.position.distance_to(position + Vector2(6, 0)) < f.r + 4.0:
			f.hurt(1); queue_free(); return
	if position.x > 500.0: queue_free()
	queue_redraw()
func _draw() -> void:
	draw_rect(Rect2(-7, -1.5, 16, 3), Color(0.45, 0.9, 1.0, 0.9)); draw_rect(Rect2(-3, -1, 10, 2), Color(0.95, 1.0, 1.0))
