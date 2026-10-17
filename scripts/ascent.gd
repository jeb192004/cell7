class_name Ascent
extends Cutscene
## Between 1-4 and 1-5: the Vagabond-9 drops in over the highway, lifts Kesh and his bike aboard with a tractor beam,
## and climbs out of the atmosphere into the belt. A short cutscene, all existing art. Any key or a tap skips it.
const SCROLL := 150.0
const CRUISE := [18, 19, 20, 19]
const SHIP_END := Vector2(100, 135)      # where the Kestrel starts 1-5, so the hand-off is seamless
const HOVER := Vector2(112, 108)         # over the bike
const BIKE_Y := 238.0
## [start, end, text] -- edit the captions here
const CAPTIONS_ := [
	[1.2, 3.6, "THE VAGABOND-9 DROPS IN OVER THE HIGHWAY."],
	[5.6, 8.0, "UP AND OUT OF BRIXWATER."],
]
const T_LIFT0 := 3.0
const T_LIFT1 := 4.5
const T_CLIMB0 := 4.9
const T_CLIMB1 := 8.0
const T_END := 9.0
var dist := 0.0
var layers: Array = []
var bike: Node2D
var bike_spr: Sprite2D
var bike_tex: Array = []
var ship: Node2D
var sky: Sprite2D
var stars: Node2D
var beam: Node2D
var flame := 0.0

func _build() -> void:
	captions = CAPTIONS_; length = T_END
	Controls.setup()
	get_tree().paused = false
	var star_layer := CanvasLayer.new(); star_layer.layer = -11; add_child(star_layer)
	stars = SpaceLevel.StarField.new(); stars.modulate.a = 0.0; star_layer.add_child(stars)
	var sky_layer := CanvasLayer.new(); sky_layer.layer = -10; add_child(sky_layer)
	sky = Sprite2D.new(); sky.texture = load("res://assets/bg_hw_sky.png"); sky.centered = false; sky_layer.add_child(sky)
	_layer("bg_hw_far", 0.12, -30)
	_layer("bg_hw_mid", 0.3, -20)
	_layer("bike_ground", 1.0, -5)
	_layer("bike_near", 1.0, -4)
	bike = Node2D.new(); bike.position = Vector2(120, BIKE_Y); bike.z_index = 5; add_child(bike)
	for i in [18, 19, 20]: bike_tex.append(load("res://assets/kesh_bike_%02d.png" % i))
	bike_spr = Sprite2D.new(); bike_spr.texture = bike_tex[0]; bike_spr.centered = false; bike_spr.position = Vector2(-74, -55); bike.add_child(bike_spr)
	beam = BeamNode.new(); beam.z_index = 8; add_child(beam)
	ship = ShipNode.new(); ship.position = Vector2(-90, 55); ship.z_index = 10; add_child(ship)
	Sfx.engine("bike_engine")

func _exit_tree() -> void:
	Sfx.engine_stop()

func _layer(tex: String, factor: float, z: int) -> void:
	var n := Node2D.new(); n.z_index = z; add_child(n)
	for i in 2:
		var s := Sprite2D.new(); s.texture = load("res://assets/%s.png" % tex); s.centered = false; s.position = Vector2(480 * i, 0); n.add_child(s)
	layers.append([n, factor])

func _step(d: float) -> void:
	# the road keeps rolling the whole time
	dist += SCROLL * d
	for l in layers: (l[0] as Node2D).position.x = -fmod(dist * l[1], 480.0)
	bike_spr.texture = bike_tex[[0, 1, 2, 1][int(t * 14.0) % 4]]
	# the ship drops in, hovers over the bike, then climbs
	var enter := _ease(clampf((t - 0.8) / 2.0, 0.0, 1.0))
	var climb := clampf((t - T_CLIMB0) / (T_CLIMB1 - T_CLIMB0), 0.0, 1.0)
	var p := Vector2(-90, 55).lerp(HOVER, enter)
	p += Vector2(0, sin(t * 3.0) * 2.0 * (1.0 - climb))
	p = p.lerp(SHIP_END, _ease(climb))
	ship.position = p
	ship.rotation = lerpf(0.0, -0.10, enter) * (1.0 - climb) + sin(climb * PI) * -0.28
	(ship as ShipNode).power = 0.4 + 0.6 * climb + (0.3 if t > T_LIFT0 else 0.0)
	# tractor beam and the lift
	var beam_a := clampf((t - 2.6) / 0.4, 0.0, 1.0) * (1.0 - clampf((t - T_LIFT1) / 0.4, 0.0, 1.0))
	(beam as BeamNode).alpha = beam_a
	(beam as BeamNode).top = Vector2(ship.position.x, ship.position.y + 18.0)
	(beam as BeamNode).t = t
	var lift := _ease(clampf((t - T_LIFT0) / (T_LIFT1 - T_LIFT0), 0.0, 1.0))
	bike.position = Vector2(120.0 + lift * (ship.position.x - 8.0 - 120.0), lerpf(BIKE_Y, ship.position.y + 62.0, lift) + sin(t * 9.0) * 1.5 * lift)
	bike.rotation = sin(t * 5.0) * 0.04 * lift
	bike.modulate.a = 1.0 - clampf((t - (T_LIFT1 - 0.2)) / 0.3, 0.0, 1.0)
	if t > T_LIFT1 + 0.1 and bike.visible and bike.modulate.a <= 0.0:
		bike.visible = false; Sfx.engine("ship_engine")
	# the world drops away and the sky turns to stars
	var drop := _ease(clampf((t - T_CLIMB0) / 3.2, 0.0, 1.0)) * 320.0
	for l in layers: (l[0] as Node2D).position.y = drop
	sky.modulate.a = 1.0 - _ease(clampf((t - 5.6) / 2.4, 0.0, 1.0))
	stars.modulate.a = _ease(clampf((t - 5.2) / 2.4, 0.0, 1.0))
	(stars as SpaceLevel.StarField).scroll += d * lerpf(0.3, 1.0, climb)

static func _ease(x: float) -> float:
	return x * x * (3.0 - 2.0 * x)

class ShipNode extends Node2D:
	var power := 0.5
	var tex: Texture2D = load("res://assets/vagabond.png")
	func _process(_d: float) -> void:
		queue_redraw()
	func _draw() -> void:
		draw_texture(tex, -tex.get_size() / 2.0)
		var l := (8.0 + power * 22.0) * (0.85 + randf() * 0.3)
		for y in [-4.0, 11.0]:
			draw_rect(Rect2(-44.0 - l, y, l, 3), Color(1.0, 0.55, 0.2, 0.9))
			draw_rect(Rect2(-44.0 - l * 0.6, y + 0.5, l * 0.6, 2), Color(1.0, 0.92, 0.65, 0.95))

class BeamNode extends Node2D:
	var alpha := 0.0
	var top := Vector2.ZERO
	var t := 0.0
	func _process(_d: float) -> void:
		queue_redraw()
	func _draw() -> void:
		if alpha <= 0.01: return
		var y1 := 262.0
		var pts := PackedVector2Array([top + Vector2(-16, 0), top + Vector2(16, 0), Vector2(top.x + 52, y1), Vector2(top.x - 52, y1)])
		draw_colored_polygon(pts, Color(0.45, 0.85, 1.0, 0.22 * alpha))
		var inner := PackedVector2Array([top + Vector2(-8, 0), top + Vector2(8, 0), Vector2(top.x + 30, y1), Vector2(top.x - 30, y1)])
		draw_colored_polygon(inner, Color(0.8, 0.97, 1.0, 0.25 * alpha))
		for i in 6:   # rising rungs
			var k := fposmod(t * 1.4 + i / 6.0, 1.0)
			var y := y1 - k * (y1 - top.y)
			var w := lerpf(52.0, 16.0, k)
			draw_rect(Rect2(top.x - w, y, w * 2.0, 1), Color(0.85, 1.0, 1.0, 0.5 * alpha * (1.0 - k * 0.6)))
