class_name BlastCutscene
extends Cutscene
## End of 2-4: the Vagabond-9 pulls away from the Meridian and Fuse's charges go off, one after another. Art: assets/meridian_blast_00..18.
## Runs inside the level at the clear (Level adds it, then shows the outro card). It covers the screen with its own space backdrop.
const SCALE := 1.35
const SHIP_AT := Vector2(318.0, 118.0)
const T_HOLD := 3.2          # the Meridian sits quiet while the Vagabond-9 leaves
const T_DAMAGE := 0.4        # seconds per damage frame (frames 1-8)
var frames: Array = []
var ship: Sprite2D
var vag: Ascent.ShipNode
var flash: ColorRect
var stars := []
var back: Node2D
var times := []              # frame index -> start time
var fired := {}
var shake := 0.0

func _build() -> void:
	fade_in = 0.6; fade_out = 0.8; length = 11.8
	captions = [
		[0.7, 3.0, "THE VAGABOND-9 BREAKS AWAY."],
		[3.6, 6.8, "FUSE'S CHARGES GO OFF, ONE BY ONE."],
		[8.6, 11.0, "THE MERIDIAN BURNS."],
	]
	for i in 19: frames.append(load("res://assets/meridian_blast_%02d.png" % i))
	# frame start times: 0 idle, 1-8 damage, 9-11 hollow, 12 flash, 13-15 blast, 16-18 fade
	var tt := T_HOLD
	times = [0.0]
	for i in range(1, 9): times.append(tt); tt += T_DAMAGE
	for i in range(9, 12): times.append(tt); tt += 0.35
	times.append(tt); tt += 0.15
	for i in range(13, 16): times.append(tt); tt += 0.2
	for i in range(16, 19): times.append(tt); tt += 0.4
	var layer := CanvasLayer.new(); layer.layer = 15; add_child(layer)
	var bg := ColorRect.new(); bg.color = Color(0.02, 0.02, 0.07); bg.size = Vector2(480, 270); layer.add_child(bg)
	for i in 70: stars.append([Vector2(randf() * 480.0, randf() * 270.0), 0.3 + randf() * 0.9])
	back = Node2D.new(); layer.add_child(back)
	back.draw.connect(_draw_stars)
	ship = Sprite2D.new(); ship.texture = frames[0]; ship.scale = Vector2(SCALE, SCALE); ship.position = SHIP_AT; layer.add_child(ship)
	vag = Ascent.ShipNode.new(); layer.add_child(vag)
	vag.position = Vector2(170.0, 178.0); vag.scale = Vector2(-0.8, 0.8)   # faces left, flying away
	flash = ColorRect.new(); flash.color = Color(1, 0.95, 0.8, 0.0); flash.size = Vector2(480, 270)
	flash.mouse_filter = Control.MOUSE_FILTER_IGNORE; layer.add_child(flash)
	Sfx.engine("ship_engine")

func _exit_tree() -> void:
	Sfx.engine_stop()

func _draw_stars() -> void:
	for s in stars:
		var p: Vector2 = s[0]
		p.x = fposmod(p.x - t * 6.0 * float(s[1]), 480.0)
		back.draw_rect(Rect2(p, Vector2(1, 1)), Color(0.8, 0.85, 1.0, 0.35 + 0.4 * float(s[1]) / 1.2))

func _step(_d: float) -> void:
	back.queue_redraw()
	# the Vagabond-9 slides away to the left and shrinks
	var v := ease_(clampf((t - 0.6) / 3.0, 0.0, 1.0))
	vag.position = Vector2(170.0 - v * 250.0, 178.0 - v * 40.0)
	var vs := lerpf(0.8, 0.3, v)
	vag.scale = Vector2(-vs, vs)
	vag.power = 0.6 + v * 0.8
	vag.visible = t < 3.8
	# which frame
	var f := 0
	for i in times.size():
		if t >= times[i]: f = i
	ship.texture = frames[f]
	# shake builds with the damage, then dies away
	var amt := 0.0
	if t > T_HOLD: amt = clampf((t - T_HOLD) / 4.0, 0.0, 1.0) * 2.5
	if t > times[12]: amt = 4.0 * clampf(1.0 - (t - times[12]) / 3.0, 0.0, 1.0)
	ship.position = SHIP_AT + Vector2(randf_range(-amt, amt), randf_range(-amt, amt))
	# blasts
	for k in [1, 3, 5, 7, 9]:
		if t >= times[k] and not fired.has(k):
			fired[k] = true; Sfx.play("explode", 1.5 - k * 0.07, 0.1)
	if t >= times[12] and not fired.has(12):
		fired[12] = true; Sfx.play("explode", 0.6)
	var fa := 0.0
	if t >= times[12] and t < times[13]: fa = 0.85
	elif t >= times[13] and t < times[13] + 0.35: fa = 0.5 * (1.0 - (t - times[13]) / 0.35)
	flash.color.a = fa
