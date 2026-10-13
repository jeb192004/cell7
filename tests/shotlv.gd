extends SceneTree
func _init() -> void:
	for k in Story.CARDS: Story.played[k] = true
	for k in ["cover", "shoot", "cone", "shield"]: Prefs.mark_seen(k)
	var lv := OS.get_environment("LV")
	var m = load("res://scenes/levels/%s.tscn" % lv).instantiate()
	root.add_child(m)
	for i in 30: await process_frame
	var ens := get_nodes_in_group("enemies")
	if lv == "level_01" and ens.size() > 0 and m.get("player") != null:
		var e: Node2D = ens[0]; m.player.position = Vector2(e.position.x - 90.0, e.position.y)
	if OS.get_environment("X") != "" and m.get("player") != null: m.player.position = Vector2(float(OS.get_environment("X")), 222.0)
	var n := int(OS.get_environment("N")) if OS.get_environment("N") != "" else 120
	for i in n: await process_frame
	root.get_viewport().get_texture().get_image().save_png("/tmp/ai/shot_%s%s.png" % [lv, OS.get_environment("TAG")])
	Prefs.delete_all(); quit()
