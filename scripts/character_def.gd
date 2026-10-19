class_name CharacterDef
extends Resource
## One playable character as data. Player reads this instead of hard-coding Kesh, so Renn, Brix and Fuse are a new
## CharacterDef (and their sprite frames) rather than a copy of player.gd.
## Frames are loaded from res://assets/<key>_<frame>.png, e.g. kesh_idle_0.png.
@export var key := "kesh"
@export var display_name := "KESH"
@export var hp := 5
@export var run_speed := 115.0
@export var sprint_speed := 180.0
@export var jump_v := -320.0
@export var sprite_offset := Vector2(5, -23)   # where the sprite sits relative to the feet
@export var body := Vector2(12, 42)            # standing hitbox
@export var crouch_body := Vector2(12, 28)
@export var can_shoot := true                  # false: the shoot button does nothing (Renn's blade comes with the 1-3b fight)
@export var hide_cover_min := 0.0              # crouching only hides behind cover at least this tall (Brix is too big for a single crate)
@export var can_crouch_shoot := true
@export var crouch_only := false               # Fuse: always low, walks crouched, no jump (she has no standing walk / run / jump art)
@export var can_slash := false                 # Renn: the shoot button swings the Arc-Blade (melee, cuts through shields)
@export var ammo_max := 5                      # shot charges (Brix carries more)
@export var burst := 1                         # bolts fired per trigger pull (Brix: 3)
@export var can_block := false                 # Renn: holding the shoot button raises the Arc-Blade and deflects blaster bolts from the front
@export var can_special := false               # Fuse: the special button tosses a bomb, then she shoots it
@export var special_cd := 6.0                  # seconds before the special can be used again
@export var can_plant := false                 # the shoot button plants a charge at a ChargeSpot
@export var muzzle := Vector2(26, -33)         # where shots leave, ahead of the feet and up (crouching uses y -23)
## Nudge one animation up or down in game pixels: animation name -> Vector2 (negative y = up). Use it when a pose's feet sit too low / high.
@export var anim_nudge := {}
## Draw one animation bigger or smaller, scaled around the feet: animation name -> factor. (Renn's block sheet is a low stance drawn small.)
@export var anim_scale := {}
## animation name -> [frame names, fps, loop]. Empty = the default Kesh table below.
@export var anims := {}

const SHOOT_FPS := 14.0
func scale_of(anim: String) -> float:
	return float(anim_scale.get(anim, 1.0))
func nudge(anim: String) -> Vector2:
	return anim_nudge.get(anim, Vector2.ZERO)
## All of this character's animations as SpriteFrames (frames are res://assets/<key>_<frame>.png).
func make_frames() -> SpriteFrames:
	var sf := SpriteFrames.new()
	sf.remove_animation("default")
	var table: Dictionary = anims if not anims.is_empty() else CharacterDef.default_anims()
	for n in table:
		sf.add_animation(n); sf.set_animation_speed(n, table[n][1]); sf.set_animation_loop(n, table[n][2])
		for f in table[n][0]:
			sf.add_frame(n, load("res://assets/%s_%s.png" % [key, f]))
	return sf

static func by_key(k: String) -> CharacterDef:
	match k:
		"brix": return brix()
		"renn": return renn()
		"fuse": return fuse()
	return kesh()

static func default_anims() -> Dictionary:
	return {
		"idle": [["idle_0", "idle_1", "idle_2", "idle_3"], 4.0, true],
		"walk": [["walk_0", "walk_1", "walk_2", "walk_3", "walk_4", "walk_5", "walk_6"], 6.0, true],
		"run": [["run_0", "run_1", "run_2", "run_3", "run_4", "run_5", "run_6", "run_7", "run_8", "run_9", "run_10", "run_11", "run_12", "run_13"], 8.0, true],
		"jump": [["jump_0", "jump_1"], 6.0, false],
		"fall": [["jump_2"], 1.0, false],
		"shoot": [["shoot_0", "shoot_1", "shoot_2", "shoot_3", "shoot_4"], SHOOT_FPS, false],
		"crouch": [["crouch_0"], 1.0, false],
		"cwalk": [["cwalk_0", "cwalk_1", "cwalk_2", "cwalk_3"], 5.0, true],
		"cshoot": [["cshoot_0", "cshoot_1", "cshoot_2", "cshoot_3", "cshoot_4"], SHOOT_FPS, false],
		"hit": [["hit_0", "hit_1"], 10.0, false],
	}

static func kesh() -> CharacterDef:
	return CharacterDef.new()   # the defaults above are Kesh

## Brix: big and slow, tough, and he won't shoot crouched. Sheets come from tools/import_brix.py.
static func brix() -> CharacterDef:
	var d := CharacterDef.new()
	d.key = "brix"; d.display_name = "BRIX"
	d.hp = 8; d.run_speed = 92.0; d.sprint_speed = 135.0; d.jump_v = -285.0
	d.sprite_offset = Vector2(5, -36); d.body = Vector2(18, 58); d.crouch_body = Vector2(18, 40)
	d.can_crouch_shoot = false; d.muzzle = Vector2(46, -38); d.hide_cover_min = 50.0
	d.ammo_max = 14; d.burst = 3   # heavy gunner: three-round bursts and a deep magazine
	d.anim_nudge = {"idle": Vector2(0, -2)}   # idle: boots sat a little below the floor
	d.anims = {
		"idle": [["idle_0", "idle_1", "idle_2", "idle_3"], 4.0, true],
		"walk": [["walk_0", "walk_1", "walk_2", "walk_3", "walk_4", "walk_5", "walk_6", "walk_7"], 7.0, true],
		"run": [["run_0", "run_1", "run_2", "run_3", "run_4", "run_5", "run_6", "run_7"], 9.0, true],
		"jump": [["jump_0", "jump_1"], 6.0, false],
		"fall": [["jump_2"], 1.0, false],
		"shoot": [["shoot_0", "shoot_1", "shoot_2", "shoot_3", "shoot_4"], SHOOT_FPS, false],
		"crouch": [["crouch_0"], 1.0, false],
		"cwalk": [["cwalk_0", "cwalk_1", "cwalk_2", "cwalk_3", "cwalk_4", "cwalk_5", "cwalk_6", "cwalk_7"], 7.0, true],
		"hit": [["hit_0", "hit_1", "hit_2"], 8.0, false],
	}
	return d

## Renn: a keeper. Quick and sure-footed, hides behind anything, but has no gun: the blade fight comes later (can_shoot is off).
static func renn() -> CharacterDef:
	var d := CharacterDef.new()
	d.key = "renn"; d.display_name = "RENN"
	d.hp = 6; d.run_speed = 118.0; d.sprint_speed = 190.0; d.jump_v = -325.0
	d.sprite_offset = Vector2(5, -36); d.body = Vector2(14, 50); d.crouch_body = Vector2(14, 32)
	d.can_shoot = false; d.can_block = true; d.can_slash = true
	d.anim_scale = {"block": 1.3, "slash": 1.3}
	d.anims = {
		"idle": [["idle_0", "idle_1", "idle_2", "idle_3"], 4.0, true],
		"walk": [["walk_0", "walk_1", "walk_2", "walk_3", "walk_4", "walk_5", "walk_6", "walk_7"], 8.0, true],
		"run": [["run_0", "run_1", "run_2", "run_3", "run_4", "run_5", "run_6", "run_7"], 11.0, true],
		"jump": [["jump_0", "jump_1"], 6.0, false],
		"fall": [["jump_2"], 1.0, false],
		"shoot": [["idle_0"], 1.0, false],
		"crouch": [["crouch_0"], 1.0, false],
		"cwalk": [["cwalk_0", "cwalk_1", "cwalk_2", "cwalk_3", "cwalk_4", "cwalk_5", "cwalk_6", "cwalk_7"], 8.0, true],
		"cshoot": [["crouch_0"], 1.0, false],
		"block": [["block_0", "block_1", "block_2", "block_3", "block_4", "block_5", "block_6", "block_7", "block_8", "block_9", "block_10", "block_11", "block_12", "block_13", "block_14", "block_15"], 12.0, true],   # tools/src/renn/new-block.png
		"slash": [["slash_0", "slash_1", "slash_2"], 8.0, false],
		"hit": [["hit_0", "hit_1", "hit_2"], 8.0, false],
	}
	return d

## Fuse: a demolitions specialist. Pistol, a bomb special (toss it, then shoot it out of the air), and the shoot button plants a charge at a ChargeSpot.
static func fuse() -> CharacterDef:
	var d := CharacterDef.new()
	d.key = "fuse"; d.display_name = "FUSE"
	d.hp = 5; d.run_speed = 105.0; d.sprint_speed = 165.0; d.jump_v = -285.0
	d.sprite_offset = Vector2(0, -32); d.body = Vector2(12, 46); d.crouch_body = Vector2(12, 32)
	d.muzzle = Vector2(32, -30)
	d.can_plant = true; d.can_special = true
	var cw := [["cwalk_0", "cwalk_1", "cwalk_2", "cwalk_3", "cwalk_4", "cwalk_5", "cwalk_6", "cwalk_7"], 8.0, true]
	d.anims = {
		"idle": [["idle_0", "idle_1", "idle_2", "idle_3"], 4.0, true],
		"walk": [["walk_0", "walk_1", "walk_2", "walk_3", "walk_4", "walk_5", "walk_6", "walk_7"], 9.0, true],
		"run": [["run_0", "run_1", "run_2", "run_3", "run_4", "run_5", "run_6", "run_7"], 12.0, true],
		"jump": [["jump_0", "jump_1"], 8.0, false], "fall": [["jump_3", "jump_4"], 6.0, true],
		"shoot": [["shoot_0", "shoot_1", "shoot_2", "shoot_3", "shoot_4"], SHOOT_FPS, false],
		"cshoot": [["cshoot_0", "cshoot_1", "cshoot_2", "cshoot_3", "cshoot_4"], SHOOT_FPS, false],
		"crouch": [["crouch_0"], 1.0, false], "cwalk": cw,
		"special": [["special_0", "special_1", "special_2", "special_3", "special_4", "special_5", "special_6", "special_7", "special_8", "special_9", "special_10", "special_11", "special_12", "special_13"], 11.0, false],
		"hit": [["hit_0", "hit_1", "hit_2", "hit_3"], 8.0, false],
		"plant_ground": [["plant_ground_0", "plant_ground_1", "plant_ground_2", "plant_ground_3", "plant_ground_4", "plant_ground_5", "plant_ground_6", "plant_ground_7", "plant_ground_8", "plant_ground_9"], 8.0, false],
		"plant_wall": [["plant_wall_0", "plant_wall_1", "plant_wall_2", "plant_wall_3", "plant_wall_4", "plant_wall_5"], 8.0, false],
	}
	return d
