class_name Cutscene
extends Node2D
## Base for short cutscenes. Subclasses fill in `captions` and `length`, build their picture in `_build()`, and animate in `_step(d)`.
## Two ways to run one:
##   - its own scene: set `next_level` and it changes scene when it ends (see Ascent).
##   - inside a level: add it as a child, `await cutscene.finished` (see PickupCutscene).
## Any key or tap skips it. The touch pad hides while one is running (group "cutscene").
signal finished
@export_file("*.tscn") var next_level := ""
static var return_to_title := false   # set by the title screen's CUTSCENES list: go back there when this ends
var captions: Array = []        # [start, end, text] -- edit these in the subclass
var length := 8.0
var fade_in := 0.5              # 0 = no fade (in-level cutscenes)
var fade_out := 0.5
var t := 0.0
var skipping := false
var leaving := false
var cap: PixLabel
var fade: ColorRect
var skip_l: PixLabel

func _ready() -> void:
	add_to_group("cutscene")
	physics_interpolation_mode = Node.PHYSICS_INTERPOLATION_MODE_OFF
	var hud := CanvasLayer.new(); hud.layer = 20; add_child(hud)
	cap = PixLabel.new("", 1, Color(0.95, 0.9, 0.8)); cap.position = Vector2(240, 236); cap.modulate.a = 0.0; hud.add_child(cap)
	fade = ColorRect.new(); fade.color = Color(0, 0, 0, 1.0 if fade_in > 0.0 else 0.0); fade.size = Vector2(480, 270)
	fade.mouse_filter = Control.MOUSE_FILTER_IGNORE; hud.add_child(fade)
	var st := "SKIP ALL" if Touch.active else ("X > SKIP ALL" if not Input.get_connected_joypads().is_empty() else "TAB > SKIP ALL")
	skip_l = PixLabel.new(st, 1, Color(0.7, 0.65, 0.8), false); skip_l.position = Vector2(470.0 - 6.0 * st.length(), 8); skip_l.modulate.a = 0.7; hud.add_child(skip_l)
	_build()
	if Story.skip_all: skipping = true; t = 1.0

func _build() -> void: pass
func _step(_d: float) -> void: pass
func _finish() -> void: pass          # cleanup just before it ends

func _skip_all() -> void:
	Story.skip_all = true; skipping = true

func _skip() -> void:
	if t > 0.6 and not skipping: skipping = true

func _input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		if get_viewport().get_mouse_position().x > 380.0 and get_viewport().get_mouse_position().y < 40.0: _skip_all()   # the SKIP ALL spot, top right
		else: _skip()
	elif event is InputEventScreenTouch and event.pressed: _skip()

func _process(d: float) -> void:
	t += d
	if Input.is_action_just_pressed("skip_story"): _skip_all()
	if Input.is_action_just_pressed("jump") or Input.is_action_just_pressed("shoot") or Input.is_action_just_pressed("pause") or Input.is_action_just_pressed("ui_accept"): _skip()
	_step(d)
	var ca := 0.0
	for c in captions:
		if t >= c[0] and t <= c[1]:
			cap.text = c[2]
			ca = minf(1.0, minf((t - c[0]) / 0.3, (c[1] - t) / 0.3))
	cap.modulate.a = ca
	var f := 1.0 - clampf(t / fade_in, 0.0, 1.0) if fade_in > 0.0 else 0.0
	if fade_out > 0.0:
		var out_t := length - fade_out
		if skipping and out_t > t: out_t = t
		if t > out_t: f = maxf(f, clampf((t - out_t) / fade_out, 0.0, 1.0))
	fade.color.a = f
	if not leaving and (t > length or (skipping and (f >= 1.0 or fade_out <= 0.0))):
		leaving = true
		_finish()
		if return_to_title:
			return_to_title = false
			get_tree().change_scene_to_file("res://scenes/title.tscn")
		elif next_level != "":
			get_tree().change_scene_to_file(next_level)
		else:
			finished.emit(); queue_free()

static func ease_(x: float) -> float:
	return x * x * (3.0 - 2.0 * x)
