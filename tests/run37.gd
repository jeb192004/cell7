extends Node
const SC := "/tmp/claude-0/-home-claude/4fb42d60-b296-53b8-86b1-508c67e69597/scratchpad/"
func _ready():
	for k in Story.CARDS: Story.played[k] = true
	var lv = load("res://scenes/levels/level_3_7.tscn").instantiate(); lv.set("tutorial", false)
	get_tree().root.add_child.call_deferred(lv)
	await get_tree().create_timer(0.6).timeout
	var p: Player = lv.player; p.hp = 8
	var c = lv.get_node("Enemies/Corvane")
	print("who=", p.def.key, " corvane visible=", c.visible, " in enemies=", c.is_in_group("enemies"), " hunters=", c.is_in_group("hunters"))
	await get_tree().create_timer(2.0).timeout
	print("2s: visible=", c.visible, " waiting=", c.waiting, " level cleared? clear_t=", lv.clear_t)
	for e in lv.get_node("Enemies").get_children():
		if e != c: e.hurt(99)
	await get_tree().create_timer(1.0).timeout
	print("squad dead: visible=", c.visible, " waiting=", c.waiting, " x=", snappedf(c.position.x, 1), " player x=", snappedf(p.position.x, 1))
	c.hurt(500); print("hit 500: hp=", c.hp, " enraged=", c.enraged, " ready=", c.finale_ready)
	p.hp = 3; await get_tree().create_timer(3.2).timeout; print("hp 3: ready=", c.finale_ready)
	p.hp = 1
	var got := false
	for i in 80:
		await get_tree().create_timer(0.25).timeout
		if not got and not get_tree().get_nodes_in_group("cutscene").is_empty(): got = true; print("cutscene started after ", i * 0.25, "s (ready=", c.finale_ready, ")")
		if got and get_tree().get_nodes_in_group("cutscene").is_empty(): print("cutscene ended clear_t=", lv.clear_t); break
	get_tree().quit()
