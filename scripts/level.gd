class_name Level
extends Node2D
## One playable level. Everything you see in the 2D editor is real: drag Warden / Drone / Crate scenes in, move the
## Marker2Ds (PlayerStart, Exit, checkpoints in the "checkpoint" group), set `length`, press F6 to play just this level.
const GROUND_Y := 222.0
@export var length := 3600.0
@export var title := ""                        # shown when the level starts, e.g. "1-1 SALT FLATS"
@export_file("*.tscn") var next_level := ""
@export var top := 0.0                         # camera can climb this far above the start (negative); 0 = fixed camera
@export var kill_y := 0.0                      # falling below this costs a pip and returns you to the checkpoint (0 = off)
@export var tutorial := true                   # one-time tips (crates, shooting, sight cones, shield Wardens)
@export var vent_from := -1.0                 # between vent_from and vent_to Kesh has to crawl (forced crouch)
@export var vent_to := -1.0
@export var stealth_only := false              # being spotted (Warden alerted, drone diving) restarts the level
@export var free_required := 0                 # cages that must be opened before the exit works
@export var survive_time := 0.0                # > 0: boss level, you clear it when the timer runs out (or the boss falls)
@export var survive_label := "HELP ARRIVES IN"
@export var ursk_pal := false                  # a young Ursk follows Kesh
@export var ground := true                     # false = no street at all (everything is rooftops over a drop)
@export var ground_end := -1.0                 # the street only runs this far (-1 = the whole level)
static var checkpoint_x := -1.0
static var checkpoint_y := 222.0
var hud_layer: CanvasLayer
static var checkpoint_scene := ""
var player: Player
var cam: Camera2D
var overlay: Overlay
var elapsed := 0.0
var kills := 0
var total_foes := 0
var down_t := -1.0
var clear_t := -1.0
var freed := 0
var story_busy := false
var survive_left := 0.0
var goal_label: PixLabel
var exit_warn := 0.0
var caught_t := -1.0

func _ready() -> void:
	Controls.setup()
	if checkpoint_scene != scene_file_path:
		checkpoint_x = -1.0
		checkpoint_scene = scene_file_path
	for n in get_children():
		if n is Parallax2D:
			n.repeat_times = int(length / 480.0) + 4
	# ground the player can stand on
	var b := StaticBody2D.new()
	var c := CollisionShape2D.new(); var r := RectangleShape2D.new()
	var gw := length + 800.0 if ground_end < 0.0 else ground_end + 400.0
	r.size = Vector2(gw, 60); c.shape = r; c.position = Vector2((gw - 400.0) / 2.0 if ground_end >= 0.0 else length / 2.0, GROUND_Y + 30)
	b.add_child(c)
	if ground: add_child(b)
	# Kesh
	player = Player.new()
	var start := $PlayerStart as Marker2D
	player.position = Vector2(checkpoint_x, checkpoint_y) if checkpoint_x >= 0.0 else start.position
	add_child(player)
	cam = Camera2D.new()
	cam.limit_left = 0; cam.limit_right = int(length)
	cam.limit_top = int(top); cam.limit_bottom = 270
	if not get_tree().get_nodes_in_group("vents").is_empty():
		cam.limit_top = -3000; cam.limit_bottom = 3000   # vents can be above or below the street
		var gl := get_node_or_null("Ground") as Parallax2D
		if gl != null: gl.scroll_scale.y = 1.0   # the street art moves with the world when the camera drops into a below-floor vent
	cam.position_smoothing_enabled = true
	cam.position_smoothing_speed = 8.0
	add_child(cam)
	cam.position = Vector2(player.position.x, _cam_y())
	cam.reset_smoothing()
	for e in get_tree().get_nodes_in_group("enemies"):
		e.player = player
	# HUD, pause menu, clear card
	var layer := CanvasLayer.new(); layer.layer = 10; add_child(layer); hud_layer = layer
	var hearts := Hearts.new(); hearts.player = player; layer.add_child(hearts)
	overlay = Overlay.new()
	add_child(overlay)
	overlay.resume.connect(func(): pass)
	overlay.restart.connect(_restart)
	overlay.to_title.connect(_to_title)
	overlay.next.connect(_go_next)
	if title != "":
		var tl := PixLabel.new(title, 3, Color(1.0, 0.82, 0.35))
		tl.position = Vector2(240, 60); layer.add_child(tl)
		var tw := create_tween()
		tw.tween_interval(2.0); tw.tween_property(tl, "modulate:a", 0.0, 0.8); tw.tween_callback(tl.queue_free)
	if tutorial and (DisplayServer.get_name() != "headless" or OS.get_environment("TIPS") != ""): layer.add_child(Tutorial.new(self))
	if vent_from >= 0.0:
		var vc := VentCeiling.new(); vc.x0 = vent_from; vc.x1 = vent_to; add_child(vc)
	if free_required > 0 or survive_time > 0.0:
		goal_label = PixLabel.new("", 1, Color(1.0, 0.85, 0.45)); goal_label.position = Vector2(240, 8); layer.add_child(goal_label)
	survive_left = survive_time
	if ursk_pal:
		var up := UrskPal.new(); up.position = player.position + Vector2(-30, 0); add_child(up)
	_story_intro.call_deferred()
	Sfx.music_for(scene_file_path)
	total_foes = 0
	for e in get_tree().get_nodes_in_group("enemies"):
		total_foes += 1
		e.defeated.connect(func(): kills += 1)

func _story_intro() -> void:
	await Story.play(self, scene_file_path.get_file().get_basename())

func _cam_y() -> float:
	if player.vent != null and player.vent.global_position.y > GROUND_Y: return player.position.y - 87.0   # only follow down into below-floor vents
	if top >= 0.0: return 135.0
	return clampf(player.position.y - 30.0, top + 135.0, 135.0)

func _toast(text: String) -> void:
	var tl := PixLabel.new(text, 2, Color(0.55, 0.9, 1.0))
	tl.position = Vector2(240, 40); hud_layer.add_child(tl)
	var tw := create_tween()
	tw.tween_interval(0.8); tw.tween_property(tl, "modulate:a", 0.0, 0.5); tw.tween_callback(tl.queue_free)

func _fall_respawn() -> void:
	player.hp -= 1
	if player.hp <= 0: return
	var start := $PlayerStart as Marker2D
	player.position = Vector2(checkpoint_x, checkpoint_y) if checkpoint_x >= 0.0 else start.position
	player.velocity = Vector2.ZERO
	player.is_back = false
	player.vent = null
	player.hurt_t = 1.2
	cam.position = Vector2(player.position.x, _cam_y())
	cam.reset_smoothing()
	_toast("FELL")

func _restart() -> void:
	checkpoint_x = -1.0
	get_tree().reload_current_scene()

func _to_title() -> void:
	Story.reset()
	checkpoint_x = -1.0
	get_tree().change_scene_to_file(Overlay.TITLE_SCENE)

func _go_next() -> void:
	checkpoint_x = -1.0
	get_tree().change_scene_to_file(next_level)

func _process(d: float) -> void:
	if player == null: return
	cam.position = Vector2(player.position.x + 30.0 * player.facing, _cam_y())
	if player.hp <= 0:
		if down_t < 0.0:
			down_t = 0.0; overlay.show_banner("DOWN")
		down_t += d
		if down_t > 1.6:
			get_tree().reload_current_scene()
		return
	if clear_t < 0.0:
		elapsed += d
	if kill_y != 0.0 and player.position.y > kill_y:
		_fall_respawn()
	for m in get_tree().get_nodes_in_group("checkpoint"):
		if player.position.x >= (m as Node2D).position.x and (m as Node2D).position.x > checkpoint_x:
			checkpoint_x = (m as Node2D).position.x
			checkpoint_y = (m as Node2D).position.y
			if player.hp < player.max_hp:
				player.hp += 1   # reaching a checkpoint heals a pip
				_toast("CHECKPOINT +1")
	player.forced_crouch = player.in_vent or (vent_from >= 0.0 and player.position.x > vent_from and player.position.x < vent_to)
	if stealth_only and clear_t < 0.0:
		if caught_t < 0.0:
			for e in get_tree().get_nodes_in_group("enemies"):
				if e.get("alerted") == true or (e.get("kind") == "drone" and e.get("state") in ["wind", "dive"]):
					caught_t = 0.0; overlay.show_banner("SPOTTED")
					player.set_physics_process(false)
					for x in get_tree().get_nodes_in_group("enemies"): x.set_physics_process(false)
					break
		else:
			caught_t += d
			if caught_t > 1.3: get_tree().reload_current_scene()
	exit_warn = maxf(exit_warn - d, 0.0)
	if free_required > 0 and goal_label != null: goal_label.text = "URSK FREED %d/%d" % [freed, free_required]
	if survive_time > 0.0 and clear_t < 0.0:
		survive_left -= d
		goal_label.text = "%s %d" % [survive_label, maxi(ceili(survive_left), 0)]
		var hunters := get_tree().get_nodes_in_group("hunters")
		if survive_left <= 0.0 or (hunters.is_empty() and elapsed > 3.0):
			clear_t = 0.0
			for h in get_tree().get_nodes_in_group("enemies"): h.queue_free()
	var ex := get_node_or_null("Exit") as Marker2D
	if ex != null and clear_t < 0.0 and player.position.x >= ex.position.x and absf(player.position.y - ex.position.y) < 90.0:
		if freed >= free_required: clear_t = 0.0
		elif exit_warn <= 0.0:
			exit_warn = 2.0; _toast("FREE THE URSK FIRST")
	if clear_t >= 0.0:
		clear_t += d
		if clear_t > 0.5 and overlay.mode == "" and not story_busy:
			story_busy = true
			await Story.play(self, "outro_" + scene_file_path.get_file().get_basename())
			overlay.open_clear(elapsed, kills, total_foes, next_level != "")


## Dark ceiling over the vent stretch so you can see you're crawling.
class VentCeiling extends Node2D:
	var x0 := 0.0
	var x1 := 0.0
	func _ready() -> void:
		z_index = 4
	func _draw() -> void:
		var h := GROUND_Y - 32.0
		draw_rect(Rect2(x0, -200, x1 - x0, h + 200), Color(0.06, 0.07, 0.1))
		draw_rect(Rect2(x0, h - 3, x1 - x0, 3), Color(0.3, 0.32, 0.38))
		var x := x0 + 6.0
		while x < x1:
			draw_rect(Rect2(x, h - 18, 3, 15), Color(0.16, 0.17, 0.22)); x += 14.0
		draw_rect(Rect2(x0, h, x1 - x0, 2), Color(0.0, 0.0, 0.0, 0.5))
