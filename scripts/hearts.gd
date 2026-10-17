class_name Hearts
extends Node2D
## Health pips, top-left.
var player
var prev_ammo := 5.0
var big_text := ""
var big_t := 0.0
func _armed() -> bool:
	var dd = player.get("def") if player != null else null   # bike / ship players have no def
	return dd == null or dd.can_shoot
func _process(d: float) -> void:
	if player != null and not player.get("infinite_ammo") and _armed():
		if player.ammo < 2.0 and prev_ammo >= 2.0: big_text = "LAST SHOT"; big_t = 1.1
		if player.ammo < 1.0 and prev_ammo >= 1.0: big_text = "EMPTY"; big_t = 1.1
		if player.dry_t > 0.2: big_text = "EMPTY"; big_t = 0.8   # tried to fire with nothing left
		prev_ammo = player.ammo
	big_t = maxf(big_t - d, 0.0)
	queue_redraw()
func _draw() -> void:
	if player == null: return
	for i in int(player.max_hp):
		var x: int = 8 + i * 14
		var full: bool = i < player.hp
		draw_rect(Rect2(x - 1, 7, 12, 12), Color(0.1, 0.07, 0.12))
		draw_rect(Rect2(x, 8, 10, 10), Color(0.95, 0.72, 0.25) if full else Color(0.3, 0.24, 0.3))
		if full: draw_rect(Rect2(x + 1, 9, 4, 3), Color(1, 0.93, 0.7))
	if player.get("sprinting"):   # sprint is toggled on (keyboard, gamepad or the touch RUN button)
		draw_rect(Rect2(7, 23, 26, 11), Color(0.1, 0.07, 0.12))
		draw_rect(Rect2(8, 24, 24, 9), Color(0.95, 0.72, 0.25))
		PixFont.draw(self, "RUN", Vector2(11, 25), 1, Color(0.1, 0.07, 0.12), false)
	if player.get("concealed"):
		var o := Vector2(40, 24)
		draw_rect(Rect2(o.x - 1, o.y - 1, 16, 8), Color(0.1, 0.07, 0.12))
		draw_rect(Rect2(o.x, o.y, 14, 6), Color(0.85, 0.85, 0.8))
		draw_rect(Rect2(o.x + 5, o.y, 4, 6), Color(0.2, 0.55, 0.6))
		draw_rect(Rect2(o.x + 6, o.y + 2, 2, 2), Color(0.05, 0.05, 0.08))
	if player.get("infinite_ammo") or not _armed(): return
	# slingshot charges, next to the hearts
	var ax: int = 8 + int(player.max_hp) * 14 + 8
	var mx = player.get("max_ammo")
	for i in int(mx if mx != null else player.MAX_AMMO):
		var f: float = clampf(player.ammo - i, 0.0, 1.0)
		var back := Color(0.55, 0.15, 0.12) if player.dry_t > 0.0 else Color(0.1, 0.07, 0.12)
		draw_rect(Rect2(ax + i * 8 - 1, 9, 8, 10), back)
		draw_rect(Rect2(ax + i * 8, 10, 6, 8), Color(0.3, 0.24, 0.3))
		if f > 0.0: draw_rect(Rect2(ax + i * 8, 18 - int(8.0 * f), 6, int(8.0 * f)), Color(0.45, 0.85, 1.0))
	# warning: one charge left / none left
	var blink := int(Time.get_ticks_msec() / 200.0) % 2 == 0
	if player.ammo < 1.0:
		PixFont.draw(self, "EMPTY", Vector2(ax, 22), 1, Color(1.0, 0.35, 0.3) if blink else Color(0.6, 0.2, 0.18))
	elif player.ammo < 2.0:
		PixFont.draw(self, "LAST SHOT", Vector2(ax, 22), 1, Color(1.0, 0.8, 0.3) if blink else Color(0.7, 0.5, 0.2))
	if big_t > 0.0:   # big, high on the screen so it doesn't cover the action
		var col := Color(1.0, 0.35, 0.3) if big_text == "EMPTY" else Color(1.0, 0.8, 0.3)
		col.a = clampf(big_t / 0.3, 0.0, 1.0) * (1.0 if int(Time.get_ticks_msec() / 130.0) % 2 == 0 else 0.55)
		var w := PixFont.text_width(big_text, 4)
		PixFont.draw(self, big_text, Vector2(240 - w / 2.0, 52), 4, col)
