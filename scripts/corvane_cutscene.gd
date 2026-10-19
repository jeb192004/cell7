class_name CorvaneCutscene
extends Cutscene
## End of 3-6, once the second Titan Strider is down: smoke pours off the wreck and Head Warden Corvane walks out of it.
## Runs inside the level at the clear (Level adds it, then shows the outro card). Uses the Warden art (Corvane is a red-tinted Warden until he has his own).
var player: Player
var left_x := 0.0
var frozen: Node
var wreck_x := 0.0
var base_y := 222.0
var cv: Sprite2D
var cv_frames: Array = []
var puffs: Array = []     # [pos, age, vel, size]
var embers: Array = []    # [pos, age, vel]
var smoke: Node2D
var puff_t := 0.0
var debris: Array = []   # [dx, w, h, shade, tilt]
var flames: Array = []   # [dx, dy, size, phase]
var blasts := [0.9, 2.3]
var wreck_draw: Node2D
const GOAL_FROM_LEFT := 250.0   # where Corvane stops, measured from the left edge of the screen

func _build() -> void:
	fade_in = 0.25; fade_out = 0.0; length = 10.2; skip_lock = 3.0
	captions = [
		[0.6, 3.4, "THE STRIDER BURNS. SOMETHING MOVES IN THE SMOKE."],
		[4.0, 6.0, "HEAD WARDEN CORVANE."],
		[6.4, 9.8, "'TWO WALKERS. YOUR CREW WILL PAY FOR BOTH.'"],
	]
	for n in get_tree().get_nodes_in_group("enemy_shots"): n.queue_free()
	var camera := get_viewport().get_camera_2d()
	left_x = camera.get_screen_center_position().x - 240.0 if camera != null else player.global_position.x - 110.0
	frozen = get_parent()
	if frozen != null: frozen.set_process(false)
	player.global_position.x = left_x + 100.0
	base_y = player.global_position.y
	player.set_physics_process(false); player.velocity = Vector2.ZERO
	player.facing = 1; player.sprite.flip_h = false; player.sprite.play("idle")
	z_index = 20
	wreck_x = left_x + 380.0
	# the dead Strider stays where it fell: pull it onto the stage. (No Strider in the preview, so make a wreck.)
	var w := get_tree().current_scene.get_node_or_null("Enemies/Walker") as Node2D
	if w != null:
		w.global_position.x = wreck_x
	else:
		var s := Sprite2D.new(); s.texture = load("res://assets/walker_15.png"); s.centered = false
		s.position = Vector2(wreck_x - 75.0, base_y - 108.0); s.z_index = -1; add_child(s)
	for i in 8: cv_frames.append(load("res://assets/warden_walk_%d.png" % i))
	cv = Sprite2D.new(); cv.texture = cv_frames[0]; cv.centered = false; cv.flip_h = true
	cv.scale = Vector2(1.12, 1.12); cv.position = Vector2(wreck_x - 10.0, base_y - 62.0)
	cv.modulate = Color(0.02, 0.0, 0.0, 0.0); cv.z_index = -1; add_child(cv)
	smoke = SmokeDraw.new(); smoke.set("owner_cs", self); smoke.z_index = 5; add_child(smoke)
	var rng := RandomNumberGenerator.new(); rng.seed = 36
	for i in 14: debris.append([rng.randf_range(-105.0, 85.0), rng.randf_range(4.0, 11.0), rng.randf_range(2.0, 5.0), rng.randf_range(0.18, 0.4), rng.randf_range(-0.5, 0.5)])
	for dx in [-48.0, -26.0, -4.0, 18.0, 36.0]: flames.append([dx, rng.randf_range(-62.0, -42.0), rng.randf_range(10.0, 17.0), rng.randf() * 6.0])
	wreck_draw = WreckDraw.new(); wreck_draw.set("owner_cs", self); wreck_draw.z_index = 2; add_child(wreck_draw)
	Sfx.play("explode", 0.5, 0.0)

func _step(d: float) -> void:
	# smoke and embers rise off the wreck the whole time
	puff_t -= d
	if puff_t <= 0.0:
		puff_t = 0.07
		puffs.append([Vector2(wreck_x + randf_range(-34.0, 26.0), base_y - randf_range(55.0, 80.0)), 0.0, Vector2(randf_range(-6.0, 10.0), randf_range(-26.0, -14.0)), randf_range(7.0, 12.0)])
		if randf() < 0.5: embers.append([Vector2(wreck_x + randf_range(-40.0, 30.0), base_y - randf_range(40.0, 85.0)), 0.0, Vector2(randf_range(-14.0, 14.0), randf_range(-60.0, -25.0))])
	for p in puffs.duplicate():
		p[1] += d; p[0] += p[2] * d; p[3] += 5.0 * d
		if p[1] > 2.4: puffs.erase(p)
	for e in embers.duplicate():
		e[1] += d; e[0] += e[2] * d; e[2].y += 20.0 * d
		if e[1] > 1.2: embers.erase(e)
	# Corvane: dark shape in the smoke at 2.0 s, steps out, colour comes back as he clears the wreck, stops in front of Fuse
	var goal := left_x + GOAL_FROM_LEFT
	var k := ease_(clampf((t - 2.2) / 3.4, 0.0, 1.0))
	var x := lerpf(wreck_x - 10.0, goal, k)
	cv.position.x = x - 20.0
	var fadein := clampf((t - 2.0) / 1.0, 0.0, 1.0)
	var col := Color(0.0, 0.0, 0.0).lerp(Color(1.0, 0.55, 0.55), clampf((t - 3.4) / 1.6, 0.0, 1.0))
	cv.modulate = Color(col.r, col.g, col.b, fadein)
	cv.z_index = 3 if t > 3.0 else -1
	if k > 0.0 and k < 1.0:
		cv.texture = cv_frames[int(t * 8.0) % cv_frames.size()]
	else:
		cv.texture = cv_frames[0]
	wreck_draw.queue_redraw()
	for b in blasts.duplicate():
		if t >= b:
			blasts.erase(b)
			var fx := BlastFx.new(); fx.radius = 38.0; fx.global_position = Vector2(wreck_x + randf_range(-30.0, 25.0), base_y - randf_range(25.0, 55.0)); add_child(fx)
			Sfx.play("explode", 0.6, 0.05)
	smoke.queue_redraw()

func _finish() -> void:
	if frozen != null and is_instance_valid(frozen): frozen.set_process(true)
	player.sprite.play("idle")
	if cv != null: cv.queue_free()

## Burning wreckage: scattered plates and struts on the street, and flames licking off the Strider.
class WreckDraw extends Node2D:
	var owner_cs
	func _draw() -> void:
		var cs = owner_cs
		if cs == null: return
		var x: float = cs.wreck_x; var y: float = cs.base_y
		for d in cs.debris:
			var c := Color(d[3], d[3] * 0.95, d[3] * 1.1)
			var p := Vector2(x + d[0], y)
			var r: float = d[4]
			var pts := PackedVector2Array([p + Vector2(-d[1] / 2.0, 0), p + Vector2(d[1] / 2.0, 0), p + Vector2(d[1] / 2.0 - 1.0 + r * 3.0, -d[2]), p + Vector2(-d[1] / 2.0 + 1.0, -d[2] * 0.6)])
			draw_colored_polygon(pts, c)
			draw_line(pts[2], pts[2] + Vector2(r * 6.0, -d[2] - 2.0), Color(0.55, 0.5, 0.5), 1.0)   # a bent strut
		var tm: float = cs.t
		for f in cs.flames:
			var h: float = f[2] * (0.7 + 0.3 * sin(tm * 14.0 + f[3])) * clampf(1.4 - tm / 12.0, 0.5, 1.0)
			var b := Vector2(x + f[0], y + f[1])
			var sway := sin(tm * 9.0 + f[3]) * 2.0
			draw_colored_polygon(PackedVector2Array([b + Vector2(-5, 0), b + Vector2(5, 0), b + Vector2(sway, -h)]), Color(1.0, 0.4, 0.08, 0.85))
			draw_colored_polygon(PackedVector2Array([b + Vector2(-2.5, 0), b + Vector2(2.5, 0), b + Vector2(sway, -h * 0.65)]), Color(1.0, 0.85, 0.3, 0.95))

class SmokeDraw extends Node2D:
	var owner_cs
	func _draw() -> void:
		var cs = owner_cs
		if cs == null: return
		for p in cs.puffs:
			var a: float = clampf(1.0 - p[1] / 2.4, 0.0, 1.0) * 0.55
			draw_circle(p[0], p[3], Color(0.12, 0.11, 0.14, a))
			draw_circle(p[0] + Vector2(-1.5, -1.5), p[3] * 0.6, Color(0.22, 0.2, 0.24, a * 0.8))
		for e in cs.embers:
			var a: float = clampf(1.0 - e[1] / 1.2, 0.0, 1.0)
			draw_rect(Rect2(e[0], Vector2(2, 2)), Color(1.0, 0.6, 0.2, a))
