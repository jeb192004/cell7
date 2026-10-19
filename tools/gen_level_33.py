#!/usr/bin/env python3
"""Builds scenes/levels/level_3_3.tscn (3-3 LOADING UP: Kesh holds the loader while the crates go aboard). Run from the project root. Edit the lists below, or just open the scene in Godot and move things.
One arena: the bay 7 floor with a catwalk on each side (stairs up from the floor). Wardens keep arriving from both ends (wave_spawn markers); survive the timer."""
L = 1500
out = []
def n(name, parent, extra="", typ="Node2D", inst=None, script=None, pos=None, props=()):
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
for i, p in [(1, "scripts/level.gd"), (20, "scripts/stairs.gd"), (21, "scripts/deck.gd"), (23, "scripts/barrier.gd"), (30, "scripts/catwalk.gd"), (31, "scripts/gantry.gd"), (40, "scripts/hull.gd")]:
    out.append('[ext_resource type="Script" path="res://%s" id="%d"]' % (p, i))
for i, p in [(2, "bg_ship_sky"), (3, "bg_ship_far"), (4, "bg_ship_mid")]:
    out.append('[ext_resource type="Texture2D" path="res://assets/%s.png" id="%d"]' % (p, i))
for i, p in [(7, "warden"), (8, "drone"), (9, "cargo"), (10, "warden_shield"), (11, "bomber")]:
    out.append('[ext_resource type="PackedScene" path="res://scenes/%s.tscn" id="%d"]' % (p, i))
out.append("")
out.append('[node name="Level3_3" type="Node2D"]')
out.extend(['script = ExtResource("1")', 'length = %d.0' % L, 'title = "3-3 LOADING UP"',
        'next_level = "res://scenes/levels/level_3_4.tscn"', 'top = -60.0', 'multi_floor = true', 'survive_time = 45.0', 'survive_label = "THE LOADER FINISHES IN"', 'survive_boss = false', 'ground = false', 'wave_every = 4.5', 'wave_max = 6', ''])
n("Sky", ".", typ="CanvasLayer", props=["layer = -10"])
n("Sprite", "Sky", typ="Sprite2D", props=['texture = ExtResource("2")', 'centered = false'])
for nm, tex, z, sc in [("Far", 3, -30, 0.15), ("Mid", 4, -20, 0.4)]:
    n(nm, ".", typ="Parallax2D", props=["z_index = %d" % z, "scroll_scale = Vector2(%s, 0)" % sc, "repeat_size = Vector2(480, 0)", "repeat_times = 14"])
    n("Sprite", nm, typ="Sprite2D", props=['texture = ExtResource("%d")' % tex, 'centered = false'])
BAY, HIGH = 222, 130
n("PlayerStart", ".", typ="Marker2D", pos=(750, BAY))
n("Checkpoints", ".")
n("Spawns", ".")
for nm, x in [("SpawnL", 20), ("SpawnR", 1480)]:
    n(nm, "Spawns", typ="Marker2D", pos=(x, BAY + 2), props=['groups = ["wave_spawn"]'])

n("Floors", ".")
def hull(name, x0, x1, top, thick):
    out.append('[node name="%s" type="Node2D" parent="Floors"]' % name); out.append('z_index = -2'); out.append('position = Vector2(%d, %d)' % ((x0 + x1) // 2, top))
    out.extend(['script = ExtResource("40")', 'width = %d' % (x1 - x0), 'thick = %d' % thick, ""])
def deck(name, x0, x1, top, script, extra=()):
    out.append('[node name="%s" type="Node2D" parent="Floors"]' % name); out.append('z_index = -1'); out.append('position = Vector2(%d, %d)' % ((x0 + x1) // 2, top))
    out.append('script = ExtResource("%d")' % script); out.append('width = %d' % (x1 - x0)); out.extend(list(extra)); out.append("")
def stairs(name, x, top, rise, d):
    out.append('[node name="%s" type="Node2D" parent="Floors"]' % name); out.append('z_index = -2'); out.append('position = Vector2(%d, %d)' % (x, top))
    out.extend(['script = ExtResource("20")', 'rise = %d' % rise, 'dir = %d' % d, ''])
hull("DockFloor", -400, 1900, BAY, 260)
deck("CatwalkL", 230, 700, HIGH, 30, ["legs = false", "skirt = 4"])
deck("CatwalkR", 800, 1270, HIGH, 30, ["legs = false", "skirt = 4"])
stairs("StairsL", 115, BAY, BAY - HIGH, 1)
stairs("StairsR", 1385, BAY, BAY - HIGH, -1)

n("Props", ".")
def crate(name, x, y, stack=1):
    n(name, "Props", inst=9, pos=(x, y + 1), props=(["stack = %d" % stack] if stack > 1 else []))
def barrier(name, x, y):
    n(name, "Props", script=23, pos=(x, y))
crate("Crate1", 330, BAY, 2); barrier("Barrier1", 520, BAY); crate("Crate2", 660, BAY, 1)
crate("Crate3", 850, BAY, 1); barrier("Barrier2", 980, BAY); crate("Crate4", 1170, BAY, 2)
crate("Crate5", 400, HIGH, 1); crate("Crate6", 1100, HIGH, 1)

n("Enemies", ".")
n("Drone1", "Enemies", inst=8, pos=(450, 90))
n("Drone2", "Enemies", inst=8, pos=(1050, 90))
n("Bomber1", "Enemies", inst=11, pos=(750, 40))
open("scenes/levels/level_3_3.tscn", "w").write("\n".join(out) + "\n")
print("wrote scenes/levels/level_3_3.tscn")
