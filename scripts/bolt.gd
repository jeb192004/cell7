class_name Bolt
extends Node2D
## Glowing slingshot charge.
const SPEED := 330.0
var dir := Vector2.RIGHT
var life := 0.5   # x SPEED = 165 px, shorter than a Warden's sight

func _ready() -> void:
	var s := Sprite2D.new()
	s.texture = load("res://assets/bolt.png")
	s.centered = true
	add_child(s)
	rotation = dir.angle()
	if dir.x < 0.0:
		s.flip_v = true

func _physics_process(delta: float) -> void:
	global_position += dir * SPEED * delta
	life -= delta
	for c in get_tree().get_nodes_in_group("barriers"):
		if c.rect().has_point(global_position): queue_free(); return
	for e in get_tree().get_nodes_in_group("enemies"):
		if e.hit_rect().has_point(global_position):
			if e.has_method("blocks") and e.blocks(dir.x):
				queue_free(); return
			e.hurt(1); queue_free(); return
	if life <= 0.0 or global_position.y > Level.bolt_floor:
		queue_free()
