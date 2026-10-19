#!/usr/bin/env python3
"""Builds scenes/levels/level_3_2.tscn (3-2 HOLD THE GATE: Brix + Renn). Run from the project root. Edit the lists below, or just open the scene in Godot and move things.
Layout, left to right: gantry (start) > drop to the dock floor > drop into the trench > stairs up > stairs up to a high catwalk > drop to the last stretch and the gate.
Brix jumps only ~43 px, so no wall climbs here: drops and stairs only. """
L = 4300
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
out.append('[node name="Level3_2" type="Node2D"]')
out.extend(['script = ExtResource("1")', 'length = %d.0' % L, 'title = "3-2 HOLD THE GATE"',
        'next_level = "res://scenes/levels/level_3_3.tscn"', 'top = -80.0', 'bottom = 480.0', 'multi_floor = true', 'ground = false', 'play_as = "brix"', 'crew_partner = "renn"', ''])
n("Sky", ".", typ="CanvasLayer", props=["layer = -10"])
n("Sprite", "Sky", typ="Sprite2D", props=['texture = ExtResource("2")', 'centered = false'])
for nm, tex, z, sc in [("Far", 3, -30, 0.15), ("Mid", 4, -20, 0.4)]:
    n(nm, ".", typ="Parallax2D", props=["z_index = %d" % z, "scroll_scale = Vector2(%s, 0)" % sc, "repeat_size = Vector2(480, 0)", "repeat_times = 14"])
    n("Sprite", nm, typ="Sprite2D", props=['texture = ExtResource("%d")' % tex, 'centered = false'])
# dark depth behind everything below the old street line, so the sunken floors do not show empty sky
n("Depths", ".", typ="ColorRect", props=["z_index = -40", "offset_left = -300.0", "offset_top = 255.0", "offset_right = %d.0" % (L + 300), "offset_bottom = 900.0", "color = Color(0.07, 0.08, 0.13, 1)"])

# floor heights
UP, BAY, PIT, HIGH = 110, 222, 318, 130
n("PlayerStart", ".", typ="Marker2D", pos=(100, UP - 2))
n("Exit", ".", typ="Marker2D", pos=(4200, BAY))
n("Checkpoints", ".")
for i, (x, y) in enumerate([(850, BAY), (1700, PIT), (2800, BAY), (3750, BAY)], 1):
    n("Checkpoint%d" % i, "Checkpoints", typ="Marker2D", pos=(x, y), props=['groups = ["checkpoint"]'])

n("Floors", ".")
def hull(name, x0, x1, top, thick, edge=False):
    p = ['script = ExtResource("40")', 'width = %d' % (x1 - x0), 'thick = %d' % thick]
    if edge: p.append('hazard_edge = true')
    out.append('[node name="%s" type="Node2D" parent="Floors"]' % name); out.append('z_index = -2'); out.append('position = Vector2(%d, %d)' % ((x0 + x1) // 2, top)); out.extend(p); out.append("")
def deck(name, x0, x1, top, script, extra=()):
    out.append('[node name="%s" type="Node2D" parent="Floors"]' % name); out.append('z_index = -1'); out.append('position = Vector2(%d, %d)' % ((x0 + x1) // 2, top))
    out.append('script = ExtResource("%d")' % script); out.append('width = %d' % (x1 - x0)); out.extend(list(extra)); out.append("")
def stairs(name, x, top, rise, d):
    out.append('[node name="%s" type="Node2D" parent="Floors"]' % name); out.append('z_index = -2'); out.append('position = Vector2(%d, %d)' % (x, top))
    out.extend(['script = ExtResource("20")', 'rise = %d' % rise, 'dir = %d' % d, ''])
hull("DockFloor", -400, 1500, BAY, 260)
hull("TrenchFloor", 1500, 2570, PIT, 150)
hull("UpperFloor", 2570, 4800, BAY, 260)
deck("Gantry", -40, 760, UP, 30, ["legs = false", "skirt = 4"])
deck("HighCatwalk", 2890, 3680, HIGH, 30, ["legs = false", "skirt = 4"])
stairs("StairsUp1", 2450, PIT, PIT - BAY, 1)
stairs("StairsUp2", 2775, BAY, BAY - HIGH, 1)

n("Props", ".")
def crate(name, x, y, stack=1):
    n(name, "Props", inst=9, pos=(x, y + 1), props=(["stack = %d" % stack] if stack > 1 else []))
def barrier(name, x, y):
    n(name, "Props", script=23, pos=(x, y))
crate("Crate1", 330, UP, 1); crate("Crate2", 620, UP, 2)
crate("Crate3", 860, BAY, 2); barrier("Barrier1", 1000, BAY); crate("Crate4", 1120, BAY, 1); crate("Crate5", 1240, BAY, 2); barrier("Barrier2", 1400, BAY)
barrier("Barrier3", 1650, PIT); crate("Crate6", 1760, PIT, 2); barrier("Barrier4", 1900, PIT); crate("Crate7", 2020, PIT, 1); crate("Crate8", 2150, PIT, 2); barrier("Barrier5", 2300, PIT)
crate("Crate9", 2680, BAY, 1); crate("Crate10", 3050, BAY, 2); barrier("Barrier6", 3250, BAY); crate("Crate11", 3480, BAY, 1)
crate("Crate12", 3030, HIGH, 1); barrier("Barrier7", 3300, HIGH); crate("Crate13", 3560, HIGH, 2)
crate("Crate14", 3800, BAY, 2); barrier("Barrier8", 3940, BAY); crate("Crate15", 4040, BAY, 1)

n("Enemies", ".")
def warden(name, x, y, rng, shield=False, facing=-1):
    pr = ["patrol_range = %d.0" % rng]
    if facing == 1: pr.append("start_facing = 1")
    n(name, "Enemies", inst=10 if shield else 7, pos=(x, y + 2), props=pr)
warden("Warden1", 430, UP, 60)
warden("Warden2", 920, BAY, 50); warden("Warden3", 1180, BAY, 60); warden("ShieldWarden1", 1330, BAY, 40)
warden("Warden4", 1780, PIT, 60); warden("ShieldWarden2", 1960, PIT, 50); warden("Warden5", 2120, PIT, 50); warden("Warden6", 2310, PIT, 30)
warden("Warden7", 2720, BAY, 40)
warden("ShieldWarden3", 3080, HIGH, 50); warden("Warden8", 3400, HIGH, 60); warden("Warden9", 3600, HIGH, 40)
warden("Warden10", 3120, BAY, 60); warden("ShieldWarden4", 3380, BAY, 50)
warden("Warden11", 3860, BAY, 50); warden("ShieldWarden5", 4000, BAY, 40); warden("Warden12", 4130, BAY, 30)
n("Drone1", "Enemies", inst=8, pos=(1000, 150))
n("Drone2", "Enemies", inst=8, pos=(3800, 150))
n("Bomber1", "Enemies", inst=11, pos=(1700, 220))
n("Bomber2", "Enemies", inst=11, pos=(2250, 230))
n("Bomber3", "Enemies", inst=11, pos=(3500, 60))
open("scenes/levels/level_3_2.tscn", "w").write("\n".join(out) + "\n")
print("wrote scenes/levels/level_3_2.tscn")
