class_name Tutorial
extends CanvasLayer
## Short one-time tips: first crate, first enemy, the sight cones, first shield Warden. Each pops up once, pauses the game,
## and is remembered in Prefs so it never repeats.
const TIPS := {
	"cover": ["HIDE BEHIND CRATES", ["PRESS UP AT A CRATE TO STEP BEHIND IT.", "YOU CAN ALSO CROUCH BY HOLDING DOWN.", "WALK OUT FROM BEHIND OR JUMP TO LEAVE."]],
	"shoot": ["SHOOTING", ["PRESS Y OR R1 TO SHOOT.", "YOUR AMMO BARS REFILL", "WHEN YOU STOP FIRING.", "B JUMPS, L1 SPRINTS."]],
	"cone": ["WATCH THE CONE", ["YELLOW CONE: HE IS PATROLLING.", "RED CONE: HE SPOTTED YOU.", "STAY OUT OF THE CONE, OR HIDE", "BEHIND COVER TO LOSE HIM."]],
	"shield": ["SHIELD WARDEN", ["SHOTS FROM THE FRONT BOUNCE OFF.", "HIT HIM 6 TIMES TO BREAK THE SHIELD,", "OR GET BEHIND HIM. AFTER IT BREAKS", "HE FIGHTS LIKE A NORMAL WARDEN."]],
}
var level: Level
var shown := {}
var active := ""
var arm_t := 0.0
var panel: Control
var title_l: PixLabel
var lines: Array = []
var hint: PixLabel

func _init(lv: Level = null) -> void:
	level = lv

func _ready() -> void:
	layer = 15
	process_mode = Node.PROCESS_MODE_ALWAYS
	panel = Control.new(); panel.visible = false; panel.mouse_filter = Control.MOUSE_FILTER_IGNORE; add_child(panel)
	var back := ColorRect.new(); back.color = Color(0.04, 0.02, 0.08, 0.45); back.size = Vector2(480, 270); back.mouse_filter = Control.MOUSE_FILTER_IGNORE
	panel.add_child(back)
	var card := Overlay.PanelDraw.new(); card.position = Vector2(50, 62); card.size = Vector2(380, 146); panel.add_child(card)
	title_l = PixLabel.new("", 2, Color(1.0, 0.82, 0.35)); title_l.position = Vector2(240, 74); panel.add_child(title_l)
	for i in 4:
		var l := PixLabel.new("", 1, Color(0.95, 0.9, 0.8)); l.position = Vector2(240, 104 + i * 14); panel.add_child(l); lines.append(l)
	hint = PixLabel.new("PRESS B TO CONTINUE", 1, Color(0.55, 0.9, 1.0)); hint.position = Vector2(240, 190); panel.add_child(hint)

func _process(d: float) -> void:
	if level == null or level.player == null: return
	if active != "":
		arm_t -= d
		if arm_t <= 0.0 and (Input.is_action_just_pressed("jump") or Input.is_action_just_pressed("shoot") or Input.is_action_just_pressed("slide")):
			_close()
		return
	if level.player.hp <= 0 or level.overlay.mode != "" or get_tree().paused: return
	var cand := _check()
	if cand != "": _open(cand)

func _on_screen(n: Node2D) -> bool:
	var dx := n.global_position.x - level.player.global_position.x
	return absf(dx) < 210.0 and absf(n.global_position.y - level.player.global_position.y) < 120.0

func _check() -> String:
	var p := level.player
	if not Prefs.seen("cover") and not p.is_back:
		for c in get_tree().get_nodes_in_group("cover"):
			var dx: float = c.global_position.x - p.global_position.x
			if dx > -10.0 and dx < 70.0: return "cover"
	var shielded := false; var warden := false; var any := false
	for e in get_tree().get_nodes_in_group("enemies"):
		if not is_instance_valid(e) or not (e is Node2D) or not _on_screen(e) or e.get("hp") == null: continue
		any = true
		if e.get("kind") == "warden":
			warden = true
			if e.get("shield") == true: shielded = true
	if shielded and not Prefs.seen("shield"): return "shield"
	if any and not Prefs.seen("shoot"): return "shoot"
	if warden and not Prefs.seen("cone") and Prefs.seen("shoot"): return "cone"
	if warden and not Prefs.seen("cone"): return "shoot"
	return ""

func _open(tip: String) -> void:
	active = tip; arm_t = 0.45
	var t: Array = TIPS[tip]
	title_l.text = t[0]
	for i in 4: lines[i].text = t[1][i] if i < t[1].size() else ""
	panel.visible = true
	Sfx.play("tip_open")
	get_tree().paused = true

func _close() -> void:
	Prefs.mark_seen(active); active = ""; panel.visible = false
	await get_tree().process_frame; await get_tree().process_frame
	if active == "" and level.overlay.mode == "": get_tree().paused = false
