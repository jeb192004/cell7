#!/usr/bin/env python3
"""Writes scenes/levels/level_2_1c.tscn: Fuse plants five charges along the Meridian's deck (existing ship art).
Wardens see ~230 px ahead, so each patrol (4 of them) is covered by a chain of crates you walk behind (Up at a crate = back lane),
with a two-crate gap in the middle where you have to step out. The five ChargeSpots sit in the quiet stretches between the patrols.
Re-run to regenerate; edit in Godot if you want to tweak by hand (then don't re-run)."""
import os
OUT = os.path.join(os.path.dirname(__file__), '..', 'scenes', 'levels', 'level_2_1c.tscn')
W = [(620, -1), (1320, 1), (2020, -1), (2720, 1)]            # (x, start_facing), patrol_range 80
C = []
for wx, _ in W:
    x0 = wx - 300
    for i in range(18):
        if i in (8, 9): continue                               # the gap
        C.append((x0 + i * 34, 2 if i % 6 == 3 else 1))
S = [(280, 'wall', 1), (970, 'ground', 1), (1670, 'wall', -1), (2370, 'ground', 1), (3070, 'wall', 1)]
CP = [1000, 1700, 2400]
LENGTH, EXITX = 3400, 3260
ex = [('1', 'res://scripts/level.gd', 'Script'), ('2', 'res://assets/bg_ship_sky.png', 'Texture2D'), ('3', 'res://assets/bg_ship_far.png', 'Texture2D'),
      ('4', 'res://assets/bg_ship_mid.png', 'Texture2D'), ('5', 'res://assets/ship_ground.png', 'Texture2D'),
      ('7', 'res://scenes/warden.tscn', 'PackedScene'), ('9', 'res://scenes/cargo.tscn', 'PackedScene'), ('10', 'res://scripts/charge_spot.gd', 'Script')]
L = [f'[gd_scene load_steps={len(ex) + 1} format=3]', '']
L += [f'[ext_resource type="{t}" path="{p}" id="{i}"]' for i, p, t in ex] + ['']
L += ['[node name="Level2_1c" type="Node2D"]', 'script = ExtResource("1")', f'length = {float(LENGTH)}', 'title = "2-2 THE DETONATORS"',
      'next_level = "res://scenes/levels/level_2_1b.tscn"', 'tutorial = false', 'stealth_only = true', f'free_required = {len(S)}',
      'play_as = "fuse"', 'goal_word = "DETONATORS SET"', 'goal_block = "SET ALL THE DETONATORS FIRST"', '']
L += ['[node name="Sky" type="CanvasLayer" parent="."]', 'layer = -10', '', '[node name="Sprite" type="Sprite2D" parent="Sky"]', 'texture = ExtResource("2")', 'centered = false', '']
for name, tex, sc, z in (('Far', 3, 0.15, -30), ('Mid', 4, 0.4, -20), ('Ground', 5, 1.0, -5)):
    L += [f'[node name="{name}" type="Parallax2D" parent="."]', f'scroll_scale = Vector2({sc}, 0)', 'repeat_size = Vector2(480, 0)', 'repeat_times = 12', f'z_index = {z}', '',
          f'[node name="Sprite" type="Sprite2D" parent="{name}"]', f'texture = ExtResource("{tex}")', 'centered = false', '']
L += ['[node name="PlayerStart" type="Marker2D" parent="."]', 'position = Vector2(100, 222)', '',
      '[node name="Exit" type="Marker2D" parent="."]', f'position = Vector2({EXITX}, 222)', '', '[node name="Checkpoints" type="Node2D" parent="."]', '']
for i, x in enumerate(CP, 1): L += [f'[node name="Checkpoint{i}" type="Marker2D" parent="Checkpoints" groups=["checkpoint"]]', f'position = Vector2({x}, 222)', '']
L += ['[node name="Props" type="Node2D" parent="."]', '']
for i, (x, st) in enumerate(C, 1):
    L += [f'[node name="Cargo{i}" parent="Props" instance=ExtResource("9")]', f'position = Vector2({x}, 223)'] + ([f'stack = {st}'] if st != 1 else []) + ['']
L += ['[node name="ChargeSpots" type="Node2D" parent="."]', '']
for i, (x, k, f) in enumerate(S, 1):
    L += [f'[node name="Spot{i}" type="Node2D" parent="ChargeSpots"]', 'script = ExtResource("10")', f'position = Vector2({x}, 222)'] + (['kind = "wall"', f'face = {f}'] if k == 'wall' else []) + ['']
L += ['[node name="Enemies" type="Node2D" parent="."]', '']
for i, (x, f) in enumerate(W, 1):
    L += [f'[node name="Warden{i}" parent="Enemies" instance=ExtResource("7")]', f'position = Vector2({x}, 222)', 'patrol_range = 80.0', f'start_facing = {f}', '']
open(OUT, 'w').write('\n'.join(L)); print('wrote', os.path.normpath(OUT))
