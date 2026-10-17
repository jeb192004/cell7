class_name ApproachCutscene
extends Cutscene
## Intro to 2-1, after the "Vagabond-9 slips into the blind spot" card: the little Vagabond-9 climbs along the flank of the huge Meridian.
## Runs inside the level while the game is paused (Story.play adds it). Art: assets/meridian_blast_00.png, meridian_logo.png, vagabond.png.
const SCALE := 2.3
var ship: Sprite2D
var vag: Ascent.ShipNode
var logo: Sprite2D
var back: Node2D
var stars := []
var glow: ColorRect

func _build() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	fade_in = 0.6; fade_out = 0.7; length = 9.5
	captions = [[3.6, 8.2, "THE VAGABOND-9 SLIPS INTO THE MERIDIAN'S BLIND SPOT."]]
	var layer := CanvasLayer.new(); layer.layer = 15; layer.process_mode = Node.PROCESS_MODE_ALWAYS; add_child(layer)
	var bg := ColorRect.new(); bg.color = Color(0.02, 0.02, 0.07); bg.size = Vector2(480, 270); layer.add_child(bg)
	for i in 70: stars.append([Vector2(randf() * 480.0, randf() * 270.0), 0.3 + randf() * 0.9])
	back = Node2D.new(); layer.add_child(back); back.draw.connect(_draw_stars)
	ship = Sprite2D.new(); ship.texture = load("res://assets/meridian_blast_00.png"); ship.scale = Vector2(SCALE, SCALE)
	ship.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR; layer.add_child(ship)
	vag = Ascent.ShipNode.new(); layer.add_child(vag)
	logo = Sprite2D.new(); logo.texture = load("res://assets/meridian_logo.png"); logo.position = Vector2(240, 120); logo.modulate.a = 0.0
	logo.scale = Vector2(1.5, 1.5); logo.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR; layer.add_child(logo)
	Sfx.engine("ship_engine")

func _exit_tree() -> void:
	Sfx.engine_stop()

func _draw_stars() -> void:
	for s in stars:
		var p: Vector2 = s[0]
		p.x = fposmod(p.x - t * 4.0 * float(s[1]), 480.0)
		back.draw_rect(Rect2(p, Vector2(1, 1)), Color(0.8, 0.85, 1.0, 0.35 + 0.4 * float(s[1]) / 1.2))

func _step(_d: float) -> void:
	back.queue_redraw()
	# the Meridian drifts left across the whole shot, so it feels enormous
	var k := t / length
	ship.position = Vector2(290.0 - k * 90.0, 100.0 + k * 14.0)
	# the Vagabond-9 climbs from the lower left toward the underside of the hull, shrinking into its shadow
	var v := ease_(clampf((t - 1.2) / 6.8, 0.0, 1.0))
	vag.position = Vector2(-30.0 + v * 290.0, 255.0 - v * 85.0)
	vag.rotation = -0.22 * (1.0 - v * 0.6)
	vag.scale = Vector2.ONE * lerpf(0.4, 0.2, v)
	vag.power = 0.7
	vag.modulate = Color(1, 1, 1).lerp(Color(0.35, 0.35, 0.45), clampf((t - 6.0) / 2.0, 0.0, 1.0))
	logo.modulate.a = clampf(minf((t - 0.5) / 0.6, (3.2 - t) / 0.6), 0.0, 1.0)
