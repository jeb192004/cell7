"""Labelled contact sheets of every sprite, for handing to an AI art tool. python3 tools/make_contact_sheets.py OUTDIR"""
import sys, os
from PIL import Image, ImageDraw, ImageFont
A = 'assets'; OUT = sys.argv[1] if len(sys.argv) > 1 else '/tmp/art_pack'
os.makedirs(OUT, exist_ok=True)
try: F = ImageFont.load_default(size=14); FS = ImageFont.load_default(size=11)
except TypeError: F = FS = ImageFont.load_default()
BG = (38, 34, 52)

def sheet(name, title, items, scale, cols, cell_w=None, note=''):
    """items: list of (file, label, optional crop box or frames)"""
    imgs = []
    for it in items:
        f = it[0]; im = Image.open(f'{A}/{f}').convert('RGBA')
        if len(it) > 2 and it[2]: im = im.crop(it[2])
        imgs.append((it[1] if len(it) > 1 else f, f, im))
    cw = cell_w or max(i[2].width for i in imgs) * scale + 16
    ch = max(i[2].height for i in imgs) * scale + 40
    rows = (len(imgs) + cols - 1) // cols
    W, H = cw * cols, ch * rows + 56
    s = Image.new('RGB', (W, H), BG); d = ImageDraw.Draw(s)
    d.text((10, 8), title, fill=(255, 220, 140), font=F); d.text((10, 30), note, fill=(190, 190, 210), font=FS)
    for i, (label, f, im) in enumerate(imgs):
        x, y = (i % cols) * cw, 56 + (i // cols) * ch
        big = im.resize((im.width * scale, im.height * scale), Image.NEAREST)
        s.paste(big, (x + 8, y + 4), big)
        d.text((x + 8, y + big.height + 8), f"{label}", fill=(235, 235, 245), font=FS)
        d.text((x + 8, y + big.height + 22), f"{f}  {im.width}x{im.height}", fill=(150, 150, 175), font=FS)
    s.save(f'{OUT}/{name}'); print(name, s.size)

kesh = [(f'kesh_{n}.png', n) for n in ['idle_0','run_0','run_1','run_2','run_3','run_4','run_5','jump_0','jump_1','jump_2','shoot_0','shoot_1','shoot_2','shoot_3','shoot_4','crouch_0','cshoot_0','cshoot_1','cshoot_2','cshoot_3','cshoot_4','slide_0','hit_0','hit_1']]
sheet('1_kesh.png', 'KESH (player) - 24 frames, side view facing RIGHT, 48x48 each, feet on the bottom row',
      kesh, 3, 6, note='Teen rebel: messy dark hair, teal goggles on forehead, tan fringed tunic, olive backpack, blue pants, brown boots. Slingshot-style blaster. Keep the same size, feet position and facing in every frame.')
ward = [(f'warden_{n}.png', 'regular ' + n) for n in ['ready','aim','fire','caim','cfire']] + [(f'warden_s_{n}.png', 'SHIELD ' + n) for n in ['ready','aim','fire','caim','cfire']]
sheet('2_wardens.png', 'WARDENS (enemy soldiers) - 10 frames, 44x56 each, facing RIGHT (game flips them)',
      ward, 4, 5, note='Hooded dark cloak, round black visor with orange glow, gold trim, rifle. Shield version carries a tall blue riot shield. c* = crouched versions. Same size/feet in every frame.')
sheet('3_bikes_and_ships.png', 'BIKES + SHIPS (highway chase 1-4 and space level 1-5)',
      [('kesh_bike.png', 'Kesh hover bike (faces RIGHT, flame at back)'), ('warden_bike.png', 'Warden hover bike (faces LEFT)'),
       ('shrike.png', 'Shrike (faces LEFT) - boss/fighter, side view'), ('shrike_big.png', 'Shrike ACE (bigger version of the same)'),
       ('vagabond.png', 'Vagabond-9 hero ship (faces RIGHT)')], 4, 2, note='Hover bikes need the rider ON the bike. Ships: side view, no flame needed on the Vagabond (drawn in code).')
props = [('cover_crate.png','crate'),('cover_cargo.png','cargo container'),('cover_wreck.png','wrecked vehicle (cover)'),('road_wreck.png','burnt-out hovercar (road hazard)'),
         ('road_barrier.png','road barrier'),('drone.png','drone (flying enemy)'),('bolt.png','player bolt'),('shot_high.png','enemy shot (high)'),('shot_low.png','enemy shot (low)')]
sheet('4_props_and_enemies.png', 'PROPS, DRONE, SHOTS', props, 6, 5, note='Small sprites - keep them readable at tiny size.')
rocks = []
for n in ('rock_s', 'rock_m', 'rock_l'):
    im = Image.open(f'{A}/{n}.png'); w = im.width // 16
    rocks.append((n + '.png', f'{n} (16 spin frames in one strip, 1 frame = {w}x{im.height})', (0, 0, w * 4, im.height)))
sheet('5_asteroids.png', 'ASTEROIDS - spin strips (16 frames side by side; showing the first 4)', rocks, 3, 1, note='Each rock is a horizontal strip of 16 rotation frames with the light staying fixed.')
# backgrounds: composited per level + the separate layers
def comp(layers):
    base = Image.new('RGBA', (480, 270), (0, 0, 0, 255))
    for l in layers:
        base.alpha_composite(Image.open(f'{A}/{l}.png').convert('RGBA'))
    return base
levels = [('1-1 / 1-2 Salt Flats (desert)', ['bg_sky', 'bg_far', 'bg_mid', 'bg_dunes', 'ground']),
          ('1-2 Highway Run', ['bg_hw_sky', 'bg_hw_far', 'bg_hw_mid', 'bg_hw_dunes', 'hw_ground']),
          ('1-3 Town Rooftops (night)', ['bg_town_sky', 'bg_town_far', 'bg_town_mid', 'bg_town_dunes', 'town_ground']),
          ('1-4 Highway Escape (chase)', ['bg_hw_sky', 'bg_hw_far', 'bg_hw_mid', 'bike_ground', 'bike_near'])]
W = 480 * 2 + 30; H = 56 + (270 + 40) * 2
s = Image.new('RGB', (W, H), BG); d = ImageDraw.Draw(s)
d.text((10, 8), 'BACKGROUNDS - how each level looks stacked (480x270 each)', fill=(255, 220, 140), font=F)
d.text((10, 30), 'Each is built from separate 480x270 layers (sky, far, mid, dunes/near, ground). Layers scroll at different speeds and need to tile left-right.', fill=(190, 190, 210), font=FS)
for i, (name, ls) in enumerate(levels):
    x, y = (i % 2) * 495 + 10, 56 + (i // 2) * 310
    s.paste(comp(ls).convert('RGB'), (x, y)); d.text((x, y + 274), name + '  - layers: ' + ', '.join(ls), fill=(235, 235, 245), font=FS)
s.save(f'{OUT}/6_backgrounds.png'); print('6_backgrounds.png', s.size)
