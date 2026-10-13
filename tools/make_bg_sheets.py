"""Per-layer background sheets: each layer on its own, transparent areas filled flat magenta."""
import sys, os
from PIL import Image, ImageDraw, ImageFont
out = sys.argv[1]; os.makedirs(out, exist_ok=True)
SETS = {'7_bg_1-1_salt_flats': ['bg_sky', 'bg_far', 'bg_mid', 'bg_dunes', 'ground'],
        '8_bg_1-2_highway': ['bg_hw_sky', 'bg_hw_far', 'bg_hw_mid', 'bg_hw_dunes', 'hw_ground'],
        '9_bg_1-3_town': ['bg_town_sky', 'bg_town_far', 'bg_town_mid', 'bg_town_dunes'],
        '10_bg_1-4_bike': ['bike_ground', 'bike_near'],
        '11_bg_2-1_ship_interior': ['bg_ship_sky', 'bg_ship_far', 'bg_ship_mid', 'ship_ground'],
        '12_bg_2-2_vents_and_bay': ['bg_vent_sky', 'bg_vent_far', 'bg_vent_mid', 'vent_ground', 'bg_bay_sky', 'bg_bay_far', 'bg_bay_mid', 'bay_ground'],
        '13_bg_2-3_cinder_mines': ['bg_mines_sky', 'bg_mines_far', 'bg_mines_mid', 'mines_ground'],
        '14_bg_2-4_catwalk': ['bg_cat_sky', 'bg_cat_far', 'bg_cat_mid', 'cat_ground']}
try: f = ImageFont.truetype('/usr/share/fonts/truetype/dejavu/DejaVuSansMono.ttf', 13)
except Exception: f = None
for sname, layers in SETS.items():
    rows = (len(layers) + 1) // 2; S = Image.new('RGB', (2 * 500 + 20, rows * 310 + 50), (13, 18, 39)); d = ImageDraw.Draw(S)
    d.text((10, 8), sname.split('_', 1)[1].upper() + ' - each layer is 480x270, tiles left-right, transparent areas shown as magenta', fill=(190, 200, 255), font=f)
    for i, n in enumerate(layers):
        im = Image.open('assets/%s.png' % n).convert('RGBA'); bg = Image.new('RGBA', im.size, (255, 0, 255, 255)); bg.alpha_composite(im)
        x, y = 10 + (i % 2) * 500, 40 + (i // 2) * 310; S.paste(bg.convert('RGB'), (x, y))
        d.text((x, y + 274), '%s.png  480x270' % n, fill=(255, 255, 160), font=f)
    S.save('%s/%s.png' % (out, sname)); print(sname)
