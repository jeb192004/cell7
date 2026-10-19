extends Node
const SC := "/tmp/claude-0/-home-claude/4fb42d60-b296-53b8-86b1-508c67e69597/scratchpad/"
func _ready():
	for k in Story.CARDS: Story.played[k] = true
	var lv = load("res://scenes/levels/level_3_6.tscn").instantiate(); lv.set("tutorial", false)
	get_tree().root.add_child.call_deferred(lv)
	await get_tree().create_timer(0.6).timeout
	lv.player.hp = 999
	var w = lv.get_node("Enemies/Walker")
	await get_tree().create_timer(3.0).timeout
	w.hurt(99)
	var shots := [0.5, 2.0, 3.5, 5.0, 7.0, 9.0]
	var t0 := -1.0; var got := false
	for i in 120:
		await get_tree().create_timer(0.25).timeout
		if not got and not get_tree().get_nodes_in_group("cutscene").is_empty(): got = true; t0 = 0.0; print("cutscene started after ", i * 0.25)
		if got:
			var n := 0
			for s in shots:
				if absf(t0 - s) < 0.13: get_viewport().get_texture().get_image().save_png(SC + "cs_" + str(s) + ".png")
			t0 += 0.25
		if got and get_tree().get_nodes_in_group("cutscene").is_empty(): print("cutscene ended, clear_t=", lv.clear_t); break
	get_tree().quit()
