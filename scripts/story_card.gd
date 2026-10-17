class_name StoryCard
extends CanvasLayer
signal done
static var active := false
const WRAP := 54
var heading := ""
var pages: Array = []
var page := 0
var shown := 0.0
var lines: Array = []
var body: Control
var arm_t := 0.35
var hint: PixLabel
var head_l: PixLabel
var count_l: PixLabel
var skip_l: PixLabel

func _init(h := "", p: Array = []) -> void:
	heading = h; pages = p

static func wrap_text(text: String, width: int) -> Array:
	var out: Array = []; var cur := ""
	for w in text.split(" "):
		if cur != "" and cur.length() + 1 + w.length() > width: out.append(cur); cur = w
		else: cur = w if cur == "" else cur + " " + w
	if cur != "": out.append(cur)
	return out

func _ready() -> void:
	layer = 30; process_mode = Node.PROCESS_MODE_ALWAYS
	active = true; get_tree().paused = true
	var back := ColorRect.new(); back.color = Color(0.03, 0.02, 0.07, 0.9); back.size = Vector2(480, 270); back.mouse_filter = Control.MOUSE_FILTER_IGNORE; add_child(back)
	var card := Overlay.PanelDraw.new(); card.position = Vector2(40, 50); card.size = Vector2(400, 170); add_child(card)
	head_l = PixLabel.new(heading, 2, Color(1.0, 0.82, 0.35)); head_l.position = Vector2(240, 64); add_child(head_l)
	body = Control.new(); body.mouse_filter = Control.MOUSE_FILTER_IGNORE; body.position = Vector2(60, 98); add_child(body)
	body.draw.connect(_draw_body)
	hint = PixLabel.new("NEXT" if Touch.active else "B > NEXT", 1, Color(0.55, 0.9, 1.0)); hint.position = Vector2(240, 202); add_child(hint)
	count_l = PixLabel.new("", 1, Color(0.7, 0.65, 0.8), false); count_l.position = Vector2(54, 202); add_child(count_l)
	skip_l = PixLabel.new(_skip_text(), 1, Color(0.7, 0.65, 0.8), false); skip_l.position = Vector2(440.0 - 6.0 * _skip_text().length() - 12.0, 202); add_child(skip_l)
	_set_page(0)

func _skip_text() -> String:
	if Touch.active: return "SKIP ALL"
	return "X > SKIP ALL" if not Input.get_connected_joypads().is_empty() else "TAB > SKIP ALL"

func _skip_all() -> void:
	Story.skip_all = true
	_finish()

func _set_page(i: int) -> void:
	page = i; shown = 0.0
	lines = wrap_text(pages[i], WRAP)
	count_l.text = "%d/%d" % [i + 1, pages.size()]
	var nxt := "NEXT" if i < pages.size() - 1 else "CONTINUE"
	hint.text = nxt if Touch.active else "B > " + nxt
	body.queue_redraw()

func _process(d: float) -> void:
	arm_t -= d
	var total := 0
	for l in lines: total += l.length()
	if shown < total:
		var before := int(shown) / 3; shown += 70.0 * d
		if int(shown) / 3 != before: Sfx.play("blip")
	body.queue_redraw()
	if arm_t > 0.0: return
	if Input.is_action_just_pressed("skip_story"): _skip_all()
	elif Input.is_action_just_pressed("jump") or Input.is_action_just_pressed("shoot"): _advance()
	elif Input.is_action_just_pressed("pause"):
		_finish()

func _advance() -> void:
	var total := 0
	for l in lines: total += l.length()
	if shown < total: shown = total
	elif page < pages.size() - 1: _set_page(page + 1)
	else: _finish()

func _input(event: InputEvent) -> void:
	# a tap anywhere on the card (touch becomes a left click) is the same as pressing B
	if arm_t <= 0.0 and event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		get_viewport().set_input_as_handled()
		var pos: Vector2 = get_viewport().get_mouse_position()
		if pos.x > 360.0 and pos.y > 194.0 and pos.y < 220.0: _skip_all()   # the SKIP ALL spot, bottom right of the card
		else: _advance()

func _draw_body() -> void:
	var left := int(shown)
	for i in lines.size():
		var t: String = lines[i]
		if left <= 0: break
		PixFont.draw(body, t.substr(0, left), Vector2(0, i * 13), 1, Color(0.95, 0.9, 0.8))
		left -= t.length()

var finished := false
func _finish() -> void:
	if finished: return
	finished = true
	set_process(false)
	await get_tree().process_frame; await get_tree().process_frame
	active = false; get_tree().paused = false
	done.emit(); queue_free()
