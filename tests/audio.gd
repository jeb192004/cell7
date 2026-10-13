extends SceneTree
func _init() -> void:
	Prefs.delete_all()
	var t = load("res://scenes/title.tscn").instantiate()
	root.add_child(t)
	for i in 6: await process_frame
	print("sfx_node=", Sfx.inst != null and Sfx.inst.is_inside_tree(), " want=", Sfx.inst.want, " current=", Sfx.inst.current, " playing=", Sfx.inst.mus.playing)
	Sfx.play("shoot"); Sfx.play("explode")
	var busy := 0
	for p in Sfx.inst.pool: if p.playing: busy += 1
	print("sfx_playing=", busy)
	for k in ["desert", "highway", "town", "bike", "space", "title"]:
		var st = load("res://assets/music/%s.ogg" % k); print(k, " ", st != null and st.get_length() > 20.0)
	t._show_settings(true)
	Sfx.set_volumes(Sfx.music_vol - 2, Sfx.sfx_vol - 1)
	print("vols=", Sfx.music_vol, "/", Sfx.sfx_vol, " saved=", Prefs.get_num("audio", "music", -1), "/", Prefs.get_num("audio", "sfx", -1))
	Prefs.mark_seen("cover"); t._on_settings(2); print("tips_reset=", not Prefs.seen("cover"))
	t._on_settings(3); print("deleted=", not FileAccess.file_exists(Prefs.PATH), " vols=", Sfx.music_vol, "/", Sfx.sfx_vol)
	for s in ["shoot","jump","slide","hurt","enemy_shoot","enemy_hit","enemy_die","shield_block","shield_break","spot","pickup","explode","bike_hit","menu_move","menu_select","blip","tip_open","clear","down"]:
		if not ResourceLoader.exists("res://assets/sfx/%s.wav" % s): print("MISSING ", s)
	t._show_settings(true)
	for i in 4: await process_frame
	root.get_viewport().get_texture().get_image().save_png("/tmp/ai/settings.png")
	t._show_settings(false)
	for i in 4: await process_frame
	root.get_viewport().get_texture().get_image().save_png("/tmp/ai/title.png")
	quit()
