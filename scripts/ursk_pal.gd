class_name UrskPal
extends Node2D
## A young Ursk that follows Kesh (placeholder art drawn in code).
var player: Player
var t := 0.0
func _process(d: float) -> void:
	t += d
	if player == null: player = get_tree().get_first_node_in_group("player") as Player; return
	var want := player.global_position.x - 30.0 * player.facing
	position.x = move_toward(position.x, want, 140.0 * d)
	position.y = player.global_position.y
	queue_redraw()
func _draw() -> void:
	var fur := Color(0.5, 0.35, 0.22); var dark := Color(0.3, 0.2, 0.13)
	var bob := absf(sin(t * 12.0)) * 1.5 if player != null and absf(player.velocity.x) > 10.0 else 0.0
	draw_rect(Rect2(-6, -26 - bob, 12, 16), fur); draw_rect(Rect2(-5, -36 - bob, 10, 10), fur)
	draw_rect(Rect2(-4, -10, 3, 10), dark); draw_rect(Rect2(1, -10, 3, 10), dark)
	draw_rect(Rect2(1, -33 - bob, 2, 2), Color(0.95, 0.9, 0.6))
