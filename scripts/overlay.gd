class_name Overlay
extends CanvasLayer
## Pause menu and level-clear card. Lives above the level, keeps running while the game is paused.
signal resume
signal restart
signal to_title
signal next
const TITLE_SCENE := "res://scenes/title.tscn"
var panel: Control
var menu: PixMenu
var heading: PixLabel
var sub: PixLabel
var ids: Array = []
var mode := ""          # "", "pause", "clear"
var banner: PixLabel

func _ready() -> void:
	layer = 20
	process_mode = Node.PROCESS_MODE_ALWAYS
	panel = Control.new()
	panel.visible = false
	panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(panel)
	var back := ColorRect.new()
	back.color = Color(0.04, 0.02, 0.08, 0.62)
	back.size = Vector2(480, 270)
	back.mouse_filter = Control.MOUSE_FILTER_IGNORE
	panel.add_child(back)
	var card := PanelDraw.new()
	card.position = Vector2(110, 52); card.size = Vector2(260, 168)
	panel.add_child(card)
	heading = PixLabel.new("", 3, Color(1.0, 0.82, 0.35))
	heading.position = Vector2(240, 66)
	panel.add_child(heading)
	sub = PixLabel.new("", 1, Color(0.85, 0.8, 0.7))
	sub.position = Vector2(240, 100)
	panel.add_child(sub)
	menu = PixMenu.new(PackedStringArray(), 2)
	menu.chosen.connect(_on_chosen)
	panel.add_child(menu)
	banner = PixLabel.new("", 4, Color(1.0, 0.5, 0.35))
	banner.position = Vector2(240, 105)
	banner.visible = false
	add_child(banner)

func show_banner(text: String) -> void:
	banner.text = text
	Sfx.play("down")
	banner.visible = true

func _open(title: String, line: String, entries: Array) -> void:
	heading.text = title
	sub.text = line
	var labels := PackedStringArray()
	ids = []
	for e in entries:
		labels.append(e[0]); ids.append(e[1])
	menu.items = labels
	menu.index = 0
	menu.armed_t = 0.25
	menu.size = Vector2(200, menu.row_h * labels.size())
	menu.place(240, 120 if line != "" else 110)
	panel.visible = true
	get_tree().paused = true

func open_pause() -> void:
	mode = "pause"
	_open("PAUSED", "", [["RESUME", "resume"], ["RESTART LEVEL", "restart"], ["TITLE SCREEN", "title"]])

func open_clear(time_s: float, kills: int, total: int, has_next: bool) -> void:
	mode = "clear"
	Sfx.play("clear")
	var m := int(time_s) / 60
	var s := int(time_s) % 60
	var line := "TIME %d:%02d     FOES %d/%d" % [m, s, kills, total]
	var entries: Array = []
	if has_next:
		entries.append(["NEXT LEVEL", "next"])
	entries.append(["PLAY AGAIN", "restart"])
	entries.append(["TITLE SCREEN", "title"])
	_open("LEVEL CLEAR", line, entries)

func close() -> void:
	panel.visible = false
	mode = ""
	get_tree().paused = false

func _on_chosen(i: int) -> void:
	var id: String = ids[i]
	close()
	match id:
		"resume": resume.emit()
		"restart": restart.emit()
		"title": to_title.emit()
		"next": next.emit()

func _process(_d: float) -> void:
	if banner.visible or StoryCard.active: return
	if Input.is_action_just_pressed("pause"):
		if mode == "pause":
			close(); resume.emit()
		elif mode == "":
			open_pause()

class PanelDraw extends Control:
	func _init() -> void:
		mouse_filter = Control.MOUSE_FILTER_IGNORE
	func _draw() -> void:
		var r := Rect2(Vector2.ZERO, size)
		draw_rect(r.grow(2), Color(0.07, 0.04, 0.1))
		draw_rect(r, Color(0.78, 0.6, 0.25))
		draw_rect(r.grow(-2), Color(0.1, 0.07, 0.14))
		draw_rect(r.grow(-4), Color(0.16, 0.11, 0.2))
		draw_rect(Rect2(6, 6, size.x - 12, 2), Color(0.25, 0.18, 0.3))
