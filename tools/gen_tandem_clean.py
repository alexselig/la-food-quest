#!/usr/bin/env python3
"""Procedurally draw axis-aligned tandem-bike sprites for LA Food Quest.

The bike only moves in cardinal directions, so the sprites must be EXACTLY aligned:
- tandem_up / tandem_down : bike vertical (long axis up-down)
- tandem_side            : bike horizontal (long axis left-right)
Alp (taller, grey hair, denim) always rides in FRONT; Xiao (red hoodie) behind.
Deterministic (no AI) so alignment is guaranteed. Chibi flat colors + dark outline.
"""
import os, math
from PIL import Image, ImageDraw

PROJ = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
CHAR = os.path.join(PROJ, "assets", "characters")
os.makedirs(CHAR, exist_ok=True)

INK = (36, 26, 58, 255)
SKIN = (240, 201, 160, 255)
ALP_HAIR = (201, 201, 210, 255)
ALP_CLOTH = (58, 110, 165, 255)     # denim
XIAO_HAIR = (30, 26, 26, 255)
XIAO_CLOTH = (210, 59, 48, 255)     # red hoodie
FRAME = (206, 62, 52, 255)
FRAME_DK = (150, 40, 34, 255)
TIRE = (40, 40, 46, 255)
RIM = (156, 162, 170, 255)
HUB = (36, 26, 58, 255)
SPOKE = (120, 120, 130, 255)


def circle(d, cx, cy, r, fill, outline=INK):
    if outline is not None:
        d.ellipse([cx - r - 1, cy - r - 1, cx + r + 1, cy + r + 1], fill=outline)
    d.ellipse([cx - r, cy - r, cx + r, cy + r], fill=fill)


def rrect(d, x0, y0, x1, y1, fill, outline=INK, rad=4):
    if outline is not None:
        d.rounded_rectangle([x0 - 1, y0 - 1, x1 + 1, y1 + 1], radius=rad + 1, fill=outline)
    d.rounded_rectangle([x0, y0, x1, y1], radius=rad, fill=fill)


def wheel_round(d, cx, cy, r):
    circle(d, cx, cy, r, TIRE)
    circle(d, cx, cy, r - 3, RIM, outline=TIRE)
    for a in range(0, 180, 30):
        dx = math.cos(math.radians(a)) * (r - 3)
        dy = math.sin(math.radians(a)) * (r - 3)
        d.line([cx - dx, cy - dy, cx + dx, cy + dy], fill=SPOKE, width=1)
    circle(d, cx, cy, 2, HUB, outline=None)


def wheel_vert(d, cx, cy, rx, ry):
    # narrow vertical ellipse (a round wheel seen almost edge-on from above)
    d.ellipse([cx - rx - 1, cy - ry - 1, cx + rx + 1, cy + ry + 1], fill=INK)
    d.ellipse([cx - rx, cy - ry, cx + rx, cy + ry], fill=TIRE)
    d.ellipse([cx - rx + 2, cy - ry + 2, cx + rx - 2, cy + ry - 2], fill=RIM)
    d.line([cx, cy - ry + 2, cx, cy + ry - 2], fill=SPOKE, width=1)


def rider_front(d, cx, cy, hair, cloth, back=False, big=False):
    s = 1.18 if big else 1.0
    tw = int(20 * s)
    th = int(19 * s)
    r = int(8 * s)
    # torso
    rrect(d, cx - tw // 2, cy - th // 2, cx + tw // 2, cy + th // 2, cloth, INK, rad=5)
    # arms reaching forward/down to the handlebars + skin hands
    d.line([cx - tw // 2 + 1, cy - 2, cx - tw // 2 - 3, cy + 9], fill=cloth, width=3)
    d.line([cx + tw // 2 - 1, cy - 2, cx + tw // 2 + 3, cy + 9], fill=cloth, width=3)
    circle(d, cx - tw // 2 - 3, cy + 9, 2, SKIN)
    circle(d, cx + tw // 2 + 3, cy + 9, 2, SKIN)
    # head
    hy = cy - th // 2 - r + 3
    circle(d, cx, hy, r, hair)                       # full hair
    if not back:
        circle(d, cx, hy + 2, r - 1, SKIN, outline=None)   # reveal hair on top only
        d.rectangle([cx - 3, hy, cx - 2, hy + 2], fill=INK)  # eyes
        d.rectangle([cx + 2, hy, cx + 3, hy + 2], fill=INK)


def rider_side(d, cx, cy, hair, cloth, big=False):
    # profile facing RIGHT (front of bike)
    s = 1.18 if big else 1.0
    tw = int(15 * s)
    th = int(18 * s)
    r = int(7 * s)
    rrect(d, cx - tw // 2, cy, cx + tw // 2, cy + th, cloth, INK, rad=4)
    # forward arm toward handlebars
    d.line([cx + tw // 2 - 1, cy + 4, cx + tw // 2 + 8, cy + 11], fill=cloth, width=3)
    circle(d, cx + tw // 2 + 8, cy + 11, 2, SKIN)
    hy = cy - r + 2
    circle(d, cx, hy, r, hair)                        # full hair
    circle(d, cx + 2, hy + 1, r - 1, SKIN, outline=None)  # reveal hair on top+back(left)
    d.rectangle([cx + r - 3, hy, cx + r - 2, hy + 2], fill=INK)  # eye toward front


def new(w, h):
    img = Image.new("RGBA", (w, h), (0, 0, 0, 0))
    return img, ImageDraw.Draw(img)


def save(img, name):
    img.save(os.path.join(CHAR, name + ".png"))
    print("  saved", name, img.size)


def make_vertical(facing_down: bool):
    W, H = 40, 96
    img, d = new(W, H)
    cx = W // 2
    top_wy, bot_wy = 16, 80
    # frame bar + wheels
    wheel_vert(d, cx, top_wy, 8, 13)
    rrect(d, cx - 3, top_wy, cx + 3, bot_wy, FRAME, FRAME_DK, rad=3)
    wheel_vert(d, cx, bot_wy, 8, 13)
    # handlebar across the front
    hb_y = bot_wy - 10 if facing_down else top_wy + 10
    d.line([cx - 9, hb_y, cx + 9, hb_y], fill=INK, width=2)
    # riders — draw far rider first so the near one overlaps on top
    if facing_down:
        rider_front(d, cx, 36, XIAO_HAIR, XIAO_CLOTH, back=False)            # behind (upper)
        rider_front(d, cx, 60, ALP_HAIR, ALP_CLOTH, back=False, big=True)    # front (lower/near)
    else:
        rider_front(d, cx, 34, ALP_HAIR, ALP_CLOTH, back=True, big=True)     # front (upper/far)
        rider_front(d, cx, 60, XIAO_HAIR, XIAO_CLOTH, back=True)             # behind (lower/near)
    save(img, "tandem_down" if facing_down else "tandem_up")


def make_side():
    W, H = 104, 56
    img, d = new(W, H)
    cy = 40
    rear_x, front_x = 22, 82
    # frame (rear hub -> seat -> front, plus lower bar) then wheels
    d.line([rear_x, cy, 52, 20], fill=FRAME, width=3)
    d.line([52, 20, front_x, cy], fill=FRAME, width=3)
    d.line([52, 20, 52, cy], fill=FRAME, width=3)
    d.line([rear_x, cy, front_x, cy], fill=FRAME, width=3)
    wheel_round(d, rear_x, cy, 13)
    wheel_round(d, front_x, cy, 13)
    # handlebar post at the front
    d.line([front_x, cy, front_x, 20], fill=INK, width=2)
    d.line([front_x - 4, 20, front_x + 4, 20], fill=INK, width=2)
    # riders: back (left=Xiao) first, then front (right=Alp) on top
    rider_side(d, 38, 16, XIAO_HAIR, XIAO_CLOTH)
    rider_side(d, 66, 13, ALP_HAIR, ALP_CLOTH, big=True)
    save(img, "tandem_side")


def main():
    make_vertical(True)
    make_vertical(False)
    make_side()
    print("DONE")


if __name__ == "__main__":
    main()
