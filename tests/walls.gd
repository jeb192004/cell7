extends SceneTree
func _init() -> void:
	var m = load("res://scenes/levels/level_03.tscn").instantiate()
	root.add_child(m)
	await process_frame
	for e in get_nodes_in_group("enemies"): e.queue_free()
	var p: Player = m.player
	p.position = Vector2(1715, 150); p.velocity = Vector2.ZERO   # in the gap between roof 6 (right edge 1690) and roof 7 (left edge 1745)
	Input.action_press("right")
	var maxx := 0.0
	for i in 40:
		await physics_frame
		maxx = maxf(maxx, p.position.x)
	Input.action_release("right")
	print("walls_ok=", maxx < 1745.0 - 5.0, " maxx=", maxx)
	quit()
