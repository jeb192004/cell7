extends Node
var lv
func press(a, on):
	var e := InputEventAction.new(); e.action = a; e.pressed = on; Input.parse_input_event(e)
func _ready():
	for k in Story.CARDS: Story.played[k] = true
	lv = load("res://scenes/levels/level_3_2.tscn").instantiate(); lv.tutorial = false
	get_tree().root.add_child.call_deferred(lv)
	await get_tree().create_timer(1.0).timeout
	print("ENEMIES ", get_tree().get_nodes_in_group("enemies").size(), " who=", lv.player.def.key)
	for e in get_tree().get_nodes_in_group("enemies"): e.queue_free()
	for c in get_tree().get_nodes_in_group("cover"): c.queue_free()
	for b in get_tree().get_nodes_in_group("barriers"): b.queue_free()
	press("right", true)
	for i in 60:
		await get_tree().create_timer(1.0).timeout
		print("RUN t=", i + 1, " pos=", lv.player.global_position, " hp=", lv.player.hp)
		if lv.player.global_position.x > 4150 or lv.get("clear_t") != null and lv.clear_t >= 0.0: break
	press("right", false)
	get_tree().quit()
