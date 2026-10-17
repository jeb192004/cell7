"""One-off generator for scenes/title.tscn (title, controls, level select, settings, crew as editable nodes).
After this the scene is yours to edit in the 2D editor; don't re-run it over your edits."""
ext = {}
ext_lines = []
def ex(kind, path):
    if path not in ext:
        ext[path] = len(ext) + 1
        ext_lines.append('[ext_resource type="%s" path="%s" id="%d"]' % (kind, path, ext[path]))
    return ext[path]
SC = ex("Script", "res://scripts/title.gd")
LBL = ex("Script", "res://scripts/pix_label.gd")
MNU = ex("Script", "res://scripts/pix_menu.gd")
frames = [ex("Texture2D", "res://assets/kesh_run_%d.png" % i) for i in range(14)]
nodes = []
def C(r, g, b, a=1.0): return "Color(%s, %s, %s, %s)" % (r, g, b, a)
GOLD = C(1.0, 0.82, 0.35); CREAM = C(0.96, 0.9, 0.75); DIM = C(0.62, 0.58, 0.52); INK = C(0.93, 0.88, 0.76)
def node(name, typ, parent=None, props=None, unique=False):
    h = '[node name="%s" type="%s"' % (name, typ)
    if parent is not None: h += ' parent="%s"' % parent
    body = "unique_name_in_owner = true\n" if unique else ""
    nodes.append(h + ']\n' + body + "".join("%s = %s\n" % kv for kv in (props or {}).items()))
def rect(x, y, w, h):
    return {"layout_mode": 0, "offset_left": float(x), "offset_top": float(y), "offset_right": float(x + w), "offset_bottom": float(y + h)}
def label(name, parent, text, px, col, x, y, w, h=None, boxed=True, centered=True, unique=False):
    p = {"script": 'ExtResource("%d")' % LBL}   # script first: its _init resets size, so the rect must come after
    p.update(rect(x, y, w, h if h else 8 * px))
    p["text"] = '"%s"' % text; p["px"] = px; p["color"] = col
    if not centered: p["centered"] = "false"
    if boxed: p["boxed"] = "true"
    node(name, "Control", parent, p, unique)
def menu(name, parent, items, px, x, y, w, rows, max_rows=0):
    rh = 13 * px
    p = {"script": 'ExtResource("%d")' % MNU}
    p.update(rect(x, y, w, rh * rows))
    p["items"] = "PackedStringArray(%s)" % ", ".join('"%s"' % i for i in items)
    if px != 2: p["px"] = px
    if max_rows: p["max_rows"] = max_rows
    node(name, "Control", parent, p, True)
def dim(name, parent, a):
    p = rect(0, 0, 480, 270); p["color"] = C(0.05, 0.03, 0.1, a); p["mouse_filter"] = 2
    node(name, "ColorRect", parent, p)

node("Title", "Node2D", None, {"script": 'ExtResource("%d")' % SC})
# ---- backdrop
node("Sky", "Sprite2D", ".", {"z_index": -50, "texture": 'ExtResource("%d")' % ex("Texture2D", "res://assets/bg_sky.png"), "centered": "false"})
for nm, tex, sp, z in [("Far", "bg_far", -5, -30), ("Mid", "bg_mid", -13, -20), ("Dunes", "bg_dunes", -26, -10), ("Ground", "ground", -105, -5)]:
    node(nm, "Parallax2D", ".", {"z_index": z, "scroll_scale": "Vector2(1, 1)", "repeat_size": "Vector2(480, 0)", "autoscroll": "Vector2(%d, 0)" % sp, "repeat_times": 4})
    node("Sprite", "Sprite2D", nm, {"texture": 'ExtResource("%d")' % ex("Texture2D", "res://assets/%s.png" % tex), "centered": "false"})
p = {"z_index": -2, "mouse_filter": 2, "color": C(0.05, 0.03, 0.1, 0.35), "layout_mode": 0, "offset_right": 480.0, "offset_bottom": 270.0}
node("Shade", "ColorRect", ".", p)
node("Kesh", "AnimatedSprite2D", ".", {"position": "Vector2(115, 199)", "sprite_frames": 'SubResource("frames")', "animation": '&"run"', "autoplay": '"run"'}, True)
node("UI", "CanvasLayer", ".", {"layer": 5})
# ---- title
node("TitleGroup", "Node2D", "UI", None, True)
label("Logo", "UI/TitleGroup", "CELL 7", 7, GOLD, 0, 30, 480, 58)
node("Rule", "ColorRect", "UI/TitleGroup", dict(rect(150, 88, 180, 2), color=C(0.8, 0.26, 0.2), mouse_filter=2))
label("Subtitle", "UI/TitleGroup", "UPRISING", 4, CREAM, 0, 98, 480, 30)
menu("Menu", "UI/TitleGroup", ["START", "CONTROLS", "SETTINGS", "CREW", "LEVEL SELECT", "QUIT"], 2, 200, 128, 200, 5, 5)
label("By", "UI/TitleGroup", "SERPENT SCRIPTS", 1, C(0.75, 0.68, 0.6), 0, 264, 480, 8)
# ---- controls
node("ControlsGroup", "Node2D", "UI", {"visible": "false"}, True)
dim("Dim", "UI/ControlsGroup", 0.78)
label("Heading", "UI/ControlsGroup", "CONTROLS", 3, GOLD, 0, 18, 480, 24)
cols = [40, 170, 310]
label("HeadRetroid", "UI/ControlsGroup", "RETROID", 1, GOLD, cols[1], 58, 120, 8, False, False)
label("HeadKeyboard", "UI/ControlsGroup", "KEYBOARD", 1, GOLD, cols[2], 58, 120, 8, False, False)
rows = [["MOVE", "STICK OR D-PAD", "ARROWS OR WASD"], ["JUMP", "B", "SPACE OR K"], ["SHOOT", "Y OR R1", "J OR X"],
        ["SPRINT", "HOLD L1 OR L2", "HOLD SHIFT"], ["CROUCH", "HOLD DOWN", "HOLD DOWN OR S"],
        ["HIDE", "UP AT A CRATE", "UP OR W AT A CRATE"], ["PAUSE", "START", "P OR ESC"]]
for r, row in enumerate(rows):
    y = 78 + r * 15
    for i in range(3):
        label("Row%d%s" % (r + 1, ["Action", "Retroid", "Keys"][i]), "UI/ControlsGroup", row[i], 1, DIM if i == 0 else INK, cols[i], y, 130, 8, False, False)
label("Tip", "UI/ControlsGroup", "HOLD DOWN ON A CRATE TO DROP BEHIND IT", 1, DIM, 0, 204, 480, 8)
menu("ControlsBack", "UI/ControlsGroup", ["BACK"], 2, 160, 224, 160, 1)
# ---- level select
node("SelectGroup", "Node2D", "UI", {"visible": "false"}, True)
dim("Dim", "UI/SelectGroup", 0.82)
label("Heading", "UI/SelectGroup", "LEVEL SELECT", 3, GOLD, 0, 20, 480, 24)
menu("SelectMenu", "UI/SelectGroup", ["(LEVELS COME FROM TITLE.GD)", "1-1 SALT FLATS", "1-2 HIGHWAY RUN", "BACK"], 2, 90, 74, 300, 6, 6)
# ---- settings
node("SettingsGroup", "Node2D", "UI", {"visible": "false"}, True)
dim("Dim", "UI/SettingsGroup", 0.82)
label("Heading", "UI/SettingsGroup", "SETTINGS", 3, GOLD, 0, 20, 480, 24)
menu("SettingsMenu", "UI/SettingsGroup", ["MUSIC  < 7 >", "SOUND  < 8 >", "TOUCH PAD  < AUTO >", "DEV: RESET TIPS", "DEV: DELETE ALL PREFS", "BACK"], 2, 60, 62, 360, 6)
label("SettingsNote", "UI/SettingsGroup", "LEFT / RIGHT CHANGES VOLUME AND TOUCH PAD", 1, DIM, 0, 214, 480, 8, unique=True)
# ---- crew
node("CrewGroup", "Node2D", "UI", {"visible": "false"}, True)
dim("Dim", "UI/CrewGroup", 0.88)
label("Heading", "UI/CrewGroup", "THE CREW", 2, GOLD, 0, 8, 480, 16)
node("CrewCard", "Sprite2D", "UI/CrewGroup", {"position": "Vector2(240, 110)"}, True)
label("CrewName", "UI/CrewGroup", "KESH", 3, CREAM, 0, 200, 480, 24, unique=True)
label("CrewRole", "UI/CrewGroup", "SCAVENGER", 1, C(0.7, 0.66, 0.6), 0, 226, 480, 8, unique=True)
label("ArrowLeft", "UI/CrewGroup", "<", 4, GOLD, 2, 100, 40, 32)
label("ArrowRight", "UI/CrewGroup", ">", 4, GOLD, 438, 100, 40, 32)
menu("CrewBack", "UI/CrewGroup", ["BACK"], 2, 160, 238, 160, 1)

sub = '[sub_resource type="SpriteFrames" id="frames"]\nanimations = [{\n"frames": [%s],\n"loop": true,\n"name": &"run",\n"speed": 8.0\n}]\n' % ", ".join('{\n"duration": 1.0,\n"texture": ExtResource("%d")\n}' % f for f in frames)
out = '[gd_scene load_steps=%d format=3]\n\n' % (len(ext) + 2) + "\n".join(ext_lines) + "\n\n" + sub + "\n" + "\n".join(nodes)
open("scenes/title.tscn", "w").write(out)
print(len(nodes), "nodes")
