extends SceneTree
## Duck high shots, jump low shots, standing gets hit by both.
func _run(m, p: Player, kind: String, pose: String) -> int:
	p.hp = 5; p.hurt_t = 0.0; p.position = Vector2(400, 222); p.velocity = Vector2.ZERO
	for e in get_nodes_in_group("enemies"): e.queue_free()
	Input.action_release("down"); Input.action_release("jump")
	if pose == "crouch": Input.action_press("down")
	for i in 6: await physics_frame
	if pose == "jump":
		Input.action_press("jump")
		for i in 2: await physics_frame
	var s := EnemyShot.new()
	s.kind = kind; s.dir = 1.0; s.player = p
	s.global_position = Vector2(p.position.x - 60.0, 222.0 - (33.0 if kind == "high" else 9.0))
	m.add_child(s)
	var n := 0
	while is_instance_valid(s) and n < 120:
		await physics_frame; n += 1
		if pose == "jump" and n == 8: Input.action_release("jump")
	return 5 - p.hp
func _init() -> void:
	var m = load("res://scenes/levels/level_01.tscn").instantiate()
	root.add_child(m)
	await process_frame
	var p: Player = m.player
	var r := {}
	for kind in ["high", "low"]:
		for pose in ["stand", "crouch", "jump"]:
			r[kind + "/" + pose] = await _run(m, p, kind, pose)
	print(r)
	var ok: bool = r["high/stand"] == 1 and r["high/crouch"] == 0 and r["low/stand"] == 1 and r["low/crouch"] == 1 and r["low/jump"] == 0
	print("shots_ok=", ok)
	quit(0 if ok else 1)
