class_name PixLabel
extends Control
## Pixel-font text, centred on its position. Set `text` any time.
var text := "":
	set(v):
		text = v
		queue_redraw()
var px := 1
var color := Color(0.96, 0.9, 0.7)
var centered := true

func _init(t := "", scale := 1, c := Color(0.96, 0.9, 0.7), center := true) -> void:
	text = t; px = scale; color = c; centered = center
	mouse_filter = Control.MOUSE_FILTER_IGNORE

func _draw() -> void:
	var w := PixFont.text_width(text, px)
	PixFont.draw(self, text, Vector2(-w / 2.0 if centered else 0.0, 0), px, color)
