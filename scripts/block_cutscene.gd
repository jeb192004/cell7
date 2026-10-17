class_name BlockCutscene
extends Cutscene
## End of 2-3: soldiers pour in and Renn runs out in front of Kesh and blocks every bolt with the Arc-Blade.
## Runs inside the level at the clear (Level adds it, then shows the outro card). Uses the Warden art and Renn's block sheet.
const FRAMES := 16
const FPS := 12.0
var player: Player
var renn: AnimatedSprite2D
var rx := 0.0           # Renn's feet x (world)
var base := Vector2.ZERO
var wardens: Array = []
var bolts: Array = []   # [pos, vel]
var sparks: Array = []  # [pos, age, vel]
var fire_t := 0.0
var drawer: Node2D
var left_x := 0.0       # world x of the left edge of the screen
var frozen: Node        # the level, whose camera follow is paused while this plays

func _build() -> void:
	fade_in = 0.25; fade_out = 0.0; length = 8.5   # a quick fade-in hides Kesh being set at his mark
	captions = [
		[0.5, 3.2, "RENN STEPS FORWARD.  'STAY BEHIND ME.'"],
		[4.0, 7.8, "EVERY BOLT, BLOCKED BY THE ARC-BLADE."],
	]
	for e in get_tree().get_nodes_in_group("enemies"): e.queue_free()
	for n in get_tree().get_nodes_in_group("enemy_shots"): n.queue_free()
	# Lay everything out from the screen, not from Kesh: at the end of a level the camera stops at the edge of the map,
	# so Kesh can be well right of centre. Pin the camera, put Kesh on his mark at the left, and Renn comes to mid-screen.
	var camera := get_viewport().get_camera_2d()
	left_x = camera.get_screen_center_position().x - 240.0 if camera != null else player.global_position.x - 110.0
	frozen = get_parent()
	if frozen != null: frozen.set_process(false)
	player.global_position.x = left_x + 110.0
	base = player.global_position
	for c in get_tree().get_nodes_in_group("cover"):   # keep the stage clear so the bolts and the blade read
		if c is CanvasItem and absf(c.global_position.x - (left_x + 240.0)) < 460.0: c.visible = false
	player.set_physics_process(false); player.velocity = Vector2.ZERO
	player.facing = 1; player.sprite.flip_h = false; player.sprite.play("idle")
	z_index = 20
	var sf := SpriteFrames.new(); sf.remove_animation("default")
	sf.add_animation("run"); sf.set_animation_speed("run", 11.0); sf.set_animation_loop("run", true)
	for i in 8: sf.add_frame("run", load("res://assets/renn_run_%d.png" % i))
	sf.add_animation("block"); sf.set_animation_speed("block", FPS); sf.set_animation_loop("block", true)
	for i in FRAMES: sf.add_frame("block", load("res://assets/renn_block_%d.png" % i))
	renn = AnimatedSprite2D.new(); renn.sprite_frames = sf; renn.position = Vector2(5, -36); renn.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	var holder := Node2D.new(); holder.name = "Renn"; add_child(holder); holder.add_child(renn); renn.play("run")
	rx = left_x - 40.0
	holder.position = Vector2(rx, base.y)
	for i in 2:   # two Wardens show at the right of the screen
		var w := Sprite2D.new(); w.texture = load("res://assets/warden_fire.png"); w.centered = false; w.flip_h = true
		w.position = Vector2(left_x + 520.0 + i * 44.0, base.y - 56.0); add_child(w); wardens.append(w)
	drawer = BoltDraw.new(); drawer.set("owner_cs", self); add_child(drawer)

func _step(d: float) -> void:
	var holder := get_node("Renn") as Node2D
	# Renn runs out in front of Kesh, then plants and blocks
	var tx := left_x + 240.0      # the middle of the screen, Kesh behind him
	if t < 2.6:
		rx = lerpf(left_x - 40.0, tx, ease_(clampf((t - 0.3) / 1.9, 0.0, 1.0)))
		if t > 2.1 and renn.animation != "block": renn.play("block")
	holder.position = Vector2(rx, base.y)
	# the soldiers file in from the right and take positions
	for i in wardens.size():
		var w: Sprite2D = wardens[i]
		var goal := left_x + 372.0 + i * 44.0
		w.position.x = move_toward(w.position.x, goal, 150.0 * d)
	# fire
	if t > 2.7 and t < 7.4:
		fire_t -= d
		if fire_t <= 0.0:
			fire_t = 0.28 + randf() * 0.12
			var w: Sprite2D = wardens[randi() % wardens.size()]
			var from := w.position + Vector2(-2.0, 18.0)
			var to := Vector2(rx + 22.0, base.y - 28.0 + randf_range(-14.0, 14.0))
			bolts.append([from, (to - from).normalized() * 300.0, to.x])
			Sfx.play("enemy_shoot", 1.0, 0.08)
	for b in bolts.duplicate():
		b[0] += b[1] * d
		if b[0].x <= b[2]:
			bolts.erase(b)
			Sfx.play("shield_block", 1.0, 0.1)
			for k in 7:
				var a := randf_range(-0.9, 0.9)
				sparks.append([b[0], 0.0, Vector2(cos(a) * 120.0, sin(a) * -120.0 - 30.0)])
			# a deflected bolt streaks back up and away
			sparks.append([b[0], 0.0, Vector2(260.0, -170.0), true])
	for s in sparks.duplicate():
		s[1] += d; s[0] += s[2] * d
		if s[1] > 0.35: sparks.erase(s)
	drawer.queue_redraw()

func _finish() -> void:
	if frozen != null and is_instance_valid(frozen): frozen.set_process(true)
	player.sprite.play("idle")
	var holder := get_node_or_null("Renn")
	if holder != null: holder.queue_free()

class BoltDraw extends Node2D:
	var owner_cs
	func _draw() -> void:
		var cs = owner_cs
		if cs == null: return
		for b in cs.bolts:
			var dir: Vector2 = b[1].normalized()
			draw_line(b[0], b[0] - dir * 18.0, Color(1.0, 0.25, 0.2), 3.0)
			draw_line(b[0], b[0] - dir * 9.0, Color(1.0, 0.85, 0.7), 1.5)
		for s in cs.sparks:
			var a: float = 1.0 - s[1] / 0.35
			if s.size() > 3: draw_line(s[0], s[0] - s[2].normalized() * 14.0, Color(1.0, 0.4, 0.3, a), 2.0)
			else: draw_rect(Rect2(s[0], Vector2(2, 2)), Color(0.8, 0.95, 1.0, a))
