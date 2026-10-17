class_name CrewFollower
extends Node2D
## A crew member who follows the player through a stealth level (2-1a: whichever of Renn / Brix you didn't pick).
## He can't be seen or shot (the Wardens only look for the player). He crouches, hides and stops when the player does.
var def: CharacterDef
var player: Player
var spr: AnimatedSprite2D
var gap := 38.0

func _ready() -> void:
	spr = AnimatedSprite2D.new(); spr.sprite_frames = def.make_frames(); spr.position = def.sprite_offset
	spr.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	add_child(spr); spr.play("idle")
	z_index = -1

## After a swap: this crew member becomes the one the player just stopped being.
func set_def(d: CharacterDef) -> void:
	def = d; spr.sprite_frames = d.make_frames(); spr.position = d.sprite_offset; spr.play("idle")

func _process(d: float) -> void:
	if player == null: player = get_tree().get_first_node_in_group("player") as Player; return
	var want := player.global_position.x - gap * player.facing
	var hiding := player.is_back and is_instance_valid(player.cover_ref)
	if hiding:
		# tuck in behind the same crate as the player, not out in the open next to it
		var c: Cover = player.cover_ref
		want = clampf(want, c.global_position.x - c.half_w + 9.0, c.global_position.x + c.half_w - 9.0)
	var dx := want - position.x
	var speed := (player.def.sprint_speed if absf(player.velocity.x) > 130.0 else player.def.run_speed) * 1.1
	position.x = move_toward(position.x, want, speed * d)
	position.y = player.global_position.y if player.is_on_floor() else lerpf(position.y, player.global_position.y, 0.25)
	# animate like the character being played: same walk / run / crouch-walk while the player moves, idle when they stand still
	var moving := absf(dx) > 3.0 or absf(player.velocity.x) > 8.0
	var crouch := player.crouching or hiding
	var n := "idle"
	if crouch: n = "cwalk" if moving else "crouch"
	elif not player.is_on_floor(): n = "jump" if player.velocity.y < 60.0 else "fall"
	elif moving: n = "run" if player.sprinting else "walk"
	if spr.animation != n: spr.play(n)
	if absf(dx) > 3.0: spr.flip_h = dx < 0.0
	elif absf(player.velocity.x) > 8.0: spr.flip_h = player.velocity.x < 0.0
	else: spr.flip_h = player.facing < 0
	spr.position.x = def.sprite_offset.x * (-1.0 if spr.flip_h else 1.0)
	spr.position.y = def.sprite_offset.y + def.nudge(spr.animation).y
	# in the back lane when the player is: behind the crates, a little dim
	z_index = -3 if player.is_back else -1
	spr.modulate = Color(0.72, 0.72, 0.85, 1.0) if player.is_back else Color.WHITE
