#!/usr/bin/env python3
"""Writes scenes/levels/level_1_1.tscn. Run it once to regenerate the starter layout; after that, edit the scene in Godot."""
import os
out = os.path.join(os.path.dirname(__file__), '..', 'scenes', 'levels', 'level_1_1.tscn')
W = [  # x, facing, patrol
    (780, -1, 40), (1230, -1, 70), (1700, -1, 50), (1900, 1, 50), (2520, -1, 60), (3020, -1, 40), (3170, 1, 40)]
D = [(520, 150), (1360, 140), (2260, 150), (2380, 135)]
C = [(330, 1), (580, 1), (665, 2), (1105, 1), (1580, 2), (1790, 1), (2000, 2), (2400, 1), (2860, 2), (2965, 1), (3085, 2), (3290, 1)]
CP = [920, 2150, 2750]
lines = ['[gd_scene load_steps=11 format=3]', '',
 '[ext_resource type="Script" path="res://scripts/level.gd" id="1"]',
 '[ext_resource type="Texture2D" path="res://assets/bg_sky.png" id="2"]',
 '[ext_resource type="Texture2D" path="res://assets/bg_far.png" id="3"]',
 '[ext_resource type="Texture2D" path="res://assets/bg_mid.png" id="4"]',
 '[ext_resource type="Texture2D" path="res://assets/bg_dunes.png" id="5"]',
 '[ext_resource type="Texture2D" path="res://assets/ground.png" id="6"]',
 '[ext_resource type="PackedScene" path="res://scenes/warden.tscn" id="7"]',
 '[ext_resource type="PackedScene" path="res://scenes/drone.tscn" id="8"]',
 '[ext_resource type="PackedScene" path="res://scenes/crate.tscn" id="9"]', '',
 '[node name="Level01" type="Node2D"]', 'script = ExtResource("1")', 'length = 3700.0', 'title = "1-1 SALT FLATS"', 'next_level = "res://scenes/levels/level_1_2.tscn"', '']
lines += ['[node name="Sky" type="CanvasLayer" parent="."]', 'layer = -10', '',
          '[node name="Sprite" type="Sprite2D" parent="Sky"]', 'texture = ExtResource("2")', 'centered = false', '']
for name, tex, sc, z in (('Far', 3, 0.15, -30), ('Mid', 4, 0.35, -20), ('Dunes', 5, 0.6, -10), ('Ground', 6, 1.0, -5)):
    lines += [f'[node name="{name}" type="Parallax2D" parent="."]', f'scroll_scale = Vector2({sc}, 0)',
              'repeat_size = Vector2(480, 0)', 'repeat_times = 12', f'z_index = {z}', '',
              f'[node name="Sprite" type="Sprite2D" parent="{name}"]', f'texture = ExtResource("{tex}")', 'centered = false', '']
lines += ['[node name="PlayerStart" type="Marker2D" parent="."]', 'position = Vector2(100, 222)', '',
          '[node name="Exit" type="Marker2D" parent="."]', 'position = Vector2(3550, 222)', '']
lines += ['[node name="Checkpoints" type="Node2D" parent="."]', '']
for i, x in enumerate(CP, 1):
    lines += [f'[node name="Checkpoint{i}" type="Marker2D" parent="Checkpoints" groups=["checkpoint"]]', f'position = Vector2({x}, 222)', '']
lines += ['[node name="Props" type="Node2D" parent="."]', '']
for i, (x, st) in enumerate(C, 1):
    lines += [f'[node name="Crate{i}" parent="Props" instance=ExtResource("9")]', f'position = Vector2({x}, 223)'] + ([f'stack = {st}'] if st != 1 else []) + ['']
lines += ['[node name="Enemies" type="Node2D" parent="."]', '']
for i, (x, f, pr) in enumerate(W, 1):
    lines += [f'[node name="Warden{i}" parent="Enemies" instance=ExtResource("7")]', f'position = Vector2({x}, 222)', f'patrol_range = {float(pr)}', f'start_facing = {f}', '']
for i, (x, y) in enumerate(D, 1):
    lines += [f'[node name="Drone{i}" parent="Enemies" instance=ExtResource("8")]', f'position = Vector2({x}, {y})', '']
open(out, 'w').write('\n'.join(lines))
print('wrote', os.path.normpath(out))
