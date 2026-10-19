extends SceneTree
## Crate tops: hop onto a single crate, stand on it, Down+jump drops off; a 2-high stack can't be reached from the ground.
func _crate(m, stack: int) -> Cover:
	for e in get_nodes_in_group("enemies"): e.queue_free()
	for c in get_nodes_in_group("cover"): c.queue_free()
	await physics_frame
	var c := Cover.new(); c.stack = stack; c.position = Vector2(900, 223); m.add_child(c)
	await physics_frame
	return c
func _init() -> void:
	var m = load("res://scenes/levels/level_1_1.tscn").instantiate()
	root.add_child(m)
	await process_frame
	var p: Player = m.player
	await _crate(m, 1)
	p.position = Vector2(900, 222); p.velocity = Vector2.ZERO
	for i in 8: await physics_frame
	Input.action_press("jump")
	for i in 20: await physics_frame
	Input.action_release("jump")
	for i in 50: await physics_frame
	var on_top: bool = p.position.y < 200.0 and p.is_on_floor() and absf(p.position.x - 900.0) < 20.0
	print("on_crate_top=", on_top, " y=", p.position.y)
	# Down + jump drops off the front
	Input.action_press("down"); Input.action_press("jump")
	for i in 3: await physics_frame
	Input.action_release("jump")
	for i in 30: await physics_frame
	Input.action_release("down")
	var dropped: bool = p.position.y > 220.0 and p.is_on_floor()
	print("dropped=", dropped, " y=", p.position.y)
	# hold Down on top: drop behind the crate into the back lane
	p.position = Vector2(900, 192); p.velocity = Vector2.ZERO; p.is_back = false
	for i in 6: await physics_frame
	Input.action_press("down")
	for i in 40: await physics_frame
	Input.action_release("down")
	var behind: bool = p.is_back and p.position.y > 220.0
	print("drop_behind=", behind, " back=", p.is_back, " y=", p.position.y)
	p.is_back = false
	for i in 4: await physics_frame
	# walk off the end
	p.position = Vector2(900, 192); p.velocity = Vector2.ZERO
	for i in 4: await physics_frame
	Input.action_press("right")
	for i in 50: await physics_frame
	Input.action_release("right")
	var walked_off: bool = p.position.y > 220.0
	print("walked_off=", walked_off)
	# Up on top of a crate does not send you into the back lane
	p.position = Vector2(900, 192); p.velocity = Vector2.ZERO
	for i in 8: await physics_frame
	Input.action_press("up")
	for i in 3: await physics_frame
	Input.action_release("up")
	var no_lane: bool = not p.is_back
	print("no_lane_on_top=", no_lane)
	# 2-high stack: out of reach from the ground
	await _crate(m, 2)
	p.position = Vector2(850, 222); p.velocity = Vector2.ZERO; p.is_back = false
	for i in 20: await physics_frame
	Input.action_press("right"); Input.action_press("jump")
	for i in 20: await physics_frame
	Input.action_release("jump")
	for i in 40: await physics_frame
	Input.action_release("right")
	var cant: bool = p.position.y > 215.0
	print("stack2_unreachable=", cant, " y=", p.position.y)
	var ok: bool = on_top and dropped and behind and walked_off and no_lane and cant
	print("climb_ok=", ok)
	quit(0 if ok else 1)
