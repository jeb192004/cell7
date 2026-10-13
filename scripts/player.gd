class_name Player
extends CharacterBody2D
## Kesh. Origin is at his feet. Runs with the slingshot stowed, draws it only to shoot.

const RUN := 115.0
const SPRINT := 180.0
const SLIDE_SPEED := 190.0
const SLIDE_TIME := 0.45
const ACCEL := 900.0
const GRAV := 950.0
const JUMP_V := -320.0
const COYOTE := 0.09
const BUFFER := 0.1
const SHOOT_FPS := 14.0

var facing := 1
var coyote := 0.0
var buffer := 0.0
var slide_t := 0.0
var shoot_t := -1.0
var fired := false
var hurt_t := 0.0
var sprinting := false
var hp := 5
var max_hp := 5
var crouching := false
var forced_crouch := false   # set by the level inside vents: you have to crawl
var concealed := false
var vent: Vent = null        # the crawl space Kesh is inside (set by grates)
var in_vent: bool:
	get: return vent != null
var is_back := false      # in the back lane, behind a crate
var cover_ref: Cover = null
var down_hold := 0.0
const FALL_PIP := 150.0   # landing after falling further than this costs a pip
var peak_y := 0.0
var was_air := false
var roof_drop_t := 0.0
var drop_t := 0.0         # falling through a crate top
var leaving := false      # jumping out: stay behind the crate until Kesh is above it
var reveal_t := 0.0
const MAX_AMMO := 5.0
const AMMO_DELAY := 0.6   # seconds after your last shot before charges start coming back
const AMMO_RATE := 1.0    # charges per second
var ammo := MAX_AMMO
var since_shot := 9.0
var dry_t := 0.0
var sprite: AnimatedSprite2D
var shape: CollisionShape2D
var bolt_scene_parent: Node

func _ready() -> void:
	add_to_group("player")
	collision_mask = 7   # 1 = ground, 2 = crate tops (switched off behind crates), 3 = rooftops
	shape = CollisionShape2D.new()
	var r := RectangleShape2D.new(); r.size = Vector2(12, 42)
	shape.shape = r; shape.position = Vector2(0, -21)
	add_child(shape)
	sprite = AnimatedSprite2D.new()
	sprite.sprite_frames = _frames()
	sprite.position = Vector2(5, -23)
	add_child(sprite)
	sprite.play("idle")

func _frames() -> SpriteFrames:
	var sf := SpriteFrames.new()
	sf.remove_animation("default")
	_anim(sf, "idle", ["idle_0", "idle_1", "idle_2", "idle_3"], 4, true)
	_anim(sf, "walk", ["walk_0", "walk_1", "walk_2", "walk_3", "walk_4", "walk_5", "walk_6"], 6, true)
	_anim(sf, "run", ["run_0", "run_1", "run_2", "run_3", "run_4", "run_5", "run_6", "run_7", "run_8", "run_9", "run_10", "run_11", "run_12", "run_13"], 8, true)
	_anim(sf, "jump", ["jump_0", "jump_1"], 6, false)
	_anim(sf, "fall", ["jump_2"], 1, false)
	_anim(sf, "shoot", ["shoot_0", "shoot_1", "shoot_2", "shoot_3", "shoot_4"], SHOOT_FPS, false)
	_anim(sf, "slide", ["slide_0"], 1, false)
	_anim(sf, "crouch", ["crouch_0"], 1, false)
	_anim(sf, "cwalk", ["cwalk_0", "cwalk_1", "cwalk_2", "cwalk_3"], 5, true)
	_anim(sf, "cshoot", ["cshoot_0", "cshoot_1", "cshoot_2", "cshoot_3", "cshoot_4"], SHOOT_FPS, false)
	_anim(sf, "hit", ["hit_0", "hit_1"], 10, false)
	return sf

func _anim(sf: SpriteFrames, n: String, frames: Array, fps: float, loop: bool) -> void:
	sf.add_animation(n); sf.set_animation_speed(n, fps); sf.set_animation_loop(n, loop)
	for f in frames:
		sf.add_frame(n, load("res://assets/kesh_%s.png" % f))

func _physics_process(delta: float) -> void:
	var dir := Input.get_axis("left", "right")
	var on_floor := is_on_floor()
	coyote = COYOTE if on_floor else maxf(coyote - delta, 0.0)
	buffer = BUFFER if Input.is_action_just_pressed("jump") else maxf(buffer - delta, 0.0)
	hurt_t = maxf(hurt_t - delta, 0.0)
	reveal_t = maxf(reveal_t - delta, 0.0)
	dry_t = maxf(dry_t - delta, 0.0)
	since_shot += delta
	if since_shot > AMMO_DELAY: ammo = minf(ammo + AMMO_RATE * delta, MAX_AMMO)
	drop_t = maxf(drop_t - delta, 0.0)
	roof_drop_t = maxf(roof_drop_t - delta, 0.0)
	sprinting = Input.is_action_pressed("run")
	if Input.is_action_just_pressed("up") and on_floor and not is_back and shoot_t < 0.0 and slide_t <= 0.0:
		_use_grate()
	_lanes(on_floor)

	if on_floor and buffer > 0.0 and Input.is_action_pressed("down") and global_position.y < 215.0:
		if _crate_under_feet() != null:
			drop_t = 0.25   # Down + jump on a crate top: step off through it
		else:
			roof_drop_t = 0.25   # Down + jump on a rooftop: drop to what's below
		buffer = 0.0; coyote = 0.0
		position.y += 2.0
	if not on_floor:
		velocity.y += GRAV * delta
	if buffer > 0.0 and coyote > 0.0 and slide_t <= 0.0 and not forced_crouch:
		velocity.y = JUMP_V; buffer = 0.0; coyote = 0.0
		Sfx.play("jump")
	if Input.is_action_just_released("jump") and velocity.y < -110.0 and not leaving:
		velocity.y = -110.0   # tap = short hop

	if Input.is_action_just_pressed("slide") and on_floor and slide_t <= 0.0 and not is_back and not forced_crouch:
		slide_t = SLIDE_TIME
		Sfx.play("slide")
		if dir != 0.0: facing = 1 if dir > 0.0 else -1
	if slide_t > 0.0:
		slide_t -= delta
		velocity.x = SLIDE_SPEED * facing
		(shape.shape as RectangleShape2D).size = Vector2(12, 18); shape.position = Vector2(0, -9)
	else:
		crouching = on_floor and (forced_crouch or (Input.is_action_pressed("down") and Input.get_action_strength("up") < 0.5))
		if crouching:
			(shape.shape as RectangleShape2D).size = Vector2(12, 28); shape.position = Vector2(0, -14)
		else:
			(shape.shape as RectangleShape2D).size = Vector2(12, 42); shape.position = Vector2(0, -21)
		var target := (0.0 if crouching and not forced_crouch else dir) * (SPRINT if sprinting and not forced_crouch else RUN) * (0.45 if (shoot_t >= 0.0 and on_floor) or forced_crouch else 1.0)
		velocity.x = move_toward(velocity.x, target, ACCEL * delta)
		if dir != 0.0 and shoot_t < 0.0: facing = 1 if dir > 0.0 else -1

	if Input.is_action_just_pressed("shoot") and shoot_t < 0.0 and slide_t <= 0.0 and not is_back and not in_vent:
		if ammo >= 1.0:
			shoot_t = 0.0; fired = false
		else:
			dry_t = 0.25   # out of charges: HUD flashes
	if shoot_t >= 0.0:
		shoot_t += delta
		if not fired and shoot_t >= 3.0 / SHOOT_FPS:
			fired = true; _fire()
		if shoot_t >= 5.0 / SHOOT_FPS:
			shoot_t = -1.0

	move_and_slide()
	if is_on_floor():
		if was_air and position.y - peak_y > FALL_PIP and hurt_t <= 0.0:
			hp -= 1; hurt_t = 0.8   # hard landing
		was_air = false; peak_y = position.y
	else:
		if not was_air: peak_y = position.y
		was_air = true; peak_y = minf(peak_y, position.y)
	concealed = in_vent or is_back and reveal_t <= 0.0 and (crouching or (cover_ref != null and cover_ref.tall >= 56.0))
	_animate()

func _cover_here() -> Cover:
	for c in get_tree().get_nodes_in_group("cover"):
		if absf(c.global_position.x - global_position.x) < c.half_w - 2.0 and global_position.y > c.global_position.y - 8.0:
			return c
	return null

func _crate_under_feet() -> Cover:
	for c in get_tree().get_nodes_in_group("cover"):
		if absf(c.global_position.x - global_position.x) < c.half_w - 2.0 and absf(global_position.y - (c.global_position.y - (c.tall - 1.0))) < 6.0:
			return c
	return null

func _lanes(on_floor: bool) -> void:
	# Standing on a crate top and holding Down: step off the back of it into the back lane.
	if on_floor and not is_back and global_position.y < 215.0 and Input.is_action_pressed("down") and not Input.is_action_just_pressed("jump"):
		down_hold += get_physics_process_delta_time()
		if down_hold >= 0.2:
			var top := _crate_under_feet()
			if top != null:
				is_back = true; cover_ref = top; down_hold = 0.0
	else:
		down_hold = 0.0
	# Up while standing at a crate: step into the back lane. Walk off the end of it or jump to come back out.
	if not is_back:
		if on_floor and shoot_t < 0.0 and slide_t <= 0.0 and Input.is_action_just_pressed("up"):
			var c := _cover_here()
			if c != null:
				is_back = true; cover_ref = c
	else:
		if not is_instance_valid(cover_ref) or absf(cover_ref.global_position.x - global_position.x) > cover_ref.half_w + 4.0:
			is_back = false
		elif buffer > 0.0:
			leaving = true    # jump hops you back out front, but only once you clear the top
		if leaving:
			if cover_ref.global_position.y - cover_ref.tall >= global_position.y - 1.0:
				is_back = false; leaving = false
			elif on_floor and buffer <= 0.0:
				leaving = false   # landed again without clearing it (e.g. a 2-high stack)
	if not is_back:
		leaving = false
	z_index = -3 if is_back else (3 if in_vent else 0)
	set_collision_mask_value(1, not in_vent)
	set_collision_mask_value(2, not is_back and drop_t <= 0.0 and not in_vent)
	set_collision_mask_value(3, roof_drop_t <= 0.0 and not in_vent)
	set_collision_mask_value(4, in_vent)

func _use_grate() -> void:
	for g in get_tree().get_nodes_in_group("grates"):
		if g.can_use(global_position) and (not g.inside or g.vent == vent):
			var t: Grate = g.target()
			if t == null: return
			global_position = t.global_position + Vector2(0, 14)
			velocity = Vector2.ZERO
			vent = t.vent if t.inside else null
			is_back = false; leaving = false
			Sfx.play("jump")
			return

func aim() -> Vector2:
	var up := Input.get_action_strength("up") - Input.get_action_strength("down") * 0.0
	var a := -0.45 * up   # up tilts the shot ~26 degrees
	return Vector2(facing, 0).rotated(a * facing)

func _fire() -> void:
	reveal_t = 1.0   # shooting gives you away for a moment
	Sfx.play("shoot", 1.0, 0.05)
	ammo -= 1.0; since_shot = 0.0
	var b := Bolt.new()
	b.global_position = global_position + Vector2(facing * 26, -23 if crouching else -33)
	b.dir = aim()
	get_parent().add_child(b)

func hurtbox() -> Rect2:
	if is_back or in_vent:
		return Rect2(-9999, -9999, 0, 0)   # out of the Wardens' lane: slugs and claws can't reach you
	var sz := (shape.shape as RectangleShape2D).size
	return Rect2(global_position + shape.position - sz / 2.0, sz)

func take_hit(from_x: float) -> void:
	if hurt_t > 0.0: return
	hp -= 1; hurt_t = 0.8
	Sfx.play("hurt")
	velocity = Vector2(-sign(from_x - global_position.x) * 120.0, -150.0)

func _animate() -> void:
	sprite.flip_h = facing < 0
	sprite.position.x = 5.0 * facing
	var n := "idle"
	if hurt_t > 0.55: n = "hit"
	elif crouching and shoot_t < 0.0: n = "cwalk" if absf(velocity.x) > 8.0 else "crouch"
	elif slide_t > 0.0: n = "slide"
	elif shoot_t >= 0.0: n = "cshoot" if crouching else "shoot"
	elif not is_on_floor(): n = "jump" if velocity.y < 60.0 else "fall"
	elif absf(velocity.x) > 8.0: n = "run" if sprinting else "walk"
	if n == "shoot" or n == "cshoot":
		sprite.animation = n
		sprite.frame = clampi(int(shoot_t * SHOOT_FPS), 0, 4)
		sprite.pause()
	elif sprite.animation != n or not sprite.is_playing():
		sprite.play(n)
	sprite.speed_scale = 1.0
	sprite.modulate = Color(0.72, 0.72, 0.85, 1.0) if is_back else Color.WHITE
	sprite.modulate.a = 0.5 if hurt_t > 0.0 and int(hurt_t * 20.0) % 2 == 0 else 1.0
