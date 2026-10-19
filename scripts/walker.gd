class_name Walker
extends Node2D
## The Titan Strider (3-5 boss, a Sovereignty walker). Art: assets/walker_00..15 (tools/import_walker.py). It keeps its distance and shoots (duck the high
## bursts, jump the low ones), lobs missiles that come down on the red marks, and stomps if you stand under it. After a missile volley it
## vents steam and is open: hits count double. Val's strafing run (the Vagabond-9) hits it at 2/3 and 1/3 health. Renn's blade is the only weapon.
signal defeated
const GROUND_Y := 222.0
const W := 144.0            # art size
const AX := 75.0            # art x of the body centre
const H := 107.0            # art height: feet are at the bottom
const IDLE := 6             # standing frame
const MUZZLE := Vector2(50.0, -46.0)   # gun barrel tip, from the feet, art facing right
const PODS := [-37.0, -2.0]            # missile pod x, art facing right (the pods rise to y -105 when the launcher is vertical)
const WALK := [0, 2, 4, 5, 3, 1]
const MarkDraw := preload("res://scripts/walker_mark.gd")   # the red landing ring of a missile
@export var hp := 55
@export var min_x := 0.0
@export var max_x := 99999.0
@export var keep_dist := 175.0     # how close it walks to the player before it stops and shoots
@export var stomp_dist := 105.0    # inside this it stomps instead of shooting
@export var fuse_mode := false     # 3-6: the player is Fuse. No Val strafes and no vent window; planted charges (ChargeSpot) blow when it walks over them
@export var charge_dmg := 7
var max_hp := 0
var player: Player
var sprite: Sprite2D
var tex: Array = []
var state := "walk"
var st := 0.0
var facing := -1
var flash := 0.0
var cd := 2.0
var walk_t := 0.0
var shots_left := 0
var shot_t := 0.0
var missiles_next := false
var volley_left := 0
var volley_t := 0.0
var strafed := 0         # how many of Val's runs have happened
var ship: Node2D
var ship_t := 0.0
var bombs := 0.0
var stomped := false
var muzzle_t := 0.0      # > 0: gun flash showing
var puffs: Array = []    # launch smoke [pos, age]

func _ready() -> void:
	max_hp = hp
	add_to_group("enemies"); add_to_group("hunters")
	for i in 16: tex.append(load("res://assets/walker_%02d.png" % i))
	sprite = Sprite2D.new(); sprite.centered = false
	sprite.texture = tex[IDLE]; add_child(sprite)
	z_index = 2

func hit_rect() -> Rect2:
	if state == "dying" or state == "dead": return Rect2()
	return Rect2(global_position + Vector2(-48, -100), Vector2(96, 100))

func _open() -> bool:
	return state == "vent" or state == "strafe"

func hurt(d: int) -> void:
	if state == "dying" or state == "dead": return
	hp -= d * (2 if _open() else 1); flash = 0.12
	Sfx.play("enemy_hit", 0.7, 0.06)
	if hp <= 0:
		hp = 0; _die()
	elif not fuse_mode and strafed < 2 and hp <= max_hp * (2.0 - strafed) / 3.0 and state != "strafe":
		_strafe()

func _die() -> void:
	state = "dying"; st = 0.0
	remove_from_group("hunters"); remove_from_group("enemies")
	defeated.emit()

func _toast(t: String) -> void:
	var lv := get_tree().current_scene
	if lv != null and lv.has_method("_toast"): lv._toast(t)

func _strafe() -> void:
	strafed += 1
	state = "strafe"; st = 0.0
	ship = Ascent.ShipNode.new(); ship.z_index = 20; ship.power = 0.9
	get_parent().add_child(ship)
	ship.global_position = Vector2(global_position.x - 440.0, 62.0)
	ship_t = 0.0; bombs = 0.0
	_toast("VAL: STRAFING RUN!")

func _face(dx: float) -> void:
	facing = 1 if dx >= 0.0 else -1

func _physics_process(delta: float) -> void:
	if player == null: player = get_tree().get_first_node_in_group("player") as Player
	if player == null: return
	flash = maxf(flash - delta, 0.0)
	st += delta
	var dx := player.global_position.x - global_position.x
	if state != "dying" and state != "dead" and player.hp > 0: _face(dx)
	if state != "dying" and state != "dead" and player.hp > 0 and player.hurtbox().intersects(Rect2(global_position + Vector2(-44.0, -100.0), Vector2(88.0, 100.0))):
		player.take_hit(global_position.x)   # its body hurts: you can't run through it
	if fuse_mode and (state == "walk" or state == "guns" or state == "missiles" or state == "stomp"): _check_charges()
	var f := IDLE
	muzzle_t = maxf(muzzle_t - delta, 0.0)
	for pf in puffs: pf[1] += delta
	puffs = puffs.filter(func(pf): return pf[1] < 0.7)
	match state:
		"walk":
			var want := keep_dist
			var mv := 0.0
			if absf(dx) > want + 15.0: mv = 1.0 if dx > 0.0 else -1.0
			position.x = clampf(position.x + mv * 36.0 * rage() * delta, min_x, max_x)
			if mv != 0.0:
				var prev := int(walk_t * 5.0)
				walk_t += delta
				var idx := int(walk_t * 5.0)
				f = WALK[idx % WALK.size()]
				if idx != prev and f == 5: Sfx.play("slide", 0.45)
			else: walk_t = 0.0
			cd -= delta
			if cd <= 0.0 and player.hp > 0: _pick_attack(dx)
		"guns":
			f = IDLE
			shot_t -= delta
			if shot_t <= 0.0 and shots_left > 0:
				shots_left -= 1; shot_t = 0.28 / rage(); muzzle_t = 0.09
				var s := EnemyShot.new(); s.kind = "high"; s.dir = float(facing); s.player = player
				s.global_position = global_position + Vector2(facing * MUZZLE.x, MUZZLE.y)
				get_parent().add_child(s); Sfx.play("enemy_shoot", 0.7, 0.05)
			if shots_left == 0 and shot_t <= 0.0: state = "walk"; cd = (1.2 + randf() * 0.5) / rage(); st = 0.0
		"missiles":
			# the launcher swings up (8, 10, 11), fires straight up, then folds back down
			if volley_left > 0 or st < 0.6 + 0.3 * 3 + 0.4:
				f = 8 if st < 0.15 else (10 if st < 0.3 else 11)
				if volley_left == 0 and st > 0.6 + 0.9 + 0.1: f = 10 if st < 0.6 + 0.9 + 0.25 else 8
			volley_t -= delta
			if volley_t <= 0.0 and volley_left > 0 and st >= 0.45:
				volley_left -= 1; volley_t = 0.3
				var m := Missile.new(); m.walker = self; m.player = player
				var px: float = float(facing) * float(PODS[volley_left % 2])
				m.global_position = global_position + Vector2(px, -104.0)
				m.target_x = clampf(player.global_position.x + player.velocity.x * 0.4 + [-80.0, 0.0, 80.0][volley_left % 3], 40.0, 99999.0)   # leads a runner
				get_parent().add_child(m); Sfx.play("enemy_shoot", 0.5, 0.05)
				puffs.append([Vector2(px, -104.0), 0.0])
			if volley_left == 0 and st > 1.9:
				if fuse_mode: state = "walk"; cd = 1.0 / rage(); st = 0.0
				else: state = "vent"; st = 0.0; _toast("OPEN! HIT IT NOW!")
		"vent":
			f = 13
			if st >= (2.2 if fuse_mode else 2.5): state = "walk"; cd = 1.0 / rage(); st = 0.0
		"strafe":
			f = 13
			ship_t += delta
			if ship != null:
				ship.global_position.x = lerpf(global_position.x - 440.0, global_position.x + 440.0, clampf(ship_t / 2.2, 0.0, 1.0))
				bombs -= delta
				if bombs <= 0.0 and ship_t < 2.0:
					bombs = 0.35
					var fx := BlastFx.new(); fx.radius = 34.0; fx.global_position = global_position + Vector2(randf_range(-40, 40), -randf_range(20, 90))
					get_parent().add_child(fx); Sfx.play("explode", 0.9, 0.05)
					if ship_t > 0.4: hp = maxi(hp - 1, 1); flash = 0.12
				if ship_t >= 2.4: ship.queue_free(); ship = null
			if st >= 3.8: state = "walk"; cd = 1.0; st = 0.0
		"stomp":
			# lifts a leg (telegraph), then slams: anyone on the ground close to it is hit; jump over it
			if st < 0.6: f = 4
			else:
				f = 5
				if not stomped:
					stomped = true
					Sfx.play("explode", 0.7, 0.05)
					for sx in [-50.0, 50.0]:
						var fx := BlastFx.new(); fx.radius = 18.0; fx.global_position = global_position + Vector2(sx, -6.0); get_parent().add_child(fx)
					if player.is_on_floor() and absf(player.global_position.x - global_position.x) < stomp_dist + 15.0: player.take_hit(global_position.x)
				if st >= 1.0: state = "walk"; cd = 1.2 / rage(); st = 0.0
		"dying":
			f = 12 if st < 0.6 else (13 if st < 1.2 else 14)
			if int(st * 7.0) != int((st - delta) * 7.0):
				var fx := BlastFx.new(); fx.radius = randf_range(18.0, 34.0); fx.global_position = global_position + Vector2(randf_range(-45, 45), -randf_range(10, 95))
				get_parent().add_child(fx); Sfx.play("explode", randf_range(0.7, 1.1), 0.05)
			if st >= 2.0: state = "dead"; Sfx.play("enemy_die", 0.5)
		"dead":
			f = 15
	sprite.texture = tex[f]
	sprite.flip_h = facing < 0   # the art faces right
	sprite.position = Vector2(-AX, -H) if facing > 0 else Vector2(-(W - AX), -H)
	sprite.modulate = Color(3, 3, 3) if flash > 0.0 else (Color(1.0, 0.85, 0.7) if _open() else Color(1, 1, 1))
	if _open() and state == "vent": sprite.position.x += randf_range(-1.0, 1.0)
	if muzzle_t > 0.0: sprite.position.x -= facing * 2.0   # recoil
	queue_redraw()

## Fuse's planted charges: it blows when the Strider's feet pass over one. Stuns it for a moment (the vent pose).
func _check_charges() -> void:
	for sp in get_tree().get_nodes_in_group("charge_spots"):
		if sp.planted and absf(sp.global_position.x - global_position.x) < 36.0:
			sp.planted = false; sp.queue_redraw()
			var lv := get_tree().current_scene
			if lv != null and "freed" in lv: lv.freed = maxi(lv.freed - 1, 0)
			for off in [-22.0, 0.0, 22.0]:
				var fx := BlastFx.new(); fx.radius = 40.0 if off == 0.0 else 26.0; fx.global_position = sp.global_position + Vector2(off, -8.0); get_parent().add_child(fx)
			Sfx.play("explode", 0.7, 0.04)
			hp -= charge_dmg; flash = 0.2
			if hp <= 0: hp = 0; _die(); return
			state = "vent"; st = 0.0; _toast("DIRECT HIT!")
			return

## 1.0 at full health, up to 1.7 near death: it walks, shoots and recovers faster the more you hurt it.
func rage() -> float:
	return 1.0 + 0.7 * (1.0 - clampf(float(hp) / float(max_hp), 0.0, 1.0))

func _pick_attack(dx: float) -> void:
	st = 0.0
	if absf(dx) < stomp_dist:
		state = "stomp"; stomped = false; return
	if missiles_next or randf() < 0.3 + 0.3 * (rage() - 1.0) / 0.7:
		missiles_next = false
		state = "missiles"; volley_left = 3; volley_t = 0.5; return
	state = "guns"; shots_left = 4 + (1 if rage() > 1.35 else 0); shot_t = 0.5 / rage()
	missiles_next = randf() < 0.5

func _draw() -> void:
	if state == "dying" or state == "dead": return
	var w := 70.0
	draw_rect(Rect2(-w / 2.0, -H - 10.0, w, 4.0), Color(0.1, 0.05, 0.05, 0.8))
	draw_rect(Rect2(-w / 2.0 + 1.0, -H - 9.0, (w - 2.0) * float(hp) / float(max_hp), 2.0), Color(0.95, 0.35, 0.25))
	if muzzle_t > 0.0:
		var f := float(facing); var m := Vector2(f * MUZZLE.x, MUZZLE.y); var k := muzzle_t / 0.09
		var l := 22.0 + randf() * 8.0
		draw_colored_polygon(PackedVector2Array([m + Vector2(0, -7) * k, m + Vector2(f * l, 0), m + Vector2(0, 7) * k, m + Vector2(-f * 3.0, 0)]), Color(1.0, 0.55, 0.15, 0.95))
		draw_colored_polygon(PackedVector2Array([m + Vector2(0, -4) * k, m + Vector2(f * l * 0.7, 0), m + Vector2(0, 4) * k]), Color(1.0, 0.85, 0.35, 1.0))
		draw_circle(m + Vector2(f * 3.0, 0), 3.0 * k + 1.0, Color(1, 1, 0.9))
		for sp in [[-1.0, 0.5], [1.0, 0.8], [0.2, 1.0]]:
			draw_rect(Rect2(m + Vector2(f * (10.0 + 18.0 * sp[1] * (1.0 - k)), sp[0] * 9.0 * (1.0 - k)), Vector2(2, 2)), Color(1.0, 0.8, 0.3))
	for pf in puffs:
		var a: float = pf[1] / 0.7
		draw_circle(pf[0] + Vector2(0, -pf[1] * 30.0), 3.0 + a * 7.0, Color(0.8, 0.8, 0.82, 0.55 * (1.0 - a)))
	if state == "vent":
		for i in 5:
			var t := fmod(st * 1.5 + i * 0.2, 1.0)
			draw_circle(Vector2(-20.0 + i * 10.0, -H + 18.0 - t * 30.0), 3.0 + t * 4.0, Color(0.85, 0.9, 0.95, 0.5 * (1.0 - t)))

## A walker missile: climbs, hangs over its target, then dives. The red ring on the ground is where it lands (and explodes, radius ~30).
class Missile extends Node2D:
	var walker: Walker
	var player: Player
	var target_x := 0.0
	var t := 0.0
	var start := Vector2.ZERO
	var mark: Node2D
	const RISE := 0.55
	const FALL := 0.5
	func _ready() -> void:
		z_index = 5; start = global_position
		mark = Node2D.new(); mark.z_index = 1; mark.set_script(MarkDraw)
		get_parent().add_child(mark); mark.global_position = Vector2(target_x, GROUND_Y)
	func _physics_process(d: float) -> void:
		t += d
		if t < RISE:
			var k := t / RISE
			global_position = Vector2(lerpf(start.x, target_x, k * 0.6), start.y - 150.0 * sin(k * PI * 0.5))
		elif t < RISE + 0.35:
			global_position.x = lerpf(global_position.x, target_x, 0.2)
		else:
			var k := (t - RISE - 0.35) / FALL
			global_position = Vector2(target_x, lerpf(start.y - 150.0, GROUND_Y - 4.0, minf(k * k, 1.0)))
			if k >= 1.0: _boom(); return
		queue_redraw()
	func _boom() -> void:
		var fx := BlastFx.new(); fx.radius = 34.0; fx.global_position = Vector2(target_x, GROUND_Y - 14.0); get_parent().add_child(fx)
		Sfx.play("explode", 0.9, 0.05)
		if player != null and player.hp > 0 and player.hurtbox().intersects(Rect2(target_x - 28.0, GROUND_Y - 58.0, 56.0, 60.0)): player.take_hit(target_x)
		if is_instance_valid(mark): mark.queue_free()
		queue_free()
	func _draw() -> void:
		draw_rect(Rect2(-2, -8, 4, 12), Color(0.85, 0.85, 0.8))
		draw_rect(Rect2(-2, -10, 4, 3), Color(0.8, 0.2, 0.15))
		draw_rect(Rect2(-1, 4, 2, 5 + randi() % 4), Color(1.0, 0.7, 0.25))
