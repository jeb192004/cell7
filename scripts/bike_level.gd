class_name BikeLevel
extends Node2D
## 1-4: the speeder-bike escape. Fixed screen, scrolling highway, three lanes.
## Up / Down change lane, Left / Right ride forward or fall back, shoot fires along your lane.
const SCROLL := 150.0
@export var title := ""
@export_file("*.tscn") var next_level := ""
var player: BikePlayer
var overlay: Overlay
var hud: CanvasLayer
var t := 0.0
var dist := 0.0
var kills := 0
var total_foes := 0
var ev_i := 0
var layers: Array = []
var down_t := -1.0
var clear_t := -1.0
var boss_dead := false
## [time, kind, lane]
var events: Array = [
	[1.5, "wreck", 1], [3.5, "barrier", 2], [4.5, "wreck", 0],
	[7.0, "bike", 1], [9.5, "barrier", 0], [10.0, "barrier", 1], [12.0, "pip", 2],
	[13.0, "bike", 0], [15.5, "ram", 2], [17.0, "wreck", 2], [17.5, "wreck", 1],
	[19.5, "bike", 2], [19.5, "bike", 0],
	[23.0, "swoop", 1], [25.0, "barrier", 2], [26.5, "ram", 0], [27.5, "bike", 1],
	[30.5, "wreck", 0], [31.0, "wreck", 1], [33.0, "bike", 2], [34.5, "ram", 1],
	[37.0, "pip", 1], [37.5, "swoop", 0], [39.0, "bike", 1], [39.0, "bike", 2],
	[43.0, "barrier", 1], [43.5, "barrier", 2], [44.5, "ram", 0], [46.0, "bike", 0],
	[49.0, "swoop", 2], [50.5, "wreck", 1], [52.0, "bike", 1], [52.5, "ram", 2],
	[56.0, "pip", 0], [56.5, "bike", 0], [56.5, "bike", 2], [58.0, "swoop", 1],
	[62.0, "wreck", 0], [62.5, "barrier", 1], [64.0, "ram", 2], [66.0, "bike", 1],
	[70.0, "boss", 1]]

func _ready() -> void:
	physics_interpolation_mode = Node.PHYSICS_INTERPOLATION_MODE_OFF   # everything here moves in _process; interpolation made new foes flash on 120Hz screens
	Controls.setup()
	if ResourceLoader.exists("res://data/level_04_events.gd"):
		events = (load("res://data/level_04_events.gd") as GDScript).new().EVENTS.duplicate()
		events.sort_custom(func(a, b): return a[0] < b[0])
	get_tree().paused = false
	var sky_layer := CanvasLayer.new(); sky_layer.layer = -10; add_child(sky_layer)
	var sky := Sprite2D.new(); sky.texture = load("res://assets/bg_hw_sky.png"); sky.centered = false; sky_layer.add_child(sky)
	_layer("bg_hw_far", 0.12, -30)
	_layer("bg_hw_mid", 0.3, -20)
	_layer("bike_ground", 1.0, -5)
	_layer("bike_near", 1.0, -4)
	player = BikePlayer.new(); add_child(player)
	hud = CanvasLayer.new(); hud.layer = 10; add_child(hud)
	var hearts := Hearts.new(); hearts.player = player; hud.add_child(hearts)
	overlay = Overlay.new(); add_child(overlay)
	overlay.restart.connect(func(): get_tree().reload_current_scene())
	overlay.to_title.connect(func(): get_tree().change_scene_to_file(Overlay.TITLE_SCENE))
	overlay.next.connect(func(): get_tree().change_scene_to_file(next_level))
	for e in events:
		if e[1] in ["bike", "ram", "swoop", "boss"]: total_foes += 1
	if title != "":
		var tl := PixLabel.new(title, 3, Color(1.0, 0.82, 0.35))
		tl.position = Vector2(240, 40); hud.add_child(tl)
		var tw := create_tween()
		tw.tween_interval(2.0); tw.tween_property(tl, "modulate:a", 0.0, 0.8); tw.tween_callback(tl.queue_free)
	_story_intro.call_deferred()
	Sfx.music_for(scene_file_path)
	Sfx.engine("bike_engine")


func _exit_tree() -> void:
	Sfx.engine_stop()

func _story_intro() -> void:
	await Story.play(self, scene_file_path.get_file().get_basename())

func _layer(tex: String, factor: float, z: int) -> void:
	var n := Node2D.new(); n.z_index = z; add_child(n)
	for i in 2:
		var s := Sprite2D.new(); s.texture = load("res://assets/%s.png" % tex); s.centered = false; s.position = Vector2(480 * i, 0); n.add_child(s)
	layers.append([n, factor])

func spawn(kind: String, lane: int) -> void:
	var f := BikeFoe.new()
	f.kind = kind; f.lane = lane; f.level = self
	add_child(f)

func burst(at: Vector2) -> void:
	var b := Burst.new(); b.position = at; b.z_index = 400; add_child(b)

func boss_dead_now() -> void:
	pass

func boss_down() -> void:
	boss_dead = true
	for n in get_tree().get_nodes_in_group("foes"):
		if n != null and n.kind != "boss": n.queue_free()
	clear_t = 0.0

func _process(d: float) -> void:
	if player.hp <= 0:
		if down_t < 0.0:
			down_t = 0.0; overlay.show_banner("DOWN"); Sfx.engine_stop()
		down_t += d
		if down_t > 1.6: get_tree().reload_current_scene()
		return
	t += d
	dist += SCROLL * d
	for l in layers: (l[0] as Node2D).position.x = -fmod(dist * l[1], 480.0)
	while ev_i < events.size() and t >= events[ev_i][0]:
		spawn(events[ev_i][1], events[ev_i][2]); ev_i += 1
	if clear_t >= 0.0:
		clear_t += d
		if clear_t > 1.6 and overlay.mode == "":
			overlay.open_clear(t, kills, total_foes, next_level != "")

class Burst extends Node2D:
	var life := 0.0
	func _process(d: float) -> void:
		life += d
		if life > 0.5: queue_free()
		queue_redraw()
	func _draw() -> void:
		var r := 8.0 + life * 60.0
		draw_circle(Vector2.ZERO, r, Color(1.0, 0.7, 0.3, 0.7 * (1.0 - life * 2.0)))
		draw_circle(Vector2.ZERO, r * 0.55, Color(1.0, 0.95, 0.7, 0.9 * (1.0 - life * 2.0)))
