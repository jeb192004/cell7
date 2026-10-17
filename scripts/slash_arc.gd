class_name SlashArc
extends Node2D
## The bright crescent of an Arc-Blade swing.
var facing := 1
var t := 0.0
func _ready() -> void:
	z_index = 20
func _process(d: float) -> void:
	t += d
	if t > 0.2: queue_free()
	queue_redraw()
func _draw() -> void:
	var k := 1.0 - t / 0.2
	var c := Vector2(-8.0 * facing, 6.0)
	var a0 := -1.5 if facing > 0 else PI + 0.0
	for i in 3:
		var r := 30.0 - i * 3.0
		var col := Color(0.75, 0.95, 1.0, k * (1.0 - i * 0.3))
		if facing > 0: draw_arc(c, r, -1.35 + t * 2.0, 0.55 + t * 2.0, 14, col, 2.0)
		else: draw_arc(c, r, PI - 0.55 - t * 2.0, PI + 1.35 - t * 2.0, 14, col, 2.0)
