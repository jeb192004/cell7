"""Hover bikes for the highway chase, SNES-style (height-field render). Kesh's faces right, the Warden's faces left.
python3 tools/make_bikes_snes.py"""
import sys; sys.path.insert(0, 'tools')
from hf import *

W, H = 84, 64

def tube(s, pts, width, color, height=3.0, mat=0):
    im = Image.new('L', (s.w, s.h), 0); ImageDraw.Draw(im).line(pts, fill=255, width=width)
    return s.add(np.array(im) > 127, color, height, width / 2.0, mat)

def bike(pal, rider_img, rider_xy, lean, leg_col, boot_col, glove, arm_col, cloak=None, shard=False, flame=((90, 150, 255), (150, 205, 255), (235, 250, 255))):
    body, body_hi, trim, dark, steel, glow, light = pal
    s = HF(W, H, light=(-0.55, -0.7, 0.55))
    s.add([(8, 38), (16, 37), (16, 46), (8, 45)], (30, 32, 44), 3, 2, 1)   # rear nozzle
    # ---- chassis
    s.add([(10, 38), (70, 36), (74, 42), (70, 48), (12, 48)], steel, 4, 5, 1)                      # main frame
    s.add([(20, 41), (46, 41), (46, 51), (20, 51)], dark, 3, 3, 1)                                  # engine block (belly)
    for k in range(5): s.line((22 + k * 5, 42), (22 + k * 5, 50))
    s.rect(24, 45, 42, 46, glow, emit=True) if False else None
    s.add([(48, 43), (64, 43), (64, 52), (48, 52)], (132, 92, 60), 2.5, 2, 1)                       # cargo box
    s.rect(50, 46, 62, 47, (214, 168, 90))
    # ---- hover pods
    for cx in (20, 62):
        s.add([(cx - 11, 51), (cx + 11, 51), (cx + 9, 55), (cx - 9, 55)], (118, 120, 134), 3, 3, 1)
        s.add([(cx - 8, 55), (cx + 8, 55), (cx + 6, 58), (cx - 6, 58)], (50, 52, 68), 2, 1.5, 1)
        for k in range(-2, 3): s.line((cx + k * 4, 52), (cx + k * 4, 54))
        s.rect(cx - 7, 58, cx + 7, 59, glow, emit=True); s.rect(cx - 4, 58, cx + 4, 58, (255, 255, 255), emit=True)
    # ---- seat, tank / fairing
    s.add([(18, 33), (38, 33), (40, 38), (16, 38)], (36, 38, 52), 3, 2, 1)                          # seat pad
    s.add([(36, 27), (54, 25), (60, 31), (58, 40), (36, 40)], body, 6, 6, 1)                        # tank
    s.add([(40, 28), (54, 27), (57, 31), (40, 33)], body_hi, 1.5, 2, 1)
    s.rect(40, 34, 56, 35, trim)
    s.add([(54, 36), (80, 40), (82, 44), (76, 48), (56, 48)], body, 5, 5, 1)                        # nose fairing
    s.add([(58, 38), (78, 41), (79, 43), (60, 44)], body_hi, 1.5, 2, 1)
    s.rect(60, 44, 78, 45, trim)
    if shard:   # Warden prow ornament (crystal facets)
        s.add([(72, 38), (84, 41), (74, 47), (66, 44)], (118, 122, 140), 4, 3, 1)
        s.add([(72, 39), (82, 41), (74, 43)], (176, 182, 200), 1.5, 1.5, 1)
    # ---- fork / bars / headlight
    tube(s, [(60, 46), (56, 28)], 3, steel, 3, 1)
    tube(s, [(50, 23), (60, 23)], 3, dark, 3, 1)
    s.add([(44, 21), (52, 21), (52, 25), (44, 25)], dark, 2.5, 1.2, 1)                              # bar-mounted gun
    s.add([(66, 30), (72, 30), (72, 36), (66, 36)], light, 3, 1.5, 1)                                  # headlight
    s.rect(72, 31, 73, 35, (255, 252, 230), emit=True)
    # ---- panel lines / lights
    s.line((12, 44), (66, 44)); s.line((38, 36), (38, 48))
    s.rect(14, 42, 15, 43, glow, emit=True)
    bike_img = s.render(spec=0.35, dith=0.35, ao_k=1.3, shadow_k=0.5)
    # soft glow under the pods
    glw = Image.new('RGBA', (W, H), (0, 0, 0, 0)); gd = ImageDraw.Draw(glw)
    for cx in (20, 62):
        gd.ellipse([cx - 14, 58, cx + 14, 66], fill=tuple(glow) + (50,)); gd.ellipse([cx - 9, 59, cx + 9, 66], fill=tuple(glow) + (90,))
    out = Image.new('RGBA', (W, H), (0, 0, 0, 0)); out.alpha_composite(glw); out.alpha_composite(bike_img)
    # ---- rider: cloak behind, legs astride, torso leaning, arm to the bars
    if cloak is not None:
        c = HF(W, H, light=(-0.55, -0.7, 0.55))
        c.add([(34, 24), (40, 28), (24, 40), (6, 46), (0, 40), (10, 34), (22, 28)], cloak, 3, 4, 0)
        c.add([(30, 28), (36, 30), (22, 42), (8, 42), (16, 34)], tuple(min(255, v + 14) for v in cloak), 1.5, 3, 0)
        c.line((26, 34), (8, 42)); c.line((30, 32), (14, 40))
        out.alpha_composite(c.render(spec=0.0, dith=0.3, ao_k=1.0, shadow_k=0.3))
    legs = HF(W, H, light=(-0.55, -0.7, 0.55))
    tube(legs, [(30, 36), (44, 39)], 6, leg_col, 3, 0)          # thigh
    tube(legs, [(44, 39), (40, 49)], 5, leg_col, 3, 0)          # shin
    legs.add([(35, 47), (45, 47), (46, 51), (35, 51)], boot_col, 3, 2, 0)
    out.alpha_composite(legs.render(spec=0.0, dith=0.3))
    big = Image.new('RGBA', (W, H), (0, 0, 0, 0)); big.alpha_composite(rider_img, rider_xy)
    big = big.rotate(-lean, center=(30, 36), resample=Image.NEAREST)
    out.alpha_composite(big)
    arm = HF(W, H, light=(-0.55, -0.7, 0.55))
    tube(arm, [(40, 30), (51, 24)], 4, arm_col, 3, 0)
    arm.add([(50, 21), (56, 21), (56, 27), (50, 27)], glove, 3, 1.5, 0)
    out.alpha_composite(arm.render(spec=0.0, dith=0.25))
    # exhaust flame trails out the back (needs room, so widen the canvas)
    wide = Image.new('RGBA', (W + 18, H), (0, 0, 0, 0)); wide.alpha_composite(out, (18, 0))
    px = wide.load()
    for j in range(20):
        half = max(1, round(4 * (1 - j / 20.0)) + 1)
        for dy in range(-half, half + 1):
            t = abs(dy) / max(half, 1) * 0.6 + j / 20.0 * 0.8
            col = flame[2] if t < 0.25 else (flame[1] if t < 0.55 else flame[0])
            if px[26 - j, 41 + dy][3] == 0: px[26 - j, 41 + dy] = col + (255,)
    return wide

def crop(src, box):
    return Image.open(f'assets/{src}').convert('RGBA').crop(box)

# Kesh (from the shaded idle frame: head, backpack, tunic)
kesh_rider = crop('kesh_idle_0.png', (0, 0, 48, 31))
kb = bike(((156, 202, 232), (214, 236, 250), (222, 172, 72), (48, 52, 70), (112, 116, 132), (90, 215, 255), (255, 244, 214)),
          kesh_rider, (10, 5), 16, (70, 92, 130), (112, 70, 52), (150, 110, 70), (176, 120, 70))
kb.save('assets/kesh_bike.png')
# Warden (faces right here, flipped for the game)
wd_rider = crop('warden_ready.png', (0, 0, 44, 36))
wb = bike(((50, 52, 70), (84, 88, 110), (214, 52, 46), (34, 34, 46), (84, 86, 104), (255, 120, 60), (255, 236, 200)),
          wd_rider, (8, 4), 20, (36, 36, 50), (22, 20, 30), (40, 40, 52), (52, 52, 70),
          cloak=(40, 40, 56), shard=True, flame=((255, 90, 50), (255, 160, 80), (255, 240, 190)))
wb.transpose(Image.FLIP_LEFT_RIGHT).save('assets/warden_bike.png')
pv = Image.new('RGBA', (220, 76), (60, 50, 80, 255)); pv.alpha_composite(kb, (4, 6)); pv.alpha_composite(wb.transpose(Image.FLIP_LEFT_RIGHT), (116, 6))
pv.resize((pv.width * 5, pv.height * 5), 0).save('/tmp/bikes_new.png'); print(kb.size)
