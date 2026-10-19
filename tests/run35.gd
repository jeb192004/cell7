extends Node
func _ready():
	for k in Story.CARDS: Story.played[k] = true
	var lv = load("res://scenes/levels/level_3_5.tscn").instantiate(); lv.set("tutorial", false)
	get_tree().root.add_child.call_deferred(lv)
	await get_tree().create_timer(0.6).timeout
	lv.player.hp = 999
	var w = lv.get_node("Enemies/Walker")
	print("who=", lv.player.def.key, " hp=", w.hp)
	var seen := {}
	for i in 60:
		await get_tree().create_timer(0.5).timeout
		seen[w.state] = true
		if i == 3 or i == 5 or i == 7 or i == 9:
			print("SHOT ", i); get_viewport().get_texture().get_image().save_png("/tmp/claude-0/-home-claude/4fb42d60-b296-53b8-86b1-508c67e69597/scratchpad/w1_" + str(i) + ".png")
		if i == 14: w.hurt(14); print("HURT14 -> state=", w.state, " hp=", w.hp)
		if i == 28: w.hurt(8); print("HURT8 -> state=", w.state, " hp=", w.hp, " strafed=", w.strafed)
		if i == 16 or i == 19: get_viewport().get_texture().get_image().save_png("/tmp/claude-0/-home-claude/4fb42d60-b296-53b8-86b1-508c67e69597/scratchpad/w2.png")
		if i == 44: w.hurt(99); print("KILL state=", w.state)
		if i % 4 == 0: print("t=", i * 0.5, " state=", w.state, " hp=", w.hp, " x=", snappedf(w.position.x, 1))
		if lv.clear_t > 0.5: print("CLEARED at i=", i); break
	print("STATES ", seen.keys())
	get_tree().quit()
