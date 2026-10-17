class_name Player
extends CharacterBody2D
## Kesh. Origin is at his feet. Runs with the slingshot stowed, draws it only to shoot.

## Which character this is (sprites, speeds, hitbox). Set before add_child() to play someone other than Kesh.
var def: CharacterDef = CharacterDef.kesh()
const ACCEL := 900.0
const GRAV := 950.0
const COYOTE := 0.09
const BUFFER := 0.1
const SHOOT_FPS := 14.0

var facing := 1
var coyote := 0.0
var buffer := 0.0
var shoot_t := -1.0
var fired := false
var hurt_t := 0.0
var sprinting := false
var sprint_latch := false   # keyboard / gamepad sprint toggle (the touch pad has its own RUN toggle, which holds the "run" action)
var hp := 5
var max_hp := 5
var crouching := false
var forced_crouch := false   # set by the level inside vents: you have to crawl
var concealed := false
var blocking := false        # Renn: blade up, holding the shoot button
var planting := -1.0         # Fuse: seconds into planting a charge (-1 = not planting)
var plant_spot: ChargeSpot = null
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
const MAX_AMMO := 5.0     # Kesh's; other characters use def.ammo_max (see max_ammo)
var max_ammo := 5.0
var slash_t := -1.0       # Renn: seconds into an Arc-Blade swing (-1 = not swinging)
var slash_hit := false
var burst_left := 0       # Brix: bolts still to come in this burst
var burst_t := 0.0
const AMMO_DELAY := 0.6   # seconds after your last shot before charges start coming back
const AMMO_RATE := 1.0    # charges per second
var ammo := 5.0
var since_shot := 9.0
var dry_t := 0.0
var sprite: AnimatedSprite2D
var shape: CollisionShape2D
var bolt_scene_parent: Node

func _ready() -> void:
	add_to_group("player")
	floor_snap_length = 8.0   # stays glued to stairs going down and to lifts
	collision_mask = 7   # 1 = ground, 2 = crate tops (switched off behind crates), 3 = rooftops
	shape = CollisionShape2D.new()
	hp = def.hp; max_hp = def.hp
	max_ammo = float(def.ammo_max); ammo = max_ammo
	var r := RectangleShape2D.new(); r.size = def.body
	shape.shape = r; shape.position = Vector2(0, -def.body.y / 2.0)
	add_child(shape)
	sprite = AnimatedSprite2D.new()
	sprite.sprite_frames = _frames()
	sprite.position = def.sprite_offset
	add_child(sprite)
	sprite.play("idle")

func _frames() -> SpriteFrames:
	return def.make_frames()

func _physics_process(delta: float) -> void:
	var dir := Input.get_axis("left", "right")
	var on_floor := is_on_floor()
	coyote = COYOTE if on_floor else maxf(coyote - delta, 0.0)
	buffer = BUFFER if Input.is_action_just_pressed("jump") else maxf(buffer - delta, 0.0)
	hurt_t = maxf(hurt_t - delta, 0.0)
	reveal_t = maxf(reveal_t - delta, 0.0)
	dry_t = maxf(dry_t - delta, 0.0)
	since_shot += delta
	if since_shot > AMMO_DELAY: ammo = minf(ammo + AMMO_RATE * (1.0 + (max_ammo - 5.0) / 8.0) * delta, max_ammo)
	drop_t = maxf(drop_t - delta, 0.0)
	roof_drop_t = maxf(roof_drop_t - delta, 0.0)
	if Input.is_action_just_pressed("sprint_toggle"): sprint_latch = not sprint_latch
	sprinting = sprint_latch or Input.is_action_pressed("run")
	if Input.is_action_just_pressed("up") and on_floor and not is_back and shoot_t < 0.0:
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
	var crawl := forced_crouch or def.crouch_only
	blocking = def.can_block and on_floor and not is_back and not in_vent and hurt_t < 0.4 and Input.is_action_pressed("block")
	if buffer > 0.0 and coyote > 0.0 and not crawl and planting < 0.0:
		velocity.y = def.jump_v; buffer = 0.0; coyote = 0.0
		Sfx.play("jump")
	if Input.is_action_just_released("jump") and velocity.y < -110.0 and not leaving:
		velocity.y = -110.0   # tap = short hop

	crouching = on_floor and (crawl or (Input.is_action_pressed("down") and Input.get_action_strength("up") < 0.5))
	if crouching:
		(shape.shape as RectangleShape2D).size = def.crouch_body; shape.position = Vector2(0, -def.crouch_body.y / 2.0)
	else:
		(shape.shape as RectangleShape2D).size = def.body; shape.position = Vector2(0, -def.body.y / 2.0)
	var target := (0.0 if (crouching and not crawl) or planting >= 0.0 else dir) * (def.sprint_speed if sprinting and not crawl else def.run_speed) * (0.45 if (shoot_t >= 0.0 and on_floor) or forced_crouch else (0.4 if blocking else (0.5 if slash_t >= 0.0 and on_floor else 1.0)))
	velocity.x = move_toward(velocity.x, target, ACCEL * delta)
	if dir != 0.0 and shoot_t < 0.0 and planting < 0.0: facing = 1 if dir > 0.0 else -1

	if Input.is_action_just_pressed("shoot") and shoot_t < 0.0 and not is_back and not in_vent and def.can_shoot and (def.can_crouch_shoot or not crouching):
		if ammo >= 1.0:
			shoot_t = 0.0; fired = false
		else:
			dry_t = 0.25   # out of charges: HUD flashes
	_plant(delta, on_floor)
	_melee_and_burst(delta)
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
	concealed = in_vent or is_back and reveal_t <= 0.0 and ((crouching and (cover_ref == null or cover_ref.tall >= def.hide_cover_min)) or (cover_ref != null and cover_ref.tall >= 56.0))
	_animate()

## Fuse: shoot at a ChargeSpot kneels and sets a charge (the spot is armed when the last frame is reached).
func _plant(delta: float, on_floor: bool) -> void:
	if planting < 0.0:
		if def.can_plant and on_floor and not is_back and not in_vent and Input.is_action_just_pressed("shoot"):
			for sp in get_tree().get_nodes_in_group("charge_spots"):
				if sp.can_plant(global_position):
					plant_spot = sp; planting = 0.0; velocity.x = 0.0
					if sp.kind == "wall": facing = sp.face
					return
		return
	planting += delta
	var anim := "plant_wall" if plant_spot.kind == "wall" else "plant_ground"
	var n := sprite.sprite_frames.get_frame_count(anim)
	if planting >= n / def.anims[anim][1]:
		plant_spot.plant()
		planting = -1.0; plant_spot = null

## True when a bolt travelling in direction `shot_dir` hits the raised blade (it has to come at Renn's front).
func blocks_shot(shot_dir: float) -> bool:
	return blocking and signf(shot_dir) == -float(facing)

func block_spark(at: Vector2) -> void:
	var sp := BlockSpark.new(); sp.global_position = at; get_parent().add_child(sp)
	Sfx.play("shield_break", 1.6)

## Swap to another crew member's body (sprites, hitbox, speeds, hp) without reloading the level.
func set_def(d: CharacterDef, new_hp: int) -> void:
	def = d; hp = new_hp; max_hp = d.hp
	sprite.sprite_frames = d.make_frames()
	sprite.position = d.sprite_offset
	sprite.play("idle")
	shoot_t = -1.0; blocking = false; slash_t = -1.0; burst_left = 0
	max_ammo = float(d.ammo_max); ammo = max_ammo

## Renn's Arc-Blade swing, and the rest of Brix's burst.
func _melee_and_burst(delta: float) -> void:
	if burst_left > 0:
		burst_t -= delta
		if burst_t <= 0.0:
			if ammo >= 1.0: _fire(randf_range(-0.07, 0.07))
			burst_left -= 1; burst_t = 0.085
	if not def.can_slash: return
	if slash_t < 0.0:
		if Input.is_action_just_pressed("shoot") and not blocking and not in_vent and not is_back and planting < 0.0:
			slash_t = 0.0; slash_hit = false
			Sfx.play("jump", 1.5, 0.05)
		return
	slash_t += delta
	if not slash_hit and slash_t >= 0.2:
		slash_hit = true
		reveal_t = 1.0
		var arc := SlashArc.new(); arc.facing = facing; arc.global_position = global_position + Vector2(0, -30); get_parent().add_child(arc)
		var reach := Rect2(global_position.x + (0.0 if facing > 0 else -46.0), global_position.y - 52.0, 46.0, 56.0)
		for e in get_tree().get_nodes_in_group("enemies"):
			if e.has_method("hit_rect") and e.hit_rect().intersects(reach):
				e.hurt(2)   # the blade cuts straight through a riot shield
	if slash_t >= 0.375 or blocking: slash_t = -1.0

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
		if on_floor and shoot_t < 0.0 and Input.is_action_just_pressed("up"):
			var c := _cover_here()
			if c != null:
				is_back = true; cover_ref = c
				if c.tall < def.hide_cover_min and get_parent() != null and get_parent().has_method("_toast"): get_parent()._toast("TOO BIG TO HIDE BEHIND THIS")
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

func _fire(spread := 0.0) -> void:
	reveal_t = 1.0   # shooting gives you away for a moment
	Sfx.play("shoot", 1.0, 0.05)
	ammo -= 1.0; since_shot = 0.0
	if spread == 0.0 and def.burst > 1: burst_left = def.burst - 1; burst_t = 0.085
	var b := Bolt.new()
	b.global_position = global_position + Vector2(facing * def.muzzle.x, -23 if crouching else def.muzzle.y)
	b.dir = aim().rotated(spread)
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
	sprite.position.x = def.sprite_offset.x * facing
	var sc := def.scale_of(sprite.animation)
	var half := 37.0
	if sprite.sprite_frames != null and sprite.sprite_frames.has_animation(sprite.animation): half = sprite.sprite_frames.get_frame_texture(sprite.animation, 0).get_height() / 2.0
	sprite.scale = Vector2(sc, sc)
	sprite.position.y = def.sprite_offset.y + def.nudge(sprite.animation).y + half * (1.0 - sc)   # scaled around the feet
	var n := "idle"
	if planting >= 0.0:
		var pa := "plant_wall" if plant_spot.kind == "wall" else "plant_ground"
		sprite.animation = pa
		sprite.frame = clampi(int(planting * def.anims[pa][1]), 0, sprite.sprite_frames.get_frame_count(pa) - 1)
		sprite.pause()
		sprite.modulate = Color.WHITE
		return
	if slash_t >= 0.0 and hurt_t <= 0.0:
		sprite.animation = "slash"; sprite.frame = clampi(int(slash_t * 8.0), 0, 2); sprite.pause()
		sprite.modulate = Color.WHITE
		return
	if blocking and hurt_t <= 0.0: n = "block"
	elif hurt_t > 0.55: n = "hit"
	elif crouching and shoot_t < 0.0: n = "cwalk" if absf(velocity.x) > 8.0 else "crouch"
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
