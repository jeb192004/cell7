extends SceneTree
func _init() -> void:
	var m = load("res://scenes/levels/level_03.tscn").instantiate()
	root.add_child(m)
	await process_frame
	for e in get_nodes_in_group("enemies"): e.queue_free()
	var p: Player = m.player
	var roofs: Array = []
	for r in m.get_node("Buildings").get_children(): roofs.append([r.position.x, r.width, r.height])
	var ok := true
	for i in range(roofs.size() - 1):
		var a = roofs[i]; var b = roofs[i + 1]
		var gap: float = (b[0] - b[1] / 2.0) - (a[0] + a[1] / 2.0)
		if gap > 85.0:
			print("skip ", i + 1, "->", i + 2, " (street between, gap ", gap, ")"); continue
		p.position = Vector2(a[0] + a[1] / 2.0 - 14.0, 222.0 - a[2] - 1.0); p.velocity = Vector2.ZERO
		for k in 8: await physics_frame
		Input.action_press("right"); Input.action_press("run"); Input.action_press("jump")
		var air := false
		for k in 90:
			await physics_frame
			if k == 14: Input.action_release("jump")
			if not p.is_on_floor(): air = true
			elif air: break
		Input.action_release("right"); Input.action_release("run")
		for k in 3: await physics_frame
		var on_b: bool = p.is_on_floor() and absf(p.position.y - (222.0 - b[2])) < 3.0 and p.position.x > b[0] - b[1] / 2.0 and p.position.x < b[0] + b[1] / 2.0 + 20.0
		print("roof", i + 1, "->", i + 2, " gap=", gap, " up=", b[2] - a[2], " ok=", on_b, " pos=", p.position)
		ok = ok and on_b
	print("roofs_ok=", ok)
	quit()
