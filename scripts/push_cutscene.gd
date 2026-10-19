class_name PushCutscene
extends Cutscene
## End of 3-7: Corvane has beaten Brix and stands over him. Kesh runs in and throws him back with the Current.
## Runs inside the level at the clear (Level adds it, then shows the outro card). Brix is the player.
## Kesh's push pose is a placeholder (his slingshot pose) until assets/kesh_push_0.png, kesh_push_1.png ... exist: they are used automatically.
var player: Player
var left_x := 0.0
var base_y := 222.0
var frozen: Node
var real_corvane: Node2D
var cv: Sprite2D
var cv_frames: Array = []
var cv_x := 0.0
var cv_vx := 0.0
var cv_y_off := 0.0
var kesh: AnimatedSprite2D
var kesh_holder: Node2D
var kx := 0.0
var push_frames := 0
var waves: Array = []     # [age]
var dust: Array = []      # [pos, age, vel]
var flung := false
const PUSH_T := 7.2
const CV_STAND := 235.0   # Corvane's place over Brix, from the left edge of the screen

func _build() -> void:
	fade_in = 0.25; fade_out = 0.0; length = 11.6; skip_lock = 3.0
	captions = [
		[0.6, 3.4, "BRIX IS DOWN. CORVANE STANDS OVER HIM."],
		[3.8, 6.0, "'YOU FOUGHT WELL. IT CHANGES NOTHING.'"],
		[6.2, 7.6, "KESH: 'GET AWAY FROM HIM!'"],
		[8.0, 11.2, "THE CURRENT. IT THROWS CORVANE BACK."],
	]
	for n in get_tree().get_nodes_in_group("enemy_shots"): n.queue_free()
	for e in get_tree().get_nodes_in_group("enemies"):
		if e.get("finale_ready") == true: real_corvane = e
	var camera := get_viewport().get_camera_2d()
	left_x = camera.get_screen_center_position().x - 240.0 if camera != null else player.global_position.x - 110.0
	frozen = get_parent()
	if frozen != null: frozen.set_process(false)
	base_y = player.global_position.y
	player.global_position.x = left_x + 170.0
	player.set_physics_process(false); player.velocity = Vector2.ZERO
	player.facing = 1; player.sprite.flip_h = false
	player.sprite.animation = "hit"; player.sprite.frame = player.sprite.sprite_frames.get_frame_count("hit") - 1; player.sprite.pause()
	player.sprite.modulate = Color.WHITE
	z_index = 20
	cv_x = left_x + 420.0
	if real_corvane != null:
		cv_x = clampf(real_corvane.global_position.x, left_x + 330.0, left_x + 440.0)
		real_corvane.visible = false
	for i in 8: cv_frames.append(load("res://assets/warden_walk_%d.png" % i))
	cv = Sprite2D.new(); cv.texture = cv_frames[0]; cv.centered = true; cv.flip_h = true
	cv.scale = Vector2(1.12, 1.12); cv.modulate = Color(1.0, 0.55, 0.55); add_child(cv)
	var kd := CharacterDef.kesh()
	kesh_holder = Node2D.new(); add_child(kesh_holder)
	kesh = AnimatedSprite2D.new(); kesh.sprite_frames = kd.make_frames(); kesh.position = kd.sprite_offset; kesh.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	kesh_holder.add_child(kesh); kesh.play("run")
	while ResourceLoader.exists("res://assets/kesh_push_%d.png" % push_frames): push_frames += 1
	if push_frames > 0:
		kesh.sprite_frames.add_animation("push"); kesh.sprite_frames.set_animation_speed("push", 12.0); kesh.sprite_frames.set_animation_loop("push", false)
		for i in push_frames: kesh.sprite_frames.add_frame("push", load("res://assets/kesh_push_%d.png" % i))
	kx = left_x - 40.0
	kesh_holder.position = Vector2(kx, base_y); kesh_holder.visible = false
	Sfx.play("slide", 0.6)

func _step(d: float) -> void:
	# Corvane walks up to Brix and stands over him
	if not flung:
		var k := ease_(clampf((t - 0.3) / 1.8, 0.0, 1.0))
		cv_x = lerpf(cv_x, left_x + CV_STAND, k * 0.2 + 0.0)
		var moving: bool = absf(cv_x - (left_x + CV_STAND)) > 1.5 and t < 3.0
		cv.texture = cv_frames[int(t * 8.0) % cv_frames.size()] if moving else load("res://assets/warden_%s.png" % ("aim" if t < 5.4 else "fire"))
	else:
		cv_x += cv_vx * d; cv_vx *= pow(0.5, d * 1.2); cv_y_off = -absf(sin((t - PUSH_T) * 3.2)) * 26.0 * clampf(1.0 - (t - PUSH_T) / 1.6, 0.0, 1.0)
		cv.rotation += 7.0 * d * clampf(1.0 - (t - PUSH_T) / 1.4, 0.0, 1.0)
		cv.texture = load("res://assets/warden_ready.png")
	cv.flip_h = not flung
	cv.position = Vector2(cv_x, base_y - 35.0 + cv_y_off)   # centred, so the spin is about his middle
	# Kesh runs in from the left and stops short of Brix
	if t >= 5.0:
		kesh_holder.visible = true
		var rk := clampf((t - 5.0) / 1.4, 0.0, 1.0)
		kx = lerpf(left_x - 40.0, left_x + 60.0, ease_(rk))
		kesh_holder.position = Vector2(kx, base_y)
		if rk < 1.0:
			if kesh.animation != "run": kesh.play("run")
		elif t < PUSH_T - 0.1:
			if kesh.animation != "idle": kesh.play("idle")
	if t >= PUSH_T - 0.1 and not flung:
		if push_frames > 0: kesh.play("push")
		else: kesh.animation = "shoot"; kesh.frame = 2; kesh.pause()
	# the push
	if t >= PUSH_T and not flung:
		flung = true; cv_vx = 330.0
		waves.append(0.0); waves.append(-0.12); waves.append(-0.24)
		Sfx.play("explode", 0.5, 0.0); Sfx.play("shield_block", 0.7, 0.0)
		for i in 14: dust.append([Vector2(cv_x - 10.0, base_y - randf_range(2.0, 40.0)), 0.0, Vector2(randf_range(40.0, 160.0), randf_range(-60.0, 20.0))])
	for i in waves.size(): waves[i] += d
	for p in dust.duplicate():
		p[1] += d; p[0] += p[2] * d; p[2] *= 0.94
		if p[1] > 0.7: dust.erase(p)
	if flung and t > PUSH_T + 4.0: cv.visible = false
	if not flung: cv.rotation = 0.0
	queue_redraw()

func _draw() -> void:
	var hand := Vector2(kx + 24.0, base_y - 28.0)
	for w in waves:
		if w < 0.0 or w > 0.9: continue
		var r: float = w * 260.0; var a: float = clampf(1.0 - w / 0.9, 0.0, 1.0)
		draw_arc(hand, r, -0.9, 0.9, 20, Color(0.55, 0.9, 1.0, a), 3.0)
		draw_arc(hand, r * 0.85, -0.8, 0.8, 18, Color(0.9, 1.0, 1.0, a * 0.8), 1.5)
	if flung and t - PUSH_T < 0.25:
		draw_circle(hand, 16.0 * (1.0 - (t - PUSH_T) / 0.25) + 4.0, Color(0.8, 0.97, 1.0, 0.9))
	for p in dust:
		draw_rect(Rect2(p[0], Vector2(2, 2)), Color(0.75, 0.7, 0.65, 1.0 - p[1] / 0.7))

func _finish() -> void:
	if frozen != null and is_instance_valid(frozen): frozen.set_process(true)
	player.sprite.play("idle")
	if real_corvane != null and is_instance_valid(real_corvane): real_corvane.queue_free()
	if cv != null: cv.queue_free()
	if kesh_holder != null: kesh_holder.queue_free()
