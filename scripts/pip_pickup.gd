class_name PipPickup
extends Node2D
## A pip (heart) to grab: heals one. Stays put if you're already at full health.
var t := 0.0
var player: Player

func _ready() -> void:
	add_to_group("pickups")
	z_index = 1

func _process(d: float) -> void:
	t += d
	if player == null:
		player = get_tree().get_first_node_in_group("player") as Player
	elif player.hp > 0 and player.hp < player.max_hp and (player.global_position + Vector2(0, -20)).distance_to(global_position) < 16.0:
		player.hp += 1
		Sfx.play("pickup")
		queue_free()
		return
	queue_redraw()

func _draw() -> void:
	var bob := sin(t * 3.0) * 2.0
	var glow := 0.25 + 0.15 * sin(t * 5.0)
	draw_circle(Vector2(0, bob), 10.0, Color(1.0, 0.8, 0.3, glow))
	draw_rect(Rect2(-6, bob - 6, 12, 12), Color(0.1, 0.07, 0.12))
	draw_rect(Rect2(-5, bob - 5, 10, 10), Color(0.95, 0.72, 0.25))
	draw_rect(Rect2(-4, bob - 4, 4, 3), Color(1, 0.93, 0.7))
	if int(t * 4.0) % 3 == 0: draw_rect(Rect2(5, bob - 9, 2, 2), Color(1, 1, 0.9))
