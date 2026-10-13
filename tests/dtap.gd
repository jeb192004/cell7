extends SceneTree
func _init() -> void:
	var m = load("res://scenes/levels/level_02.tscn").instantiate()
	root.add_child(m)
	await process_frame
	var sw: Enemy = null
	for e in get_nodes_in_group("enemies"):
		if e.kind == "warden" and e.shield and sw == null: sw = e
	for e in get_nodes_in_group("enemies"):
		if e != sw: e.queue_free()
	var p: Player = m.player
	sw.position.x = 400; sw.facing = -1; sw.patrol_range = 0
	p.position = Vector2(500, 222); p.facing = -1
	for i in 3: await physics_frame
	var shots := 0
	for k in 5:
		Input.action_press("shoot"); await physics_frame; Input.action_release("shoot")
		for i in 24: await physics_frame
		shots += 1
	for i in 60: await physics_frame
	print("hp_left=", sw.hp if is_instance_valid(sw) else 0, " ammo=", p.ammo)
	quit()
