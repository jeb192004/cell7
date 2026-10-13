extends SceneTree
## Back lane: Up behind a crate. 2-high hides a standing Kesh, 1-high needs a crouch. Slugs can't reach the back lane.
func _setup(m, stack: int) -> Enemy:
	for e in get_nodes_in_group("enemies"): e.queue_free()
	for c in get_nodes_in_group("cover"): c.queue_free()
	await physics_frame
	var w := Enemy.new(); w.kind = "warden"; w.position = Vector2(1000, 222); w.player = m.player
	m.add_child(w)
	w.facing = -1; w.patrol_dir = -1; w.pause_t = 99.0
	var c := Cover.new(); c.stack = stack; c.position = Vector2(900, 223); m.add_child(c)
	return w
func _up() -> void:
	Input.action_press("up")
	for i in 3: await physics_frame
	Input.action_release("up")
func _case(m, label: String, px: float, stack: int, go_back: bool, crouch: bool) -> bool:
	var w: Enemy = await _setup(m, stack)
	var p: Player = m.player
	p.position = Vector2(px, 222); p.hp = 5; p.velocity = Vector2.ZERO; p.hurt_t = 0.0; p.is_back = false
	Input.action_release("down")
	for i in 5: await physics_frame
	if go_back: await _up()
	if crouch: Input.action_press("down")
	for i in 30: await physics_frame
	var seen := w.alerted
	print(label, " alerted=", seen, " back=", p.is_back, " concealed=", p.concealed)
	Input.action_release("down")
	w.queue_free()
	return seen
func _init() -> void:
	var m = load("res://scenes/levels/level_01.tscn").instantiate()
	root.add_child(m)
	await process_frame
	var r1 = await _case(m, "front_lane_in_cone", 880.0, 1, false, false)
	var r2 = await _case(m, "behind_2high_standing", 900.0, 2, true, false)
	var r3 = await _case(m, "behind_1high_standing", 900.0, 1, true, false)
	var r4 = await _case(m, "behind_1high_crouched", 900.0, 1, true, true)
	var r5 = await _case(m, "stand_behind_warden", 1100.0, 1, false, false)
	var ok: bool = r1 and not r2 and r3 and not r4 and not r5
	# slugs pass through the back lane
	var w: Enemy = await _setup(m, 2)
	var p: Player = m.player
	p.position = Vector2(900, 222); p.hp = 5; p.is_back = false; p.velocity = Vector2.ZERO
	for i in 5: await physics_frame
	await _up()
	var s := EnemyShot.new(); s.kind = "low"; s.dir = -1.0; s.player = p
	s.global_position = Vector2(960, 213); m.add_child(s)
	for i in 60: await physics_frame
	var no_dmg: bool = p.hp == 5 and p.is_back
	print("back_lane_immune=", no_dmg)
	# jump exits the lane only once Kesh is above a 1-high crate; a 2-high stack keeps him behind
	Input.action_press("jump")
	for i in 3: await physics_frame
	Input.action_release("jump")
	var stayed_2high := true
	for i in 50:
		await physics_frame
		if not p.is_back: stayed_2high = false
	print("jump_2high_stays_back=", stayed_2high)
	for e in get_nodes_in_group("cover"): e.queue_free()
	for e in get_nodes_in_group("enemies"): e.queue_free()
	await physics_frame
	var c1 := Cover.new(); c1.stack = 1; c1.position = Vector2(900, 223); m.add_child(c1)
	p.position = Vector2(900, 222); p.is_back = false
	for i in 8: await physics_frame
	await _up()
	var back1: bool = p.is_back
	Input.action_press("jump")
	for i in 2: await physics_frame
	Input.action_release("jump")
	var still_back_low := p.is_back
	var exit_h := -1.0
	for i in 60:
		await physics_frame
		if not p.is_back and exit_h < 0.0:
			exit_h = 222.0 - p.position.y
	var out_jump: bool = back1 and still_back_low and exit_h >= 28.0 and not p.is_back
	print("jump_exits_after_clearing=", out_jump, " exit_height=", exit_h)
	for i in 60: await physics_frame
	# walking off the end exits the lane
	p.position = Vector2(900, 222); p.is_back = false
	for i in 8: await physics_frame
	await _up()
	var went_back: bool = p.is_back
	Input.action_press("left")
	for i in 40: await physics_frame
	Input.action_release("left")
	var out_walk: bool = went_back and not p.is_back
	print("walk_exits=", out_walk)
	ok = ok and no_dmg and stayed_2high and out_jump and out_walk
	print("stealth_ok=", ok)
	quit(0 if ok else 1)
