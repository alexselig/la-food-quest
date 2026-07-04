#!/usr/bin/env python3
"""Regenerate buildings as FLAT front-view 8-bit sprites (not isometric/3D), plus
generic city filler buildings. Downscaled + palette-reduced for a chunky 8-bit look.
"""
import io, os, warnings
warnings.filterwarnings("ignore")
from google import genai
from google.genai import types
from PIL import Image

PROJ = os.path.expanduser("~/la-food-quest")
BLD = os.path.join(PROJ, "assets", "buildings")
os.makedirs(BLD, exist_ok=True)


def key():
    for p in ["~/SteampunkBeachDemo/.env", "~/pose-generator/.env.local"]:
        p = os.path.expanduser(p)
        if os.path.exists(p):
            for l in open(p):
                if l.startswith("GEMINI_API_KEY="):
                    return l.strip().split("=", 1)[1].strip().strip('"').strip("'")
    return os.environ.get("GEMINI_API_KEY", "")


c = genai.Client(api_key=key())
CFG = types.GenerateContentConfig(response_modalities=["TEXT", "IMAGE"])

BASE = ("Flat 2D FRONT-VIEW pixel-art building sprite in classic 8-bit NES / Game Boy Color style, "
        "facing the viewer straight on (orthographic front elevation, absolutely NOT isometric, NOT 3D, "
        "no perspective, no side walls, flat facade), a simple rectangular building with a flat roof line, "
        "chunky large pixels, bold black outline, limited flat color palette, centered on a plain solid "
        "flat white background, no text, no ground, no shadow")

JOBS = {
    "taco": BASE + ", a Mexican TACO restaurant stand, colorful, striped awning and a taco sign",
    "boba": BASE + ", a BOBA bubble-tea shop, teal and pink, a round bubble-tea cup sign",
    "ramen": BASE + ", a Japanese RAMEN shop, dark wood, red awning, a noodle-bowl sign and a red lantern",
    "diner": BASE + ", an American BURGER diner, red and white, a big burger sign",
    "dumpling": BASE + ", a Chinese DUMPLING restaurant, red and gold, a bamboo steamer dumpling sign",
    "golden_ladle": BASE + ", a fancy GOLDEN gourmet restaurant, ornate gold facade, a golden ladle sign",
    "home": BASE + ", a small cozy apartment HOME, warm brick, a front door and two windows",
    "fill_apartment_a": BASE + ", a tall city APARTMENT building, tan bricks, rows of windows",
    "fill_apartment_b": BASE + ", a city APARTMENT building, red brick, rows of windows and a door",
    "fill_office": BASE + ", a small city OFFICE building, blue-gray, grid of glass windows",
    "fill_shop_a": BASE + ", a small city SHOP storefront, green awning and a display window",
    "fill_shop_b": BASE + ", a small city SHOP storefront, orange striped awning and a window",
    "fill_house": BASE + ", a small city ROWHOUSE, teal walls, a door and upstairs windows",
}


def gen(p):
    try:
        r = c.models.generate_content(model="gemini-2.5-flash-image", contents=p, config=CFG)
        for part in r.candidates[0].content.parts:
            if part.inline_data is not None:
                return Image.open(io.BytesIO(part.inline_data.data)).convert("RGBA")
    except Exception as e:
        print("  err", str(e)[:120])
    return None


def strip(img, th=236):
    img = img.convert("RGBA"); px = img.load()
    for y in range(img.height):
        for x in range(img.width):
            r, g, b, a = px[x, y]
            if r >= th and g >= th and b >= th:
                px[x, y] = (r, g, b, 0)
    return img


def crop(i):
    bb = i.getbbox(); return i.crop(bb) if bb else i


def pixelate_8bit(img, target_h=56, colors=20):
    img = crop(strip(img))
    w = max(1, round(img.width * target_h / img.height))
    small = img.resize((w, target_h), Image.LANCZOS)
    # palette reduce RGB, keep alpha
    a = small.split()[3]
    rgb = small.convert("RGB").quantize(colors=colors, method=Image.MEDIANCUT).convert("RGB")
    out = Image.merge("RGBA", (rgb.split()[0], rgb.split()[1], rgb.split()[2], a))
    # hard alpha edge
    ap = out.load()
    for y in range(out.height):
        for x in range(out.width):
            r, g, b, al = ap[x, y]
            ap[x, y] = (r, g, b, 0 if al < 128 else 255)
    return out


for name, prompt in JOBS.items():
    im = gen(prompt)
    if im:
        pixelate_8bit(im).save(os.path.join(BLD, name + ".png"))
        print("saved", name)
    else:
        print("FAILED", name)
print("DONE")
