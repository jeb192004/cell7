class_name FuseBomb
extends Node2D
## Fuse's special: a lobbed bomb. She shoots it out of the air (detonate_in) and it blows up where it hangs. It also goes off when it hits
## the ground, a barrier or an enemy, or runs out of fuse, so it can't be left lying around.
const GRAV := 400.0
const RADIUS := 52.0     # blast reach, measured to the nearest point of an enemy
const DAMAGE := 4
var vel := Vector2.ZERO
var life := 1.8
var fuse := -1.0         # set when she shoots it: seconds to the bang
var blown := false

func _ready() -> void:
	z_index = 20

func detonate_in(t: float) -> void:
	fuse = t

func _physics_process(d: float) -> void:
	if blown: return
	global_position += vel * d
	vel.y += GRAV * d
	rotation += 8.0 * d * signf(vel.x if vel.x != 0.0 else 1.0)
	life -= d
	queue_redraw()
	if fuse >= 0.0:
		fuse -= d
		if fuse <= 0.0: _boom(); return
	if life <= 0.0 or global_position.y > Level.bolt_floor: _boom(); return
	for c in get_tree().get_nodes_in_group("barriers"):
		if c.rect().has_point(global_position): _boom(); return
	for e in get_tree().get_nodes_in_group("enemies"):
		if e.hit_rect().has_point(global_position): _boom(); return

func _boom() -> void:
	blown = true
	var fx := BlastFx.new(); fx.radius = RADIUS; fx.global_position = global_position; get_parent().add_child(fx)
	Sfx.play("explode", 0.8, 0.05)
	for e in get_tree().get_nodes_in_group("enemies"):
		var r: Rect2 = e.hit_rect()
		var cp := Vector2(clampf(global_position.x, r.position.x, r.end.x), clampf(global_position.y, r.position.y, r.end.y))
		if cp.distance_to(global_position) <= RADIUS: e.hurt(DAMAGE)
	queue_free()

func _draw() -> void:
	draw_circle(Vector2.ZERO, 3.5, Color(0.12, 0.12, 0.14))
	draw_arc(Vector2.ZERO, 3.5, 0, TAU, 12, Color(0.45, 0.45, 0.5), 1.0)
	var blink := int(Time.get_ticks_msec() / 90) % 2 == 0
	draw_rect(Rect2(-1, -5, 2, 2), Color(1.0, 0.2, 0.1) if blink else Color(0.5, 0.1, 0.05))
