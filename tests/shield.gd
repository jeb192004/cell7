extends SceneTree
func _init() -> void:
	var m = load("res://scenes/levels/level_02.tscn").instantiate()
	root.add_child(m)
	await process_frame
	var sw: Enemy = null
	for e in get_nodes_in_group("enemies"):
		if e.kind == "warden" and e.shield: sw = e; break
		e.queue_free()
	for e in get_nodes_in_group("enemies"):
		if e != sw: e.queue_free()
	var p: Player = m.player
	sw.position.x = 400; sw.facing = -1; sw.patrol_range = 0
	p.position = Vector2(300, 222); p.facing = 1
	for i in 5: await physics_frame
	var hp0 := sw.hp
	Input.action_press("shoot"); await physics_frame; Input.action_release("shoot")
	for i in 40: await physics_frame
	var front_blocked := sw.hp == hp0
	# now from behind
	sw.facing = -1; sw.alerted = false; sw.patrol_range = 0
	p.position = Vector2(500, 222); p.facing = -1
	for i in 5: await physics_frame
	sw.facing = -1; sw.alerted = false
	Input.action_press("shoot"); await physics_frame; Input.action_release("shoot")
	for i in 40: await physics_frame
	for i in 70: await physics_frame
	print("turned=", sw.facing == 1, " alerted=", sw.alerted)
	print("total=", m.total_foes, " front_blocked=", front_blocked, " back_hit=", sw.hp < hp0)
	quit()
