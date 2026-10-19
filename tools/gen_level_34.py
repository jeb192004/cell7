#!/usr/bin/env python3
"""Builds scenes/levels/level_3_4.tscn (3-4 THE SALE: Kesh runs the Lantern Rest market to the Vagabond-9). Run from the project root. Edit the lists below, or just open the scene in Godot and move things.
Street with two raised market walkways (stairs up and down), Wardens on both floors."""
L = 3800
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
for i, p in [(2, "bg_town_sky"), (3, "bg_town_far"), (4, "bg_town_mid"), (5, "town_ground")]:
    out.append('[ext_resource type="Texture2D" path="res://assets/%s.png" id="%d"]' % (p, i))
for i, p in [(7, "warden"), (8, "drone"), (9, "cargo"), (10, "warden_shield"), (11, "bomber")]:
    out.append('[ext_resource type="PackedScene" path="res://scenes/%s.tscn" id="%d"]' % (p, i))
out.append("")
out.append('[node name="Level3_4" type="Node2D"]')
out.extend(['script = ExtResource("1")', 'length = %d.0' % L, 'title = "3-4 THE SALE"',
        'next_level = "res://scenes/levels/level_3_5.tscn"', 'top = -60.0', 'multi_floor = true', ''])
n("Sky", ".", typ="CanvasLayer", props=["layer = -10"])
n("Sprite", "Sky", typ="Sprite2D", props=['texture = ExtResource("2")', 'centered = false'])
for nm, tex, z, sc in [("Far", 3, -30, 0.15), ("Mid", 4, -20, 0.4)]:
    n(nm, ".", typ="Parallax2D", props=["z_index = %d" % z, "scroll_scale = Vector2(%s, 0)" % sc, "repeat_size = Vector2(480, 0)", "repeat_times = 14"])
    n("Sprite", nm, typ="Sprite2D", props=['texture = ExtResource("%d")' % tex, 'centered = false'])
n("Ground", ".", typ="Parallax2D", props=["z_index = -5", "scroll_scale = Vector2(1, 1)", "repeat_size = Vector2(480, 0)", "repeat_times = 12"])
n("Sprite", "Ground", typ="Sprite2D", props=['texture = ExtResource("5")', 'centered = false'])
GR, HIGH = 222, 150
n("PlayerStart", ".", typ="Marker2D", pos=(100, GR))
n("Exit", ".", typ="Marker2D", pos=(3720, GR))
n("Checkpoints", ".")
for i, (x, y) in enumerate([(900, GR), (2050, GR), (2780, GR)], 1):
    n("Checkpoint%d" % i, "Checkpoints", typ="Marker2D", pos=(x, y), props=['groups = ["checkpoint"]'])

n("Floors", ".")
def deck(name, x0, x1, top, script, extra=()):
    out.append('[node name="%s" type="Node2D" parent="Floors"]' % name); out.append('z_index = -1'); out.append('position = Vector2(%d, %d)' % ((x0 + x1) // 2, top))
    out.append('script = ExtResource("%d")' % script); out.append('width = %d' % (x1 - x0)); out.extend(list(extra)); out.append("")
def stairs(name, x, top, rise, d):
    out.append('[node name="%s" type="Node2D" parent="Floors"]' % name); out.append('z_index = -2'); out.append('position = Vector2(%d, %d)' % (x, top))
    out.extend(['script = ExtResource("20")', 'rise = %d' % rise, 'dir = %d' % d, ''])
RISE = GR - HIGH
deck("Walkway1", 990, 1900, HIGH, 30, ["legs = false", "skirt = 4"])
stairs("StairsUp1", 900, GR, RISE, 1); stairs("StairsDown1", 1990, GR, RISE, -1)
deck("Walkway2", 2790, 3500, HIGH, 30, ["legs = false", "skirt = 4"])
stairs("StairsUp2", 2700, GR, RISE, 1); stairs("StairsDown2", 3590, GR, RISE, -1)

n("Props", ".")
def crate(name, x, y, stack=1):
    n(name, "Props", inst=9, pos=(x, y + 1), props=(["stack = %d" % stack] if stack > 1 else []))
def barrier(name, x, y):
    n(name, "Props", script=23, pos=(x, y))
crate("Crate1", 330, GR, 2); barrier("Barrier1", 520, GR); crate("Crate2", 700, GR, 1)
crate("Crate3", 1150, GR, 2); crate("Crate4", 1450, GR, 1); barrier("Barrier2", 1700, GR)
crate("Crate5", 1150, HIGH, 1); barrier("Barrier3", 1450, HIGH); crate("Crate6", 1750, HIGH, 2)
crate("Crate7", 2100, GR, 2); barrier("Barrier4", 2300, GR); crate("Crate8", 2480, GR, 1); barrier("Barrier5", 2620, GR)
crate("Crate9", 2950, HIGH, 1); barrier("Barrier6", 3200, HIGH); crate("Crate10", 3400, HIGH, 2)
crate("Crate11", 3000, GR, 2); barrier("Barrier7", 3250, GR); crate("Crate12", 3550, GR, 1)

n("Enemies", ".")
def warden(name, x, y, rng, shield=False, facing=-1):
    pr = ["patrol_range = %d.0" % rng]
    if facing == 1: pr.append("start_facing = 1")
    n(name, "Enemies", inst=10 if shield else 7, pos=(x, y + 2), props=pr)
warden("Warden1", 560, GR, 50); warden("Warden2", 760, GR, 60)
warden("Warden3", 1230, HIGH, 60); warden("Warden4", 1500, HIGH, 60); warden("ShieldWarden1", 1760, HIGH, 40)
warden("Warden5", 1100, GR, 60); warden("ShieldWarden2", 1420, GR, 50)
warden("Warden6", 2130, GR, 50); warden("ShieldWarden3", 2320, GR, 40); warden("Warden7", 2540, GR, 50)
warden("Warden8", 3000, HIGH, 60); warden("ShieldWarden4", 3280, HIGH, 40)
warden("Warden9", 3100, GR, 60); warden("Warden10", 3450, GR, 50); warden("ShieldWarden5", 3600, GR, 40)
n("Drone1", "Enemies", inst=8, pos=(700, 130))
n("Drone2", "Enemies", inst=8, pos=(2250, 120))
n("Bomber1", "Enemies", inst=11, pos=(1350, 70))
n("Bomber2", "Enemies", inst=11, pos=(2900, 70))
open("scenes/levels/level_3_4.tscn", "w").write("\n".join(out) + "\n")
print("wrote scenes/levels/level_3_4.tscn")
