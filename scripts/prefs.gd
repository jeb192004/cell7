class_name Prefs
## Tiny saved-settings helper (user://prefs.cfg). Tips already shown are remembered so they only pop up once.
const PATH := "user://prefs.cfg"
static func seen(tip: String) -> bool:
	var c := ConfigFile.new()
	if c.load(PATH) != OK: return false
	return bool(c.get_value("tips", tip, false))
static func mark_seen(tip: String) -> void:
	var c := ConfigFile.new()
	c.load(PATH)
	c.set_value("tips", tip, true)
	c.save(PATH)
static func reset_tips() -> void:
	var c := ConfigFile.new()
	c.load(PATH)
	if c.has_section("tips"): c.erase_section("tips")
	c.save(PATH)
static func get_num(section: String, key: String, def: float) -> float:
	var c := ConfigFile.new()
	if c.load(PATH) != OK: return def
	return float(c.get_value(section, key, def))
static func set_num(section: String, key: String, v: float) -> void:
	var c := ConfigFile.new()
	c.load(PATH)
	c.set_value(section, key, v)
	c.save(PATH)
static func delete_all() -> void:
	if FileAccess.file_exists(PATH): DirAccess.remove_absolute(ProjectSettings.globalize_path(PATH))
