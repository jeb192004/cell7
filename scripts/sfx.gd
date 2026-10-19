class_name Sfx
extends Node
## Sound effects + music. Everything is called statically: Sfx.play("shoot"), Sfx.music("desert").
## Files: assets/sfx/NAME.wav, assets/music/NAME.ogg (made by tools/make_audio.py). Volumes (0-10) are saved in Prefs.
const LEVEL_MUSIC := {"level_1_1": "desert", "level_1_2": "highway", "level_1_3": "town", "level_1_4": "bike", "level_1_5": "space", "level_2_1": "town", "level_2_3": "town", "level_2_2": "town", "level_2_4": "highway", "level_2_5": "desert", "level_2_6": "bike", "level_3_1": "town", "level_3_2": "town", "level_3_3": "town", "level_3_4": "town", "level_3_5": "bike", "level_3_6": "bike", "level_3_7": "bike", "title": "title"}
const GAIN_DB := {"shoot": -7.0, "enemy_shoot": -9.0, "enemy_hit": -6.0, "blip": -10.0, "menu_move": -8.0, "shield_block": -5.0}
static var inst: Sfx
static var cache := {}
static var music_vol := -1     # 0-10, -1 = not loaded yet
static var sfx_vol := -1
var pool: Array = []
var pool_i := 0
var mus: AudioStreamPlayer
var eng: AudioStreamPlayer
var eng_on := false
var eng_name := ""
var eng_cur := ""
var want := ""
var current := ""
var fade := 0.0
var out_vol := 0.0

static func _ensure() -> Sfx:
	if music_vol < 0:
		music_vol = int(Prefs.get_num("audio", "music", 7)); sfx_vol = int(Prefs.get_num("audio", "sfx", 8))
	if inst == null or not is_instance_valid(inst):
		inst = Sfx.new()
		(Engine.get_main_loop() as SceneTree).root.add_child.call_deferred(inst)
	return inst

static func _load(path: String) -> AudioStream:
	if not cache.has(path):
		cache[path] = load(path) if ResourceLoader.exists(path) else null
	return cache[path]

static func vol_db(v: int) -> float:
	return -80.0 if v <= 0 else linear_to_db(pow(v / 10.0, 1.6))

static func play(n: String, pitch := 1.0, jitter := 0.0) -> void:
	var s := _ensure()
	if not s.is_inside_tree() or sfx_vol <= 0: return
	var st := _load("res://assets/sfx/%s.wav" % n)
	if st == null: return
	var p: AudioStreamPlayer = s.pool[s.pool_i]; s.pool_i = (s.pool_i + 1) % s.pool.size()
	p.stream = st; p.pitch_scale = pitch * (1.0 + randf_range(-jitter, jitter))
	p.volume_db = vol_db(sfx_vol) + float(GAIN_DB.get(n, 0.0)); p.play()

static func music(n: String) -> void:
	var s := _ensure(); s.want = n

static func music_for(scene_path: String) -> void:
	music(LEVEL_MUSIC.get(scene_path.get_file().get_basename(), ""))

## Looping engine hum for the bike / ship levels. Sfx.engine("bike_engine"), Sfx.engine_pitch(1.1), Sfx.engine_stop().
static func engine(n: String) -> void:
	var s := _ensure(); s.eng_name = n; s.eng_on = true
static func engine_pitch(p: float) -> void:
	if inst != null and is_instance_valid(inst) and inst.eng != null: inst.eng.pitch_scale = clampf(p, 0.5, 2.0)
static func engine_stop() -> void:
	if inst != null and is_instance_valid(inst): inst.eng_on = false

static func set_volumes(m: int, f: int) -> void:
	music_vol = clampi(m, 0, 10); sfx_vol = clampi(f, 0, 10)
	Prefs.set_num("audio", "music", music_vol); Prefs.set_num("audio", "sfx", sfx_vol)

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	for i in 10:
		var p := AudioStreamPlayer.new(); add_child(p); pool.append(p)
	mus = AudioStreamPlayer.new(); add_child(mus)
	eng = AudioStreamPlayer.new(); add_child(eng)

func _process(d: float) -> void:
	if mus == null: return
	if eng_on and eng_cur != eng_name:
		var st := _load("res://assets/sfx/%s.wav" % eng_name)
		if st is AudioStreamWAV:
			st = st.duplicate(); st.loop_mode = AudioStreamWAV.LOOP_FORWARD; st.loop_begin = 0; st.loop_end = int(st.get_length() * st.mix_rate)
			eng.stream = st; eng.play(); eng_cur = eng_name
	if not eng_on and eng.playing: eng.stop(); eng_cur = ""
	eng.stream_paused = get_tree().paused
	eng.volume_db = vol_db(sfx_vol) - 15.0 if sfx_vol > 0 else -80.0
	var target := vol_db(music_vol) - 6.0 - (8.0 if get_tree().paused else 0.0)
	if want != current:
		out_vol = lerpf(out_vol, -60.0, minf(1.0, d * 9.0))
		if out_vol < -50.0 or not mus.playing:
			current = want
			if current == "": mus.stop()
			else:
				var st := _load("res://assets/music/%s.ogg" % current)
				if st is AudioStreamOggVorbis: st.loop = true
				mus.stream = st; mus.play()
	else:
		out_vol = lerpf(out_vol, target, minf(1.0, d * 3.0))
	mus.volume_db = out_vol if music_vol > 0 else -80.0
