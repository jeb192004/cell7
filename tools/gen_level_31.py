#!/usr/bin/env python3
"""Builds scenes/levels/level_3_1.tscn (3-1 CARGO BAY 7). Run from the project root. Edit the lists below, or just open the scene in Godot and move things.
Layout, left to right: upper catwalk (start) > drop to bay floor > drop into the sunken loading pit > climb the wall on ledges >
high catwalk over a lower floor > stairs down > last stretch to the bay 7 door."""
L = 4500
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
out.append('[node name="Level3_1" type="Node2D"]')
out.extend(['script = ExtResource("1")', 'length = %d.0' % L, 'title = "3-1 CARGO BAY 7"',
        'next_level = ""', 'top = -80.0', 'bottom = 480.0', 'multi_floor = true', 'ground = false', ''])
n("Sky", ".", typ="CanvasLayer", props=["layer = -10"])
n("Sprite", "Sky", typ="Sprite2D", props=['texture = ExtResource("2")', 'centered = false'])
for nm, tex, z, sc in [("Far", 3, -30, 0.15), ("Mid", 4, -20, 0.4)]:
    n(nm, ".", typ="Parallax2D", props=["z_index = %d" % z, "scroll_scale = Vector2(%s, 0)" % sc, "repeat_size = Vector2(480, 0)", "repeat_times = 14"])
    n("Sprite", nm, typ="Sprite2D", props=['texture = ExtResource("%d")' % tex, 'centered = false'])
# dark depth behind everything below the old street line, so the sunken floors do not show empty sky
n("Depths", ".", typ="ColorRect", props=["z_index = -40", "offset_left = -300.0", "offset_top = 255.0", "offset_right = %d.0" % (L + 300), "offset_bottom = 900.0", "color = Color(0.07, 0.08, 0.13, 1)"])

# floor heights
UP, BAY, PIT, HIGH = 100, 222, 330, 118
n("PlayerStart", ".", typ="Marker2D", pos=(100, UP - 2))
n("Exit", ".", typ="Marker2D", pos=(4380, PIT))
n("Checkpoints", ".")
for i, (x, y) in enumerate([(850, BAY), (1560, PIT), (2540, HIGH), (3700, PIT)], 1):
    n("Checkpoint%d" % i, "Checkpoints", typ="Marker2D", pos=(x, y), props=['groups = ["checkpoint"]'])

# solid floors, walls
n("Floors", ".")
def hull(name, x0, x1, top, thick, edge=False):
    p = ['script = ExtResource("40")', 'width = %d' % (x1 - x0), 'thick = %d' % thick]
    if edge: p.append('hazard_edge = true')
    out.append('[node name="%s" type="Node2D" parent="Floors"]' % name); out.append('z_index = -2'); out.append('position = Vector2(%d, %d)' % ((x0 + x1) // 2, top)); out.extend(p); out.append("")
def deck(name, x0, x1, top, script, extra=()):
    out.append('[node name="%s" type="Node2D" parent="Floors"]' % name); out.append('z_index = -1'); out.append('position = Vector2(%d, %d)' % ((x0 + x1) // 2, top))
    out.append('script = ExtResource("%d")' % script); out.append('width = %d' % (x1 - x0)); out.extend(list(extra)); out.append("")
hull("BayFloor", -400, 1500, BAY, 260)
hull("PitFloor", 1500, 2400, PIT, 150)
hull("Wall", 2400, 2480, HIGH, 300)
hull("LowFloor", 2480, 4900, PIT, 150)
deck("UpperCatwalk", -40, 760, UP, 30, ["legs = false", "skirt = 4"])
deck("HighCatwalk", 2480, 3320, HIGH, 30, ["legs = false", "skirt = 4"])
# climb the wall: staggered one-way ledges, each 38 px above the last
for i, (x, y) in enumerate([(2350, 292), (2280, 254), (2350, 216), (2280, 178), (2350, 140)], 1):
    deck("Ledge%d" % i, x - 40, x + 40, y, 21, ["legs = false", "skirt = 6"])
out.append('[node name="StairsDown" type="Node2D" parent="Floors"]'); out.append('z_index = -2'); out.append('position = Vector2(3585, %d)' % PIT)
out.extend(['script = ExtResource("20")', 'rise = %d' % (PIT - HIGH), 'dir = -1', ''])

n("Props", ".")
def crate(name, x, y, stack=1):
    n(name, "Props", inst=9, pos=(x, y + 1), props=(["stack = %d" % stack] if stack > 1 else []))
def barrier(name, x, y):
    n(name, "Props", script=23, pos=(x, y))
# upper catwalk
crate("Crate1", 330, UP, 1); crate("Crate2", 640, UP, 2)
# bay floor
crate("Crate3", 840, BAY, 2); barrier("Barrier1", 1000, BAY); crate("Crate4", 1120, BAY, 1); crate("Crate5", 1230, BAY, 2); barrier("Barrier2", 1400, BAY)
# pit
barrier("Barrier3", 1640, PIT); crate("Crate6", 1730, PIT, 2); crate("Crate7", 1900, PIT, 1); barrier("Barrier4", 2000, PIT); crate("Crate8", 2130, PIT, 2); barrier("Barrier5", 2300, PIT)
# high catwalk + low floor under it
crate("Crate9", 2700, HIGH, 2); barrier("Barrier6", 2960, HIGH); crate("Crate10", 3150, HIGH, 1)
crate("Crate11", 2800, PIT, 2); crate("Crate12", 3000, PIT, 1); crate("Crate13", 3300, PIT, 2)
# last stretch
crate("Crate14", 3720, PIT, 2); barrier("Barrier7", 3860, PIT); crate("Crate15", 3990, PIT, 1); crate("Crate16", 4130, PIT, 2); barrier("Barrier8", 4260, PIT)

n("Enemies", ".")
def warden(name, x, y, rng, shield=False, facing=-1):
    pr = ["patrol_range = %d.0" % rng]
    if facing == 1: pr.append("start_facing = 1")
    n(name, "Enemies", inst=10 if shield else 7, pos=(x, y + 2), props=pr)
warden("Warden1", 470, UP, 60)
warden("Warden2", 900, BAY, 50); warden("Warden3", 1180, BAY, 60); warden("ShieldWarden1", 1320, BAY, 40)
warden("Warden4", 1800, PIT, 70); warden("ShieldWarden2", 2050, PIT, 50); warden("Warden5", 2250, PIT, 40)
warden("Warden6", 2800, HIGH, 80); warden("Warden7", 3150, HIGH, 50)
warden("Warden8", 3900, PIT, 60); warden("ShieldWarden3", 4050, PIT, 40); warden("Warden9", 4200, PIT, 40)
n("Drone1", "Enemies", inst=8, pos=(1100, 150))
n("Bomber1", "Enemies", inst=11, pos=(1450, 140))
n("Bomber2", "Enemies", inst=11, pos=(1950, 250))
n("Bomber3", "Enemies", inst=11, pos=(3000, 40))
n("Bomber4", "Enemies", inst=11, pos=(4000, 250))
open("scenes/levels/level_3_1.tscn", "w").write("\n".join(out) + "\n")
print("wrote scenes/levels/level_3_1.tscn")
