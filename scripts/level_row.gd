@tool
class_name LevelRow
extends Button
## One row of the level-select list (scenes/title.tscn > UI > SelectGroup > List > Rows). Duplicate a row in the editor to add a level:
## set Title (what the list shows) and Scene (the level to load). Leave Scene empty for a row that just closes the list (BACK).
@export var title := "1-1 LEVEL":
	set(v):
		title = v
		queue_redraw()
@export_file("*.tscn") var scene := ""
## Title-menu rows use this instead of Scene: START, CONTROLS, SETTINGS, CREW, LEVEL SELECT, QUIT (title.gd decides what each does).
@export var action := ""
@export var centered := false:
	set(v):
		centered = v
		queue_redraw()
@export_range(1, 4) var px := 2:
	set(v):
		px = v
		queue_redraw()
var dragged := false      # the finger moved a lot between press and release: it was a scroll, not a tap
var _press := Vector2.ZERO

func _init() -> void:
	focus_mode = Control.FOCUS_ALL
	mouse_filter = Control.MOUSE_FILTER_PASS    # let the list see drags, so swiping scrolls it
	for st in ["normal", "hover", "pressed", "hover_pressed", "disabled", "focus"]:
		add_theme_stylebox_override(st, StyleBoxEmpty.new())

func _gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
		_press = event.position; dragged = false
	elif event is InputEventMouseMotion and (event.button_mask & MOUSE_BUTTON_MASK_LEFT) != 0:
		if event.position.distance_to(_press) > 10.0: dragged = true

func _draw() -> void:
	var on := has_focus() and not Engine.is_editor_hint()
	var r := Rect2(Vector2.ZERO, size)
	draw_rect(r, Color(0.2, 0.15, 0.1, 0.95) if on else Color(0.09, 0.07, 0.14, 0.85))
	draw_rect(Rect2(0, r.size.y - 1, r.size.x, 1), Color(0.0, 0.0, 0.0, 0.35))
	if on:
		draw_rect(Rect2(0, 0, 3, r.size.y), Color(1.0, 0.82, 0.35))
	var y := (size.y - 7 * px) / 2.0
	var x := (size.x - PixFont.text_width(title, px)) / 2.0 if centered else 12.0
	PixFont.draw(self, title, Vector2(x, y), px, Color(1.0, 0.82, 0.35) if on else Color(0.8, 0.76, 0.68))
