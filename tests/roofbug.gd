extends SceneTree
func _init() -> void:
	var m = load("res://scenes/levels/level_1_3.tscn").instantiate()
	root.add_child(m)
	await process_frame
	var sw: Enemy = null
	for e in get_nodes_in_group("enemies"):
		if e.kind == "warden" and e.shield and e.position.y < 200 and sw == null: sw = e
	for e in get_nodes_in_group("enemies"):
		if e != sw: e.queue_free()
	var p: Player = m.player
	# 1) shield warden chases along a roof edge: must not leave it
	var x0 := sw.position.x
	p.position = Vector2(1800, 62); p.velocity = Vector2.ZERO   # on the next roof to his right, in range
	for i in 200: await physics_frame
	print("warden_x=", sw.position.x, " bound_max=", sw.bound_max, " stayed=", sw.position.x <= sw.bound_max + 0.5)
	# 2) hold Down on a crate on a roof -> behind it, stays on the roof
	for c in get_nodes_in_group("cover"):
		if c.global_position.y < 200 and c.stack == 2:
			p.position = Vector2(c.global_position.x, c.global_position.y - c.tall - 2); p.velocity = Vector2.ZERO
			break
	for i in 20: await physics_frame
	Input.action_press("down")
	for i in 40: await physics_frame
	print("back_lane=", p.is_back, " y=", p.position.y, " on_roof=", p.position.y < 200)
	Input.action_release("down")
	# 3) Down + jump on a plain roof area drops through
	for i in 30: await physics_frame
	p.is_back = false
	quit()
