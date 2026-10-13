class_name SpacePlayer
extends Node2D
## Kesh flying the Kestrel. Free movement on all four directions; shoot fires straight ahead (right).
const MAX_AMMO := 6.0
const AMMO_DELAY := 0.5
const AMMO_RATE := 1.3
const SPEED := 140.0
const MIN_X := 64.0
const MAX_X := 410.0
const MIN_Y := 30.0
const MAX_Y := 244.0
const RADIUS := 12.0
const HALF := Vector2(46, 15)   # hitbox half-size: the Kestrel art is 108x43, this is the body without the wing tips

## Distance from a point to the ship's hitbox (0 when inside it).
func dist_to(pt: Vector2) -> float:
	var d := (pt - position).abs() - HALF
	return Vector2(maxf(d.x, 0.0), maxf(d.y, 0.0)).length()
var hp := 5
var max_hp := 5
var infinite_ammo := true   # the Kestrel never runs dry (HUD hides the ammo bar)
var ammo := MAX_AMMO
var since_shot := 9.0
var dry_t := 0.0
var concealed := false      # (Hearts HUD asks)
var hurt_t := 0.0
var cool := 0.0
var t := 0.0
var vel := Vector2.ZERO
var spr: Sprite2D

func _ready() -> void:
	add_to_group("player")
	spr = Sprite2D.new()
	spr.texture = load("res://assets/vagabond.png")
	add_child(spr)
	position = Vector2(100, 135)

func take_hit() -> void:
	if hurt_t > 0.0 or hp <= 0: return
	hp -= 1; hurt_t = 1.2
	Sfx.play("hurt")

func heal() -> void:
	hp = mini(hp + 1, max_hp)

func _process(d: float) -> void:
	t += d
	hurt_t = maxf(hurt_t - d, 0.0)
	cool = maxf(cool - d, 0.0)
	dry_t = maxf(dry_t - d, 0.0)
	since_shot += d
	if since_shot > AMMO_DELAY: ammo = minf(ammo + AMMO_RATE * d, MAX_AMMO)
	if hp <= 0:
		spr.visible = false
		return
	var dir := Vector2(Input.get_axis("left", "right"), Input.get_axis("up", "down"))
	vel = vel.move_toward(dir * SPEED, 900.0 * d)
	position += vel * d
	position.x = clampf(position.x, MIN_X, MAX_X); position.y = clampf(position.y, MIN_Y, MAX_Y)
	spr.rotation = vel.y / SPEED * 0.25
	Sfx.engine_pitch(1.0 + vel.x / SPEED * 0.25 - absf(vel.y) / SPEED * 0.05)
	spr.modulate.a = 0.45 if hurt_t > 0.0 and int(hurt_t * 18.0) % 2 == 0 else 1.0
	if Input.is_action_just_pressed("shoot") and cool <= 0.0:
		if ammo >= 1.0:
			if not infinite_ammo: ammo -= 1.0
			since_shot = 0.0; cool = 0.16
			Sfx.play("shoot", 1.3, 0.05)
			var b := SpaceBolt.new()
			b.position = position + Vector2(56, 0)
			get_parent().add_child(b)
		else:
			dry_t = 0.25
	queue_redraw()

func _draw() -> void:
	if hp <= 0: return
	for ny in [-11.0, 4.0]:   # twin engine flames, animated
		var fl := 8.0 + sin(t * 40.0 + ny) * 3.0 + vel.x / SPEED * 4.0
		draw_rect(Rect2(-54.0 - fl, ny - 2, fl, 5), Color(0.35, 0.6, 1.0, 0.85))
		draw_rect(Rect2(-54.0 - fl * 0.7, ny - 1, fl * 0.7, 3), Color(0.7, 0.88, 1.0))
		draw_rect(Rect2(-54.0 - fl * 0.35, ny, fl * 0.35, 1), Color(1, 1, 1))
