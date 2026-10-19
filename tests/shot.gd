extends SceneTree
func _init() -> void:
	var m = load("res://scenes/levels/level_1_4.tscn").instantiate()
	root.add_child(m)
	await process_frame
	m.t = 18.9
	for i in 150: await physics_frame
	root.get_viewport().get_texture().get_image().save_png("res://e1.png")
	m.t = 69.5
	m.player.hp = 5
	for i in 220: await physics_frame
	for e in get_nodes_in_group("foes"): if e.kind != "boss": e.queue_free()
	root.get_viewport().get_texture().get_image().save_png("res://e2.png")
	quit()
