class_name BikeFoe
extends Node2D
## Everything that comes at you on the highway:
##  wreck / barrier -- stay in a lane, steer around them        pip   -- a heart to ride through
##  bike  -- a Warden bike: rides up, telegraphs, fires a slug along its lane (change lanes!)
##  ram   -- a fast bike from behind: warning arrows on the left edge, then it blasts through that lane
##  swoop -- a Shrike dives in and skims one lane           boss -- the Shrike itself
var kind := "bike"
var lane := 1
var level: BikeLevel
var hp := 3
var t := 0.0
var st := 0.0
var state := "enter"
var vx := 0.0
var target_x := 380.0
var cooldown := 1.2
var wind := -1.0
var flash := 0.0
var hit_done := false
var spr: Sprite2D
var hw := 20.0
var lane_y := 238.0
var pattern := 0
var shots_left := 0
var warn_lane := 1
var fire_t := 0.0

func _ready() -> void:
	lane_y = BikePlayer.LANES[lane]
	spr = Sprite2D.new(); spr.centered = false; add_child(spr)
	match kind:
		"wreck":
			spr.texture = load("res://assets/road_wreck.png"); spr.position = Vector2(-24, -26); hw = 22.0
			position = Vector2(520, lane_y)
		"barrier":
			spr.texture = load("res://assets/road_barrier.png"); spr.position = Vector2(-15, -22); hw = 14.0
			position = Vector2(520, lane_y)
		"pip":
			position = Vector2(520, lane_y - 18)
		"bike":
			spr.texture = load("res://assets/warden_bike.png"); spr.position = Vector2(-42, -64); hw = 30.0
			position = Vector2(520, lane_y); vx = -170.0; target_x = 300.0 + randf() * 110.0; hp = 3; cooldown = 0.3
			add_to_group("foes")
		"ram":
			spr.texture = load("res://assets/warden_bike.png"); spr.flip_h = true; spr.position = Vector2(-60, -64); hw = 30.0
			position = Vector2(-70, lane_y); state = "warn"; hp = 1
			add_to_group("foes")
		"swoop":
			spr.texture = load("res://assets/shrike.png"); spr.position = Vector2(-50, -64); hw = 38.0
			position = Vector2(560, lane_y - 170); state = "warn"; hp = 2
			add_to_group("foes")
		"boss":
			spr.texture = load("res://assets/shrike.png"); spr.position = Vector2(-50, -64); hw = 38.0
			position = Vector2(600, lane_y); hp = 18; state = "enter"
			add_to_group("foes")

func accepts(bx: float, by: float) -> bool:
	if not is_in_group("foes") or hp <= 0: return false
	if kind == "boss" and state == "enter": return false   # not a target until he's fully in view and ready
	return absf(position.y - by) < 12.0 and absf(position.x - bx) < hw + 6.0 and bx > 0.0

func hurt(dmg: int) -> void:
	hp -= dmg; flash = 0.1
	Sfx.play("explode" if hp <= 0 else "enemy_hit", 1.0, 0.06)
	if hp <= 0:
		level.kills += 1
		level.burst(position + Vector2(0, -22))
		if kind == "boss": level.boss_down()
		queue_free()

func _shoot(k: String, ly: float) -> void:
	Sfx.play("enemy_shoot", 1.0, 0.05)
	var s := BikeShot.new()
	s.kind = k; s.player = level.player
	s.position = Vector2(position.x - 40.0, ly)
	level.add_child(s)

func _touch_player() -> void:
	var p := level.player
	if p.hp > 0 and p.in_lane(position.y) and absf(p.position.x - position.x) < hw + 14.0:
		p.take_hit()

func _process(d: float) -> void:
	t += d; st += d
	flash = maxf(flash - d, 0.0)
	var p := level.player
	match kind:
		"wreck", "barrier":
			position.x -= BikeLevel.SCROLL * d
			if not hit_done and p.hp > 0 and p.in_lane(position.y) and absf(p.position.x - position.x) < hw + 14.0:
				hit_done = true; p.take_hit()
		"pip":
			position.x -= BikeLevel.SCROLL * d
			if p.hp > 0 and p.hp < p.max_hp and p.in_lane(lane_y) and absf(p.position.x - position.x) < 24.0:
				p.hp += 1; Sfx.play("pickup"); queue_free(); return
		"bike": _bike(d, p)
		"ram": _ram(d)
		"swoop": _swoop(d)
		"boss": _boss(d, p)
	if kind != "boss" and kind != "swoop": z_index = int(position.y) + (0 if kind == "pip" else 0)
	else: z_index = int(lane_y) + 2
	if kind == "pip" or kind == "wreck" or kind == "barrier" or kind == "bike" or kind == "ram" or kind == "swoop":
		if position.x < -120.0 and kind != "ram": queue_free(); return
	if spr.texture != null:
		spr.modulate = Color(3, 3, 3) if flash > 0.0 else (Color(1.6, 1.25, 0.8) if wind >= 0.0 else Color.WHITE)
	queue_redraw()

func _bike(d: float, p: BikePlayer) -> void:
	match state:
		"enter":
			position.x += vx * d
			if position.x <= target_x:
				state = "ride"; st = 0.0
		"ride":
			position.x += (sin(t * 1.3) * 12.0 - 0.0) * d           # drift a little
			if wind < 0.0:
				cooldown -= d
				if cooldown <= 0.0:
					if randf() < 0.45 and p.lane != lane:       # sometimes slides into your lane before firing
						lane = p.lane; lane_y = BikePlayer.LANES[lane]
					wind = 0.0
			else:
				wind += d
				if wind >= 0.45:
					wind = -1.0; cooldown = 1.5 + randf() * 0.6
					_shoot("slug", lane_y)
			if st > 11.0 and wind < 0.0:
				state = "leave"
		"leave":
			position.x += 150.0 * d
			if position.x > 560.0: queue_free(); return
	position.y = move_toward(position.y, lane_y, 200.0 * d)
	_touch_player()

func _ram(d: float) -> void:
	if state == "warn":
		if st >= 1.1:
			state = "go"; vx = 300.0
	else:
		position.x += vx * d
		_touch_player()
		if position.x > 580.0: queue_free()

func _swoop(d: float) -> void:
	if state == "warn":
		if st >= 0.9:
			state = "go"; st = 0.0
		return
	position.x -= 270.0 * d
	var k := clampf((560.0 - position.x) / 320.0, 0.0, 1.0)
	position.y = lerpf(lane_y - 170.0, lane_y, k)
	if position.x < 440.0 and not hit_done:
		hit_done = true; _shoot("slug", lane_y)
	if k >= 1.0: _touch_player()
	if position.x < -90.0: queue_free()

func _boss(d: float, p: BikePlayer) -> void:
	match state:
		"enter":
			position.x -= 120.0 * d
			if position.x <= 390.0:
				state = "hover"; st = 0.0; cooldown = 0.8
		"hover":
			position.y = move_toward(position.y, lane_y, 160.0 * d)
			position.x = 390.0 + sin(t * 1.2) * 18.0
			cooldown -= d
			if cooldown <= 0.0:
				pattern = (pattern + 1) % 4
				if pattern == 0 or pattern == 2:
					lane = p.lane; lane_y = BikePlayer.LANES[lane]; state = "strafe"; st = 0.0
				elif pattern == 1:
					state = "triple"; st = 0.0; shots_left = 3
					lane = (p.lane + 1) % 3; lane_y = BikePlayer.LANES[lane]
				else:
					lane = p.lane; lane_y = BikePlayer.LANES[lane]; state = "dive_warn"; st = 0.0
		"strafe":
			position.y = move_toward(position.y, lane_y, 220.0 * d)
			wind = st
			if st >= 1.0:
				wind = -1.0; _shoot("beam", lane_y); state = "hover"; cooldown = 1.4
		"triple":
			position.y = move_toward(position.y, lane_y, 260.0 * d)
			if st >= 0.55:
				st = 0.0; _shoot("slug", lane_y); shots_left -= 1
				lane = (lane + 1) % 3; lane_y = BikePlayer.LANES[lane]
				if shots_left <= 0: state = "hover"; cooldown = 1.5
		"dive_warn":
			position.y = move_toward(position.y, lane_y, 220.0 * d)
			wind = st
			if st >= 0.9:
				wind = -1.0; state = "dive"; st = 0.0
		"dive":
			position.x -= 380.0 * d
			_touch_player()
			if position.x < -90.0: state = "return"; st = 0.0
		"return":
			position.x = move_toward(position.x, 390.0, 220.0 * d)
			if position.x >= 389.0: state = "hover"; cooldown = 1.2
	if state != "dive" and state != "return" and state != "enter": _touch_player_soft()

func _touch_player_soft() -> void:
	pass

func _band(ly: float, x0: float, x1: float, a: float, col := Color(1.0, 0.3, 0.2)) -> void:
	col.a = a
	draw_rect(Rect2(x0 - position.x, ly - 19.0 - position.y, x1 - x0, 5), col)

func _draw() -> void:
	var blink := 0.35 + 0.35 * float(int(Time.get_ticks_msec() / 90.0) % 2)
	match kind:
		"pip":
			var bob := sin(t * 3.0) * 2.0
			draw_circle(Vector2(0, bob), 10.0, Color(1.0, 0.8, 0.3, 0.3))
			draw_rect(Rect2(-6, bob - 6, 12, 12), Color(0.1, 0.07, 0.12)); draw_rect(Rect2(-5, bob - 5, 10, 10), Color(0.95, 0.72, 0.25)); draw_rect(Rect2(-4, bob - 4, 4, 3), Color(1, 0.93, 0.7))
		"bike":
			if wind >= 0.0: _band(lane_y, 0.0, position.x - 28.0, blink)
		"ram":
			if state == "warn":
				var ax := 18.0 - position.x
				for i in 3:
					draw_rect(Rect2(ax + i * 12, -22 + 0, 8, 3), Color(1, 0.3, 0.2, blink + 0.3)); draw_rect(Rect2(ax + i * 12 + 4, -20, 4, 3), Color(1, 0.3, 0.2, blink + 0.3))
				_band(lane_y, 0.0, 70.0, blink * 0.7)
		"swoop":
			if state == "warn": _band(lane_y, 0.0, 480.0, blink * 0.6)
			draw_circle(Vector2(0, lane_y - position.y - 2), 0.1, Color.TRANSPARENT)
			draw_rect(Rect2(-20, lane_y - position.y - 3, 40, 4), Color(0, 0, 0, 0.35))   # shadow marks the lane
		"boss":
			draw_rect(Rect2(-24, lane_y - position.y - 3, 48, 4), Color(0, 0, 0, 0.35))
			if state == "strafe" or state == "dive_warn": _band(lane_y, 0.0, position.x - 30.0, blink * 0.8)
