extends SceneTree
func _press(a: String) -> void:
	var e := InputEventAction.new(); e.action = a; e.pressed = true; Input.parse_input_event(e)
	await process_frame; await process_frame
	var r := InputEventAction.new(); r.action = a; r.pressed = false; Input.parse_input_event(r)
	await process_frame
func _init() -> void:
	var m = load("res://scenes/levels/level_%s.tscn" % OS.get_environment("LV")).instantiate()
	root.add_child(m)
	for i in 8: await process_frame
	print("active=", StoryCard.active, " paused=", paused)
	await create_timer(1.6, true, false, true).timeout
	root.get_viewport().get_texture().get_image().save_png("/tmp/ai/story_1.png")
	var n := 0
	while StoryCard.active and n < 8:
		await create_timer(0.5, true, false, true).timeout
		await _press("jump"); await create_timer(0.1, true, false, true).timeout
		await _press("jump"); n += 1
	for i in 6: await process_frame
	print("after active=", StoryCard.active, " paused=", paused, " presses=", n)
	quit()
