#!/usr/bin/env python3
"""Builds scenes/levels/level_3_7.tscn (3-7 CORVANE: Brix fights through a squad of Wardens, then Head Warden Corvane one on one on the landing pad).
No pips on this level: Brix is meant to lose. Corvane stays hidden until the squad is down, can't be killed, and when Brix is down to 1 pip the push cutscene (Kesh throws him back with the Current) plays."""
L = 2500
out = []
def n(name, parent, typ="Node2D", inst=None, script=None, pos=None, props=()):
    h = '[node name="%s"' % name
    if not inst: h += ' type="%s"' % typ
    if parent: h += ' parent="%s"' % parent
    if inst: h += ' instance=ExtResource("%s")' % inst
    gp = [x for x in props if x.startswith("groups")]
    props = [x for x in props if not x.startswith("groups")]
    if gp: h += ' ' + gp[0].replace(' = ', '=')
    out.append(h + ']')
    if script: out.append('script = ExtResource("%s")' % script)
    if pos is not None: out.append('position = Vector2(%s, %s)' % pos)
    out.extend(props)
    out.append("")
out.append('[gd_scene format=3]\n')
for i, p in [(1, "scripts/level.gd"), (23, "scripts/barrier.gd")]:
    out.append('[ext_resource type="Script" path="res://%s" id="%d"]' % (p, i))
for i, p in [(2, "bg_town_sky"), (3, "bg_town_far"), (4, "bg_town_mid"), (5, "town_ground")]:
    out.append('[ext_resource type="Texture2D" path="res://assets/%s.png" id="%d"]' % (p, i))
for i, p in [(7, "warden"), (9, "cargo"), (10, "warden_shield"), (13, "corvane")]:
    out.append('[ext_resource type="PackedScene" path="res://scenes/%s.tscn" id="%d"]' % (p, i))
out.append("")
out.append('[node name="Level3_7" type="Node2D"]')
out.extend(['script = ExtResource("1")', 'length = %d.0' % L, 'title = "3-7 CORVANE"', 'top = -80.0',
            'play_as = "brix"', 'boss_clear = true', 'finale_cutscene = true', ''])
n("Sky", ".", typ="CanvasLayer", props=["layer = -10"])
n("Sprite", "Sky", typ="Sprite2D", props=['texture = ExtResource("2")', 'centered = false'])
for nm, tex, z, sc in [("Far", 3, -30, 0.15), ("Mid", 4, -20, 0.4)]:
    n(nm, ".", typ="Parallax2D", props=["z_index = %d" % z, "scroll_scale = Vector2(%s, 0)" % sc, "repeat_size = Vector2(480, 0)", "repeat_times = 8"])
    n("Sprite", nm, typ="Sprite2D", props=['texture = ExtResource("%d")' % tex, 'centered = false'])
n("Ground", ".", typ="Parallax2D", props=["z_index = -5", "scroll_scale = Vector2(1, 1)", "repeat_size = Vector2(480, 0)", "repeat_times = 8"])
n("Sprite", "Ground", typ="Sprite2D", props=['texture = ExtResource("5")', 'centered = false'])
GR = 222
n("PlayerStart", ".", typ="Marker2D", pos=(120, GR))
n("Checkpoints", ".")
for i, x in enumerate([1000, 1700], 1):
    n("Checkpoint%d" % i, "Checkpoints", typ="Marker2D", pos=(x, GR), props=['groups = ["checkpoint"]'])
n("Props", ".")
def crate(name, x, st=1): n(name, "Props", inst=9, pos=(x, GR + 1), props=(["stack = %d" % st] if st > 1 else []))
def barrier(name, x): n(name, "Props", script=23, pos=(x, GR))
# the squad street
crate("Crate1", 330, 2); barrier("Barrier1", 520); crate("Crate2", 760, 1); crate("Crate3", 1040, 2); barrier("Barrier2", 1220); crate("Crate4", 1380, 2)
# Corvane's arena: tall cover for Brix (he needs a 2-stack), a few barriers
crate("Crate5", 1850, 2); crate("Crate6", 2100, 2); barrier("Barrier3", 1990); crate("Crate7", 2300, 2)
n("Enemies", ".")
def warden(name, x, rng, shield=False):
    n(name, "Enemies", inst=10 if shield else 7, pos=(x, GR + 2), props=["patrol_range = %d.0" % rng])
warden("Warden1", 600, 50); warden("Warden2", 860, 60); warden("ShieldWarden1", 1000, 40); warden("Warden3", 1150, 60)
warden("ShieldWarden2", 1300, 40); warden("Warden4", 1450, 60); warden("Warden5", 1560, 50)
n("Corvane", "Enemies", inst=13, pos=(2050, GR), props=["hp = 40", "finale_hp = 1", "finale_at_pip = 1", "wait_for_squad = true", "min_x = 900.0", "max_x = %d.0" % (L - 150)])
open("scenes/levels/level_3_7.tscn", "w").write("\n".join(out) + "\n")
print("wrote scenes/levels/level_3_7.tscn")
