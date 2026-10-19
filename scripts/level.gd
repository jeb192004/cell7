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
@export var survive_boss := true               # true: the level also clears when no "hunters" are left (boss levels). Off for wave levels: only the timer ends them
@export var boss_clear := false                # true: the level clears when every "hunters" enemy (the boss) is gone
@export var wave_every := 0.0                  # > 0 with survive_time: a Warden (every third a shield Warden) arrives from a "wave_spawn" marker this often
@export var wave_max := 6                      # no new Warden while this many are alive
@export var hero_pick := false                 # 2-1a: choose Renn or Brix at the start; the other follows you
@export var block_cutscene := false           # at the clear, Renn blocks the soldiers' bolts (2-3)
@export var ambush_cutscene := false           # at the clear, an alarm trips and Wardens close in on Kesh (2-3)
@export var blast_cutscene := false           # at the clear, the Vagabond-9 leaves and Fuse's charges blow up the Meridian (2-4)
@export var finale_cutscene := false           # at the clear, Kesh pushes Corvane away with the Current (3-7; Corvane needs finale_hp)
@export var corvane_cutscene := false          # at the clear, Corvane walks out of the wrecked Strider (3-6)
@export var pickup_cutscene := false          # at the clear, the Vagabond-9 lifts Kesh (and the Ursk pal) aboard
@export var play_as := ""                      # play as this crew member (a CharacterDef key, e.g. "fuse") with nobody following
@export var crew_partner := ""                 # a second playable crew member who follows you; the SWAP button trades places ("renn" with play_as "brix")
@export var goal_word := "URSK FREED"          # HUD text for free_required (2-1c: "CHARGES SET")
@export var goal_block := "FREE THE URSK FIRST"
@export var ursk_pal := false                  # a young Ursk follows Kesh
@export var zoom := 1.0                          # camera zoom: 1.5 makes everything bigger on screen (the world feels larger); 1 = classic view
@export var bottom := 270.0                      # lowest the camera can see; raise it (e.g. 700) for floors below the street
@export var multi_floor := false               # decks / stairs / lifts above the street: the street art stays in the world instead of on the screen (set top below 0 too)
@export var ground := true                     # false = no street at all (everything is rooftops over a drop)
@export var ground_end := -1.0                 # the street only runs this far (-1 = the whole level)
static var preview_cutscene := ""   # set by the title screen's CUTSCENES list: play just that cutscene, then go back to the title
static var hero := ""                          # "renn" or "brix" once picked (kept across restarts, cleared on the title / next level)
static var checkpoint_x := -1.0
static var checkpoint_y := 222.0
static var bolt_floor := 222.0
var hud_layer: CanvasLayer
static var checkpoint_scene := ""
var player: Player
var cam: Camera2D
var cam_pos := Vector2.ZERO   # our own camera smoothing, kept on whole pixels so a fast scroll stays crisp
var overlay: Overlay
var elapsed := 0.0
var kills := 0
var total_foes := 0
var down_t := -1.0
var clear_t := -1.0
var freed := 0
var story_busy := false
var pal_node: Node2D
var survive_left := 0.0
var wave_t := 3.0
var wave_n := 0
var boss_gone_t := 0.0
var goal_label: PixLabel
var exit_warn := 0.0
var caught_t := -1.0
var follower: CrewFollower
var crew_hp := {}              # crew key -> hp, kept while swapping

func _ready() -> void:
	Story.skip_all = false   # SKIP ALL only covers one run of cards and cutscenes
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
	if hero_pick and hero != "": player.def = CharacterDef.by_key(hero)
	if play_as != "": player.def = CharacterDef.by_key(play_as)
	var start := $PlayerStart as Marker2D
	player.position = Vector2(checkpoint_x, checkpoint_y) if checkpoint_x >= 0.0 else start.position
	add_child(player)
	cam = Camera2D.new()
	cam.limit_left = 0; cam.limit_right = int(length)
	cam.limit_top = int(top); cam.limit_bottom = int(bottom)
	cam.zoom = Vector2(zoom, zoom)
	bolt_floor = 222.0 if bottom <= 270.0 else bottom
	if not get_tree().get_nodes_in_group("vents").is_empty():
		cam.limit_top = -3000; cam.limit_bottom = 3000   # vents can be above or below the street
		var gl := get_node_or_null("Ground") as Parallax2D
		if gl != null: gl.scroll_scale.y = 1.0   # the street art moves with the world when the camera drops into a below-floor vent
	if multi_floor or zoom != 1.0 or bottom > 270.0:
		var gl2 := get_node_or_null("Ground") as Parallax2D
		if gl2 != null: gl2.scroll_scale.y = 1.0
	cam.physics_interpolation_mode = Node.PHYSICS_INTERPOLATION_MODE_OFF   # moved every frame by _process
	add_child(cam)
	cam_pos = Vector2(player.position.x, _cam_y())
	px_prev = player.position.x; px_cur = px_prev
	cam.position = cam_pos.round()
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
		var up := UrskPal.new(); up.position = player.position + Vector2(-30, 0); add_child(up); pal_node = up
	if crew_partner != "":
		var pd := CharacterDef.by_key(crew_partner)
		crew_hp[player.def.key] = player.hp; crew_hp[pd.key] = pd.hp
		follower = CrewFollower.new(); follower.def = pd; follower.player = player
		follower.position = player.position + Vector2(-38, 0); add_child(follower)
		Controls.setup()
		var tt := PixLabel.new("TAB / Y: SWAP     RENN: FIRE = SLASH, L / A = BLOCK", 1, Color(0.55, 0.9, 1.0))
		tt.position = Vector2(240, 250); hud_layer.add_child(tt)
		var tw2 := create_tween()
		tw2.tween_interval(5.0); tw2.tween_property(tt, "modulate:a", 0.0, 0.8); tw2.tween_callback(tt.queue_free)
	if hero_pick and hero != "":
		var f := CrewFollower.new(); f.def = CharacterDef.by_key("brix" if hero == "renn" else "renn"); f.player = player
		f.position = player.position + Vector2(-38, 0); add_child(f)
	if preview_cutscene != "": _preview_run.call_deferred()
	elif hero_pick and hero == "": _hero_picker.call_deferred()
	else: _story_intro.call_deferred()
	Sfx.music_for(scene_file_path)
	total_foes = 0
	for e in get_tree().get_nodes_in_group("enemies"):
		total_foes += 1
		e.defeated.connect(func(): kills += 1)

## "Who leads?" card. Pauses the level; picking reloads it so the player is built as that character.
func _hero_picker() -> void:
	get_tree().paused = true
	var layer := CanvasLayer.new(); layer.layer = 40; layer.process_mode = Node.PROCESS_MODE_ALWAYS; add_child(layer)
	var back := ColorRect.new(); back.color = Color(0.05, 0.03, 0.1, 0.9); back.size = Vector2(480, 270); layer.add_child(back)
	var h := PixLabel.new("WHO LEADS?", 3, Color(1.0, 0.82, 0.35)); h.position = Vector2(240, 40); layer.add_child(h)
	var sub := PixLabel.new("THE OTHER FOLLOWS YOU. ONE SPOTTING AND IT STARTS OVER.", 1, Color(0.8, 0.75, 0.65)); sub.position = Vector2(240, 70); layer.add_child(sub)
	var m := PixMenu.new(PackedStringArray(["RENN", "BRIX"]), 3)
	m.size = Vector2(240, m.row_h * 2); m.place(240, 100); layer.add_child(m)
	var info := PixLabel.new("", 1, Color(0.55, 0.9, 1.0)); info.position = Vector2(240, 190); layer.add_child(info)
	var notes := ["RENN: FAST, AND HIDES BEHIND ANY CRATE. NO WEAPON YET.", "BRIX: TOUGH, BUT TOO BIG FOR A LONE CRATE. HIDE BEHIND STACKS OF 2 OR MORE."]
	var upd := func(): info.text = notes[m.index]
	var t := Timer.new(); t.wait_time = 0.05; t.autostart = true; t.process_mode = Node.PROCESS_MODE_ALWAYS; t.timeout.connect(upd); layer.add_child(t)
	m.chosen.connect(func(i: int):
		hero = ["renn", "brix"][i]
		get_tree().paused = false
		get_tree().reload_current_scene())

## Wave levels: a Warden steps in from one of the "wave_spawn" markers (alternating sides) and already knows where Kesh is.
func _spawn_wave() -> void:
	var spots := get_tree().get_nodes_in_group("wave_spawn")
	if spots.is_empty(): return
	var alive := 0
	for e in get_tree().get_nodes_in_group("enemies"):
		if e.get("kind") == "warden": alive += 1
	if alive >= wave_max: return
	var spot: Node2D = spots[wave_n % spots.size()]
	var shielded := wave_n % 3 == 2
	wave_n += 1
	var w: Node2D = load("res://scenes/%s.tscn" % ("warden_shield" if shielded else "warden")).instantiate()
	w.position = spot.position
	w.set("player", player)
	w.set("patrol_range", 700.0)   # keeps sweeping the bay after losing sight of Kesh
	var host: Node = get_node_or_null("Enemies")
	if host == null: host = self
	host.add_child(w)
	w._spot(player.global_position.x - w.global_position.x)
	Sfx.play("spot")

## Title screen > CUTSCENES: stand at the end of this level, play only the cutscene, then return to the title.
func _preview_run() -> void:
	var kind := preview_cutscene
	preview_cutscene = ""
	survive_time = 0.0   # so the level's own "cleared" logic (and its cutscene) doesn't also fire
	for i in 3: await get_tree().process_frame
	for e in get_tree().get_nodes_in_group("enemies"): e.queue_free()
	for n in get_tree().get_nodes_in_group("enemy_shots"): n.queue_free()
	var ex := get_node_or_null("Exit") as Marker2D
	if ex != null:
		player.position = Vector2(ex.position.x - 120.0, player.position.y)
		if pal_node != null: pal_node.position = player.position + Vector2(-30, 0)
		px_prev = player.position.x; px_cur = px_prev     # snap the camera there instead of gliding
		cam_pos = Vector2(player.position.x + 30.0, _cam_y()); cam.position = cam_pos.round()
		for i in 3: await get_tree().process_frame
	var cs: Cutscene = null
	match kind:
		"block":
			var bc := BlockCutscene.new(); bc.player = player; cs = bc
		"ambush":
			var ac := AmbushCutscene.new(); ac.player = player; cs = ac
		"blast":
			cs = BlastCutscene.new()
		"approach":
			cs = ApproachCutscene.new()
		"corvane":
			var vc := CorvaneCutscene.new(); vc.player = player; cs = vc
		"push":
			var fc := PushCutscene.new(); fc.player = player; cs = fc
		"pickup":
			var pc := PickupCutscene.new(); pc.player = player; pc.pal = pal_node; cs = pc
	if cs != null:
		add_child(cs)
		await cs.finished
	get_tree().change_scene_to_file("res://scenes/title.tscn")

## True once Corvane has taken the beating that ends the 3-7 fight (see Corvane.finale_hp).
func _finale_ready() -> bool:
	for h in get_tree().get_nodes_in_group("hunters"):
		if h.get("finale_ready") == true: return true
	return false

func _input(event: InputEvent) -> void:
	if crew_partner != "" and event.is_action_pressed("swap") and not get_tree().paused and clear_t < 0.0 and caught_t < 0.0 and player.hp > 0:
		_swap_crew()

## Trade places with the follower: same spot, other body. A downed crew member can't be swapped to.
func _swap_crew(auto := false) -> void:
	if follower == null or player.planting >= 0.0: return
	var other := follower.def
	if int(crew_hp.get(other.key, 0)) <= 0: return
	crew_hp[player.def.key] = player.hp
	var old := player.def
	player.set_def(other, int(crew_hp[other.key]))
	follower.set_def(old)
	player.hurt_t = 0.5 if auto else 0.0
	Sfx.play("pickup")
	_toast(("%s DOWN. %s TAKES OVER" % [old.display_name, other.display_name]) if auto else other.display_name)

func _story_intro() -> void:
	await Story.play(self, scene_file_path.get_file().get_basename())
	Story.skip_all = false

func _cam_y() -> float:
	if player.vent != null and player.vent.global_position.y > GROUND_Y: return player.position.y - 87.0   # only follow down into below-floor vents
	if zoom != 1.0 or bottom > 270.0: return player.position.y - 20.0   # camera limits keep the view inside the level
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
	cam_pos = Vector2(player.position.x, _cam_y())
	px_prev = player.position.x; px_cur = px_prev
	cam.position = cam_pos.round()
	_toast("FELL")

func _restart() -> void:
	checkpoint_x = -1.0
	get_tree().reload_current_scene()

func _to_title() -> void:
	Story.reset()
	hero = ""
	checkpoint_x = -1.0
	get_tree().change_scene_to_file(Overlay.TITLE_SCENE)

func _go_next() -> void:
	hero = ""
	checkpoint_x = -1.0
	get_tree().change_scene_to_file(next_level)

var px_prev := 0.0
var px_cur := 0.0
func _physics_process(_d: float) -> void:
	if player == null: return
	px_prev = px_cur; px_cur = player.position.x

func _process(d: float) -> void:
	if player == null: return
	# follow where Kesh is actually drawn (smoothed between physics steps), not his stepped physics position
	var px: float = lerpf(px_prev, px_cur, Engine.get_physics_interpolation_fraction())
	var cam_target := Vector2(px + 30.0 * player.facing, _cam_y())
	cam_pos = cam_pos.lerp(cam_target, 1.0 - exp(-8.0 * d))
	cam.position = cam_pos.round()
	if player.hp <= 0 and crew_partner != "" and follower != null and int(crew_hp.get(follower.def.key, 0)) > 0:
		crew_hp[player.def.key] = 0
		_swap_crew(true)
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
				if e.get("alerted") == true or (e.get("kind") in ["drone", "bomber"] and e.get("state") in ["wind", "dive"]):
					caught_t = 0.0; overlay.show_banner("SPOTTED")
					player.set_physics_process(false)
					for x in get_tree().get_nodes_in_group("enemies"): x.set_physics_process(false)
					break
		else:
			caught_t += d
			if caught_t > 1.3: get_tree().reload_current_scene()
	exit_warn = maxf(exit_warn - d, 0.0)
	if free_required > 0 and goal_label != null: goal_label.text = "%s %d/%d" % [goal_word, freed, free_required]
	if survive_time > 0.0 and clear_t < 0.0:
		survive_left -= d
		goal_label.text = "%s %d" % [survive_label, maxi(ceili(survive_left), 0)]
		var hunters := get_tree().get_nodes_in_group("hunters")
		if survive_left <= 0.0 or (survive_boss and hunters.is_empty() and elapsed > 3.0):
			clear_t = 0.0
			for h in get_tree().get_nodes_in_group("enemies"): h.queue_free()
		elif wave_every > 0.0:
			wave_t -= d
			if wave_t <= 0.0:
				wave_t = wave_every; _spawn_wave()
	if boss_clear and clear_t < 0.0 and elapsed > 3.0 and (get_tree().get_nodes_in_group("hunters").is_empty() or _finale_ready()):
		boss_gone_t += d   # let the boss finish exploding before the clear card
		if boss_gone_t > (0.8 if _finale_ready() else 2.5):
			clear_t = 0.0
			for h in get_tree().get_nodes_in_group("enemies"):
				if h.get("finale_ready") != true: h.queue_free()
	var ex := get_node_or_null("Exit") as Marker2D
	if ex != null and clear_t < 0.0 and player.position.x >= ex.position.x and absf(player.position.y - ex.position.y) < 90.0:
		if freed >= free_required: clear_t = 0.0
		elif exit_warn <= 0.0:
			exit_warn = 2.0; _toast(goal_block)
	if clear_t >= 0.0:
		clear_t += d
		if clear_t > 0.5 and overlay.mode == "" and not story_busy:
			story_busy = true
			for n in get_tree().get_nodes_in_group("enemy_shots"): n.queue_free()   # no slugs left hanging over the cutscene
			if block_cutscene:
				var bc := BlockCutscene.new(); bc.player = player
				add_child(bc); await bc.finished
			if ambush_cutscene:
				var ac := AmbushCutscene.new(); ac.player = player
				add_child(ac); await ac.finished
			if blast_cutscene:
				var xc := BlastCutscene.new()
				add_child(xc); await xc.finished
			if finale_cutscene:
				var fc := PushCutscene.new(); fc.player = player
				add_child(fc); await fc.finished
			if corvane_cutscene:
				var vc := CorvaneCutscene.new(); vc.player = player
				add_child(vc); await vc.finished
			if pickup_cutscene:
				var cs := PickupCutscene.new(); cs.player = player; cs.pal = pal_node
				add_child(cs); await cs.finished
			await Story.play(self, "outro_" + scene_file_path.get_file().get_basename())
			Story.skip_all = false
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
