@tool
class_name PixMenu
extends Control
## Vertical menu. Up/Down (stick, d-pad, arrows) moves, accept (RP5 B / Space / Enter) or a tap picks. Works while paused.
signal chosen(index: int)
@export var items: PackedStringArray = []:
	set(v):
		items = v
		queue_redraw()
var index := 0
@export_range(1, 6) var px := 2:
	set(v):
		px = v; row_h = 7 * v + 6 * v
		queue_redraw()
var row_h := 26
@export var max_rows := 0       # > 0: show only this many rows and scroll to follow the cursor
var top_row := 0
var armed_t := 0.25     # ignore input briefly so the press that opened the menu doesn't pick something

func _init(list := PackedStringArray(), scale := 2) -> void:
	items = list; px = scale; row_h = 7 * scale + 6 * scale
	process_mode = Node.PROCESS_MODE_ALWAYS
	mouse_filter = Control.MOUSE_FILTER_STOP
	size = Vector2(160, row_h * items.size())
	pivot_offset = Vector2.ZERO

func place(center_x: float, top: float) -> void:
	position = Vector2(center_x - size.x / 2.0, top)

func _process(d: float) -> void:
	if Engine.is_editor_hint():
		queue_redraw(); return
	if not is_visible_in_tree(): return
	armed_t = maxf(armed_t - d, 0.0)
	_follow()
	queue_redraw()
	if armed_t > 0.0 or items.is_empty(): return
	if Input.is_action_just_pressed("ui_down"):
		index = (index + 1) % items.size(); Sfx.play("menu_move")
	elif Input.is_action_just_pressed("ui_up"):
		index = (index - 1 + items.size()) % items.size(); Sfx.play("menu_move")
	elif Input.is_action_just_pressed("ui_accept") or Input.is_action_just_pressed("jump"):
		Sfx.play("menu_select"); chosen.emit(index)

func _rows() -> int:
	return items.size() if max_rows <= 0 else mini(max_rows, items.size())

func _follow() -> void:
	var n := _rows()
	if index < top_row: top_row = index
	elif index >= top_row + n: top_row = index - n + 1
	top_row = clampi(top_row, 0, maxi(items.size() - n, 0))

var _press_y := 0.0
var _scroll_acc := 0.0
var _dragging := false
var _pressed := false

func _scroll_by(rows: int) -> void:
	var n := _rows()
	top_row = clampi(top_row + rows, 0, maxi(items.size() - n, 0))
	index = clampi(index, top_row, top_row + n - 1)   # keep the cursor on screen so _follow() doesn't snap back

func _gui_input(event: InputEvent) -> void:
	if armed_t > 0.0: return
	var scrolls := max_rows > 0 and items.size() > max_rows
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		if event.pressed:
			_pressed = true; _dragging = false; _press_y = event.position.y; _scroll_acc = 0.0
			if not scrolls:
				var i := int(event.position.y / row_h) + top_row
				if i >= 0 and i < items.size(): index = i; chosen.emit(i)
		else:
			# with a scrolling list a tap picks on release, and a drag (touch swipe) only scrolls
			if scrolls and _pressed and not _dragging:
				var i := int(event.position.y / row_h) + top_row
				if i >= 0 and i < items.size() and i < top_row + _rows(): index = i; chosen.emit(i)
			_pressed = false; _dragging = false
	elif event is InputEventMouseButton and event.pressed and scrolls:
		if event.button_index == MOUSE_BUTTON_WHEEL_UP: _scroll_by(-1)
		elif event.button_index == MOUSE_BUTTON_WHEEL_DOWN: _scroll_by(1)
	elif event is InputEventMouseMotion:
		if _pressed and scrolls:
			if absf(event.position.y - _press_y) > 8.0: _dragging = true
			if _dragging:
				_scroll_acc += event.relative.y
				while _scroll_acc >= row_h * 0.8: _scroll_by(-1); _scroll_acc -= row_h * 0.8     # drag down = list moves down
				while _scroll_acc <= -row_h * 0.8: _scroll_by(1); _scroll_acc += row_h * 0.8
		elif not _pressed:
			var j := int(event.position.y / row_h) + top_row
			if j >= 0 and j < items.size(): index = j

func _draw() -> void:
	for i in range(top_row, top_row + _rows()):
		var sel := i == index
		var label := items[i]
		var w := PixFont.text_width(label, px)
		var x := size.x / 2.0 - w / 2.0
		var y := (i - top_row) * row_h + (row_h - 7 * px) / 2.0
		var col := Color(1.0, 0.82, 0.35) if sel else Color(0.72, 0.68, 0.6)
		if sel:
			var bob := int(Time.get_ticks_msec() / 250.0) % 2
			PixFont.draw(self, ">", Vector2(x - 8 * px - bob * px, y), px, col)
		PixFont.draw(self, label, Vector2(x, y), px, col)
	if top_row > 0:
		PixFont.draw(self, "^", Vector2(size.x - 8 * px, -8 * px), px, Color(1.0, 0.82, 0.35))
	if top_row + _rows() < items.size():
		PixFont.draw(self, "v", Vector2(size.x - 8 * px, _rows() * row_h - 4), px, Color(1.0, 0.82, 0.35))
