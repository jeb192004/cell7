class_name Enemy
extends Node2D
## Warden: patrols, sees in a cone in front of him. Spotted -> "!" then he fires slugs (high = duck, low = jump
## or take cover). Lose him behind a crate for a few seconds and he goes back to patrolling.
## Drone: hovers, shakes, then dives at where Kesh was. Can't see a concealed Kesh.
signal defeated
const GROUND_Y := 222.0
const SIGHT := 230.0   # how far a Warden sees (the cone). Kesh's shots reach less than this, so you have to step into his sight to hit him
const LOSE_TIME := 2.5
const SHIELD_HITS := 6   # shots the shield soaks before it breaks
const TURN_TIME := 0.2   # shield Warden needs this long to turn around
const SPOT_TIME := 0.2   # how long he has to see you before he reacts
@export var kind := "warden"               # "warden" or "drone" (set by the scene)
@export var shield := false               # riot shield: blocks bolts from the front, turns slowly -- get behind him
@export var patrol_range := 70.0           # how far a Warden walks either side of where you placed him
@export_enum("Left:-1", "Right:1") var start_facing := -1
var hp := 3
var sprite: Sprite2D
var player: Player
var base_y := 0.0
var t := 0.0
var flash := 0.0
# warden
var facing := -1
var alerted := false
var alert_t := 0.0     # pause + "!" after spotting Kesh
var lost_t := 0.0
var see_t := 0.0      # time since last seen; "?" while searching
var home_x := 0.0
var patrol_dir := -1
var pause_t := 0.0
var cooldown := 1.2
var wind := -1.0
var next_kind := "high"
var crouched := false
var linger := 0.0
# where the Warden's slug appears, relative to his feet (x is mirrored when he faces left; negative y is up)
const MUZZLE_X := 27.0
const MUZZLE_HIGH := -36.0   # standing rifle
const MUZZLE_LOW := -28.0    # kneeling rifle
var frames := {}
var walk_frames: Array = []   # walk cycle (shield or not)
var walk_t := 0.0
var last_x := 0.0
var flash_t := 0.0
var last_kind := "high"
var turn_t := 0.0
var bound_min := -INF   # a Warden on a rooftop stays on it
var bound_max := INF
var bounds_set := false
var spark_t := 0.0
var shards: Array = []   # [pos, vel, life] -- the shattered shield
var burst_t := 0.0
# drone
var shield_hp := SHIELD_HITS
var state := "hover"   # hover, wind, dive, retreat
var st := 0.0
var dive_to := Vector2.ZERO

func _ready() -> void:
	add_to_group("enemies")
	sprite = get_node_or_null("Sprite") as Sprite2D
	if sprite == null:
		sprite = Sprite2D.new()
		sprite.name = "Sprite"
		add_child(sprite)
	sprite.centered = false
	if kind == "warden":
		facing = start_facing
		patrol_dir = start_facing
		if shield: hp = 4
		for n in ["ready", "aim", "fire", "caim", "cfire"]:
			frames[n] = load("res://assets/warden_%s%s.png" % ["s_" if shield else "", n])
		_load_walk()
		sprite.texture = frames["ready"]
		sprite.position = Vector2(-18, -56)
		last_x = position.x
		home_x = position.x
	else:
		sprite.texture = load("res://assets/%s.png" % kind)
		var sz := sprite.texture.get_size()
		sprite.position = Vector2(-sz.x / 2.0, -sz.y)
		hp = 1
		base_y = position.y
	t = randf() * 6.0
	cooldown = 0.6

func hit_rect() -> Rect2:
	var sz := Vector2(36, 56) if kind == "warden" else sprite.texture.get_size()
	if crouched: sz.y = 40.0
	return Rect2(global_position + Vector2(-sz.x / 2.0, -sz.y), sz)

func hurt(d: int) -> void:
	hp -= d; flash = 0.12
	Sfx.play("enemy_die" if hp <= 0 else "enemy_hit", 1.0, 0.06)
	if kind == "warden" and not alerted:
		_spot(player.global_position.x - global_position.x)   # getting shot wakes him up
	if hp <= 0:
		defeated.emit()
		queue_free()

## True when a bolt travelling in `bdir` runs into the shield (it's coming at his front).
func blocks(bdir: float) -> bool:
	if kind != "warden" or not shield or turn_t > 0.0: return false
	if signf(bdir) == float(facing): return false
	spark_t = 0.12
	Sfx.play("shield_block", 1.0, 0.08)
	shield_hp -= 1
	if shield_hp <= 0: _break_shield()
	return true

## Enough shots on the shield and it shatters: he's a regular Warden from then on.
func _break_shield() -> void:
	var sx := float(facing) * 20.0
	for i in 14:
		var a := randf() * TAU
		shards.append([Vector2(sx, -30.0 + randf_range(-18, 18)), Vector2(cos(a) * randf_range(40, 130) + float(facing) * 40.0, sin(a) * randf_range(40, 130) - 60.0), randf_range(0.5, 0.9)])
	burst_t = 0.25
	Sfx.play("shield_break")
	shield = false; turn_t = 0.0; flash = 0.3
	hp = 3
	for n in ["ready", "aim", "fire", "caim", "cfire"]:
		frames[n] = load("res://assets/warden_%s.png" % n)
	_load_walk()
	sprite.texture = frames["ready"]
	if player: facing = 1 if player.global_position.x >= global_position.x else -1
	cooldown = minf(cooldown, 0.3)

func _load_walk() -> void:
	walk_frames.clear()
	for i in 8: walk_frames.append(load("res://assets/warden_%swalk_%d.png" % ["s_" if shield else "", i]))

func _face(dir: int) -> void:
	if dir == facing or not shield:
		facing = dir; turn_t = 0.0
		return
	turn_t += get_physics_process_delta_time()
	if turn_t >= TURN_TIME:
		facing = dir; turn_t = 0.0

func _spot(dx: float) -> void:
	if not alerted: Sfx.play("spot")
	alerted = true; alert_t = 0.35; lost_t = 0.0
	cooldown = minf(cooldown, 0.15)   # first shot comes quickly after he spots you
	if not shield: facing = 1 if dx >= 0.0 else -1

func _sees(dx: float) -> bool:
	if player.concealed: return false
	if absf(dx) > SIGHT: return false
	if (1 if dx >= 0.0 else -1) != facing: return false
	if Barrier.blocks_line(get_tree(), global_position - Vector2(0, 20), player.global_position - Vector2(0, 20)): return false
	return absf(player.global_position.y - global_position.y) < 70.0

func _find_roof() -> void:
	bounds_set = true
	if kind != "warden" or position.y > 215.0: return
	# A Warden placed over a roof (within 40 px of its top) snaps to that roof and patrols only on it,
	# so you can move / resize roofs in the editor and just keep the Warden's X over the roof.
	var best = null; var best_d := 41.0
	for r in get_tree().get_nodes_in_group("roofs"):
		if absf(r.global_position.x - global_position.x) >= r.width / 2.0: continue
		var dd := absf(r.global_position.y - r.height - global_position.y)
		if dd < best_d: best_d = dd; best = r
	if best != null:
		global_position.y = best.global_position.y - best.height
		bound_min = best.global_position.x - best.width / 2.0 + 14.0
		bound_max = best.global_position.x + best.width / 2.0 - 14.0

func _physics_process(delta: float) -> void:
	if not bounds_set: _find_roof()
	t += delta
	flash = maxf(flash - delta, 0.0)
	spark_t = maxf(spark_t - delta, 0.0)
	burst_t = maxf(burst_t - delta, 0.0)
	for sh in shards:
		sh[1].y += 400.0 * delta; sh[0] += sh[1] * delta; sh[2] -= delta
	shards = shards.filter(func(sh): return sh[2] > 0.0)
	if player == null: return
	var dx := player.global_position.x - global_position.x
	if kind == "warden":
		_warden(delta, dx)
		position.x = clampf(position.x, bound_min, bound_max)
	else:
		sprite.flip_h = dx < 0.0
		_drone(delta, dx)
	var tint := Color.WHITE
	if flash > 0.0: tint = Color(3, 3, 3)
	elif wind >= 0.0: tint = Color(1.6, 1.25, 0.8)
	sprite.modulate = tint
	if hit_rect().grow(-6).intersects(player.hurtbox()):
		player.take_hit(global_position.x)
	queue_redraw()

func _warden(delta: float, dx: float) -> void:
	var d := absf(dx)
	linger = maxf(linger - delta, 0.0)
	flash_t = maxf(flash_t - delta, 0.0)
	crouched = (wind >= 0.0 and next_kind == "low") or linger > 0.0
	if _sees(dx):
		lost_t = 0.0
		see_t += delta
		if not alerted and see_t >= SPOT_TIME:
			_spot(dx)
	else:
		see_t = maxf(see_t - delta * 2.0, 0.0)
	# once alerted he keeps tracking you (even from behind) until you hide behind cover or get well away
	var tracking := alerted and not player.concealed and d < 320.0 and absf(player.global_position.y - global_position.y) < 70.0
	if alerted and not _sees(dx) and not tracking:
		lost_t += delta
		if lost_t > LOSE_TIME and wind < 0.0:
			alerted = false; pause_t = 0.8   # gives up, back to patrol
	if alerted:
		if shield and wind < 0.0 and lost_t == 0.0: _face(1 if dx >= 0.0 else -1)
		if alert_t > 0.0:
			alert_t -= delta
		elif wind < 0.0 and lost_t == 0.0:
			if not shield: facing = 1 if dx >= 0.0 else -1
			if d < 230.0 and d > (95.0 if shield else 150.0) and not _barrier_ahead(facing):
				position.x += facing * 24.0 * delta
	else:
		_patrol(delta)
	sprite.flip_h = facing < 0
	var f := "ready"
	if flash_t > 0.0:
		f = "cfire" if last_kind == "low" else "fire"
	elif wind >= 0.0:
		f = "caim" if next_kind == "low" else "aim"
	elif linger > 0.0:
		f = "caim"
	var moving := absf(position.x - last_x) > 0.02
	last_x = position.x
	if moving: walk_t += delta
	else: walk_t = 0.0
	if f == "ready" and moving and not walk_frames.is_empty():
		sprite.texture = walk_frames[int(walk_t * 8.0) % walk_frames.size()]
	else:
		sprite.texture = frames[f]
	# the Warden's hood sits 21px in from the left of the art (room on the right for the rifle and flash); keep him centred when flipped
	sprite.position.x = (18.0 - sprite.texture.get_width()) if sprite.flip_h else -18.0
	if wind >= 0.0:
		wind += delta
		if wind >= 0.45:
			wind = -1.0
			cooldown = 1.5 + randf() * 0.7
			last_kind = next_kind
			linger = 0.3 if next_kind == "low" else 0.0
			flash_t = 0.12
			var s := EnemyShot.new()
			s.kind = next_kind; s.dir = float(facing); s.player = player
			Sfx.play("enemy_shoot", 1.0, 0.05)
			# the slug leaves the rifle at the muzzle (change MUZZLE_* below to move it) and flies straight
			s.global_position = global_position + Vector2(facing * MUZZLE_X, MUZZLE_HIGH if next_kind == "high" else MUZZLE_LOW)
			get_parent().add_child(s)
			next_kind = "low" if next_kind == "high" and randf() < 0.55 else ("high" if randf() < 0.6 else "low")
	elif alerted and alert_t <= 0.0 and lost_t == 0.0 and d < 240.0 and (1 if dx >= 0.0 else -1) == facing:
		cooldown -= delta
		if cooldown <= 0.0:
			wind = 0.0

func _barrier_ahead(dir: int) -> bool:
	var pt := Vector2(global_position.x + dir * 14.0, global_position.y - 8.0)
	for c in get_tree().get_nodes_in_group("barriers"):
		if c.rect().has_point(pt): return true
	return false

func _patrol(delta: float) -> void:
	if pause_t > 0.0:
		pause_t -= delta
		return
	if _barrier_ahead(patrol_dir):
		patrol_dir = -patrol_dir; pause_t = 0.9   # a solid crate in the way: turn around
		return
	position.x += patrol_dir * 22.0 * delta
	facing = patrol_dir
	if absf(position.x - home_x) > patrol_range and signf(position.x - home_x) == float(patrol_dir):
		patrol_dir = -patrol_dir
		pause_t = 0.9

func _drone(delta: float, dx: float) -> void:
	st += delta
	var sees := not player.concealed
	match state:
		"hover":
			position.y = base_y + sin(t * 2.0) * 5.0
			if sees and absf(dx) < 210.0 and absf(dx) > 60.0:
				position.x += signf(dx) * 38.0 * delta
			if sees and absf(dx) < 110.0 and st > 1.0:
				state = "wind"; st = 0.0
		"wind":
			position.x += sin(st * 60.0) * 0.6
			wind = st
			if st > 0.45:
				state = "dive"; st = 0.0; wind = -1.0
				dive_to = player.global_position + Vector2(0, -14)
		"dive":
			var dir := (dive_to - global_position).normalized()
			global_position += dir * 190.0 * delta
			if global_position.distance_to(dive_to) < 6.0 or st > 0.9:
				state = "retreat"; st = 0.0
		"retreat":
			position.y = move_toward(position.y, base_y, 90.0 * delta)
			if absf(position.y - base_y) < 2.0:
				state = "hover"; st = 0.0

func _draw() -> void:
	if kind != "warden": return
	if burst_t > 0.0:   # flash as the shield goes
		var r := (0.25 - burst_t) * 160.0 + 8.0
		draw_arc(Vector2(float(facing) * 20.0, -30), r, 0, TAU, 20, Color(1, 0.9, 0.5, burst_t * 4.0), 2.0)
	for sh in shards:
		var c := Color(0.75, 0.85, 1.0, clampf(sh[2] * 2.0, 0.0, 1.0)) if int(sh[2] * 20.0) % 2 == 0 else Color(1, 0.85, 0.4, clampf(sh[2] * 2.0, 0.0, 1.0))
		draw_rect(Rect2(sh[0], Vector2(3, 3)), c)
	if spark_t > 0.0:   # shot bounced off the shield
		var sx := float(facing) * 20.0
		draw_rect(Rect2(sx - 3, -36, 6, 6), Color(1, 0.95, 0.7)); draw_rect(Rect2(sx - 6, -40, 2, 2), Color(1, 0.8, 0.3)); draw_rect(Rect2(sx + 4, -28, 2, 2), Color(1, 0.8, 0.3))
	# sight cone from the visor
	var col := Color(1.0, 0.3, 0.2, 0.17) if alerted else Color(1.0, 0.95, 0.5, 0.13)
	var f := float(facing)
	draw_colored_polygon(PackedVector2Array([Vector2(f * 10.0, -42.0), Vector2(f * SIGHT, -78.0), Vector2(f * SIGHT, 8.0)]), col)
	# "!" when he spots you, "?" while he searches
	if alerted and alert_t > 0.0:
		draw_rect(Rect2(-2, -72, 4, 8), Color(0.1, 0.05, 0.1)); draw_rect(Rect2(-1, -71, 2, 4), Color(1.0, 0.35, 0.25)); draw_rect(Rect2(-1, -66, 2, 2), Color(1.0, 0.35, 0.25))
	elif alerted and lost_t > 0.0:
		draw_rect(Rect2(-3, -73, 6, 9), Color(0.1, 0.05, 0.1)); draw_rect(Rect2(-2, -72, 4, 2), Color(1, 0.85, 0.3)); draw_rect(Rect2(1, -70, 2, 2), Color(1, 0.85, 0.3)); draw_rect(Rect2(-1, -68, 2, 2), Color(1, 0.85, 0.3)); draw_rect(Rect2(-1, -65, 2, 1), Color(1, 0.85, 0.3))
