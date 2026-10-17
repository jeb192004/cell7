class_name PickupCutscene
extends Cutscene
## End of 2-4: the Vagabond-9 comes down over the catwalk and a tractor beam lifts Kesh and the young Ursk aboard.
## Runs inside the level (Level adds it at the clear, then shows the outro card). Existing art only.
const HOVER_DY := -118.0        # ship height above where Kesh stands
const LIFT0 := 3.2
const LIFT1 := 5.0
const LEAVE0 := 5.4
var player: Player
var pal: Node2D
var ship: Node2D
var beam: Node2D
var base := Vector2.ZERO
var lift_y := 0.0

func _build() -> void:
	fade_in = 0.0; fade_out = 0.0; length = 7.4
	captions = [
		[0.7, 3.0, "THE VAGABOND-9 ROARS IN."],
		[4.0, 6.6, "RENN HAULS KESH AND THE URSK ABOARD."],
	]
	z_index = 50
	base = player.global_position
	player.set_physics_process(false); player.velocity = Vector2.ZERO
	player.sprite.play("fall"); player.sprite.pause()
	beam = Ascent.BeamNode.new(); beam.z_index = 8; add_child(beam)
	ship = Ascent.ShipNode.new(); ship.z_index = 10; add_child(ship)
	ship.global_position = Vector2(base.x - 330.0, base.y + HOVER_DY - 60.0)
	Sfx.engine("ship_engine")

func _exit_tree() -> void:
	Sfx.engine_stop()

func _step(d: float) -> void:
	var enter := ease_(clampf((t - 0.3) / 2.6, 0.0, 1.0))
	var leave := ease_(clampf((t - LEAVE0) / 2.0, 0.0, 1.0))
	var hover := Vector2(base.x - 6.0, base.y + HOVER_DY)
	var p := Vector2(base.x - 330.0, hover.y - 60.0).lerp(hover, enter)
	p += Vector2(0.0, sin(t * 3.0) * 2.0 * (1.0 - leave))
	p += Vector2(leave * 420.0, -leave * 120.0)
	ship.global_position = p
	ship.rotation = lerpf(0.0, -0.08, enter) * (1.0 - leave) - leave * 0.2
	(ship as Ascent.ShipNode).power = 0.4 + 0.5 * leave + (0.3 if t > LIFT0 else 0.0)
	var ba := clampf((t - 2.6) / 0.4, 0.0, 1.0) * (1.0 - clampf((t - LIFT1) / 0.4, 0.0, 1.0))
	(beam as Ascent.BeamNode).alpha = ba
	(beam as Ascent.BeamNode).top = Vector2(ship.global_position.x, ship.global_position.y + 18.0)
	(beam as Ascent.BeamNode).t = t
	# Kesh and the Ursk ride the beam up into the ship
	var lift := ease_(clampf((t - LIFT0) / (LIFT1 - LIFT0), 0.0, 1.0))
	lift_y = lift * (base.y - hover.y - 20.0)
	player.global_position = Vector2(base.x + (hover.x - base.x) * lift, base.y - lift_y)
	player.sprite.frame = 0
	var a := 1.0 - clampf((lift - 0.82) / 0.18, 0.0, 1.0)
	player.modulate.a = a
	if pal != null and is_instance_valid(pal): pal.modulate.a = a

func _finish() -> void:
	player.visible = false
	if pal != null and is_instance_valid(pal): pal.visible = false
