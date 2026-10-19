extends Node
func _ready():
	for k in Story.CARDS: Story.played[k] = true
	var lv = load("res://scenes/levels/level_3_6.tscn").instantiate(); lv.set("tutorial", false)
	get_tree().root.add_child.call_deferred(lv)
	await get_tree().create_timer(0.6).timeout
	lv.player.hp = 999
	var w = lv.get_node("Enemies/Walker")
	print("who=", lv.player.def.key, " hp=", w.hp)
	var spots = lv.get_tree().get_nodes_in_group("charge_spots"); print("spots=", spots.size())
	var seen := {}
	for i in 50:
		await get_tree().create_timer(0.5).timeout
		seen[w.state] = true
		if i == 2:
			for sp in spots: sp.planted = true; sp.queue_redraw()
			get_viewport().get_texture().get_image().save_png("/tmp/claude-0/-home-claude/4fb42d60-b296-53b8-86b1-508c67e69597/scratchpad/f1.png")
		# lure: teleport player near strider's far side so it walks left over the spots
		if i % 4 == 0: print("t=", i * 0.5, " state=", w.state, " hp=", w.hp, " x=", snappedf(w.position.x, 1), " planted=", spots.filter(func(s): return s.planted).size())
		if i == 30: get_viewport().get_texture().get_image().save_png("/tmp/claude-0/-home-claude/4fb42d60-b296-53b8-86b1-508c67e69597/scratchpad/f2.png")
		if lv.clear_t > 0.5: print("CLEARED at i=", i); break
	print("STATES ", seen.keys(), " final hp=", w.hp)
	get_tree().quit()
