#!/usr/bin/env python3
"""Writes the four chapter 2 level scenes (placeholder art). Edit the scenes in Godot afterwards."""
import os
OUT = os.path.join(os.path.dirname(__file__), '..', 'scenes', 'levels')
LV = {
 '2_1': dict(name='Level2_1', title='2-1 THE MERIDIAN', length=3600, next='level_2_2', bg='ship', cover='cargo', exitx=3480,
    W=[(780, -1, 50, 0), (1150, -1, 40, 0), (1560, -1, 60, 0), (1900, -1, 40, 1), (2260, -1, 50, 0), (2600, -1, 40, 0), (2980, -1, 40, 1), (3250, -1, 50, 0)],
    D=[(520, 150), (1400, 140), (2140, 150), (2800, 135)],
    C=[(320, 1), (600, 2), (680, 1), (1040, 2), (1110, 1), (1460, 1), (1650, 2), (1800, 1), (2090, 2), (2200, 1), (2480, 2), (2700, 1), (2880, 2), (3120, 1), (3330, 2)],
    CP=[1000, 2050, 2800], extra=''),
 '2_2': dict(name='Level2_2', title='2-2 THE VENTS', length=4200, next='level_2_3', bg='bay', cover='cargo', exitx=4080,
    W=[(820, -1, 40, 0), (2000, 1, 60, 0), (3050, -1, 60, 0), (3300, 1, 40, 1), (3950, -1, 50, 0)],
    D=[(1900, 140), (3450, 135)],
    C=[(320, 1), (480, 2), (1700, 1), (1734, 2), (1768, 3), (2766, 3), (2800, 2), (2834, 1), (3000, 2), (3200, 1), (3420, 2), (3800, 1), (4000, 2)],
    CP=[1680, 2870, 3760], extra='stealth_only = true',
    V=[('VentA', 580, 222, 1000), ('VentB', 1790, 115, 910), ('VentC', 2970, 300, 700)],
    G=[('A1', 560, 208, 0, 'A2'), ('A2', 596, 208, 1, 'A1'), ('A3', 1564, 208, 1, 'A4'), ('A4', 1640, 208, 0, 'A3'),
       ('B1', 1768, 101, 0, 'B2'), ('B2', 1806, 101, 1, 'B1'), ('B3', 2684, 101, 1, 'B4'), ('B4', 2766, 101, 0, 'B3'),
       ('C1', 2950, 208, 0, 'C2'), ('C2', 2986, 286, 1, 'C1'), ('C3', 3654, 286, 1, 'C4'), ('C4', 3720, 208, 0, 'C3')]),
 '2_3': dict(name='Level2_3', title='2-3 THE CINDER MINES', length=4600, next='level_2_4', bg='mines', cover='crate', exitx=4480,
    W=[(700, -1, 50, 0), (1120, -1, 40, 0), (1480, -1, 50, 1), (1860, -1, 40, 0), (2240, -1, 60, 0), (2600, -1, 40, 1), (2980, -1, 40, 0), (3340, -1, 50, 0), (3700, -1, 40, 1), (4100, -1, 50, 0)],
    D=[(520, 150), (1300, 140), (2100, 150), (2800, 135), (3500, 145), (4000, 140)],
    C=[(320, 1), (560, 2), (900, 1), (1000, 2), (1300, 1), (1650, 2), (1750, 1), (2050, 1), (2400, 2), (2800, 1), (3150, 2), (3250, 1), (3550, 2), (3900, 1), (4250, 2)],
    CP=[1200, 2300, 3400], cages=[900, 1750, 2650, 3450, 4200], extra='free_required = 4'),
 '2_4': dict(name='Level2_4', title='2-4 THE CATWALK', length=2800, next='', bg='cat', cover='crate', exitx=None,
    W=[(900, -1, 40, 0), (1500, -1, 40, 1)], D=[],
    C=[(500, 1), (1100, 2), (1900, 1)], CP=[], hunter=1500, extra='survive_time = 50.0\nursk_pal = true\nsurvive_label = "THE VAGABOND ARRIVES IN"'),
}
for key, c in LV.items():
    bg = c['bg']
    ex = [('1', 'res://scripts/level.gd', 'Script'), ('2', f'res://assets/bg_{bg}_sky.png', 'Texture2D'), ('3', f'res://assets/bg_{bg}_far.png', 'Texture2D'),
          ('4', f'res://assets/bg_{bg}_mid.png', 'Texture2D'), ('5', f'res://assets/{bg}_ground.png', 'Texture2D'),
          ('7', 'res://scenes/warden.tscn', 'PackedScene'), ('8', 'res://scenes/drone.tscn', 'PackedScene'),
          ('9', f'res://scenes/{c["cover"]}.tscn', 'PackedScene'), ('10', 'res://scenes/warden_shield.tscn', 'PackedScene'),
          ('11', 'res://scenes/cage.tscn', 'PackedScene'), ('12', 'res://scenes/corvane.tscn', 'PackedScene'),
          ('13', 'res://scenes/vent.tscn', 'PackedScene'), ('14', 'res://scenes/grate.tscn', 'PackedScene')]
    L = [f'[gd_scene load_steps={len(ex) + 1} format=3]', '']
    L += [f'[ext_resource type="{t}" path="{p}" id="{i}"]' for i, p, t in ex] + ['']
    L += [f'[node name="{c["name"]}" type="Node2D"]', 'script = ExtResource("1")', f'length = {float(c["length"])}', f'title = "{c["title"]}"']
    if c['next']: L.append(f'next_level = "res://scenes/levels/{c["next"]}.tscn"')
    if c.get('extra'): L.append(c['extra'])
    L.append('')
    L += ['[node name="Sky" type="CanvasLayer" parent="."]', 'layer = -10', '', '[node name="Sprite" type="Sprite2D" parent="Sky"]', 'texture = ExtResource("2")', 'centered = false', '']
    for name, tex, sc, z in (('Far', 3, 0.15, -30), ('Mid', 4, 0.4, -20), ('Ground', 5, 1.0, -5)):
        L += [f'[node name="{name}" type="Parallax2D" parent="."]', f'scroll_scale = Vector2({sc}, 0)', 'repeat_size = Vector2(480, 0)', 'repeat_times = 12', f'z_index = {z}', '',
              f'[node name="Sprite" type="Sprite2D" parent="{name}"]', f'texture = ExtResource("{tex}")', 'centered = false', '']
    L += ['[node name="PlayerStart" type="Marker2D" parent="."]', 'position = Vector2(100, 222)', '']
    if c['exitx']: L += ['[node name="Exit" type="Marker2D" parent="."]', f'position = Vector2({c["exitx"]}, 222)', '']
    L += ['[node name="Checkpoints" type="Node2D" parent="."]', '']
    for i, x in enumerate(c['CP'], 1): L += [f'[node name="Checkpoint{i}" type="Marker2D" parent="Checkpoints" groups=["checkpoint"]]', f'position = Vector2({x}, 222)', '']
    L += ['[node name="Props" type="Node2D" parent="."]', '']
    for i, (x, st) in enumerate(c['C'], 1):
        L += [f'[node name="Crate{i}" parent="Props" instance=ExtResource("9")]', f'position = Vector2({x}, 223)'] + ([f'stack = {st}'] if st != 1 else []) + ['']
    for i, x in enumerate(c.get('cages', []), 1): L += [f'[node name="Cage{i}" parent="Props" instance=ExtResource("11")]', f'position = Vector2({x}, 223)', '']
    L += ['[node name="Enemies" type="Node2D" parent="."]', '']
    for i, (x, f, pr, sh) in enumerate(c['W'], 1):
        L += [f'[node name="{"Shield" if sh else ""}Warden{i}" parent="Enemies" instance=ExtResource("{10 if sh else 7}")]', f'position = Vector2({x}, 222)', f'patrol_range = {float(pr)}', f'start_facing = {f}', '']
    for i, (x, y) in enumerate(c['D'], 1): L += [f'[node name="Drone{i}" parent="Enemies" instance=ExtResource("8")]', f'position = Vector2({x}, {y})', '']
    if c.get('V'):
        L += ['[node name="Vents" type="Node2D" parent="."]', '']
        for n, x, y, w in c['V']: L += [f'[node name="{n}" parent="Vents" instance=ExtResource("13")]', f'position = Vector2({x}, {y})', f'width = {float(w)}', '']
        L += ['[node name="Grates" type="Node2D" parent="."]', '']
        for n, x, y, ins, lk in c['G']:
            L += [f'[node name="Grate{n}" parent="Grates" instance=ExtResource("14")]', f'position = Vector2({x}, {y})', f'link = NodePath("../Grate{lk}")'] + (['inside = true'] if ins else []) + ['']
    if c.get('hunter'): L += ['[node name="Corvane" parent="Enemies" instance=ExtResource("12")]', f'position = Vector2({c["hunter"]}, 222)', 'min_x = 300.0', f'max_x = {float(c["length"] - 300)}', '']
    p = os.path.join(OUT, f'level_{key}.tscn'); open(p, 'w').write('\n'.join(L)); print('wrote', os.path.normpath(p))
