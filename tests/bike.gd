extends SceneTree
func _init() -> void:
	var m = load("res://scenes/levels/level_04.tscn").instantiate()
	root.add_child(m)
	await process_frame
	var p: BikePlayer = m.player
	# lanes
	Input.action_press("up"); await physics_frame; Input.action_release("up")
	for i in 30: await physics_frame
	print("lane_up=", p.lane, " y=", p.position.y)
	Input.action_press("right")
	for i in 30: await physics_frame
	Input.action_release("right")
	print("moved_forward x=", p.position.x)
	# shoot kills a warden bike in lane
	m.t = 6.9
	for i in 30: await physics_frame
	var bikes := get_nodes_in_group("foes")
	print("foes_spawned=", bikes.size())
	if bikes.size() > 0:
		var b = bikes[0]
		b.position.x = 330; b.state = "ride"
		p.lane = b.lane; p.position.y = BikePlayer.LANES[b.lane]; p.position.x = 100
		for k in 4:
			Input.action_press("shoot"); await physics_frame; Input.action_release("shoot")
			for i in 20: await physics_frame
		print("bike_dead=", not is_instance_valid(b), " kills=", m.kills)
	# wreck hit costs a pip
	var hp0 := p.hp
	for e in get_nodes_in_group("foes"): e.queue_free()
	var w := BikeFoe.new(); w.kind = "wreck"; w.lane = p.lane; w.level = m; m.add_child(w)
	w.position.x = p.position.x + 10.0
	for i in 5: await physics_frame
	print("wreck_hit hp ", hp0, "->", p.hp)
	# boss spawns and dies
	m.t = 69.9; m.ev_i = m.events.size() - 1
	for i in 40: await physics_frame
	var boss: BikeFoe = null
	for n in m.get_children():
		if n is BikeFoe and n.kind == "boss": boss = n
	print("boss=", boss != null)
	if boss: boss.hp = 1; boss.hurt(1)
	for i in 120: await physics_frame
	print("clear_open=", m.overlay.mode == "clear", " boss_dead=", m.boss_dead)
	quit()
