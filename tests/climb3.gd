extends SceneTree
func _init() -> void:
	var m = load("res://scenes/levels/level_1_3.tscn").instantiate()
	root.add_child(m)
	await process_frame
	for e in get_nodes_in_group("enemies"): e.queue_free()
	var p: Player = m.player
	# 1) checkpoint heals a pip
	p.hp = 3
	p.position = Vector2(1340, 21); p.velocity = Vector2.ZERO
	for i in 20: await physics_frame
	print("checkpoint_heal hp=", p.hp, " cp=", Level.checkpoint_x, ",", Level.checkpoint_y)
	# 2) fall into the void between buildings: -1 pip, back at checkpoint
	p.hp = 4
	p.position = Vector2(1718, 100); p.velocity = Vector2.ZERO
	var maxy := 0.0
	for i in 260:
		await physics_frame
		maxy = maxf(maxy, p.position.y)
	print("void fall: hp=", p.hp, " pos=", p.position, " maxy=", maxy)
	# 3) hard landing (> ~150 px drop) onto a lower roof costs a pip
	Level.checkpoint_x = -1.0
	p.hp = 5; p.hurt_t = 0.0
	p.position = Vector2(1560, -200); p.velocity = Vector2.ZERO
	for i in 120: await physics_frame
	print("hard landing hp=", p.hp, " y=", p.position.y, " (expect 4, y=22)")
	# 4) pickup heals
	p.hp = 2
	var pk = get_nodes_in_group("pickups")[0]
	p.position = pk.global_position + Vector2(0, 20); p.velocity = Vector2.ZERO
	for i in 6: await physics_frame
	print("pickup hp=", p.hp, " left=", get_nodes_in_group("pickups").size())
	quit()
