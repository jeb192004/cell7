extends Node
func _ready():
	for k in Story.CARDS: Story.played[k] = true
	var lv = load("res://scenes/levels/level_3_3.tscn").instantiate(); lv.tutorial = false
	lv.survive_time = 12.0; lv.wave_every = 2.0
	get_tree().root.add_child.call_deferred(lv)
	await get_tree().create_timer(0.5).timeout
	lv.player.hp = 999
	for i in 16:
		await get_tree().create_timer(1.0).timeout
		var w = get_tree().get_nodes_in_group("enemies").filter(func(e): return e.get("kind") == "warden")
		print("T ", i + 1, " wardens=", w.size(), " left=", snappedf(lv.survive_left, 0.1), " clear_t=", snappedf(lv.clear_t, 0.1), " alerted=", w.filter(func(e): return e.alerted).size())
		if lv.clear_t > 1.0: break
	get_tree().quit()
