extends Node2D
## Level 1 test strip: salt flats, parallax, Kesh, a few placeholder enemies.
const GROUND_Y := 222.0
const WORLD_W := 3600.0
var player: Player
var cam: Camera2D
var pause_label: Label
var hud: Node2D
var down_t := -1.0

func _ready() -> void:
	Controls.setup()
	_background()
	_ground()
	player = Player.new()
	player.position = Vector2(100, GROUND_Y)
	add_child(player)
	cam = Camera2D.new()
	cam.limit_left = 0; cam.limit_right = int(WORLD_W)
	cam.limit_top = 0; cam.limit_bottom = 270
	cam.position_smoothing_enabled = true
	cam.position_smoothing_speed = 8.0
	add_child(cam)
	var i := 0
	for x in [620, 1000, 1350, 1800, 2300, 2900]:
		_enemy("warden", x, GROUND_Y)
		_cover(x - 115, 2 if i % 2 == 0 else 1)
		_cover(x + 140 if i % 3 == 1 else x - 175, 1)
		i += 1
	_cover(250, 1)
	for x in [850, 1550, 2600]:
		_enemy("drone", x, 150.0)
	var layer := CanvasLayer.new(); layer.layer = 10; add_child(layer)
	pause_label = Label.new(); pause_label.text = "PAUSED"; pause_label.position = Vector2(210, 120); pause_label.visible = false
	layer.add_child(pause_label)
	hud = Hearts.new(); hud.player = player; layer.add_child(hud)
	process_mode = Node.PROCESS_MODE_ALWAYS
	player.process_mode = Node.PROCESS_MODE_PAUSABLE

func _cover(x: float, stack := 1) -> void:
	var c := Cover.new(); c.stack = stack; c.position = Vector2(x, GROUND_Y + 1.0)
	add_child(c)

func _enemy(kind: String, x: float, y: float) -> void:
	var e := Enemy.new(); e.kind = kind; e.position = Vector2(x, y); e.player = player
	add_child(e)

func _bg_layer(file: String, scale: float, z: int) -> void:
	var p := Parallax2D.new()
	p.scroll_scale = Vector2(scale, 0.0)
	p.repeat_size = Vector2(480, 0)
	p.repeat_times = 12
	p.z_index = z
	var s := Sprite2D.new(); s.texture = load("res://assets/%s.png" % file); s.centered = false
	p.add_child(s)
	add_child(p)

func _background() -> void:
	var sky := CanvasLayer.new(); sky.layer = -10; add_child(sky)
	var s := Sprite2D.new(); s.texture = load("res://assets/bg_sky.png"); s.centered = false
	sky.add_child(s)
	_bg_layer("bg_far", 0.15, -30)
	_bg_layer("bg_mid", 0.35, -20)
	_bg_layer("bg_dunes", 0.6, -10)
	_bg_layer("ground", 1.0, -5)

func _ground() -> void:
	var b := StaticBody2D.new()
	var c := CollisionShape2D.new(); var r := RectangleShape2D.new()
	r.size = Vector2(WORLD_W + 400, 60); c.shape = r; c.position = Vector2(WORLD_W / 2.0, GROUND_Y + 30)
	b.add_child(c); add_child(b)

func _process(d: float) -> void:
	if player.hp <= 0:
		if down_t < 0.0:
			down_t = 0.0; pause_label.text = "DOWN"; pause_label.visible = true
		down_t += d
		if down_t > 1.6:
			get_tree().reload_current_scene()
		return
	cam.position = Vector2(player.position.x + 30.0 * player.facing, 135.0)
	if Input.is_action_just_pressed("pause"):
		get_tree().paused = not get_tree().paused
		pause_label.visible = get_tree().paused
