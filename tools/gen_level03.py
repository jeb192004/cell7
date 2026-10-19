#!/usr/bin/env python3
"""Writes scenes/levels/level_1_3.tscn (1-3 Town Rooftops). After this, edit the scene in Godot.
Roof heights step by <= 40 and gaps are <= 80 px so Kesh can always make the jump; falling just drops you to the street."""
import os
out = os.path.join(os.path.dirname(__file__), '..', 'scenes', 'levels', 'level_1_3.tscn')
GY = 222
R = [  # centre x, width, height above the street line.  A climb: each step up <= 40 px, gaps <= 80 px.  No street: it is all rooftops.
    (360, 220, 40), (620, 160, 40), (810, 110, 80), (1000, 150, 120), (1180, 110, 160), (1330, 150, 200), (1560, 260, 200),
    (1800, 110, 160), (1960, 130, 200), (2140, 110, 240), (2300, 120, 280), (2480, 140, 240), (2700, 240, 240),
    (2900, 100, 280), (3060, 120, 320), (3240, 110, 360), (3470, 260, 360)]
def roof_top(x):
    for cx, w, h in R:
        if cx - w / 2 <= x <= cx + w / 2: return h
    return 0
W = [  # x, facing, patrol, shield
    (440, 1, 20, 0), (1490, -1, 30, 0), (1620, -1, 25, 1), (1960, -1, 25, 0), (2300, -1, 15, 0), (2640, -1, 30, 0),
    (2760, -1, 25, 1), (3060, -1, 20, 0), (3400, -1, 30, 0), (3510, -1, 25, 1)]
D = [(1090, 57), (1860, -3), (2420, -83), (3180, -163)]
C = [(300, 1), (1535, 1), (1590, 2), (1665, 1), (2620, 2), (2700, 1), (2800, 2), (3420, 2), (3540, 1)]
PIPS = [(2300, 280 + 16), (1560, 200 + 90), (3240, 360 + 16)]   # x, height above street: one on the tiny spire roof, one on top of a crate stack, one before the end
CP = [(640, 40), (1330, 200), (2480, 240), (3240, 360)]          # x, roof height
lines = ['[gd_scene load_steps=13 format=3]', '',
 '[ext_resource type="Script" path="res://scripts/level.gd" id="1"]',
 '[ext_resource type="Texture2D" path="res://assets/bg_town_sky.png" id="2"]',
 '[ext_resource type="Texture2D" path="res://assets/bg_town_far.png" id="3"]',
 '[ext_resource type="Texture2D" path="res://assets/bg_town_mid.png" id="4"]',
 '[ext_resource type="Texture2D" path="res://assets/bg_town_dunes.png" id="5"]',
 '[ext_resource type="Texture2D" path="res://assets/town_ground.png" id="6"]',
 '[ext_resource type="PackedScene" path="res://scenes/warden.tscn" id="7"]',
 '[ext_resource type="PackedScene" path="res://scenes/drone.tscn" id="8"]',
 '[ext_resource type="PackedScene" path="res://scenes/crate.tscn" id="9"]',
 '[ext_resource type="PackedScene" path="res://scenes/warden_shield.tscn" id="10"]',
 '[ext_resource type="PackedScene" path="res://scenes/roof.tscn" id="11"]',
 '[ext_resource type="PackedScene" path="res://scenes/pip.tscn" id="12"]', '',
 '[node name="Level03" type="Node2D"]', 'script = ExtResource("1")', 'length = 4000.0', 'title = "1-3 TOWN ROOFTOPS"', 'next_level = "res://scenes/levels/level_1_4.tscn"', 'top = -340.0', 'kill_y = 300.0', 'ground = false', '']
lines += ['[node name="Sky" type="CanvasLayer" parent="."]', 'layer = -10', '',
          '[node name="Sprite" type="Sprite2D" parent="Sky"]', 'texture = ExtResource("2")', 'centered = false', '']
for name, tex, sc, sy, z in (('Far', 3, 0.15, 0.15, -30), ('Mid', 4, 0.35, 0.35, -20)):
    lines += [f'[node name="{name}" type="Parallax2D" parent="."]', f'scroll_scale = Vector2({sc}, {sy})',
              'repeat_size = Vector2(480, 0)', 'repeat_times = 12', f'z_index = {z}', '',
              f'[node name="Sprite" type="Sprite2D" parent="{name}"]', f'texture = ExtResource("{tex}")', 'centered = false', '']
lines += ['[node name="PlayerStart" type="Marker2D" parent="."]', 'position = Vector2(272, 182)', '',
          '[node name="Exit" type="Marker2D" parent="."]', 'position = Vector2(3560, -138)', '']
lines += ['[node name="Checkpoints" type="Node2D" parent="."]', '']
for i, (x, h) in enumerate(CP, 1):
    lines += [f'[node name="Checkpoint{i}" type="Marker2D" parent="Checkpoints" groups=["checkpoint"]]', f'position = Vector2({x}, {222 - h})', '']
lines += ['[node name="Buildings" type="Node2D" parent="."]', '']
for i, (x, w, h) in enumerate(R, 1):
    lines += [f'[node name="Roof{i}" parent="Buildings" instance=ExtResource("11")]', f'position = Vector2({x}, {GY})', f'width = {w}', f'height = {h}', f'look = {i}'] + ['depth = 80'] + ['']
lines += ['[node name="Props" type="Node2D" parent="."]', '']
for i, (x, st) in enumerate(C, 1):
    lines += [f'[node name="Crate{i}" parent="Props" instance=ExtResource("9")]', f'position = Vector2({x}, {GY + 1 - roof_top(x)})'] + ([f'stack = {st}'] if st != 1 else []) + ['']
lines += ['[node name="Pickups" type="Node2D" parent="."]', '']
for i, (x, h) in enumerate(PIPS, 1):
    lines += [f'[node name="Pip{i}" parent="Pickups" instance=ExtResource("12")]', f'position = Vector2({x}, {222 - h})', '']
lines += ['[node name="Enemies" type="Node2D" parent="."]', '']
for i, (x, f, pr, sh) in enumerate(W, 1):
    lines += [f'[node name="{"Shield" if sh else ""}Warden{i}" parent="Enemies" instance=ExtResource("{10 if sh else 7}")]', f'position = Vector2({x}, {GY - roof_top(x)})', f'patrol_range = {float(pr)}', f'start_facing = {f}', '']
for i, (x, y) in enumerate(D, 1):
    lines += [f'[node name="Drone{i}" parent="Enemies" instance=ExtResource("8")]', f'position = Vector2({x}, {y})', '']
open(out, 'w').write('\n'.join(lines))
print('wrote', os.path.normpath(out))
