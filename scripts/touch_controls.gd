extends CanvasLayer
## On-screen controls for phones and tablets (autoload "Touch").
## A d-pad on the left (also drives the menus), JUMP / FIRE / RUN on the right, pause top-right.
## It only feeds the same input actions the keyboard and gamepad use, so no game code needs to know about it.
## Shows itself when you touch the screen, hides when you use a gamepad or keyboard.
## Mode (Settings > TOUCH): AUTO, ON or OFF. F2 on a PC toggles it so you can try it with the mouse.
const PREF_SECTION := "touch"
const PREF_KEY := "mode"   # 0 auto, 1 on, 2 off
const DPAD_C := Vector2(62, 208)
const DPAD_R := 62.0
const DEAD := 11.0
# name, centre, radius, label, [actions]
const BUTTONS := [
	{"id": "jump",  "c": Vector2(440, 202), "r": 26.0, "round": true, "label": "JUMP",  "acts": ["jump"]},
	{"id": "shoot", "c": Vector2(376, 232), "r": 26.0, "round": true, "label": "FIRE",  "acts": ["shoot"]},
	{"id": "runtog", "c": Vector2(62, 138), "r": 16.0, "label": "RUN", "acts": []},   # tap to switch running on / off
	{"id": "pause", "c": Vector2(452, 24),  "r": 15.0, "label": "",      "acts": ["pause", "ui_cancel"]},
]
const DIRS := {"left": ["left", "ui_left"], "right": ["right", "ui_right"], "up": ["up", "ui_up"], "down": ["down", "ui_down"]}
var mode := 0
var active := false
var touches := {}      # finger index -> position
var down := {}         # action -> true while held by us
var held_dirs := {}    # "left"/"right"/"up"/"down" -> true
var held_btn := {}     # button id -> true
var run_on := false     # the RUN toggle
var pad: Control

func _ready() -> void:
	layer = 100
	process_mode = Node.PROCESS_MODE_ALWAYS
	Controls.setup()
	mode = int(Prefs.get_num(PREF_SECTION, PREF_KEY, 0.0))
	pad = Control.new()
	pad.set_anchors_preset(Control.PRESET_FULL_RECT)
	pad.mouse_filter = Control.MOUSE_FILTER_IGNORE
	pad.draw.connect(_draw_pad)
	add_child(pad)
	_refresh_visibility(true)

func set_mode(m: int) -> void:
	mode = clampi(m, 0, 2)
	Prefs.set_num(PREF_SECTION, PREF_KEY, float(mode))
	_refresh_visibility(true)

func mode_name() -> String:
	return ["AUTO", "ON", "OFF"][mode]

## True on the title screen or whenever the game is paused (pause menu, story cards, tips, level clear).
## The pad hides there and taps go straight to the menus / cards instead.
## The speeder-bike and space-ship levels only use move + fire, so they get a simpler pad (no JUMP, no RUN).
func is_flight() -> bool:
	var cs := get_tree().current_scene
	if cs == null or cs.get_script() == null: return false
	var path: String = cs.get_script().resource_path
	return path.ends_with("bike_level.gd") or path.ends_with("space_level.gd")

const SWAP_BTN := {"id": "swap", "c": Vector2(440, 150), "r": 16.0, "round": true, "label": "SWAP", "acts": ["swap"]}
const BLOCK_BTN := {"id": "block", "c": Vector2(382, 178), "r": 19.0, "round": true, "label": "BLK", "acts": ["block"]}
const FLIGHT_FIRE := {"id": "shoot", "c": Vector2(426, 214), "r": 34.0, "round": true, "label": "FIRE", "acts": ["shoot"]}
func _btns() -> Array:
	if not is_flight():
		var cs := get_tree().current_scene
		if cs != null and cs is Level and (cs as Level).crew_partner != "": return BUTTONS + [SWAP_BTN, BLOCK_BTN]
		return BUTTONS
	return [FLIGHT_FIRE, BUTTONS[BUTTONS.size() - 1]]   # FIRE + pause

func in_menu() -> bool:
	var t := get_tree()
	if t.paused: return true
	if not t.get_nodes_in_group("cutscene").is_empty(): return true   # cutscene: no pad, any tap skips
	var cs := t.current_scene
	if cs == null: return false
	if cs.scene_file_path == "res://scenes/title.tscn": return true
	return cs.get_script() != null and cs.get_script().resource_path.ends_with("ascent.gd")   # cutscene: no pad, any tap skips

var _was_flight := false
func _process(_d: float) -> void:
	var fl := is_flight()
	if fl != _was_flight:
		_was_flight = fl; _release_all(); pad.queue_redraw()
	var show := active and not in_menu()
	if show != pad.visible:
		if not show: _release_all()
		pad.visible = show
		if show: _update()
		pad.queue_redraw()

func _refresh_visibility(initial := false) -> void:
	match mode:
		1: active = true
		2: active = false
		_:
			if initial: active = DisplayServer.is_touchscreen_available() and Input.get_connected_joypads().is_empty()
	if not active: _release_all()
	pad.visible = active and not in_menu()
	pad.queue_redraw()

func _input(event: InputEvent) -> void:
	# a gamepad or keyboard in AUTO mode means the on-screen pad gets out of the way
	if mode == 0 and active and ((event is InputEventJoypadButton and event.pressed) or (event is InputEventJoypadMotion and absf(event.axis_value) > 0.6) or (event is InputEventKey and event.pressed and not event.echo)):
		active = false; _refresh_visibility()
		return
	if event is InputEventKey and event.pressed and not event.echo and event.keycode == KEY_F2 and not DisplayServer.is_touchscreen_available():
		set_mode(0 if mode == 1 else 1)   # PC testing
		return
	var idx := -99
	var pos := Vector2.ZERO
	var is_down := false
	if event is InputEventScreenTouch:
		idx = event.index; pos = event.position; is_down = event.pressed
	elif event is InputEventScreenDrag:
		idx = event.index; pos = event.position; is_down = true
	elif (event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and active and not DisplayServer.is_touchscreen_available()):
		idx = -1; pos = event.position; is_down = event.pressed   # desktop testing with the mouse
	elif event is InputEventMouseMotion and active and not DisplayServer.is_touchscreen_available() and (event.button_mask & MOUSE_BUTTON_MASK_LEFT) != 0:
		idx = -1; pos = event.position; is_down = true
	else:
		return
	if (event is InputEventScreenTouch or event is InputEventScreenDrag) and mode != 2 and not active:
		active = true; _refresh_visibility()
	if not active or in_menu(): return   # menus take the tap themselves
	if is_down: touches[idx] = pos
	else: touches.erase(idx)
	_update()
	get_viewport().set_input_as_handled()

func _update() -> void:
	var dirs := {}
	var btns := {}
	for p in touches.values():
		var off: Vector2 = p - DPAD_C
		var on_btn := false
		for b in _btns():
			if p.distance_to(b["c"]) <= b["r"] + 7.0: on_btn = true
		if not on_btn and off.length() <= DPAD_R:
			if off.x < -DEAD: dirs["left"] = true
			if off.x > DEAD: dirs["right"] = true
			if off.y < -DEAD: dirs["up"] = true
			if off.y > DEAD: dirs["down"] = true
		for b in _btns():
			if p.distance_to(b["c"]) <= b["r"] + 7.0: btns[b["id"]] = true
	if btns.has("runtog") and not held_btn.has("runtog"):
		run_on = not run_on
		Sfx.play("menu_move")
	held_dirs = dirs; held_btn = btns
	var want := {}
	for d in dirs: for a in DIRS[d]: want[a] = true
	if run_on and not is_flight(): want["run"] = true
	for b in _btns():
		if btns.has(b["id"]): for a in b["acts"]: want[a] = true
	for a in down.keys():
		if not want.has(a): _send(a, false)
	for a in want: if not down.has(a): _send(a, true)
	pad.queue_redraw()

func _send(a: String, pressed: bool) -> void:
	var e := InputEventAction.new()
	e.action = a; e.pressed = pressed; e.strength = 1.0 if pressed else 0.0
	Input.parse_input_event(e)
	if pressed: down[a] = true
	else: down.erase(a)

func _release_all() -> void:
	touches.clear()
	for a in down.keys(): _send(a, false)
	held_dirs = {}; held_btn = {}

func _notification(what: int) -> void:
	if what == NOTIFICATION_APPLICATION_FOCUS_OUT or what == NOTIFICATION_WM_WINDOW_FOCUS_OUT: _release_all()

# ---- drawing (chunky pixel-style, see-through so the game shows behind it) ----
func _box(r: Rect2, fill: Color, edge: Color) -> void:
	pad.draw_rect(r, fill)
	pad.draw_rect(Rect2(r.position, Vector2(r.size.x, 1)), edge); pad.draw_rect(Rect2(r.position + Vector2(0, r.size.y - 1), Vector2(r.size.x, 1)), edge)
	pad.draw_rect(Rect2(r.position, Vector2(1, r.size.y)), edge); pad.draw_rect(Rect2(r.position + Vector2(r.size.x - 1, 0), Vector2(1, r.size.y)), edge)

func _draw_pad() -> void:
	var idle := Color(0.08, 0.06, 0.13, 0.42)
	var lit := Color(1.0, 0.82, 0.35, 0.62)
	var edge := Color(1.0, 0.82, 0.35, 0.55)
	var ink := Color(0.96, 0.9, 0.7, 0.8)
	# d-pad: a plus of four arrow keys
	var cell := 28.0
	var arms := {"up": Vector2(0, -cell), "down": Vector2(0, cell), "left": Vector2(-cell, 0), "right": Vector2(cell, 0)}
	_box(Rect2(DPAD_C - Vector2(cell, cell) / 2.0, Vector2(cell, cell)), idle, edge)
	for d in arms:
		var c: Vector2 = DPAD_C + arms[d]
		_box(Rect2(c - Vector2(cell, cell) / 2.0, Vector2(cell, cell)), lit if held_dirs.has(d) else idle, edge)
		var v: Vector2 = arms[d].normalized()
		var n := Vector2(-v.y, v.x)
		var tip := c + v * 7.0
		pad.draw_colored_polygon(PackedVector2Array([tip, c - v * 5.0 + n * 7.0, c - v * 5.0 - n * 7.0]), ink)
	# buttons
	for b in _btns():
		var c: Vector2 = b["c"]; var r: float = b["r"]
		var on: bool = held_btn.has(b["id"]) or (b["id"] == "runtog" and run_on)
		if b.get("round", false):
			pad.draw_circle(c, r, lit if on else idle)
			pad.draw_arc(c, r - 0.5, 0.0, TAU, 48, edge, 1.0, false)
		else:
			_box(Rect2(c - Vector2(r, r), Vector2(r, r) * 2.0), lit if on else idle, edge)
		if b["id"] == "pause":
			pad.draw_rect(Rect2(c + Vector2(-5, -6), Vector2(3, 12)), ink); pad.draw_rect(Rect2(c + Vector2(2, -6), Vector2(3, 12)), ink)
		else:
			var w := PixFont.text_width(b["label"], 1)
			PixFont.draw(pad, b["label"], c - Vector2(w / 2.0, 3.5), 1, ink)
