#!/usr/bin/env python3
"""Writes scenes/levels/level_02.tscn (1-2 Highway Run: cargo-container cover, regular then shield Wardens). Edit the scene in Godot afterwards."""
import os
out = os.path.join(os.path.dirname(__file__), '..', 'scenes', 'levels', 'level_02.tscn')
W = [  # x, facing, patrol, shield  (regular Wardens first, shields introduced mid-level, mixed at the end)
    (760, -1, 50, 0), (1150, -1, 40, 0), (1500, -1, 60, 0), (1840, -1, 40, 1), (2250, -1, 50, 0),
    (2560, -1, 40, 1), (2980, -1, 60, 0), (3200, 1, 30, 1), (3430, -1, 40, 1)]
D = [(480, 150), (1400, 140), (2100, 150), (2720, 135), (3330, 145)]
C = [(300, 1), (560, 2), (640, 1), (1040, 2), (1110, 1), (1480, 1), (1560, 2), (1780, 1), (1990, 2), (2200, 1),
     (2440, 2), (2640, 1), (2860, 1), (2920, 2), (3120, 2), (3300, 1), (3380, 2)]
CP = [1000, 2050, 2800]
lines = ['[gd_scene load_steps=12 format=3]', '',
 '[ext_resource type="Script" path="res://scripts/level.gd" id="1"]',
 '[ext_resource type="Texture2D" path="res://assets/bg_hw_sky.png" id="2"]',
 '[ext_resource type="Texture2D" path="res://assets/bg_hw_far.png" id="3"]',
 '[ext_resource type="Texture2D" path="res://assets/bg_hw_mid.png" id="4"]',
 '[ext_resource type="Texture2D" path="res://assets/bg_hw_dunes.png" id="5"]',
 '[ext_resource type="Texture2D" path="res://assets/hw_ground.png" id="6"]',
 '[ext_resource type="PackedScene" path="res://scenes/warden.tscn" id="7"]',
 '[ext_resource type="PackedScene" path="res://scenes/drone.tscn" id="8"]',
 '[ext_resource type="PackedScene" path="res://scenes/cargo.tscn" id="9"]',
 '[ext_resource type="PackedScene" path="res://scenes/warden_shield.tscn" id="10"]', '',
 '[node name="Level02" type="Node2D"]', 'script = ExtResource("1")', 'length = 3900.0', 'title = "1-2 HIGHWAY RUN"', 'next_level = "res://scenes/levels/level_03.tscn"', '']
lines += ['[node name="Sky" type="CanvasLayer" parent="."]', 'layer = -10', '',
          '[node name="Sprite" type="Sprite2D" parent="Sky"]', 'texture = ExtResource("2")', 'centered = false', '']
for name, tex, sc, z in (('Far', 3, 0.15, -30), ('Mid', 4, 0.35, -20), ('Dunes', 5, 0.6, -10), ('Ground', 6, 1.0, -5)):
    lines += [f'[node name="{name}" type="Parallax2D" parent="."]', f'scroll_scale = Vector2({sc}, 0)',
              'repeat_size = Vector2(480, 0)', 'repeat_times = 12', f'z_index = {z}', '',
              f'[node name="Sprite" type="Sprite2D" parent="{name}"]', f'texture = ExtResource("{tex}")', 'centered = false', '']
lines += ['[node name="PlayerStart" type="Marker2D" parent="."]', 'position = Vector2(100, 222)', '',
          '[node name="Exit" type="Marker2D" parent="."]', 'position = Vector2(3750, 222)', '']
lines += ['[node name="Checkpoints" type="Node2D" parent="."]', '']
for i, x in enumerate(CP, 1):
    lines += [f'[node name="Checkpoint{i}" type="Marker2D" parent="Checkpoints" groups=["checkpoint"]]', f'position = Vector2({x}, 222)', '']
lines += ['[node name="Props" type="Node2D" parent="."]', '']
for i, (x, st) in enumerate(C, 1):
    lines += [f'[node name="Crate{i}" parent="Props" instance=ExtResource("9")]', f'position = Vector2({x}, 223)'] + ([f'stack = {st}'] if st != 1 else []) + ['']
lines += ['[node name="Enemies" type="Node2D" parent="."]', '']
for i, (x, f, pr, sh) in enumerate(W, 1):
    lines += [f'[node name="{"Shield" if sh else ""}Warden{i}" parent="Enemies" instance=ExtResource("{10 if sh else 7}")]', f'position = Vector2({x}, 222)', f'patrol_range = {float(pr)}', f'start_facing = {f}', '']
for i, (x, y) in enumerate(D, 1):
    lines += [f'[node name="Drone{i}" parent="Enemies" instance=ExtResource("8")]', f'position = Vector2({x}, {y})', '']
open(out, 'w').write('\n'.join(lines))
print('wrote', os.path.normpath(out))
