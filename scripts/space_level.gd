class_name SpaceLevel
extends Node2D
## 1-5: the Kestrel in the asteroid belt. Fixed screen, everything drifts right to left.
## Move in all four directions, shoot fires ahead. Shoot the Shrikes, shoot or dodge the rocks.
@export var title := ""
@export_file("*.tscn") var next_level := ""
var player: SpacePlayer
var overlay: Overlay
var hud: CanvasLayer
var t := 0.0
var kills := 0
var total_foes := 0
var ev_i := 0
var down_t := -1.0
var clear_t := -1.0
var story_busy := false
var boss_dead := false
var toast_label: PixLabel
var stars: StarField
## [time, kind, y, pattern]
var events: Array = []

func _ready() -> void:
	Controls.setup()
	get_tree().paused = false
	var bg := CanvasLayer.new(); bg.layer = -10; add_child(bg)
	stars = StarField.new(); bg.add_child(stars)
	player = SpacePlayer.new(); add_child(player)
	hud = CanvasLayer.new(); hud.layer = 10; add_child(hud)
	var hearts := Hearts.new(); hearts.player = player; hud.add_child(hearts)
	overlay = Overlay.new(); add_child(overlay)
	overlay.restart.connect(func(): get_tree().reload_current_scene())
	overlay.to_title.connect(func(): get_tree().change_scene_to_file(Overlay.TITLE_SCENE))
	overlay.next.connect(func(): get_tree().change_scene_to_file(next_level))
	if ResourceLoader.exists("res://data/level_05_events.gd"):
		events = (load("res://data/level_05_events.gd") as GDScript).new().EVENTS.duplicate()
		events.sort_custom(func(a, b): return a[0] < b[0])
	else:
		_build_events()
	for e in events:
		if e[1] in ["shrike", "ace"]: total_foes += 1
	if title != "":
		var tl := PixLabel.new(title, 3, Color(1.0, 0.82, 0.35))
		tl.position = Vector2(240, 40); hud.add_child(tl)
		var tw := create_tween()
		tw.tween_interval(2.0); tw.tween_property(tl, "modulate:a", 0.0, 0.8); tw.tween_callback(tl.queue_free)
	_story_intro.call_deferred()
	Sfx.music_for(scene_file_path)
	Sfx.engine("ship_engine")


func _exit_tree() -> void:
	Sfx.engine_stop()

func _story_intro() -> void:
	await Story.play(self, scene_file_path.get_file().get_basename())

func _build_events() -> void:
	var rng := RandomNumberGenerator.new(); rng.seed = 7
	# asteroid belt: density rises through the level
	var tt := 1.0
	while tt < 66.0:
		var k := "rock_m"
		var roll := rng.randf()
		if tt > 20.0 and roll > 0.8: k = "rock_l"
		elif roll < 0.4: k = "rock_s"
		events.append([tt, k, rng.randf_range(30.0, 240.0), ""])
		tt += rng.randf_range(0.5, 1.1) if tt < 30.0 else rng.randf_range(0.4, 0.8)
	# Shrikes
	for e in [[14.0, 80.0, "line"], [14.8, 190.0, "line"],
		[22.0, 135.0, "weave"], [27.0, 70.0, "weave"], [27.0, 200.0, "weave"],
		[33.0, 100.0, "line"], [34.0, 170.0, "line"], [35.0, 135.0, "line"],
		[41.0, 90.0, "strafe"], [41.5, 190.0, "strafe"],
		[50.0, 70.0, "weave"], [50.5, 135.0, "weave"], [51.0, 200.0, "weave"],
		[58.0, 100.0, "strafe"], [58.0, 175.0, "strafe"]]:
		events.append([e[0], "shrike", e[1], e[2]])
	for e in [[19.0, 135.0], [38.0, 60.0], [47.0, 210.0], [62.0, 135.0]]:
		events.append([e[0], "pip", e[1], ""])
	events.append([68.0, "ace", 135.0, ""])
	events.sort_custom(func(a, b): return a[0] < b[0])

func spawn(kind: String, y: float, pat: String) -> void:
	var f := SpaceFoe.new()
	f.kind = kind; f.pat = pat; f.level = self
	f.position = Vector2(520.0 if kind != "ace" else 540.0, y)
	add_child(f)

func burst(at: Vector2, r: float) -> void:
	var b := Burst.new(); b.position = at; b.size = r; b.z_index = 400; add_child(b)

func toast(s: String) -> void:
	var l := PixLabel.new(s, 2, Color(1.0, 0.85, 0.4))
	l.position = Vector2(player.position.x, player.position.y - 26.0); add_child(l); l.z_index = 500
	var tw := create_tween(); tw.tween_property(l, "position:y", l.position.y - 14.0, 0.7); tw.parallel().tween_property(l, "modulate:a", 0.0, 0.7); tw.tween_callback(l.queue_free)

func boss_down() -> void:
	boss_dead = true
	for n in get_tree().get_nodes_in_group("sfoes"):
		if n != null and not n.is_queued_for_deletion() and n.kind != "ace": n.queue_free()
	clear_t = 0.0

func _process(d: float) -> void:
	if player.hp <= 0:
		if down_t < 0.0:
			down_t = 0.0; overlay.show_banner("DOWN"); Sfx.engine_stop(); burst(player.position, 20.0)
		down_t += d
		stars.scroll += 30.0 * d
		if down_t > 1.6: get_tree().reload_current_scene()
		return
	t += d
	stars.scroll += d * 1.0 * (1.0 if not boss_dead else 0.5)
	while ev_i < events.size() and t >= events[ev_i][0]:
		spawn(events[ev_i][1], events[ev_i][2], events[ev_i][3]); ev_i += 1
	if clear_t >= 0.0:
		clear_t += d
		if clear_t > 1.6 and overlay.mode == "" and not story_busy:
			story_busy = true
			await Story.play(self, "outro_" + scene_file_path.get_file().get_basename())
			overlay.open_clear(t, kills, total_foes, next_level != "")

class StarField extends Node2D:
	var scroll := 0.0
	var layers: Array = []
	func _ready() -> void:
		var rng := RandomNumberGenerator.new(); rng.seed = 3
		for li in 3:
			var arr: Array = []
			for i in [60, 40, 24][li]:
				arr.append(Vector2(rng.randf() * 480.0, rng.randf() * 270.0))
			layers.append(arr)
	func _process(_d: float) -> void:
		queue_redraw()
	func _draw() -> void:
		draw_rect(Rect2(0, 0, 480, 270), Color(0.03, 0.03, 0.09))
		draw_circle(Vector2(330, 80), 90.0, Color(0.10, 0.06, 0.20, 0.5))   # nebula
		draw_circle(Vector2(300, 100), 60.0, Color(0.16, 0.08, 0.26, 0.4))
		draw_circle(Vector2(90, 220), 70.0, Color(0.05, 0.12, 0.2, 0.5))
		var speeds := [20.0, 45.0, 90.0]
		var sizes := [1.0, 1.0, 2.0]
		var cols := [Color(0.5, 0.5, 0.7), Color(0.75, 0.75, 0.9), Color(1, 1, 1)]
		for li in 3:
			for s in layers[li]:
				var x: float = fposmod(s.x - scroll * speeds[li], 480.0)
				draw_rect(Rect2(x, s.y, sizes[li], sizes[li]), cols[li])

class Burst extends Node2D:
	var life := 0.0
	var size := 12.0
	func _process(d: float) -> void:
		life += d
		if life > 0.55: queue_free()
		queue_redraw()
	func _draw() -> void:
		var r := size * 0.6 + life * 70.0
		draw_circle(Vector2.ZERO, r, Color(1.0, 0.7, 0.3, 0.7 * (1.0 - life * 1.8)))
		draw_circle(Vector2.ZERO, r * 0.55, Color(1.0, 0.95, 0.7, 0.9 * (1.0 - life * 1.8)))
