class_name BlastFx
extends Node2D
## A quick fireball: expands, burns white to orange to smoke, then frees itself. `radius` is how big it gets.
var radius := 40.0
var t := 0.0
const LIFE := 0.5
var sparks: Array = []   # [pos, vel]

func _ready() -> void:
	z_index = 30
	for i in 14:
		var a := randf() * TAU
		sparks.append([Vector2.ZERO, Vector2(cos(a), sin(a)) * randf_range(60.0, 170.0) * (radius / 40.0)])

func _process(d: float) -> void:
	t += d
	for s in sparks:
		s[0] += s[1] * d; s[1] *= 0.93
	queue_redraw()
	if t > LIFE: queue_free()

func _draw() -> void:
	var k := clampf(t / LIFE, 0.0, 1.0)
	var r := radius * (0.35 + 0.65 * sqrt(k))
	var a := 1.0 - k
	draw_circle(Vector2.ZERO, r, Color(1.0, 0.45, 0.1, 0.55 * a))
	draw_circle(Vector2.ZERO, r * 0.7, Color(1.0, 0.7, 0.2, 0.8 * a))
	draw_circle(Vector2.ZERO, r * 0.4, Color(1.0, 0.95, 0.75, 0.95 * a))
	draw_arc(Vector2.ZERO, r * 1.1, 0, TAU, 28, Color(1.0, 0.85, 0.5, 0.7 * a), 2.0)
	for s in sparks:
		draw_rect(Rect2(s[0], Vector2(2, 2)), Color(1.0, 0.8, 0.3, a))
