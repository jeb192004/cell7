extends SceneTree
func _init() -> void:
	var m = load("res://scenes/levels/level_03.tscn").instantiate()
	root.add_child(m)
	await process_frame
	for e in get_nodes_in_group("enemies"): e.queue_free()
	var p: Player = m.player
	p.position = Vector2(620, 181); p.velocity = Vector2.ZERO
	for i in 20: await physics_frame
	Input.action_press("down"); Input.action_press("jump")
	for i in 4: await physics_frame
	Input.action_release("jump")
	for i in 60: await physics_frame
	Input.action_release("down")
	print("drop_ok=", absf(p.position.y - 222.0) < 3.0, " y=", p.position.y)
	quit()
