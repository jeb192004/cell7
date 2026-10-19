extends Node
func _ready():
	for k in Story.CARDS: Story.played[k] = true
	var lv = load("res://scenes/levels/level_3_6.tscn").instantiate(); lv.set("tutorial", false)
	get_tree().root.add_child.call_deferred(lv)
	await get_tree().create_timer(0.6).timeout
	var w = lv.get_node("Enemies/Walker"); w.set_physics_process(false)
	var b := FuseBomb.new(); b.global_position = w.global_position + Vector2(-60, -60); lv.add_child(b); b.detonate_in(0.05)
	await get_tree().create_timer(0.3).timeout
	print("walker hp after bomb=", w.hp)
	get_tree().quit()
