class_name AmbushCutscene
extends Cutscene
## End of 2-3: the download trips the alarm and Wardens close in on Kesh from both sides. Runs inside the level at the clear,
## before the "TOO LATE" card. Uses the existing Kesh and Warden art.
var player: Player
var base := Vector2.ZERO
var left_x := 0.0
var frozen: Node
var wardens: Array = []   # [sprite, goal_x, side]
var red: ColorRect
var walk_t := 0.0
const WALK := 8

func _build() -> void:
	fade_in = 0.25; fade_out = 0.8; length = 9.0
	captions = [
		[0.4, 2.4, "THE DOWNLOAD TRIPS A SILENT ALARM."],
		[3.0, 5.6, "WARDENS POUR IN FROM EVERY SIDE."],
		[6.2, 8.2, "KESH HAS NOWHERE LEFT TO RUN."],
	]
	for e in get_tree().get_nodes_in_group("enemies"): e.queue_free()
	for n in get_tree().get_nodes_in_group("enemy_shots"): n.queue_free()
	var camera := get_viewport().get_camera_2d()
	left_x = camera.get_screen_center_position().x - 240.0 if camera != null else player.global_position.x - 240.0
	frozen = get_parent()
	if frozen != null: frozen.set_process(false)
	player.global_position.x = left_x + 240.0
	base = player.global_position
	for c in get_tree().get_nodes_in_group("cover"):
		if c is CanvasItem and absf(c.global_position.x - (left_x + 240.0)) < 300.0: c.visible = false
	player.set_physics_process(false); player.velocity = Vector2.ZERO
	player.facing = 1; player.sprite.flip_h = false; player.sprite.play("idle")
	z_index = 20
	var hud := CanvasLayer.new(); hud.layer = 12; add_child(hud)
	red = ColorRect.new(); red.color = Color(1, 0.05, 0.05, 0.0); red.size = Vector2(480, 270); red.mouse_filter = Control.MOUSE_FILTER_IGNORE; hud.add_child(red)
	for i in 6:
		var side := -1 if i % 2 == 0 else 1         # -1 = comes from the left
		var k := i / 2
		var w := Sprite2D.new(); w.texture = load("res://assets/warden_walk_0.png"); w.centered = false; w.flip_h = side > 0
		var sx := left_x - 90.0 - k * 50.0 if side < 0 else left_x + 480.0 + 20.0 + k * 50.0
		w.position = Vector2(sx, base.y - 56.0 - 0.0); add_child(w)
		var goal := left_x + 240.0 - 40.0 - 56.0 - k * 34.0 if side < 0 else left_x + 240.0 + 40.0 - 12.0 + k * 34.0
		wardens.append([w, goal, side, 2.6 + i * 0.12])

func _step(d: float) -> void:
	walk_t += d
	# alarm pulse
	red.color.a = (0.10 + 0.14 * absf(sin(t * 5.0))) * (1.0 if t < 7.5 else 0.0)
	if int(t * 2.5) != int((t - d) * 2.5) and t < 7.5: Sfx.play("enemy_shoot", 0.5, 0.0)
	var armed := t > 5.0
	for w in wardens:
		var s: Sprite2D = w[0]
		if t < w[3]: continue
		if absf(s.position.x - w[1]) > 1.0:
			s.position.x = move_toward(s.position.x, w[1], 110.0 * d)
			s.texture = load("res://assets/warden_walk_%d.png" % (int(walk_t * 9.0) % WALK))
		else:
			s.texture = load("res://assets/warden_aim.png") if armed else load("res://assets/warden_ready.png")
	# Kesh throws his hands up once he is surrounded
	if t > 5.4 and player.sprite.animation != "hit":
		player.sprite.play("hit")

func _finish() -> void:
	if frozen != null and is_instance_valid(frozen): frozen.set_process(true)
	player.sprite.play("idle")
