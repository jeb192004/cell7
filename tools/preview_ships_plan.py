"""Preview-only: straight-down (plan) views. Vagabond-9 nose right, Aegis-Interceptor nose left."""
import sys; sys.path.insert(0, 'tools')
from pxshade import *
from PIL import Image

def vagabond():
    W, H = 100, 62; cy = 31
    c = Canvas(W, H, light=(-0.4, -0.9))
    dx = 16
    M = lambda pts: [(x + dx, 2 * cy - y) for x, y in pts]          # mirror top->bottom
    T = lambda pts: [(x + dx, y) for x, y in pts]
    def both(pts, col, bulge): c.part(T(pts), col, bulge=bulge); c.part(M(pts), col, bulge=bulge)
    gray = (118, 116, 122); dgray = (84, 82, 94); brown = (146, 106, 74); teal = (100, 214, 224)
    for sgn in (-1, 1):   # engines + flames
        y0 = cy + sgn * 13
        c.part([(dx - 2, y0 - 5), (dx + 18, y0 - 5), (dx + 18, y0 + 5), (dx - 2, y0 + 5)], (66, 66, 80), bulge=4)
        c.rect(dx - 2, y0 - 2, dx + 3, y0 + 2, (34, 34, 48))
        c.rect(dx - 12, y0 - 1, dx - 3, y0 + 1, (120, 190, 255)); c.rect(dx - 9, y0, dx - 3, y0, (235, 252, 255)); c.px(dx - 14, y0, (70, 120, 220))
    both([(26, cy - 8), (32, cy - 22), (52, cy - 22), (56, cy - 8)], brown, 5)          # cargo pods
    c.part(T([(8, cy - 9), (56, cy - 10), (68, cy - 6), (68, cy + 6), (56, cy + 10), (8, cy + 9)]), gray, bulge=8)   # fuselage
    both([(58, cy - 12), (68, cy - 26), (78, cy - 24), (80, cy - 12)], dgray, 5)          # hammerhead crossbar
    c.part(T([(58, cy - 12), (80, cy - 12), (80, cy + 12), (58, cy + 12)]), dgray, bulge=6)
    c.part(T([(68, cy - 8), (80, cy - 6), (80, cy + 6), (68, cy + 8)]), teal, bulge=4)     # cockpit glass
    c.line((74 + dx, cy - 7), (74 + dx, cy + 7), (50, 82, 102))
    c.px(70 + dx, cy - 6, (235, 255, 255)); c.px(71 + dx, cy - 6, (235, 255, 255))
    c.rect(78 + dx, cy - 25, 82 + dx, cy - 24, (90, 90, 100)); c.rect(78 + dx, cy + 24, 82 + dx, cy + 25, (90, 90, 100))   # wingtip guns
    c.part([(dx + 28, cy - 9), (dx + 38, cy - 9), (dx + 42, cy - 4), (dx + 38, cy + 1), (dx + 28, cy + 1), (dx + 24, cy - 4)], (130, 134, 142), bulge=4)   # offset turret
    c.rect(dx + 42, cy - 5, dx + 52, cy - 4, (66, 68, 80)); c.rect(dx + 52, cy - 5, dx + 53, cy - 4, (255, 190, 100))
    c.part([(dx + 14, cy + 3), (dx + 22, cy + 3), (dx + 24, cy + 9), (dx + 14, cy + 9)], (176, 178, 186), bulge=3)   # radar dish
    c.line((dx + 8, cy), (dx + 56, cy), (60, 56, 66)); c.line((dx + 46, cy - 8), (dx + 46, cy + 8), (60, 56, 66))
    c.outer_outline(); return c

def aegis():
    W, H = 80, 74; cy = 37
    c = Canvas(W, H, light=(0.4, -0.9))
    metal = (98, 104, 120); dark = (58, 62, 80); pod = (74, 80, 102)
    c.part([(50, cy - 10), (66, cy - 30), (72, cy - 30), (62, cy - 6)], dark, bulge=2)              # rear sweep (top, shorter)
    c.part([(50, cy + 10), (68, cy + 34), (76, cy + 34), (62, cy + 6)], metal, bulge=3)             # rear sweep (bottom, longer)
    c.part([(32, cy - 10), (18, cy - 26), (4, cy - 32), (4, cy - 28), (16, cy - 20), (28, cy - 6)], metal, bulge=2)   # pincer arm top
    c.part([(32, cy + 10), (16, cy + 28), (2, cy + 34), (2, cy + 29), (14, cy + 22), (28, cy + 6)], dark, bulge=2)    # pincer arm bottom
    c.rect(2, cy + 26, 6, cy + 27, (255, 140, 90)); c.rect(2, cy - 29, 6, cy - 28, (255, 140, 90))                    # laser emitters
    c.part([(24, cy), (36, cy - 14), (56, cy - 14), (66, cy), (56, cy + 14), (36, cy + 14)], pod, bulge=9)             # faceted pod
    c.part([(36, cy - 14), (56, cy - 14), (50, cy - 6), (34, cy - 6)], (120, 128, 152), bulge=2)
    c.part([(28, cy - 3), (36, cy - 6), (36, cy + 6), (28, cy + 3)], (210, 44, 40), bulge=2)        # red visor, nose end
    c.rect(29, cy - 1, 34, cy + 1, (255, 150, 110)); c.px(30, cy, (255, 235, 210))
    c.line((38, cy), (62, cy), (50, 54, 72)); c.line((46, cy - 12), (46, cy + 12), (50, 54, 72))
    c.rect(66, cy - 3, 72, cy + 3, (255, 120, 60)); c.rect(70, cy - 1, 76, cy + 1, (255, 225, 160))
    c.outer_outline(); return c

v = vagabond(); a = aegis()
sheet = Image.new('RGBA', (200, 84), (14, 12, 36, 255))
sheet.alpha_composite(Image.fromarray(v.img, 'RGBA'), (4, 10)); sheet.alpha_composite(Image.fromarray(a.img, 'RGBA'), (116, 4))
sheet.resize((sheet.width * 5, sheet.height * 5), 0).save('/tmp/ships_plan.png')
