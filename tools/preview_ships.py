"""Preview-only: side views of the Vagabond-9 (hero ship) and Aegis-Interceptor (enemy). Not used in game yet."""
import sys; sys.path.insert(0, 'tools')
from pxshade import *
from PIL import Image, ImageDraw

def vagabond():
    dx = 16
    c = Canvas(128, 54)
    P = lambda pts: [(x + dx, y + 2) for x, y in pts]
    gray = (110, 108, 112); dgray = (78, 76, 84); brown = (140, 100, 70); teal = (96, 210, 220)
    # thrusters (rear), blue flames
    for y0 in (14, 27):
        c.part(P([(-4, y0), (12, y0 - 1), (12, y0 + 8), (-4, y0 + 7)]), (60, 60, 72), bulge=3)
        c.rect(dx - 4 + 8, y0 + 1 + 2, dx + 11, y0 + 6 + 2, (36, 36, 48))
        c.rect(dx - 14, y0 + 3 + 2, dx - 5, y0 + 4 + 2, (130, 200, 255))
        c.rect(dx - 10, y0 + 3 + 2, dx - 5, y0 + 4 + 2, (230, 250, 255))
        c.px(dx - 15, y0 + 3 + 2, (80, 140, 230)); c.px(dx - 16, y0 + 3 + 2, (60, 100, 200))
    c.part(P([(12, 15), (30, 10), (66, 10), (80, 15), (86, 26), (80, 35), (20, 37), (8, 28)]), gray, bulge=7)   # main hull
    c.part(P([(30, 11), (50, 11), (52, 18), (32, 20)]), brown, bulge=3)                                          # panels
    c.part(P([(12, 15), (26, 12), (28, 20), (12, 24)]), brown, bulge=3)
    c.part(P([(54, 24), (74, 24), (76, 34), (56, 35)]), dgray, bulge=3)
    c.part(P([(20, 28), (46, 28), (44, 36), (20, 37)]), brown, bulge=3)
    c.part(P([(70, 6), (90, 8), (98, 20), (96, 36), (86, 40), (70, 38)]), dgray, bulge=7)                                # hammerhead nose (taller than the hull)
    c.part(P([(76, 11), (90, 12), (96, 22), (80, 23)]), teal, bulge=4); c.part(P([(80, 25), (95, 25), (94, 31), (82, 32)]), (70, 170, 190), bulge=3)   # cockpit glass
    c.line((84 + dx, 11 + 2), (88 + dx, 22 + 2), (50, 80, 100)); c.line((90 + dx, 12 + 2), (92 + dx, 22 + 2), (50, 80, 100))
    c.px(79 + dx, 13 + 2, (235, 255, 255)); c.px(80 + dx, 13 + 2, (235, 255, 255)); c.px(81 + dx, 14 + 2, (190, 245, 250))
    c.rect(97 + dx, 34 + 2, 101 + dx, 35 + 2, (90, 90, 100)); c.px(102 + dx, 34 + 2, (255, 190, 100))   # nose gun
    # dorsal turret
    c.part(P([(38, 4), (50, 2), (56, 8), (36, 9)]), (122, 126, 134), bulge=3)
    c.rect(54 + dx, 4 + 2, 66 + dx, 5 + 2, (70, 72, 82)); c.px(66 + dx, 4 + 2, (255, 190, 100))
    # radar dish + sensor lights
    c.part(P([(58, 36), (66, 34), (70, 42), (60, 44)]), (170, 172, 178), bulge=3)
    for i, y in enumerate((38, 40, 42)): c.px(68 + dx, y + 2, (120, 220, 255))
    # ramp + landing fin
    c.part(P([(22, 36), (40, 36), (38, 42), (20, 41)]), (120, 86, 60), bulge=2)
    c.part(P([(46, 36), (60, 36), (56, 45), (44, 45)]), brown, bulge=3)
    # panel lines / rivets
    for x0, y0, x1, y1 in ((30, 21, 52, 21), (54, 14, 54, 34), (20, 26, 46, 26), (70, 12, 70, 33)):
        c.line((x0 + dx, y0 + 2), (x1 + dx, y1 + 2), (50, 46, 56))
    for x in range(34, 52, 4): c.px(x + dx, 12 + 2, (190, 160, 130))
    c.outer_outline(); return c

def aegis():
    c = Canvas(100, 62, light=(0.5, -0.8))
    P = lambda pts: [(x + 2, y + 2) for x, y in pts]
    metal = (92, 98, 112); dark = (54, 58, 74); pod = (70, 76, 98)
    c.part(P([(70, 16), (86, 2), (92, 2), (80, 20)]), dark, bulge=2)                            # small rear fin (top)
    c.part(P([(62, 40), (80, 46), (96, 58), (88, 58), (66, 50), (52, 42)]), metal, bulge=3)    # long swept wing, drops back-down
    c.part(P([(44, 18), (24, 8), (2, 2), (2, 5), (22, 14), (46, 24)]), metal, bulge=2)        # forward prong, up-left
    c.part(P([(46, 40), (28, 46), (14, 44), (14, 41), (34, 38)]), dark, bulge=2)                # lower pincer arm
    c.part(P([(28, 22), (50, 12), (70, 20), (72, 38), (52, 48), (28, 40), (22, 31)]), pod, bulge=9)   # faceted mask-pod
    c.part(P([(28, 22), (50, 12), (62, 17), (36, 27)]), (118, 126, 150), bulge=2)              # top facet
    c.part(P([(28, 40), (52, 48), (72, 38), (54, 36)]), dark, bulge=2)                         # lower facet
    c.part(P([(24, 30), (40, 27), (62, 31), (40, 37)]), (200, 40, 36), bulge=2)                # red visor
    for x in range(30, 56): c.px(x + 2, 30 + 2, (255, 110, 80))
    for x in range(36, 48): c.px(x + 2, 29 + 2, (255, 215, 185))
    c.line((48, 14), (66, 21), (150, 156, 176)); c.line((34, 40), (50, 46), (40, 44, 60))
    c.rect(4, 46, 22, 49, (70, 72, 84)); c.rect(2, 47, 6, 48, (40, 40, 52)); c.px(1, 47, (255, 150, 90))   # under-gun on the pincer
    c.rect(72, 28, 88, 32, (255, 120, 60)); c.rect(78, 29, 94, 31, (255, 220, 150))
    c.outer_outline(); return c

v = vagabond(); a = aegis()
v.save('/tmp/vagabond.png'); a.save('/tmp/aegis.png')
sheet = Image.new('RGBA', (270, 70), (14, 12, 36, 255))
sheet.alpha_composite(Image.fromarray(v.img, 'RGBA'), (4, 8)); sheet.alpha_composite(Image.fromarray(a.img, 'RGBA'), (160, 4))
sheet.resize((sheet.width * 4, sheet.height * 4), 0).save('/tmp/ships_preview.png')
