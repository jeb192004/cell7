class_name UrskAnim
extends Node2D
## An Ursk drawn from assets/ursk_idle_N / ursk_walk_N (facing right). The feet sit on the node's origin.
## Set `moving` to switch between idle and walk, and `face` to -1 to flip him left.
static var _idle: Array = []
static var _walk: Array = []
var moving := false
var face := 1
var t := 0.0
var s: Sprite2D

static func _load() -> void:
	if not _idle.is_empty(): return
	for i in 16:
		_idle.append(load("res://assets/ursk_idle_%d.png" % i))
		_walk.append(load("res://assets/ursk_walk_%d.png" % i))

func _ready() -> void:
	_load()
	s = Sprite2D.new(); s.centered = false; s.show_behind_parent = show_behind_parent
	s.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST; add_child(s)
	_show()

func _process(d: float) -> void:
	t += d
	_show()

func _show() -> void:
	var set_: Array = _walk if moving else _idle
	var fps := 14.0 if moving else 6.0
	var tex: Texture2D = set_[int(t * fps) % set_.size()]
	s.texture = tex
	s.position = Vector2(-tex.get_width() * 0.5, -tex.get_height())
	s.flip_h = face < 0
