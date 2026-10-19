extends Node
const SC := "/tmp/claude-0/-home-claude/4fb42d60-b296-53b8-86b1-508c67e69597/scratchpad/"
func hold(a: String, on: bool) -> void:
	if on: Input.action_press(a)
	else: Input.action_release(a)
func shot(n: String) -> void:
	get_viewport().get_texture().get_image().save_png(SC + n + ".png")
func _ready():
	for k in Story.CARDS: Story.played[k] = true
	var lv = load("res://scenes/levels/level_3_6.tscn").instantiate(); lv.set("tutorial", false)
	get_tree().root.add_child.call_deferred(lv)
	await get_tree().create_timer(0.6).timeout
	var p: Player = lv.player; p.hp = 999
	var w = lv.get_node("Enemies/Walker"); w.set_physics_process(false); w.position.x = 900
	print("who=", p.def.key, " crouch_only=", p.def.crouch_only)
	hold("right", true); await get_tree().create_timer(0.5).timeout; shot("f_walk"); print("anim=", p.sprite.animation)
	Input.action_press("run"); await get_tree().create_timer(0.5).timeout; shot("f_run"); print("anim=", p.sprite.animation); Input.action_release("run")
	hold("right", false)
	Input.action_press("jump"); await get_tree().create_timer(0.15).timeout; shot("f_jump"); print("anim=", p.sprite.animation); Input.action_release("jump")
	await get_tree().create_timer(1.0).timeout
	Input.action_press("shoot"); await get_tree().create_timer(0.05).timeout; Input.action_release("shoot")
	await get_tree().create_timer(0.27).timeout; shot("f_shoot"); print("anim=", p.sprite.animation, " ammo=", p.ammo)
	await get_tree().create_timer(0.6).timeout
	Input.action_press("down"); await get_tree().create_timer(0.2).timeout
	Input.action_press("shoot"); await get_tree().create_timer(0.05).timeout; Input.action_release("shoot")
	await get_tree().create_timer(0.27).timeout; shot("f_cshoot"); print("anim=", p.sprite.animation)
	Input.action_release("down"); await get_tree().create_timer(0.6).timeout
	Input.action_press("special"); await get_tree().create_timer(0.05).timeout; Input.action_release("special")
	for i in 7:
		await get_tree().create_timer(0.2).timeout
		shot("f_sp" + str(i)); print("sp t=", snappedf(p.special_t, 0.01), " anim=", p.sprite.animation, " bomb=", is_instance_valid(p.special_bomb))
	print("cd=", p.special_cd)
	get_tree().quit()
