extends SceneTree
## Headless smoke: run right, jump, shoot, check Kesh moved and a warden died.
func _init() -> void:
	var m = load("res://scenes/levels/level_1_1.tscn").instantiate()
	root.add_child(m)
	await process_frame
	await process_frame
	var p: Player = m.player
	Input.action_press("right")
	for i in 120: await physics_frame
	var x1 := p.position.x
	Input.action_press("run")
	for i in 40: await physics_frame
	var sprint_ok := absf(p.velocity.x) > 150.0
	Input.action_release("run")
	Input.action_press("jump")
	for i in 5: await physics_frame
	var rose := p.position.y < 222.0
	Input.action_release("jump")
	for i in 80: await physics_frame
	# kill the first warden with shots
	Input.action_release("right")
	var w = null
	for e in get_nodes_in_group("enemies"):
		if e.kind == "warden": w = e; break
	p.position.x = w.position.x - 120.0; p.facing = 1
	for i in 6:
		Input.action_press("shoot")
		await physics_frame
		Input.action_release("shoot")
		for j in 30: await physics_frame
	print("sprint=", sprint_ok, " moved=", x1 > 150.0, " jumped=", rose, " warden_dead=", not is_instance_valid(w))
	quit(0 if (x1 > 150.0 and sprint_ok and rose and not is_instance_valid(w)) else 1)
