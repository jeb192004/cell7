extends Node2D
## Start screen: drifting salt flats with Kesh running, title, menu, controls page.
const FIRST_LEVEL := "res://scenes/levels/level_01.tscn"
## Dev level select (only shown in debug builds / when run from the editor). Add new levels here.
const LEVELS := [
	["1-1 SALT FLATS", "res://scenes/levels/level_01.tscn"],
	["1-2 HIGHWAY RUN", "res://scenes/levels/level_02.tscn"],
	["1-3 TOWN ROOFTOPS", "res://scenes/levels/level_03.tscn"],
	["1-4 HIGHWAY ESCAPE", "res://scenes/levels/level_04.tscn"],
	["1-5 THE BELT", "res://scenes/levels/level_05.tscn"],
	["2-1 THE MERIDIAN", "res://scenes/levels/level_2_1.tscn"],
	["2-2 THE VENTS", "res://scenes/levels/level_2_2.tscn"],
	["2-3 THE CINDER MINES", "res://scenes/levels/level_2_3.tscn"],
	["2-4 THE CATWALK", "res://scenes/levels/level_2_4.tscn"],
]
var select_group: Node2D
var select_menu: PixMenu
var menu: PixMenu
var back_menu: PixMenu
var title_group: Node2D
var controls_group: Node2D
var settings_group: Node2D
var settings_menu: PixMenu
var crew_group: Node2D
var crew_back: PixMenu
var crew_card: Sprite2D
var crew_name: PixLabel
var crew_role: PixLabel
var crew_page := 0
const CREW := [
	["VAL", "CAPTAIN AND PILOT", "res://assets/crew_val.png"],
	["RENN FOX", "MENTOR AND MARKSMAN", "res://assets/crew_renn.png"],
	["MAREN FUSE HOLT", "DEMOLITIONS", "res://assets/crew_fuse.png"],
	["BRIX", "MUSCLE", "res://assets/crew_brix.png"],
]
var settings_note: PixLabel
var kesh: AnimatedSprite2D
var t := 0.0

func _ready() -> void:
	Controls.setup()
	get_tree().paused = false
	Story.reset()
	_backdrop()
	_kesh()
	var layer := CanvasLayer.new(); layer.layer = 5; add_child(layer)
	title_group = Node2D.new(); layer.add_child(title_group)
	controls_group = Node2D.new(); controls_group.visible = false; layer.add_child(controls_group)
	select_group = Node2D.new(); select_group.visible = false; layer.add_child(select_group)
	settings_group = Node2D.new(); settings_group.visible = false; layer.add_child(settings_group)
	_build_title()
	_build_controls()
	_build_select()
	_build_settings()
	_build_crew()
	Sfx.music("title")

func _backdrop() -> void:
	var sky := Sprite2D.new(); sky.texture = load("res://assets/bg_sky.png"); sky.centered = false; sky.z_index = -50
	add_child(sky)
	for spec in [["bg_far", -5.0, -30], ["bg_mid", -13.0, -20], ["bg_dunes", -26.0, -10], ["ground", -105.0, -5]]:
		var p := Parallax2D.new()
		p.repeat_size = Vector2(480, 0)
		p.repeat_times = 4
		p.autoscroll = Vector2(spec[1], 0)
		p.z_index = spec[2]
		var s := Sprite2D.new(); s.texture = load("res://assets/%s.png" % spec[0]); s.centered = false
		p.add_child(s)
		add_child(p)
	var shade := ColorRect.new()
	shade.color = Color(0.05, 0.03, 0.1, 0.35)
	shade.size = Vector2(480, 270); shade.z_index = -2
	add_child(shade)

func _kesh() -> void:
	kesh = AnimatedSprite2D.new()
	var sf := SpriteFrames.new()
	sf.remove_animation("default")
	sf.add_animation("run"); sf.set_animation_speed("run", 8.0); sf.set_animation_loop("run", true)
	for i in 14:
		sf.add_frame("run", load("res://assets/kesh_run_%d.png" % i))
	kesh.sprite_frames = sf
	kesh.position = Vector2(110 + 5, 222 - 23)
	kesh.play("run")
	add_child(kesh)

func _build_title() -> void:
	var cell := PixLabel.new("CELL 7", 7, Color(1.0, 0.82, 0.35))
	cell.position = Vector2(240, 30)
	title_group.add_child(cell)
	var rule := ColorRect.new(); rule.color = Color(0.8, 0.26, 0.2); rule.position = Vector2(150, 88); rule.size = Vector2(180, 2)
	title_group.add_child(rule)
	var up := PixLabel.new("UPRISING", 4, Color(0.96, 0.9, 0.75))
	up.position = Vector2(240, 98)
	title_group.add_child(up)
	var items := PackedStringArray(["START", "CONTROLS", "SETTINGS", "CREW"])
	if OS.is_debug_build():
		items.append("LEVEL SELECT")
	if not OS.has_feature("mobile"):
		items.append("QUIT")
	menu = PixMenu.new(items, 2)
	menu.max_rows = 5
	menu.size = Vector2(200, menu.row_h * mini(items.size(), 5))
	menu.place(300, 128)
	menu.chosen.connect(_on_menu)
	title_group.add_child(menu)
	var by := PixLabel.new("SERPENT SCRIPTS", 1, Color(0.75, 0.68, 0.6))
	by.position = Vector2(240, 264)
	title_group.add_child(by)

func _build_controls() -> void:
	var back := ColorRect.new(); back.color = Color(0.05, 0.03, 0.1, 0.78); back.size = Vector2(480, 270)
	controls_group.add_child(back)
	var h := PixLabel.new("CONTROLS", 3, Color(1.0, 0.82, 0.35)); h.position = Vector2(240, 18)
	controls_group.add_child(h)
	var dim := Color(0.62, 0.58, 0.52)
	var gold := Color(1.0, 0.82, 0.35)
	var ink := Color(0.93, 0.88, 0.76)
	var cols := [40.0, 170.0, 310.0]
	var head := ["", "RETROID", "KEYBOARD"]
	for i in 3:
		if head[i] != "":
			controls_group.add_child(_text(head[i], Vector2(cols[i], 58), gold))
	var rows := [
		["MOVE", "STICK OR D-PAD", "ARROWS OR WASD"],
		["JUMP", "B", "SPACE OR K"],
		["SHOOT", "Y OR R1", "J OR X"],
		["SLIDE", "A", "L OR C"],
		["SPRINT", "HOLD L1 OR L2", "HOLD SHIFT"],
		["CROUCH", "HOLD DOWN", "HOLD DOWN OR S"],
		["HIDE", "UP AT A CRATE", "UP OR W AT A CRATE"],
		["PAUSE", "START", "P OR ESC"],
	]
	for r in rows.size():
		var y := 78 + r * 15
		controls_group.add_child(_text(rows[r][0], Vector2(cols[0], y), dim))
		controls_group.add_child(_text(rows[r][1], Vector2(cols[1], y), ink))
		controls_group.add_child(_text(rows[r][2], Vector2(cols[2], y), ink))
	var tip := PixLabel.new("HOLD DOWN ON A CRATE TO DROP BEHIND IT", 1, dim); tip.position = Vector2(240, 204)
	controls_group.add_child(tip)
	back_menu = PixMenu.new(PackedStringArray(["BACK"]), 2)
	back_menu.size = Vector2(160, back_menu.row_h)
	back_menu.place(240, 224)
	back_menu.chosen.connect(func(_i): _show_controls(false))
	controls_group.add_child(back_menu)

func _build_select() -> void:
	var back := ColorRect.new(); back.color = Color(0.05, 0.03, 0.1, 0.82); back.size = Vector2(480, 270)
	select_group.add_child(back)
	var h := PixLabel.new("LEVEL SELECT", 3, Color(1.0, 0.82, 0.35)); h.position = Vector2(240, 20)
	select_group.add_child(h)
	var items := PackedStringArray()
	for l in LEVELS: items.append(l[0])
	items.append("BACK")
	select_menu = PixMenu.new(items, 2)
	select_menu.max_rows = 6
	select_menu.size = Vector2(300, select_menu.row_h * 6)
	select_menu.place(240, 74)
	select_menu.chosen.connect(_on_select)
	select_group.add_child(select_menu)

func _settings_items() -> PackedStringArray:
	return PackedStringArray(["MUSIC  < %d >" % Sfx.music_vol, "SOUND  < %d >" % Sfx.sfx_vol, "DEV: RESET TIPS", "DEV: DELETE ALL PREFS", "BACK"])

func _build_settings() -> void:
	Sfx._ensure()
	var back := ColorRect.new(); back.color = Color(0.05, 0.03, 0.1, 0.82); back.size = Vector2(480, 270)
	settings_group.add_child(back)
	var h := PixLabel.new("SETTINGS", 3, Color(1.0, 0.82, 0.35)); h.position = Vector2(240, 20)
	settings_group.add_child(h)
	settings_menu = PixMenu.new(_settings_items(), 2)
	settings_menu.size = Vector2(360, settings_menu.row_h * 5)
	settings_menu.place(240, 62)
	settings_menu.chosen.connect(_on_settings)
	settings_group.add_child(settings_menu)
	settings_note = PixLabel.new("LEFT / RIGHT CHANGES VOLUME", 1, Color(0.62, 0.58, 0.52)); settings_note.position = Vector2(240, 214)
	settings_group.add_child(settings_note)

func _on_settings(i: int) -> void:
	match i:
		2:
			Prefs.reset_tips(); settings_note.text = "TIPS RESET - THEY WILL SHOW AGAIN"
		3:
			Prefs.delete_all(); Sfx.music_vol = 7; Sfx.sfx_vol = 8; settings_menu.items = _settings_items()
			settings_note.text = "ALL PREFS DELETED"
		4: _show_settings(false)

func _show_settings(on: bool) -> void:
	settings_group.visible = on
	title_group.visible = not on
	if on:
		settings_menu.items = _settings_items(); settings_menu.index = 0; settings_menu.armed_t = 0.25
		settings_note.text = "LEFT / RIGHT CHANGES VOLUME"
	else:
		menu.armed_t = 0.25
	menu.process_mode = Node.PROCESS_MODE_DISABLED if on else Node.PROCESS_MODE_ALWAYS
	settings_menu.process_mode = Node.PROCESS_MODE_ALWAYS if on else Node.PROCESS_MODE_DISABLED

func _on_select(i: int) -> void:
	if i >= LEVELS.size():
		_show_select(false)
		return
	Level.checkpoint_x = -1.0
	get_tree().change_scene_to_file(LEVELS[i][1])

func _show_select(on: bool) -> void:
	select_group.visible = on
	title_group.visible = not on
	if on:
		select_menu.index = 0
		select_menu.armed_t = 0.25
	else:
		menu.armed_t = 0.25
	menu.process_mode = Node.PROCESS_MODE_DISABLED if on else Node.PROCESS_MODE_ALWAYS
	select_menu.process_mode = Node.PROCESS_MODE_ALWAYS if on else Node.PROCESS_MODE_DISABLED

func _build_crew() -> void:
	crew_group = Node2D.new(); crew_group.visible = false; add_child(crew_group)
	var back := ColorRect.new(); back.color = Color(0.05, 0.03, 0.1, 0.88); back.size = Vector2(480, 270)
	crew_group.add_child(back)
	var h := PixLabel.new("THE CREW", 2, Color(1.0, 0.82, 0.35)); h.position = Vector2(240, 8)
	crew_group.add_child(h)
	crew_card = Sprite2D.new(); crew_card.position = Vector2(240, 26 + 84); crew_group.add_child(crew_card)
	crew_name = PixLabel.new("", 3, Color(0.96, 0.9, 0.75)); crew_name.position = Vector2(240, 200); crew_group.add_child(crew_name)
	crew_role = PixLabel.new("", 1, Color(0.7, 0.66, 0.6)); crew_role.position = Vector2(240, 226); crew_group.add_child(crew_role)
	var la := PixLabel.new("<", 4, Color(1.0, 0.82, 0.35)); la.position = Vector2(22, 100); crew_group.add_child(la)
	var ra := PixLabel.new(">", 4, Color(1.0, 0.82, 0.35)); ra.position = Vector2(458, 100); crew_group.add_child(ra)
	crew_back = PixMenu.new(PackedStringArray(["BACK"]), 2)
	crew_back.size = Vector2(160, crew_back.row_h)
	crew_back.place(240, 238)
	crew_back.chosen.connect(func(_i): _show_crew(false))
	crew_group.add_child(crew_back)
	crew_back.process_mode = Node.PROCESS_MODE_DISABLED
	_crew_show(0)

func _crew_show(i: int) -> void:
	crew_page = (i + CREW.size()) % CREW.size()
	crew_card.texture = load(CREW[crew_page][2])
	crew_name.text = CREW[crew_page][0]
	crew_name.px = 3 if crew_name.text.length() < 11 else 2
	crew_role.text = CREW[crew_page][1]

func _show_crew(on: bool) -> void:
	crew_group.visible = on
	title_group.visible = not on
	if on:
		crew_back.armed_t = 0.25; _crew_show(0)
	else:
		menu.armed_t = 0.25
	menu.process_mode = Node.PROCESS_MODE_DISABLED if on else Node.PROCESS_MODE_ALWAYS
	crew_back.process_mode = Node.PROCESS_MODE_ALWAYS if on else Node.PROCESS_MODE_DISABLED

func _text(s: String, pos: Vector2, col: Color) -> PixLabel:
	var l := PixLabel.new(s, 1, col, false)
	l.position = pos
	return l

func _show_controls(on: bool) -> void:
	controls_group.visible = on
	title_group.visible = not on
	if on:
		back_menu.armed_t = 0.25
	else:
		menu.armed_t = 0.25
	menu.process_mode = Node.PROCESS_MODE_DISABLED if on else Node.PROCESS_MODE_ALWAYS

func _on_menu(i: int) -> void:
	match menu.items[i]:
		"START":
			Level.checkpoint_x = -1.0
			get_tree().change_scene_to_file(FIRST_LEVEL)
		"CONTROLS":
			_show_controls(true)
		"SETTINGS":
			_show_settings(true)
		"CREW":
			_show_crew(true)
		"LEVEL SELECT":
			_show_select(true)
		"QUIT":
			get_tree().quit()

func _process(d: float) -> void:
	t += d
	kesh.position.y = 222 - 23 + (1 if int(t * 22.0) % 2 == 0 else 0) * 0.0
	if settings_group.visible:
		var dv := int(Input.is_action_just_pressed("ui_right")) - int(Input.is_action_just_pressed("ui_left"))
		if dv != 0 and settings_menu.index < 2:
			if settings_menu.index == 0: Sfx.set_volumes(Sfx.music_vol + dv, Sfx.sfx_vol)
			else: Sfx.set_volumes(Sfx.music_vol, Sfx.sfx_vol + dv); Sfx.play("shoot")
			settings_menu.items = _settings_items()
		if Input.is_action_just_pressed("ui_cancel"): _show_settings(false)
	if crew_group.visible:
		var cd := int(Input.is_action_just_pressed("ui_right")) - int(Input.is_action_just_pressed("ui_left"))
		if cd != 0: _crew_show(crew_page + cd); Sfx.play("menu_move")
		if Input.is_action_just_pressed("ui_cancel"): _show_crew(false)
	if select_group.visible and Input.is_action_just_pressed("ui_cancel"):
		_show_select(false)
	if controls_group.visible and Input.is_action_just_pressed("ui_cancel"):
		_show_controls(false)
