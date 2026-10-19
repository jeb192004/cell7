#!/usr/bin/env python3
"""Writes scenes/levels/level_2_3.tscn: the Kesh high route over the Meridian's cargo bay (existing art only).
Wardens only see about 70 px up and down, and a 3-high cargo stack puts Kesh's feet ~92 px above the deck, so he walks the stack
tops unseen. Gaps between stacks are 42..80 px (walk-jump up to ~77, sprint-jump ~120). Two spots break the chain and you have to
cross the floor behind cover. Re-run this to regenerate; edit in Godot if you want to tweak by hand (then don't re-run)."""
import os
OUT = os.path.join(os.path.dirname(__file__), '..', 'scenes', 'levels', 'level_2_3.tscn')
# (x, stack) cargo; stack 3 = the safe high route, 1-2 are steps and hides
STAIRS_UP = lambda x: [(x, 1), (x + 34, 2), (x + 68, 3)]
STAIRS_DN = lambda x: [(x, 2), (x + 34, 1)]
C = []
C += STAIRS_UP(300)
C += [(x, 3) for x in (440, 516, 598, 680, 762, 846, 930)]
C += STAIRS_DN(964)
C += [(1110, 2)]                       # hide on the floor crossing
C += STAIRS_UP(1380)
C += [(x, 3) for x in (1520, 1600, 1684, 1772, 1870, 1980, 2074, 2160)]
C += STAIRS_DN(2194)
C += [(2330, 2), (2490, 2), (2610, 1)]  # hides on the second floor crossing
C += STAIRS_UP(2700)
C += [(x, 3) for x in (2840, 2930, 3030, 3140)]
C += STAIRS_DN(3174)
W = [(520, -1, 120), (800, -1, 150), (1230, -1, 110), (1560, 1, 120), (1900, -1, 150), (2400, -1, 120), (2640, 1, 90), (2950, -1, 130), (3100, 1, 100)]
CP = [1060, 2260, 2780]
LENGTH, EXITX = 3500, 3340
ex = [('1', 'res://scripts/level.gd', 'Script'), ('2', 'res://assets/bg_ship_sky.png', 'Texture2D'), ('3', 'res://assets/bg_ship_far.png', 'Texture2D'),
      ('4', 'res://assets/bg_ship_mid.png', 'Texture2D'), ('5', 'res://assets/ship_ground.png', 'Texture2D'),
      ('7', 'res://scenes/warden.tscn', 'PackedScene'), ('9', 'res://scenes/cargo.tscn', 'PackedScene')]
L = [f'[gd_scene load_steps={len(ex) + 1} format=3]', '']
L += [f'[ext_resource type="{t}" path="{p}" id="{i}"]' for i, p, t in ex] + ['']
L += ['[node name="Level2_1b" type="Node2D"]', 'script = ExtResource("1")', f'length = {float(LENGTH)}', 'title = "2-1B THE HIGH ROUTE"',
      'next_level = "res://scenes/levels/level_2_4.tscn"', 'stealth_only = true', '']
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
L += ['[node name="Enemies" type="Node2D" parent="."]', '']
for i, (x, f, pr) in enumerate(W, 1):
    L += [f'[node name="Warden{i}" parent="Enemies" instance=ExtResource("7")]', f'position = Vector2({x}, 222)', f'patrol_range = {float(pr)}', f'start_facing = {f}', '']
open(OUT, 'w').write('\n'.join(L)); print('wrote', os.path.normpath(OUT))
