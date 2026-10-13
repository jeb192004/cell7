"""Preview-only: TOP-DOWN views of the Vagabond-9 (faces right) and Aegis-Interceptor (faces left)."""
import sys; sys.path.insert(0, 'tools')
from pxshade import *
from PIL import Image

def vagabond():
    c = Canvas(120, 66)
    dx, dy = 14, 1
    P = lambda pts: [(x + dx, y + dy) for x, y in pts]
    R = lambda x0, y0, x1, y1, col: c.rect(x0 + dx, y0 + dy, x1 + dx, y1 + dy, col)
    gray = (112, 110, 114); dgray = (80, 78, 88); brown = (142, 102, 72); teal = (96, 212, 222)
    for y0 in (12, 41):   # twin thrusters + blue flames
        c.part(P([(-2, y0), (20, y0 - 1), (20, y0 + 11), (-2, y0 + 10)]), (62, 62, 76), bulge=4)
        R(-2, y0 + 3, 4, y0 + 7, (36, 36, 50))
        R(-14, y0 + 4, -3, y0 + 6, (110, 180, 255)); R(-10, y0 + 4, -3, y0 + 6, (230, 250, 255))
        R(-17, y0 + 5, -14, y0 + 5, (70, 120, 220))
    c.part(P([(30, 4), (54, 6), (58, 20), (30, 22)]), brown, bulge=4)                       # side cargo pods
    c.part(P([(30, 42), (58, 44), (54, 58), (30, 60)]), brown, bulge=4)
    c.part(P([(14, 20), (70, 17), (76, 26), (76, 38), (70, 47), (14, 44), (8, 37), (8, 27)]), gray, bulge=9)   # hull
    c.part(P([(14, 22), (30, 21), (30, 28), (14, 29)]), brown, bulge=3)                       # patched panels
    c.part(P([(48, 36), (68, 36), (68, 45), (48, 45)]), brown, bulge=3)
    c.part(P([(66, 8), (92, 4), (101, 14), (101, 50), (92, 60), (66, 56)]), dgray, bulge=8)   # hammerhead
    c.part(P([(86, 20), (99, 22), (99, 42), (86, 44)]), teal, bulge=4)                        # cockpit glass
    c.line((92 + dx, 20 + dy), (93 + dx, 44 + dy), (50, 82, 102)); c.line((86 + dx, 32 + dy), (99 + dx, 32 + dy), (50, 82, 102))
    R(88, 22, 90, 23, (235, 255, 255)); R(88, 36, 89, 36, (200, 245, 250))
    R(98, 7, 103, 8, (90, 90, 100)); R(98, 55, 103, 56, (90, 90, 100))                       # wingtip guns
    c.part(P([(38, 25), (50, 25), (53, 32), (50, 39), (38, 39), (35, 32)]), (126, 130, 138), bulge=5)   # dorsal turret
    R(53, 31, 66, 33, (66, 68, 80)); R(66, 31, 68, 33, (255, 190, 100))
    c.part(P([(20, 38), (30, 35), (34, 42), (22, 44)]), (176, 178, 184), bulge=3)             # radar dish
    R(31, 38, 32, 39, (120, 220, 255))
    for x0, y0, x1, y1 in ((14, 32, 34, 32), (60, 18, 60, 46), (36, 21, 36, 43)):
        c.line((x0 + dx, y0 + dy), (x1 + dx, y1 + dy), (50, 46, 56))
    c.outer_outline(); return c

def aegis():
    c = Canvas(104, 66, light=(0.5, -0.8))
    dx, dy = 2, 1
    P = lambda pts: [(x + dx, y + dy) for x, y in pts]
    R = lambda x0, y0, x1, y1, col: c.rect(x0 + dx, y0 + dy, x1 + dx, y1 + dy, col)
    metal = (96, 102, 118); dark = (56, 60, 78); pod = (72, 78, 100)
    c.part(P([(76, 24), (92, 6), (98, 6), (86, 28)]), dark, bulge=2)                         # rear fin (top)
    c.part(P([(70, 40), (88, 46), (100, 62), (92, 62), (72, 52), (58, 42)]), metal, bulge=3) # long rear sweep (bottom)
    c.part(P([(52, 24), (34, 12), (4, 2), (2, 5), (30, 18), (54, 30)]), metal, bulge=2)      # forward prong (top, long)
    c.part(P([(52, 40), (34, 50), (14, 54), (12, 50), (30, 44), (52, 36)]), dark, bulge=2)   # forward pincer arm (bottom, short)
    R(8, 50, 22, 52, (70, 72, 84)); R(4, 50, 8, 51, (40, 40, 52))                           # laser emitter on the pincer
    c.part(P([(34, 28), (52, 18), (74, 24), (78, 36), (74, 46), (52, 50), (34, 40)]), pod, bulge=10)   # faceted mask-pod
    c.part(P([(34, 28), (52, 18), (62, 22), (44, 30)]), (118, 126, 150), bulge=2)            # top-left facet
    c.part(P([(34, 40), (52, 50), (74, 46), (56, 40)]), dark, bulge=2)                       # lower facet
    c.part(P([(30, 30), (36, 32), (36, 36), (30, 38), (26, 34)]), (205, 42, 38), bulge=2)    # red visor at the nose
    for yy in range(31, 38): R(31, yy, 34, yy, (255, 120, 86))
    R(31, 33, 32, 35, (255, 220, 190))
    c.line((52 + dx, 20 + dy), (72 + dx, 26 + dy), (150, 156, 176))
    R(78, 30, 92, 36, (255, 120, 60)); R(84, 32, 98, 34, (255, 220, 150))
    c.outer_outline(); return c

v = vagabond(); a = aegis()
sheet = Image.new('RGBA', (240, 74), (14, 12, 36, 255))
sheet.alpha_composite(Image.fromarray(v.img, 'RGBA'), (2, 4)); sheet.alpha_composite(Image.fromarray(a.img, 'RGBA'), (132, 4))
sheet.resize((sheet.width * 4, sheet.height * 4), 0).save('/tmp/ships_top.png')
