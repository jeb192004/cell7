class_name EnemyShot
extends Node2D
## Warden slug. "high" flies at chest height (duck under it), "low" at shin height (jump it).
const SPEED := 150.0
var dir := 1.0
var kind := "high"
var player: Player
var life := 3.0

func _ready() -> void:
	var s := Sprite2D.new()
	s.texture = load("res://assets/shot_%s.png" % kind)
	s.flip_h = dir < 0.0
	add_child(s)

func _physics_process(delta: float) -> void:
	global_position.x += dir * SPEED * delta
	life -= delta
	for c in get_tree().get_nodes_in_group("barriers"):
		if c.rect().has_point(global_position): queue_free(); return
	if player and Rect2(global_position - Vector2(5, 2.5), Vector2(10, 5)).intersects(player.hurtbox()):
		if player.has_method("blocks_shot") and player.blocks_shot(dir):
			player.block_spark(global_position); queue_free(); return   # Renn's blade
		player.take_hit(global_position.x - dir * 20.0)
		queue_free(); return
	if life <= 0.0:
		queue_free()
