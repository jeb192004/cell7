class_name SpaceShot
extends Node2D
## Enemy fire in space: flies in a straight line.
var vel := Vector2(-230, 0)
var player: SpacePlayer
func _ready() -> void:
	z_index = 5
func _process(d: float) -> void:
	position += vel * d
	if player != null and player.hp > 0 and player.dist_to(position) < 3.0:
		player.take_hit(); queue_free(); return
	if position.x < -40.0 or position.x > 520.0 or position.y < -20.0 or position.y > 290.0: queue_free()
	queue_redraw()
func _draw() -> void:
	var a := vel.angle()
	draw_set_transform(Vector2.ZERO, a)
	draw_rect(Rect2(-8, -2.5, 16, 5), Color(1.0, 0.4, 0.25, 0.9)); draw_rect(Rect2(-6, -1.5, 12, 3), Color(1.0, 0.9, 0.6))
