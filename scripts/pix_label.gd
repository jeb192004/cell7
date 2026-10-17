@tool
class_name PixLabel
extends Control
## Pixel-font text. Works as a scene node (edit text / px / color in the inspector).
## boxed: the text is centred in this node's own rectangle (position = top-left, so you can drag and size it in the 2D editor).
## not boxed (older code that builds labels in script): the node's position is the text's centre point.
@export var text := "":
	set(v):
		text = v
		queue_redraw()
@export_range(1, 12) var px := 1:
	set(v):
		px = v
		queue_redraw()
@export var color := Color(0.96, 0.9, 0.7):
	set(v):
		color = v
		queue_redraw()
@export var centered := true:
	set(v):
		centered = v
		queue_redraw()
@export var boxed := false:
	set(v):
		boxed = v
		queue_redraw()

func _init(t := "", scale := 1, c := Color(0.96, 0.9, 0.7), center := true) -> void:
	text = t; px = scale; color = c; centered = center
	mouse_filter = Control.MOUSE_FILTER_IGNORE

func _draw() -> void:
	var w := PixFont.text_width(text, px)
	var x := 0.0
	if centered: x = (size.x - w) / 2.0 if boxed else -w / 2.0
	PixFont.draw(self, text, Vector2(x, 0), px, color)
	if Engine.is_editor_hint() and boxed:
		draw_rect(Rect2(Vector2.ZERO, size), Color(1, 1, 1, 0.14), false)
