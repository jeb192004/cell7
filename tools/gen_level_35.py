#!/usr/bin/env python3
"""Builds scenes/levels/level_3_5.tscn (3-5 TITAN STRIDER: Renn vs the walker, Val on the Vagabond-9 for air support). One arena, town background."""
L = 1500
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
for i, p in [(1, "scripts/level.gd"), (23, "scripts/barrier.gd"), (50, "scripts/walker.gd")]:
    out.append('[ext_resource type="Script" path="res://%s" id="%d"]' % (p, i))
for i, p in [(2, "bg_town_sky"), (3, "bg_town_far"), (4, "bg_town_mid"), (5, "town_ground")]:
    out.append('[ext_resource type="Texture2D" path="res://assets/%s.png" id="%d"]' % (p, i))
for i, p in [(9, "cargo"), (12, "pip")]:
    out.append('[ext_resource type="PackedScene" path="res://scenes/%s.tscn" id="%d"]' % (p, i))
out.append("")
out.append('[node name="Level3_5" type="Node2D"]')
out.extend(['script = ExtResource("1")', 'length = %d.0' % L, 'title = "3-5 TITAN STRIDER"', 'next_level = "res://scenes/levels/level_3_6.tscn"', 'top = -80.0',
            'play_as = "renn"', 'boss_clear = true', ''])
n("Sky", ".", typ="CanvasLayer", props=["layer = -10"])
n("Sprite", "Sky", typ="Sprite2D", props=['texture = ExtResource("2")', 'centered = false'])
for nm, tex, z, sc in [("Far", 3, -30, 0.15), ("Mid", 4, -20, 0.4)]:
    n(nm, ".", typ="Parallax2D", props=["z_index = %d" % z, "scroll_scale = Vector2(%s, 0)" % sc, "repeat_size = Vector2(480, 0)", "repeat_times = 6"])
    n("Sprite", nm, typ="Sprite2D", props=['texture = ExtResource("%d")' % tex, 'centered = false'])
n("Ground", ".", typ="Parallax2D", props=["z_index = -5", "scroll_scale = Vector2(1, 1)", "repeat_size = Vector2(480, 0)", "repeat_times = 6"])
n("Sprite", "Ground", typ="Sprite2D", props=['texture = ExtResource("5")', 'centered = false'])
GR = 222
n("PlayerStart", ".", typ="Marker2D", pos=(130, GR))
n("Checkpoints", ".")
n("Props", ".")
# crates and barriers: cover from the walker's guns (shots stop on them)
for nm, x, st in [("Crate1", 300, 2), ("Crate2", 900, 1), ("Crate3", 1250, 2)]:
    n(nm, "Props", inst=9, pos=(x, GR + 1), props=(["stack = %d" % st] if st > 1 else []))
for nm, x in [("Barrier1", 410), ("Barrier2", 1020)]:
    n(nm, "Props", script=23, pos=(x, GR))
n("Pickups", ".")
for nm, x in [("Pip1", 250), ("Pip2", 1320)]:
    n(nm, "Pickups", inst=12, pos=(x, GR - 14))
n("Enemies", ".")
n("Walker", "Enemies", script=50, pos=(520, GR), props=["min_x = 300.0", "max_x = 1440.0"])
open("scenes/levels/level_3_5.tscn", "w").write("\n".join(out) + "\n")
print("wrote scenes/levels/level_3_5.tscn")
