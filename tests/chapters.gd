extends Node
func _ready():
	var t = load("res://scenes/title.tscn").instantiate()
	get_tree().root.add_child.call_deferred(t)
	await get_tree().create_timer(0.3).timeout
	t._show_select(true)
	await get_tree().create_timer(0.5).timeout
	var vis = func(): return t.level_rows.get_children().filter(func(n): return n.visible).map(func(n): return n.title)
	print("CH LIST: ", vis.call(), " heading=", t.select_heading.text)
	t._on_level_row(t.chapter_rows[1]); await get_tree().process_frame
	print("CH2: ", vis.call(), " heading=", t.select_heading.text, " focus=", t.get_viewport().gui_get_focus_owner())
	t._select_back(); await get_tree().create_timer(0.2).timeout
	print("BACK->", vis.call(), " focus=", t.get_viewport().gui_get_focus_owner().title)
	t._on_level_row(t.chapter_rows[0]); await get_tree().process_frame
	print("CH1: ", vis.call())
	var bad = 0
	for r in t.level_rows_all:
		if not ResourceLoader.exists(r.scene): bad += 1; print("MISSING ", r.scene)
	for f in DirAccess.get_files_at("res://scenes/levels"):
		if f.ends_with(".tscn"):
			var ps = load("res://scenes/levels/" + f)
			if ps == null: bad += 1; print("LOAD FAIL ", f)
			else:
				var nl = ps.instantiate().get("next_level")
				if nl and nl != "" and not ResourceLoader.exists(nl): bad += 1; print("BAD NEXT ", f, nl)
	t._select_back(); await get_tree().process_frame
	t._select_back(); await get_tree().process_frame
	print("TITLE VISIBLE: ", t.title_group.visible, " bad=", bad)
	get_tree().quit()
