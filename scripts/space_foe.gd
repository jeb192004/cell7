class_name SpaceFoe
extends Node2D
## Things in the asteroid belt:
##  rock_s / rock_m / rock_l -- drifting asteroids (shoot or dodge)    pip -- a heart to fly through
##  shrike -- patterns: line (straight pass), weave (wavy), strafe (parks on the right, tracks you, fires)
##  ace -- the Shrike ace: tough, tracks you, fires spreads after a flash
var kind := "rock_m"
var pat := "line"
var level: SpaceLevel
var r := 12.0
var hp := 2
var vel := Vector2(-90, 0)
var y0 := 135.0
var t := 0.0
var cooldown := 1.0
var flash := 0.0
var spin := 0.0
var rot := 0.0
var pts: PackedVector2Array
var tele := 0.0
var shots := 0
var shootable := true
var spr: Sprite2D
var leaving := false

func _ready() -> void:
	add_to_group("sfoes")
	y0 = position.y
	z_index = 3
	match kind:
		"rock_s": r = 8.0; hp = 1
		"rock_m": r = 14.0; hp = 2
		"rock_l": r = 22.0; hp = 4
		"pip": r = 9.0; hp = 99; shootable = false
		"shrike":
			r = 18.0; hp = 2
			spr = Sprite2D.new(); spr.texture = load("res://assets/shrike.png"); spr.centered = false; spr.position = Vector2(-44, -17); add_child(spr)
		"ace":
			r = 34.0; hp = 24
			spr = Sprite2D.new(); spr.texture = load("res://assets/shrike_big.png"); spr.centered = false; spr.position = Vector2(-62, -24); add_child(spr)
	if kind.begins_with("rock"):
		vel = Vector2(-randf_range(55.0, 110.0) * (1.2 if kind == "rock_s" else 1.0), randf_range(-14.0, 14.0))
		spin = randf_range(-1.6, 1.6)
		spr = Sprite2D.new(); spr.texture = load("res://assets/%s.png" % kind); spr.hframes = 16
		spr.frame = randi() % 16; rot = float(spr.frame)
		add_child(spr)
	elif kind == "pip":
		vel = Vector2(-60, 0)
	elif kind == "shrike":
		match pat:
			"line": vel = Vector2(-120, 0); cooldown = 0.9
			"weave": vel = Vector2(-85, 0); cooldown = 1.1
			"strafe": vel = Vector2(-200, 0); cooldown = 1.0
	elif kind == "ace":
		vel = Vector2(-90, 0); cooldown = 2.0

func hurt(d: int) -> void:
	hp -= d; flash = 0.1
	Sfx.play("explode" if hp <= 0 else "enemy_hit", 1.0, 0.06)
	if hp <= 0:
		level.burst(position, r)
		if kind == "ace": level.boss_down()
		if kind == "shrike": level.kills += 1
		queue_free()

func _fire(v: Vector2, from: Vector2 = Vector2.ZERO) -> void:
	Sfx.play("enemy_shoot", 1.2, 0.05)
	var s := SpaceShot.new(); s.vel = v; s.player = level.player; s.position = position + from
	level.add_child(s)

func _process(d: float) -> void:
	if level.player.hp <= 0: return
	t += d
	flash = maxf(flash - d, 0.0)
	var p := level.player
	match kind:
		"shrike": _shrike(d, p)
		"ace": _ace(d, p)
		_: position += vel * d
	if kind.begins_with("rock"):
		rot = fposmod(rot + spin * d * 16.0 / TAU, 16.0)
		spr.frame = int(rot) % 16
	if spr != null:
		spr.modulate = Color(3, 3, 3) if flash > 0.0 else (Color(1.6, 1.2, 0.8) if tele > 0.0 else Color.WHITE)
	# touching the player
	if p.hp > 0 and p.dist_to(position) < r - 2.0:
		if kind == "pip":
			p.heal(); Sfx.play("pickup"); level.toast("+1"); queue_free(); return
		p.take_hit()
		if kind == "rock_s": hurt(9)
	if position.x < -70.0 or (position.x > 560.0 and kind != "ace") or position.y < -60.0 or position.y > 330.0: queue_free()
	queue_redraw()

func _shrike(d: float, p: SpacePlayer) -> void:
	match pat:
		"line":
			position += vel * d
		"weave":
			position.x += vel.x * d; position.y = y0 + sin(t * 2.6) * 42.0
		"strafe":
			if not leaving:
				if position.x > 385.0: position.x += vel.x * d
				position.y = move_toward(position.y, p.position.y, 55.0 * d)
				if t > 9.0: leaving = true
			else:
				position.x += 150.0 * d
	cooldown -= d
	if cooldown <= 0.0 and position.x < 470.0 and position.x > 40.0 and not leaving:
		_fire(Vector2(-230, 0), Vector2(-46, 0))
		cooldown = 1.5 if pat != "strafe" else 1.1

func _ace(d: float, p: SpacePlayer) -> void:
	if position.x > 360.0 and not leaving:
		position.x += vel.x * d
	position.y = move_toward(position.y, clampf(p.position.y, 50.0, 220.0), 42.0 * d)
	cooldown -= d
	if tele > 0.0:
		tele -= d
		if tele <= 0.0:
			shots += 1
			var base := (p.position - position).normalized()
			if shots % 3 == 0:   # aimed burst
				for a in [-0.12, 0.0, 0.12]: _fire(base.rotated(a) * 250.0, Vector2(-68, 0))
			else:                # fan
				for a in [-0.35, -0.17, 0.0, 0.17, 0.35]: _fire(Vector2(-1, 0).rotated(a) * 215.0, Vector2(-68, 0))
	elif cooldown <= 0.0 and position.x < 400.0:
		tele = 0.45; cooldown = 2.0

func _draw() -> void:
	if kind == "pip":
		var bob := sin(t * 5.0) * 2.0
		draw_rect(Rect2(-7, -7 + bob, 14, 14), Color(0.1, 0.07, 0.12)); draw_rect(Rect2(-6, -6 + bob, 12, 12), Color(0.95, 0.72, 0.25)); draw_rect(Rect2(-4, -4 + bob, 5, 3), Color(1, 0.93, 0.7))
	elif kind == "ace" and tele > 0.0:
		draw_rect(Rect2(-r - 60, -2, 60, 4), Color(1, 0.3, 0.2, 0.5))   # muzzle charge
