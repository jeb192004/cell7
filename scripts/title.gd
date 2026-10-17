extends Node2D
## Start screen: drifting salt flats with Kesh running, title, menu, controls page.
const FIRST_LEVEL := "res://scenes/levels/level_01.tscn"
## Every screen is a node in scenes/title.tscn (edit it in the 2D editor). These are found by unique name (%Name).
@onready var select_group: Node2D = %SelectGroup
@onready var level_rows: Control = %Rows
@onready var level_list: ScrollContainer = %List
@onready var select_back: LevelRow = %SelectBack
@onready var cutscene_group: Node2D = %CutsceneGroup
@onready var cutscene_rows: Control = %CutsceneRows   # LevelRows: Action says which cutscene, Scene is the level / scene it plays in
@onready var cutscene_back: LevelRow = %CutsceneBack
@onready var menu: Control = %Menu     # a column of LevelRow buttons (UI > TitleGroup > Menu)
var menu_last: LevelRow
@onready var back_menu: PixMenu = %ControlsBack
@onready var title_group: Node2D = %TitleGroup
@onready var controls_group: Node2D = %ControlsGroup
@onready var settings_group: Node2D = %SettingsGroup
@onready var settings_rows: Control = %SettingsRows   # LevelRow buttons: MUSIC, SOUND, TOUCH, RESET_TIPS, DELETE_PREFS, BACK
@onready var settings_note: PixLabel = %SettingsNote
@onready var crew_group: Node2D = %CrewGroup
@onready var crew_back: PixMenu = %CrewBack
@onready var crew_card: Sprite2D = %CrewCard
@onready var crew_name: PixLabel = %CrewName
@onready var crew_role: PixLabel = %CrewRole
@onready var kesh: AnimatedSprite2D = %Kesh
var crew_page := 0
## [name, role, card art, optional idle frames prefix]. The idle animation is used when it exists, else the card.
const CREW := [
	["KESH", "SCAVENGER", "", "res://assets/idle_kesh_"],
	["VAL", "CAPTAIN AND PILOT", "res://assets/crew_val.png"],
	["RENN FOX", "MENTOR AND MARKSMAN", "res://assets/crew_renn.png"],
	["MAREN FUSE HOLT", "DEMOLITIONS", "res://assets/crew_fuse.png"],
	["BRIX", "MUSCLE", "res://assets/crew_brix.png"],
]
## On-screen height (px) of each idle animation on the Crew screen, so the big guy looks big. Missing = fit to 160.
const CREW_H := {"KESH": 115, "MAREN FUSE HOLT": 135, "BRIX": 150, "RENN FOX": 145, "VAL": 140}
var t := 0.0

func _ready() -> void:
	Controls.setup()
	get_tree().paused = false
	Story.reset()
	Story.skip_all = false
	kesh.play("run")
	_setup_title_menu()
	_setup_level_list()
	_setup_cutscenes()
	back_menu.chosen.connect(func(_i): _show_controls(false))
	Sfx._ensure()
	_setup_settings()
	crew_back.chosen.connect(func(_i): _show_crew(false))
	crew_back.process_mode = Node.PROCESS_MODE_DISABLED
	for g in [select_group, settings_group, controls_group, crew_group, cutscene_group]: g.visible = false
	_crew_show(0)
	Sfx.music("title")

## The scene lists every title entry; hide the ones this build doesn't use, then wire up the rest.
func _setup_title_menu() -> void:
	var rows: Array = []
	for n in menu.get_children():
		var r := n as LevelRow
		if r == null: continue
		if ((r.action == "LEVEL SELECT" or r.action == "CUTSCENES") and not OS.is_debug_build()) or (r.action == "QUIT" and OS.has_feature("mobile")):
			r.visible = false; r.focus_mode = Control.FOCUS_NONE
			continue
		rows.append(r)
		r.pressed.connect(_on_menu.bind(r))
		r.focus_entered.connect(func(): menu_last = r)   # remember the cursor for when a sub screen closes
	if rows.is_empty(): return
	for i in rows.size():
		var r: LevelRow = rows[i]
		r.focus_neighbor_top = r.get_path_to(rows[(i - 1 + rows.size()) % rows.size()])
		r.focus_neighbor_bottom = r.get_path_to(rows[(i + 1) % rows.size()])
	menu_last = rows[0]
	menu_last.grab_focus()

## Turn the title menu on or off while a sub screen is open; coming back puts the cursor on the entry you left from.
var menu_armed := 0.0
func _menu_enable(on: bool) -> void:
	for n in menu.get_children():
		var r := n as LevelRow
		if r == null or not r.visible: continue
		r.focus_mode = Control.FOCUS_ALL if on else Control.FOCUS_NONE
		r.mouse_filter = Control.MOUSE_FILTER_PASS if on else Control.MOUSE_FILTER_IGNORE
	if on:
		menu_armed = 0.25
		if menu_last: menu_last.grab_focus()
	else:
		get_viewport().gui_release_focus()

func _setting_rows() -> Array:
	return settings_rows.get_children().filter(func(n): return n is LevelRow)

func _setup_settings() -> void:
	var rows := _setting_rows()
	for i in rows.size():
		var r: LevelRow = rows[i]
		r.pressed.connect(_on_setting.bind(r))
		r.focus_neighbor_top = r.get_path_to(rows[(i - 1 + rows.size()) % rows.size()])
		r.focus_neighbor_bottom = r.get_path_to(rows[(i + 1) % rows.size()])
	_refresh_settings()

## The rows show live values, so their text is set here (the rest of each row is editable in the scene).
func _refresh_settings() -> void:
	for r: LevelRow in _setting_rows():
		match r.action:
			"MUSIC": r.title = "MUSIC  < %d >" % Sfx.music_vol
			"SOUND": r.title = "SOUND  < %d >" % Sfx.sfx_vol
			"TOUCH": r.title = "TOUCH PAD  < %s >" % Touch.mode_name()

## step: +1 for a tap / accept, -1 / +1 for left / right
func _change_setting(act: String, step: int, wrap: bool) -> void:
	match act:
		"MUSIC":
			var v := Sfx.music_vol + step
			Sfx.set_volumes(0 if (wrap and v > 10) else v, Sfx.sfx_vol); Sfx.play("menu_move")
		"SOUND":
			var v := Sfx.sfx_vol + step
			Sfx.set_volumes(Sfx.music_vol, 0 if (wrap and v > 10) else v); Sfx.play("shoot")
		"TOUCH":
			Touch.set_mode((Touch.mode + step + 3) % 3); Sfx.play("menu_move")
	_refresh_settings()

var settings_armed := 0.0
func _on_setting(row: LevelRow) -> void:
	if settings_armed > 0.0 or row.dragged: return
	match row.action:
		"MUSIC", "SOUND", "TOUCH": _change_setting(row.action, 1, true)
		"RESET_TIPS":
			Sfx.play("menu_select"); Prefs.reset_tips(); settings_note.text = "TIPS RESET - THEY WILL SHOW AGAIN"
		"DELETE_PREFS":
			Sfx.play("menu_select")
			Prefs.delete_all(); Sfx.music_vol = 7; Sfx.sfx_vol = 8; Touch.set_mode(0); _refresh_settings()
			settings_note.text = "ALL PREFS DELETED"
		"BACK":
			Sfx.play("menu_select"); _show_settings(false)

func _show_settings(on: bool) -> void:
	settings_group.visible = on
	title_group.visible = not on
	_menu_enable(not on)
	if on:
		settings_armed = 0.3
		_refresh_settings()
		settings_note.text = "LEFT / RIGHT CHANGES VOLUME AND TOUCH PAD"
		var rows := _setting_rows()
		if not rows.is_empty(): (rows[0] as Control).grab_focus()

## The level list is real nodes (UI > SelectGroup > List > Rows). Each LevelRow has a Title and a Scene.
func _setup_level_list() -> void:
	var rows: Array = level_rows.get_children().filter(func(n): return n is LevelRow)
	for r in rows: r.pressed.connect(_on_level_row.bind(r))
	select_back.pressed.connect(_on_level_row.bind(select_back))
	if rows.is_empty(): return
	var first: LevelRow = rows[0]; var last: LevelRow = rows[rows.size() - 1]
	first.focus_neighbor_top = first.get_path_to(select_back)
	last.focus_neighbor_bottom = last.get_path_to(select_back)
	select_back.focus_neighbor_top = select_back.get_path_to(last)
	select_back.focus_neighbor_bottom = select_back.get_path_to(first)
	# a thin gold scroll bar instead of arrows
	var bar := level_list.get_v_scroll_bar()
	bar.custom_minimum_size.x = 4
	var track := StyleBoxFlat.new(); track.bg_color = Color(1, 1, 1, 0.08)
	var grab := StyleBoxFlat.new(); grab.bg_color = Color(1.0, 0.82, 0.35, 0.85)
	bar.add_theme_stylebox_override("scroll", track)
	for g in ["grabber", "grabber_highlight", "grabber_pressed"]: bar.add_theme_stylebox_override(g, grab)

var select_armed := 0.0
func _on_level_row(row: LevelRow) -> void:
	if select_armed > 0.0 or row.dragged: return
	Sfx.play("menu_select")
	if row.scene == "":
		_show_select(false)
		return
	Level.checkpoint_x = -1.0
	get_tree().change_scene_to_file(row.scene)

## Title > CUTSCENES: watch a cutscene without replaying its level. Rows live in the scene (UI > CutsceneGroup > CutsceneRows).
func _setup_cutscenes() -> void:
	var rows: Array = cutscene_rows.get_children().filter(func(n): return n is LevelRow)
	for r in rows: r.pressed.connect(_on_cutscene_row.bind(r))
	cutscene_back.pressed.connect(_on_cutscene_row.bind(cutscene_back))
	if rows.is_empty(): return
	var first: LevelRow = rows[0]; var last: LevelRow = rows[rows.size() - 1]
	first.focus_neighbor_top = first.get_path_to(cutscene_back)
	last.focus_neighbor_bottom = last.get_path_to(cutscene_back)
	cutscene_back.focus_neighbor_top = cutscene_back.get_path_to(last)
	cutscene_back.focus_neighbor_bottom = cutscene_back.get_path_to(first)

var cutscene_armed := 0.0
func _on_cutscene_row(row: LevelRow) -> void:
	if cutscene_armed > 0.0 or row.dragged: return
	Sfx.play("menu_select")
	if row.scene == "":
		_show_cutscenes(false)
		return
	if row.action == "ascent":
		Cutscene.return_to_title = true
	else:
		Level.preview_cutscene = row.action
	get_tree().change_scene_to_file(row.scene)

func _show_cutscenes(on: bool) -> void:
	cutscene_group.visible = on
	title_group.visible = not on
	_menu_enable(not on)
	if on:
		cutscene_armed = 0.3
		var first := cutscene_rows.get_child(0) as Control
		if first: first.grab_focus()

func _show_select(on: bool) -> void:
	select_group.visible = on
	title_group.visible = not on
	_menu_enable(not on)
	if on:
		select_armed = 0.3
		level_list.scroll_vertical = 0
		var first := level_rows.get_child(0) as Control
		if first: first.grab_focus()

var crew_idle: Array = []
func _crew_show(i: int) -> void:
	crew_page = (i + CREW.size()) % CREW.size()
	var key: String = (CREW[crew_page][2] as String).get_file().get_basename().trim_prefix("crew_")
	var prefix: String = CREW[crew_page][3] if (CREW[crew_page] as Array).size() > 3 else "res://assets/idle_%s_" % key
	crew_idle = []
	while ResourceLoader.exists("%s%d.png" % [prefix, crew_idle.size()]):
		crew_idle.append(load("%s%d.png" % [prefix, crew_idle.size()]))
	if crew_idle.is_empty():
		crew_card.texture = load(CREW[crew_page][2]); crew_card.scale = Vector2.ONE
	else:
		_crew_idle_frame()
	crew_name.text = CREW[crew_page][0]
	crew_name.px = 3 if crew_name.text.length() < 11 else 2
	crew_role.text = CREW[crew_page][1]

func _crew_idle_frame() -> void:
	var tex: Texture2D = crew_idle[int(t * maxf(crew_idle.size() / 2.0, 4.0)) % crew_idle.size()]   # about a 2 second loop
	crew_card.texture = tex
	var want: float = CREW_H.get(CREW[crew_page][0], 0.0)
	if want > 0.0:
		var f := want / tex.get_height()
		crew_card.scale = Vector2(f, f); crew_card.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
	else:
		var sc := maxi(1, int(160.0 / tex.get_height()))   # whole-number scale keeps the pixels crisp
		crew_card.scale = Vector2(sc, sc); crew_card.texture_filter = CanvasItem.TEXTURE_FILTER_PARENT_NODE

func _show_crew(on: bool) -> void:
	crew_group.visible = on
	title_group.visible = not on
	if on:
		crew_back.armed_t = 0.25; _crew_show(0)
	_menu_enable(not on)
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
	_menu_enable(not on)

func _on_menu(row: LevelRow) -> void:
	if menu_armed > 0.0 or row.dragged: return
	Sfx.play("menu_select")
	match row.action:
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
		"CUTSCENES":
			_show_cutscenes(true)
		"QUIT":
			get_tree().quit()

var crew_press := Vector2(-1, -1)
## Touch / mouse on the Crew screen: tap the left or right side (or swipe) to flip pages. The BACK button area is left alone.
func _input(event: InputEvent) -> void:
	if crew_group == null or not crew_group.visible: return
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		if event.pressed:
			crew_press = event.position
		elif crew_press.x >= 0.0:
			var dx: float = event.position.x - crew_press.x
			var dir := 0
			if absf(dx) > 40.0 and crew_press.y < 215.0: dir = -1 if dx > 0.0 else 1
			elif crew_press.y < 215.0 and absf(dx) < 12.0:
				if crew_press.x < 190.0: dir = -1
				elif crew_press.x > 290.0: dir = 1
			crew_press = Vector2(-1, -1)
			if dir != 0:
				_crew_show(crew_page + dir); Sfx.play("menu_move")

func _process(d: float) -> void:
	t += d
	menu_armed = maxf(menu_armed - d, 0.0)
	if title_group.visible and Input.is_action_just_pressed("jump") and not Input.is_action_just_pressed("ui_accept"):   # Retroid B
		var f := get_viewport().gui_get_focus_owner()
		if f is LevelRow and f.get_parent() == menu: (f as LevelRow).pressed.emit()
	if crew_group.visible and not crew_idle.is_empty(): _crew_idle_frame()
	if settings_group.visible:
		settings_armed = maxf(settings_armed - d, 0.0)
		var dv := int(Input.is_action_just_pressed("ui_right")) - int(Input.is_action_just_pressed("ui_left"))
		var f := get_viewport().gui_get_focus_owner()
		if f is LevelRow and f.get_parent() == settings_rows:
			if dv != 0: _change_setting((f as LevelRow).action, dv, false)
			elif Input.is_action_just_pressed("jump") and not Input.is_action_just_pressed("ui_accept"): (f as LevelRow).pressed.emit()   # Retroid B
		if Input.is_action_just_pressed("ui_cancel"): _show_settings(false)
	if crew_group.visible:
		var cd := int(Input.is_action_just_pressed("ui_right")) - int(Input.is_action_just_pressed("ui_left"))
		if cd != 0: _crew_show(crew_page + cd); Sfx.play("menu_move")
		if Input.is_action_just_pressed("ui_cancel"): _show_crew(false)
	if cutscene_group.visible:
		cutscene_armed = maxf(cutscene_armed - d, 0.0)
		if Input.is_action_just_pressed("ui_cancel"): _show_cutscenes(false)
		elif Input.is_action_just_pressed("jump") and not Input.is_action_just_pressed("ui_accept"):   # Retroid B
			var cf := get_viewport().gui_get_focus_owner()
			if cf is LevelRow: (cf as LevelRow).pressed.emit()
	if select_group.visible:
		select_armed = maxf(select_armed - d, 0.0)
		if Input.is_action_just_pressed("ui_cancel"): _show_select(false)
		elif Input.is_action_just_pressed("jump") and not Input.is_action_just_pressed("ui_accept"):   # Retroid B
			var f := get_viewport().gui_get_focus_owner()
			if f is LevelRow: (f as LevelRow).pressed.emit()
	if controls_group.visible and Input.is_action_just_pressed("ui_cancel"):
		_show_controls(false)
