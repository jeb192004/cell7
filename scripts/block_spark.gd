class_name BlockSpark
extends Node2D
## A quick white-hot flash where Renn's blade swats a bolt aside.
var t := 0.0
func _ready() -> void:
	z_index = 20
func _process(d: float) -> void:
	t += d
	if t > 0.22: queue_free()
	queue_redraw()
func _draw() -> void:
	var k := 1.0 - t / 0.22
	draw_circle(Vector2.ZERO, 5.0 * k + 1.0, Color(1, 1, 1, k))
	for i in 6:
		var a := TAU * i / 6.0 + 0.4
		draw_line(Vector2.ZERO, Vector2(cos(a), sin(a)) * (10.0 + 8.0 * (1.0 - k)), Color(1.0, 0.8, 0.5, k), 1.0)
