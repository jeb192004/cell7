#!/usr/bin/env python3
"""Builds scenes/levels/level_3_6.tscn (3-6 STRIDER TRAP: Fuse vs the second Titan Strider: plant charges, lure it over them). One arena, town background."""
L = 2000
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
for i, p in [(1, "scripts/level.gd"), (23, "scripts/barrier.gd"), (50, "scripts/walker.gd"), (10, "scripts/charge_spot.gd")]:
    out.append('[ext_resource type="Script" path="res://%s" id="%d"]' % (p, i))
for i, p in [(2, "bg_town_sky"), (3, "bg_town_far"), (4, "bg_town_mid"), (5, "town_ground")]:
    out.append('[ext_resource type="Texture2D" path="res://assets/%s.png" id="%d"]' % (p, i))
for i, p in [(9, "cargo"), (12, "pip")]:
    out.append('[ext_resource type="PackedScene" path="res://scenes/%s.tscn" id="%d"]' % (p, i))
out.append("")
out.append('[node name="Level3_6" type="Node2D"]')
out.extend(['script = ExtResource("1")', 'length = %d.0' % L, 'title = "3-6 STRIDER TRAP"', 'next_level = "res://scenes/levels/level_3_7.tscn"', 'top = -80.0',
            'play_as = "fuse"', 'boss_clear = true', 'corvane_cutscene = true', ''])
n("Sky", ".", typ="CanvasLayer", props=["layer = -10"])
n("Sprite", "Sky", typ="Sprite2D", props=['texture = ExtResource("2")', 'centered = false'])
for nm, tex, z, sc in [("Far", 3, -30, 0.15), ("Mid", 4, -20, 0.4)]:
    n(nm, ".", typ="Parallax2D", props=["z_index = %d" % z, "scroll_scale = Vector2(%s, 0)" % sc, "repeat_size = Vector2(480, 0)", "repeat_times = 6"])
    n("Sprite", nm, typ="Sprite2D", props=['texture = ExtResource("%d")' % tex, 'centered = false'])
n("Ground", ".", typ="Parallax2D", props=["z_index = -5", "scroll_scale = Vector2(1, 1)", "repeat_size = Vector2(480, 0)", "repeat_times = 6"])
n("Sprite", "Ground", typ="Sprite2D", props=['texture = ExtResource("5")', 'centered = false'])
GR = 222
n("PlayerStart", ".", typ="Marker2D", pos=(560, GR))
n("Checkpoints", ".")
n("Props", ".")
# crates and barriers: cover from the walker's guns (shots stop on them)
for nm, x, st in [("Crate1", 480, 2), ("Crate2", 840, 1), ("Crate3", 1100, 2), ("Crate4", 1380, 1), ("Crate5", 1640, 2)]:
    n(nm, "Props", inst=9, pos=(x, GR + 1), props=(["stack = %d" % st] if st > 1 else []))
for nm, x in [("Barrier1", 650), ("Barrier2", 980), ("Barrier3", 1500)]:
    n(nm, "Props", script=23, pos=(x, GR))
n("ChargeSpots", ".")
for i, x in enumerate([720, 960, 1210, 1450], 1):
    n("Spot%d" % i, "ChargeSpots", script=10, pos=(x, GR))
n("Pickups", ".")
for nm, x in [("Pip1", 600), ("Pip2", 1050), ("Pip3", 1560)]:
    n(nm, "Pickups", inst=12, pos=(x, GR - 14))
n("Enemies", ".")
n("Walker", "Enemies", script=50, pos=(1750, GR), props=["min_x = 450.0", "max_x = 1900.0", "hp = 28", "fuse_mode = true", "keep_dist = 150.0", "stomp_dist = 85.0"])
open("scenes/levels/level_3_6.tscn", "w").write("\n".join(out) + "\n")
print("wrote scenes/levels/level_3_6.tscn")
