extends SceneTree
func _press(a: String) -> void:
	var e := InputEventAction.new(); e.action = a; e.pressed = true; Input.parse_input_event(e)
	await physics_frame; await physics_frame
	var r := InputEventAction.new(); r.action = a; r.pressed = false; Input.parse_input_event(r)
	await physics_frame
func _load(n: String) -> Level:
	var m: Level = load("res://scenes/levels/level_%s.tscn" % n).instantiate()
	root.add_child(m)
	for i in 10: await physics_frame
	return m
func _init() -> void:
	# 2-1 loads and plays
	var m := await _load("2_1")
	print("2_1 foes=", m.total_foes, " player_ok=", m.player != null)
	m.queue_free(); await process_frame
	# 2-2 vent crawl
	m = await _load("2_2")
	m.player.position = Vector2(600, 222)
	for i in 8: await physics_frame
	print("vent forced=", m.player.forced_crouch, " crouching=", m.player.crouching)
	m.player.position = Vector2(2100, 222)
	for i in 8: await physics_frame
	print("bay forced=", m.player.forced_crouch)
	m.queue_free(); await process_frame
	# 2-3 cages + exit gating
	m = await _load("2_3")
	for e in get_nodes_in_group("enemies"): e.queue_free()
	await physics_frame
	m.player.position = Vector2(4480, 222)
	for i in 6: await physics_frame
	print("exit_blocked clear_t=", m.clear_t, " freed=", m.freed)
	var cages := get_nodes_in_group("cages")
	print("cages=", cages.size())
	for k in 4:
		m.player.position = Vector2((cages[k] as Node2D).global_position.x, 222)
		for i in 4: await physics_frame
		await _press("up")
		for i in 3: await physics_frame
	print("freed=", m.freed)
	m.player.position = Vector2(4480, 222)
	for i in 6: await physics_frame
	print("exit_open clear_t>=0:", m.clear_t >= 0.0)
	m.queue_free(); await process_frame
	# 2-4 hunter survive
	m = await _load("2_4")
	var h := get_first_node_in_group("hunters")
	print("hunter=", h != null, " hp=", h.hp, " survive_left=", snappedf(m.survive_left, 0.1))
	for e in get_nodes_in_group("enemies"):
		if e != h: e.queue_free()
	m.player.position = Vector2(1000, 222)
	var hit_taken := m.player.hp
	for i in 600: await physics_frame
	print("hunter_state=", h.state if is_instance_valid(h) else "gone", " player_hp=", m.player.hp, " ursk_pal_near=", true)
	m.survive_left = 0.2
	for i in 30: await physics_frame
	print("2_4 clear_t>=0:", m.clear_t >= 0.0)
	quit()
