class_name BikeShot
extends Node2D
## Enemy shot on the highway. "slug" is slow (change lanes), "beam" is fast and wide.
var kind := "slug"
var speed := 230.0
var player: BikePlayer
func _ready() -> void:
	z_index = int(position.y)
	if kind == "slug": speed = 230.0
	else: speed = 440.0
func _process(d: float) -> void:
	position.x -= speed * d
	if player != null and player.in_lane(position.y) and absf(player.position.x - position.x) < (16.0 if kind == "slug" else 30.0):
		player.take_hit()
		if kind == "slug":
			queue_free(); return
	if position.x < -80.0: queue_free()
	queue_redraw()
func _draw() -> void:
	if kind == "slug":
		draw_texture(load("res://assets/shot_high.png"), Vector2(-5, -20))
	else:
		draw_rect(Rect2(-6, -22, 60, 8), Color(1.0, 0.45, 0.25, 0.9)); draw_rect(Rect2(-6, -20, 60, 4), Color(1.0, 0.9, 0.6))
