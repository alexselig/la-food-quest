#!/usr/bin/env python3
"""Generate LA Food Quest CITY art.
- Procedural PIL ground tiles: pavement, asphalt, wall (zero grass).
- Gemini: a distinct top-down building per restaurant name + apartment + multi-tile
  city park + a celebration star burst. Backgrounds removed, auto-cropped.
"""
import io
import os
import warnings
warnings.filterwarnings("ignore")
from google import genai
from google.genai import types
from PIL import Image

PROJ = os.path.expanduser("~/la-food-quest")
BLD = os.path.join(PROJ, "assets", "buildings")
TILES = os.path.join(PROJ, "assets", "tiles")
FX = os.path.join(PROJ, "assets", "fx")
for d in (BLD, TILES, FX):
    os.makedirs(d, exist_ok=True)


def key():
    k = os.environ.get("GEMINI_API_KEY")
    if k:
        return k
    for p in ["~/SteampunkBeachDemo/.env", "~/pose-generator/.env.local"]:
        p = os.path.expanduser(p)
        if os.path.exists(p):
            for line in open(p):
                if line.startswith("GEMINI_API_KEY="):
                    return line.strip().split("=", 1)[1].strip().strip('"').strip("'")
    return ""


client = genai.Client(api_key=key())
CFG = types.GenerateContentConfig(response_modalities=["TEXT", "IMAGE"])


def gen(prompt):
    try:
        r = client.models.generate_content(model="gemini-2.5-flash-image", contents=prompt, config=CFG)
        for part in r.candidates[0].content.parts:
            if part.inline_data is not None:
                return Image.open(io.BytesIO(part.inline_data.data)).convert("RGBA")
    except Exception as e:
        print("  gen error:", str(e)[:160])
    return None


def strip(img, th=236):
    img = img.convert("RGBA"); px = img.load()
    for y in range(img.height):
        for x in range(img.width):
            r, g, b, a = px[x, y]
            if r >= th and g >= th and b >= th:
                px[x, y] = (r, g, b, 0)
    return img


def crop(img):
    bb = img.getbbox(); return img.crop(bb) if bb else img


def fit_max(img, m):
    s = m / max(img.size)
    return img.resize((max(1, round(img.width * s)), max(1, round(img.height * s))), Image.LANCZOS)


# ---------- procedural city tiles ----------
def pavement():
    im = Image.new("RGBA", (16, 16), (176, 174, 170, 255))
    px = im.load()
    for i in range(16):
        px[i, 0] = (150, 148, 145, 255)   # top seam
        px[0, i] = (150, 148, 145, 255)    # left seam
    for (x, y) in [(4, 5), (11, 9), (7, 13), (13, 3)]:
        px[x, y] = (166, 164, 160, 255)
    im.save(os.path.join(TILES, "pavement.png"))


def asphalt():
    im = Image.new("RGBA", (16, 16), (68, 70, 76, 255))
    px = im.load()
    for (x, y) in [(2, 3), (9, 5), (5, 11), (13, 8), (7, 14), (11, 1)]:
        px[x, y] = (60, 62, 68, 255)
    for (x, y) in [(3, 9), (10, 12), (14, 4)]:
        px[x, y] = (78, 80, 86, 255)
    im.save(os.path.join(TILES, "asphalt.png"))


def wall():
    im = Image.new("RGBA", (16, 16), (54, 52, 58, 255))
    px = im.load()
    for i in range(16):
        px[i, 0] = (40, 38, 44, 255)
        px[i, 15] = (40, 38, 44, 255)
        px[0, i] = (40, 38, 44, 255)
        px[15, i] = (40, 38, 44, 255)
    im.save(os.path.join(TILES, "wall.png"))


STYLE = ("Top-down 2D RPG overworld building in the style of classic Game Boy Pokemon games, high overhead "
         "3/4 view, thick clean black outlines, limited flat color palette, crisp pixel-art, no text, no UI, "
         "plain solid flat white background, single structure centered")

BUILDINGS = {
    "taco":     STYLE + ", a colorful Mexican TACO FOOD TRUCK parked, serving window, striped awning, taco decorations, festive red green yellow",
    "boba":     STYLE + ", a cute BOBA bubble-tea shop storefront, teal and pink, a big bubble-tea cup sign on the roof, glass front",
    "ramen":    STYLE + ", a Japanese RAMEN noodle bar, dark wood, red awning and red paper lanterns, a steaming noodle-bowl sign",
    "diner":    STYLE + ", a retro American BURGER DINER, chrome and red, a big hamburger sign on the roof, checkered trim",
    "dumpling": STYLE + ", a Chinese DUMPLING restaurant, red and gold facade, a bamboo steamer-basket sign, curved pagoda roof",
    "golden_ladle": STYLE + ", an elegant luxurious fine-dining restaurant, ornate GOLDEN facade, a golden ladle emblem on the sign, grand and fancy",
    "home":     STYLE + ", a cozy small apartment home, warm brick, a front door and windows with flower boxes",
}


def main():
    print("tiles...")
    pavement(); asphalt(); wall()
    print("  saved pavement/asphalt/wall")

    for name, prompt in BUILDINGS.items():
        im = gen(prompt)
        if im:
            fit_max(crop(strip(im)), 128).save(os.path.join(BLD, name + ".png"))
            print("  saved building", name)
        else:
            print("  FAILED", name)

    park = gen("Top-down 2D RPG overworld CITY PARK block in classic Pokemon style, a wide rectangular green "
               "lawn with several leafy trees, a winding path and a small pond, thick outlines, flat colors, "
               "crisp pixel-art, no text, plain solid flat white background, fills a wide rectangular area")
    if park:
        fit_max(crop(strip(park)), 192).save(os.path.join(BLD, "park.png"))
        print("  saved park")

    star = gen("A single bright yellow and white PIXEL-ART STAR BURST sparkle celebration effect, radiating "
               "lines, cartoon style, thick black outline, on a plain solid flat white background, no text")
    if star:
        fit_max(crop(strip(star)), 64).save(os.path.join(FX, "star.png"))
        print("  saved star")

    print("DONE")


if __name__ == "__main__":
    main()
