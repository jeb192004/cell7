class_name BikePlayer
extends Node2D
## Kesh on the speeder bike. Three lanes (Up / Down), and Left / Right to ride forward or fall back along the road.
const LANES := [214.0, 238.0, 262.0]
const MAX_AMMO := 6.0   # on foot it is 5; the bike is busier (lane dodging) so a little more
const AMMO_DELAY := 0.5
const AMMO_RATE := 1.3   # bolts per second once refilling
const MIN_X := 44.0
const MAX_X := 330.0
const SPEED := 105.0
var hp := 5
var max_hp := 5
var ammo := MAX_AMMO
var since_shot := 9.0
var dry_t := 0.0
var concealed := false      # (Hearts HUD asks)
var hurt_t := 0.0
var lane := 1
var cool := 0.0
var t := 0.0
var spr: Sprite2D
# Kesh's bike is a 25-frame sheet (assets/kesh_bike_00..24). 8-13 full burn (holding right), 18-20 cruise flame.
const CRUISE := [18, 19, 20, 19]
const BURN := [8, 9, 10, 11, 12, 13, 12, 11, 10, 9]
var tex: Array = []
var ft := 0.0

func _ready() -> void:
	add_to_group("player")
	spr = Sprite2D.new()
	for i in 25: tex.append(load("res://assets/kesh_bike_%02d.png" % i))
	spr.texture = tex[18]   # lit from the very first frame (the level may start paused on a card)
	spr.centered = false
	spr.position = Vector2(-74, -55)
	add_child(spr)
	position = Vector2(120.0, LANES[1])

func _animate(d: float, push: bool) -> void:
	ft += d
	var seq: Array = BURN if push else CRUISE   # the road auto-scrolls, so the engine is always lit; holding right burns harder
	spr.texture = tex[seq[int(ft * 14.0) % seq.size()]]

func in_lane(y: float) -> bool:
	return absf(position.y - y) < 12.0

func take_hit() -> void:
	if hurt_t > 0.0 or hp <= 0: return
	hp -= 1; hurt_t = 1.0
	Sfx.play("hurt")
	position.x = maxf(MIN_X, position.x - 26.0)

func _process(d: float) -> void:
	t += d
	hurt_t = maxf(hurt_t - d, 0.0)
	cool = maxf(cool - d, 0.0)
	dry_t = maxf(dry_t - d, 0.0)
	since_shot += d
	if since_shot > AMMO_DELAY: ammo = minf(ammo + AMMO_RATE * d, MAX_AMMO)
	if hp <= 0: return
	if Input.is_action_just_pressed("up"): lane = maxi(lane - 1, 0)
	if Input.is_action_just_pressed("down"): lane = mini(lane + 1, 2)
	var dir := Input.get_axis("left", "right")
	position.x = clampf(position.x + dir * SPEED * d, MIN_X, MAX_X)
	position.y = move_toward(position.y, LANES[lane], 300.0 * d)
	z_index = int(position.y) + 1
	spr.position.y = -55.0 + sin(t * 9.0) * 1.0
	_animate(d, dir > 0.1)
	spr.modulate.a = 0.45 if hurt_t > 0.0 and int(hurt_t * 18.0) % 2 == 0 else 1.0
	if Input.is_action_just_pressed("shoot") and cool <= 0.0:
		if ammo >= 1.0:
			ammo -= 1.0; since_shot = 0.0; cool = 0.2
			Sfx.play("shoot", 1.0, 0.05)
			var b := BikeBolt.new()
			b.position = Vector2(position.x + 38.0, LANES[lane])
			get_parent().add_child(b)
		else:
			dry_t = 0.25
