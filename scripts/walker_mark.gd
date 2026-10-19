extends Node2D
## Red ring on the ground where a walker missile will land.
var t := 0.0
func _process(d: float) -> void:
	t += d
	queue_redraw()
func _draw() -> void:
	var on := int(t * (6.0 + t * 6.0)) % 2 == 0
	if not on: return
	draw_arc(Vector2.ZERO, 30.0, 0, TAU, 28, Color(1.0, 0.25, 0.2, 0.9), 2.0)
	draw_arc(Vector2.ZERO, 14.0, 0, TAU, 20, Color(1.0, 0.5, 0.3, 0.8), 1.0)
