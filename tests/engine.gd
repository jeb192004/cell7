extends SceneTree
func _init() -> void:
	for lv in ["04", "05"]:
		var m = load("res://scenes/levels/level_%s.tscn" % lv).instantiate()
		root.add_child(m)
		for i in 30: await process_frame
		await create_timer(0.5, true, false, true).timeout
		print(lv, " engine=", Sfx.inst.eng_cur, " playing=", Sfx.inst.eng.playing, " pitch=", snappedf(Sfx.inst.eng.pitch_scale, 0.01), " loop=", (Sfx.inst.eng.stream as AudioStreamWAV).loop_mode)
		m.queue_free(); await create_timer(0.2, true, false, true).timeout
		print("  after_exit playing=", Sfx.inst.eng.playing)
	quit()
