extends SceneTree
func _init() -> void:
	var m = load("res://scenes/levels/level_1_5.tscn").instantiate()
	root.add_child(m)
	await process_frame
	var p: SpacePlayer = m.player
	for i in 3: await physics_frame
	var y0 := p.position.y
	Input.action_press("down")
	for i in 20: await physics_frame
	Input.action_release("down")
	print("moved_down=", p.position.y > y0 + 10.0)
	Input.action_press("right")
	for i in 20: await physics_frame
	Input.action_release("right")
	print("moved_right=", p.position.x > 90.0)
	var a0 := p.ammo
	Input.action_press("shoot"); await physics_frame; Input.action_release("shoot")
	print("fired=", p.ammo < a0)
	# let the level run with the ship invulnerable-ish: heal each frame, firing now and then
	var seen := {}
	for i in 60 * 40:
		p.hp = 5
		p.position.y = 135.0 + sin(i * 0.02) * 90.0
		if i % 12 == 0: Input.action_press("shoot")
		else: Input.action_release("shoot")
		await physics_frame
		for f in get_nodes_in_group("sfoes"): seen[f.kind] = true
	print("kinds_seen=", seen.keys(), " t=", snappedf(m.t, 0.1), " kills=", m.kills, "/", m.total_foes)
	# jump to boss
	m.t = 67.5
	for i in 60 * 3: await physics_frame
	var ace = null
	for f in get_nodes_in_group("sfoes"):
		if f.kind == "ace": ace = f
	print("ace_spawned=", ace != null)
	if ace:
		ace.position = Vector2(370, 135)
		for k in 30: ace.hurt(1)
	for i in 30: await physics_frame
	print("boss_dead=", m.boss_dead)
	for i in 60 * 3: await physics_frame
	print("clear_open=", m.overlay.mode != "")
	quit()
