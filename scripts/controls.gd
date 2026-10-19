class_name Controls
## Builds the input map in code so the RP6 / keyboard bindings live in one place.
## RP5 labels are Nintendo-style: Godot A(0)=RP 'B', Godot B(1)=RP 'A', Godot X(2)=RP 'Y'.
## Joypad indices follow Godot's SDL layout: 0=A(bottom) 1=B(right) 2=X(left) 3=Y(top) 4=Back 6=Start 9=L1 10=R1 11-14=dpad
static func setup() -> void:
	_act("left",  [_key(KEY_LEFT), _key(KEY_A), _btn(JOY_BUTTON_DPAD_LEFT), _axis(JOY_AXIS_LEFT_X, -1.0)])
	_act("right", [_key(KEY_RIGHT), _key(KEY_D), _btn(JOY_BUTTON_DPAD_RIGHT), _axis(JOY_AXIS_LEFT_X, 1.0)])
	_act("up",    [_key(KEY_UP), _key(KEY_W), _btn(JOY_BUTTON_DPAD_UP), _axis(JOY_AXIS_LEFT_Y, -1.0), _axis(JOY_AXIS_RIGHT_Y, -1.0)])
	_act("down",  [_key(KEY_DOWN), _key(KEY_S), _btn(JOY_BUTTON_DPAD_DOWN), _axis(JOY_AXIS_LEFT_Y, 1.0), _axis(JOY_AXIS_RIGHT_Y, 1.0)])
	_act("jump",  [_key(KEY_SPACE), _key(KEY_K), _btn(JOY_BUTTON_A)])
	_act("shoot", [_key(KEY_J), _key(KEY_X), _btn(JOY_BUTTON_RIGHT_SHOULDER), _btn(JOY_BUTTON_X)])   # instant shot (RP5 Y or R1)
	_act("sprint_toggle", [_key(KEY_SHIFT), _btn(JOY_BUTTON_LEFT_SHOULDER), _axis(JOY_AXIS_TRIGGER_LEFT, 1.0)])   # tap L1 / L2 / Shift: sprint on, tap again: off
	_act("swap",  [_key(KEY_TAB), _key(KEY_Q), _btn(JOY_BUTTON_Y)])   # swap to the other crew member (levels with a partner)
	_act("block", [_key(KEY_L), _key(KEY_C), _btn(JOY_BUTTON_B)])   # Renn: hold to block bolts with the Arc-Blade
	_act("special", [_key(KEY_E), _key(KEY_I), _btn(JOY_BUTTON_B)])   # Fuse: toss a bomb, then shoot it
	_act("skip_story", [_key(KEY_TAB), _btn(JOY_BUTTON_Y)])   # story cards and cutscenes: skip them all (RP5 X)
	_act("run",   [])   # held while the touch pad's RUN toggle is on (touch_controls.gd presses it)
	_act("pause", [_key(KEY_ESCAPE), _key(KEY_P), _btn(JOY_BUTTON_START)])

static func _act(n: String, evs: Array) -> void:
	if not InputMap.has_action(n):
		InputMap.add_action(n, 0.35)
	for e in evs:
		InputMap.action_add_event(n, e)

static func _key(k: int) -> InputEventKey:
	var e := InputEventKey.new(); e.physical_keycode = k; return e

static func _btn(b: int) -> InputEventJoypadButton:
	var e := InputEventJoypadButton.new(); e.button_index = b; return e

static func _axis(a: int, v: float) -> InputEventJoypadMotion:
	var e := InputEventJoypadMotion.new(); e.axis = a; e.axis_value = v; return e
