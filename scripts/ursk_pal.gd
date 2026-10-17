class_name UrskPal
extends Node2D
## A young Ursk that follows Kesh: the adult Ursk art drawn smaller.
const SCALE := 0.68
var player: Player
var spr: UrskAnim
func _ready() -> void:
	spr = UrskAnim.new(); add_child(spr); scale = Vector2(SCALE, SCALE)
func _process(d: float) -> void:
	if player == null: player = get_tree().get_first_node_in_group("player") as Player; return
	var want := player.global_position.x - 30.0 * player.facing
	var dx := want - position.x
	position.x = move_toward(position.x, want, 140.0 * d)
	position.y = player.global_position.y
	spr.moving = absf(dx) > 2.0 or absf(player.velocity.x) > 10.0
	if absf(dx) > 2.0: spr.face = 1 if dx > 0 else -1
	else: spr.face = player.facing
