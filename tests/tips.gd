extends SceneTree
func _press(a: String) -> void:
	var e := InputEventAction.new(); e.action = a; e.pressed = true; Input.parse_input_event(e)
	await process_frame; await process_frame
	var r := InputEventAction.new(); r.action = a; r.pressed = false; Input.parse_input_event(r)
func _init() -> void:
	Prefs.reset_tips()
	var m = load("res://scenes/levels/level_1_1.tscn").instantiate()
	root.add_child(m)
	for i in 5: await process_frame
	var tut: Tutorial = null
	for c in m.hud_layer.get_children():
		if c is Tutorial: tut = c
	print("tutorial_node=", tut != null)
	m.player.position = Vector2(300, 222)
	for i in 6: await process_frame
	print("cover_tip=", tut.active, " paused=", paused)
	root.get_viewport().get_texture().get_image().save_png("/tmp/ai/tip_cover.png")
	await create_timer(0.7, true, false, true).timeout
	await _press("jump")
	for i in 4: await process_frame
	print("after_close active='", tut.active, "' paused=", paused, " seen=", Prefs.seen("cover"))
	# enemy tip: move next to the first drone (520,150)
	m.player.position = Vector2(450, 222)
	for i in 6: await process_frame
	print("next_tip=", tut.active)
	await create_timer(0.7, true, false, true).timeout
	await _press("shoot")
	for i in 4: await process_frame
	m.player.position = Vector2(700, 222)
	for i in 6: await process_frame
	print("tip3=", tut.active)
	root.get_viewport().get_texture().get_image().save_png("/tmp/ai/tip_cone.png")
	Prefs.reset_tips(); quit()
