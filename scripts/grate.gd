@tool
class_name Grate
extends Node2D
## Vent entrance/exit. Stand under it (or in front of it) and press Up to go through to the grate in `link`.
## Origin = the middle of the grate. `inside` = this grate is inside a Vent (the other end of a pair is outside).
## Kesh has to be 4-58 px below the grate's middle, so a ceiling grate needs a crate stack to stand on.
@export var link: NodePath
@export var inside := false
var vent: Vent = null
var near := false

func _ready() -> void:
	if Engine.is_editor_hint(): return
	add_to_group("grates")
	z_index = 2 if inside else -1
	_find.call_deferred()

func _find() -> void:
	if not inside: return
	for v in get_tree().get_nodes_in_group("vents"):
		if v.holds(global_position + Vector2(0, 14)): vent = v
	if vent == null: push_warning("Grate %s is marked inside but is not in a Vent" % name)
	modulate.a = 0.0

func target() -> Grate:
	return get_node_or_null(link) as Grate

func can_use(p: Vector2) -> bool:
	var dy := p.y - global_position.y
	return absf(p.x - global_position.x) < 20.0 and dy > 4.0 and dy < 58.0

func _process(_d: float) -> void:
	if Engine.is_editor_hint():
		queue_redraw(); return
	if vent != null:
		modulate.a = vent.amount; visible = vent.amount > 0.01
	var p := get_tree().get_first_node_in_group("player") as Player
	var n := p != null and p.hp > 0 and can_use(p.global_position) and ((inside and p.vent == vent) or (not inside and p.vent == null))
	if n != near: near = n
	if near: queue_redraw()

func _draw() -> void:
	draw_rect(Rect2(-12, -8, 24, 16), Color(0.1, 0.11, 0.15))
	draw_rect(Rect2(-10, -6, 20, 12), Color(0.2, 0.22, 0.28))
	for i in 5:
		draw_rect(Rect2(-9 + i * 4, -6, 2, 12), Color(0.05, 0.05, 0.08))
	draw_rect(Rect2(-12, -8, 24, 16), Color(0.45, 0.48, 0.58), false, 1.0)
	if Engine.is_editor_hint():
		var t := target()
		if t != null: draw_line(Vector2.ZERO, to_local(t.global_position), Color(0.3, 0.8, 1.0, 0.6), 1.0)
	if near:
		var b := sin(Time.get_ticks_msec() / 150.0) * 2.0
		draw_colored_polygon(PackedVector2Array([Vector2(0, -20 + b), Vector2(-5, -13 + b), Vector2(5, -13 + b)]), Color(1.0, 0.85, 0.4))
