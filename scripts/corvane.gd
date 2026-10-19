class_name Corvane
extends Node2D
## Corvane: stalks, fires bursts, and dashes. Placeholder look: a red-tinted Warden until real art arrives.
signal defeated
const GROUND_Y := 222.0
@export var hp := 18
@export var finale_hp := 0     # > 0: his hp can't drop below this, and he gets faster when it does (3-7: Brix can't beat him)
@export var finale_at_pip := 0 # > 0: when the player is down to this many pips the fight ends (3-7: the push cutscene plays)
@export var wait_for_squad := false   # stays hidden until every other enemy is gone, then walks in
var finale_ready := false
var waiting := false
var enraged := false
var active_t := 0.0
@export var min_x := 0.0
@export var max_x := 99999.0
var player: Player
var sprite: Sprite2D
var state := "stalk"
var st := 0.0
var facing := -1
var flash := 0.0
var shots_left := 0
var shot_t := 0.0
var next_kind := "high"
var dash_dir := 1.0
var cd := 1.5
var frames := {}
var walk_frames: Array = []
var walk_t := 0.0
var burst_kind := "high"

func _ready() -> void:
	add_to_group("enemies"); add_to_group("hunters")
	if wait_for_squad:
		waiting = true; visible = false; remove_from_group("enemies")   # still a "hunter", so the level isn't cleared while he waits
	sprite = Sprite2D.new(); sprite.centered = false; sprite.position = Vector2(-18, -56)
	for n in ["ready", "aim", "fire", "caim", "cfire"]: frames[n] = load("res://assets/warden_%s.png" % n)
	for i in 8: walk_frames.append(load("res://assets/warden_walk_%d.png" % i))
	sprite.texture = frames["ready"]; add_child(sprite)
	sprite.modulate = Color(1.0, 0.55, 0.55)
	scale = Vector2(1.12, 1.12)

func hit_rect() -> Rect2:
	return Rect2(global_position + Vector2(-16, -62), Vector2(32, 62))

func hurt(d: int) -> void:
	if finale_ready: return
	hp -= d; flash = 0.12
	if finale_hp > 0 and hp <= finale_hp:
		hp = finale_hp; enraged = true
	Sfx.play("enemy_die" if hp <= 0 else "enemy_hit", 0.8, 0.06)
	if hp <= 0:
		defeated.emit(); queue_free()

func _physics_process(delta: float) -> void:
	if player == null: player = get_tree().get_first_node_in_group("player") as Player
	if player == null or player.hp <= 0: return
	if waiting:
		for e in get_tree().get_nodes_in_group("enemies"):
			if e != self and is_instance_valid(e): return
		waiting = false; visible = true; add_to_group("enemies")
		position.x = clampf(player.global_position.x + 300.0, min_x, max_x)
		cd = 1.2; Sfx.play("slide", 0.8)
		var cs := get_tree().current_scene
		if cs != null and cs.has_method("_toast"): cs._toast("HEAD WARDEN CORVANE")
	active_t += delta
	if finale_at_pip > 0: player.hp_floor = finale_at_pip   # he can wear Brix down to this many pips, no further
	if finale_at_pip > 0 and not finale_ready and active_t > 3.0 and player.hp <= finale_at_pip:
		finale_ready = true; state = "finale"
	flash = maxf(flash - delta, 0.0)
	sprite.modulate = Color(3, 3, 3) if flash > 0.0 else (Color(1.0, 0.25, 0.25) if state == "tele" else Color(1.0, 0.55, 0.55))
	var dx := player.global_position.x - global_position.x
	if state != "dash": facing = 1 if dx >= 0.0 else -1
	sprite.flip_h = facing < 0   # the art faces right
	st += delta
	match state:
		"stalk":
			sprite.texture = frames["ready"]
			var want := 110.0
			var mv := 0.0
			if absf(dx) > want + 12.0: mv = 1.0 if dx > 0.0 else -1.0
			elif absf(dx) < want - 30.0: mv = -1.0 if dx > 0.0 else 1.0
			position.x = clampf(position.x + mv * 70.0 * (1.4 if enraged else 1.0) * delta, min_x, max_x)
			if mv != 0.0:
				walk_t += delta; sprite.texture = walk_frames[int(walk_t * 8.0) % walk_frames.size()]
			else: walk_t = 0.0
			cd -= delta * (1.6 if enraged else 1.0)
			if cd <= 0.0:
				if randf() < 0.45 and absf(dx) < 260.0: state = "tele"; st = 0.0
				else: state = "burst"; st = 0.0; shots_left = 3; shot_t = 0.35; burst_kind = next_kind; next_kind = "low" if next_kind == "high" else "high"   # a burst is three shots of one kind, close together, so one jump (or one duck) beats them all
		"finale":
			sprite.texture = frames["ready"]
		"burst":
			var low := burst_kind == "low"   # low shots: he kneels
			sprite.texture = frames["caim" if low else "aim"]
			shot_t -= delta
			if shot_t <= 0.0 and shots_left > 0:
				shots_left -= 1; shot_t = 0.16; sprite.texture = frames["cfire" if low else "fire"]
				var s := EnemyShot.new(); s.kind = burst_kind; s.dir = float(facing); s.player = player
				s.global_position = global_position + Vector2(facing * Enemy.MUZZLE_X, Enemy.MUZZLE_LOW if low else Enemy.MUZZLE_HIGH) * scale.x
				get_parent().add_child(s); Sfx.play("enemy_shoot", 0.9, 0.05)
			if shots_left == 0 and shot_t <= 0.0: state = "stalk"; cd = 1.4 + randf() * 0.8; st = 0.0
		"tele":
			sprite.texture = frames["aim"]
			if st >= 0.55:
				state = "dash"; st = 0.0; dash_dir = float(facing); Sfx.play("slide", 0.8)
		"dash":
			sprite.texture = frames["fire"]
			position.x = clampf(position.x + dash_dir * 280.0 * delta, min_x, max_x)
			if player.hurtbox().intersects(hit_rect()): player.take_hit(global_position.x)
			if st >= 0.5: state = "stalk"; cd = 1.6; st = 0.0
	sprite.position.x = (18.0 - sprite.texture.get_width()) if sprite.flip_h else -18.0
