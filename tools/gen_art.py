#!/usr/bin/env python3
"""Generate LA Food Quest art via Gemini (gemini-2.5-flash-image).

- Duo overworld sprite: down (reuse approved reference), up & side (image-conditioned
  on the reference for character consistency), background removed + auto-cropped.
- Environment: a grass ground tile + a generic storefront building (bg removed).

Key is read from env or a known .env (never committed). Outputs into assets/.
"""
import io
import os
import sys
import warnings
warnings.filterwarnings("ignore")
from google import genai
from google.genai import types
from PIL import Image

HERE = os.path.dirname(os.path.abspath(__file__))
PROJ = os.path.dirname(HERE)
REF = os.path.join(PROJ, "design", "reference", "alp_xiao_duo_ref.png")
CHAR_DIR = os.path.join(PROJ, "assets", "characters")
TILE_DIR = os.path.join(PROJ, "assets", "tiles")
os.makedirs(CHAR_DIR, exist_ok=True)
os.makedirs(TILE_DIR, exist_ok=True)


def load_key():
    k = os.environ.get("GEMINI_API_KEY")
    if k:
        return k
    for p in ["~/la-food-quest/.env", "~/SteampunkBeachDemo/.env", "~/pose-generator/.env.local"]:
        p = os.path.expanduser(p)
        if os.path.exists(p):
            for line in open(p):
                if line.strip().startswith("GEMINI_API_KEY="):
                    return line.strip().split("=", 1)[1].strip().strip('"').strip("'")
    return ""


KEY = load_key()
client = genai.Client(api_key=KEY)
MODEL = "gemini-2.5-flash-image"
CFG = types.GenerateContentConfig(response_modalities=["TEXT", "IMAGE"])

STYLE = ("Top-down 2D RPG overworld art in the style of classic Game Boy Pokemon games, high "
         "overhead camera angle, cute chibi proportions, thick clean black outlines, limited flat "
         "color palette, crisp pixel-art, no text, no UI, no watermark, plain solid flat white background")


def gen(prompt, ref_path=None):
    contents = []
    if ref_path and os.path.exists(ref_path):
        contents.append(types.Part.from_bytes(data=open(ref_path, "rb").read(), mime_type="image/png"))
    contents.append(prompt)
    try:
        r = client.models.generate_content(model=MODEL, contents=contents, config=CFG)
        for part in r.candidates[0].content.parts:
            if part.inline_data is not None:
                return Image.open(io.BytesIO(part.inline_data.data)).convert("RGBA")
    except Exception as e:
        print("  gen error:", str(e)[:180])
    return None


def strip_white(img, thresh=236):
    img = img.convert("RGBA")
    px = img.load()
    w, h = img.size
    for y in range(h):
        for x in range(w):
            r, g, b, a = px[x, y]
            if r >= thresh and g >= thresh and b >= thresh:
                px[x, y] = (r, g, b, 0)
    return img


def autocrop(img):
    bbox = img.getbbox()
    return img.crop(bbox) if bbox else img


def fit_height(img, h):
    w = max(1, round(img.width * h / img.height))
    return img.resize((w, h), Image.LANCZOS)


def save(img, path):
    img.save(path)
    print("  saved", os.path.relpath(path, PROJ), img.size)


def main():
    if not KEY:
        print("NO GEMINI KEY")
        sys.exit(1)

    # DOWN: reuse the approved reference (both men, spiked hair, correct)
    down = strip_white(Image.open(REF).convert("RGBA"))
    save(fit_height(autocrop(down), 96), os.path.join(CHAR_DIR, "duo_down.png"))

    # UP (from behind) — conditioned on the reference for consistency
    up = gen(STYLE + ". Using the SAME two characters from the reference image (tall Turkish man Alp in a "
             "denim jacket with short spiked dark hair; short Chinese man Xiao in a red hoodie with short "
             "spiked black hair), draw them seen FROM BEHIND (their backs) walking north/up, standing side "
             "by side, full body, same outfits and colors.", REF)
    if up:
        save(fit_height(autocrop(strip_white(up)), 96), os.path.join(CHAR_DIR, "duo_up.png"))

    # SIDE (facing right) — conditioned on the reference
    side = gen(STYLE + ". Using the SAME two characters from the reference image (tall Alp in denim jacket, "
               "short Xiao in red hoodie, both with spiked hair), draw them in SIDE PROFILE facing RIGHT/east, "
               "walking, one just behind the other, full body, same outfits and colors.", REF)
    if side:
        save(fit_height(autocrop(strip_white(side)), 96), os.path.join(CHAR_DIR, "duo_side.png"))

    # GRASS ground tile (keep bg, it is the fill)
    grass = gen("Seamless top-down pixel-art grass ground texture tile for a Pokemon-style RPG, simple flat "
                "green with a few subtle darker blades, evenly filling the whole square, tileable, no "
                "characters, no text, no border.")
    if grass:
        save(grass.convert("RGBA").resize((32, 32), Image.LANCZOS), os.path.join(TILE_DIR, "grass.png"))

    # BUILDING storefront (bg removed so it sits on grass)
    bld = gen(STYLE + ". A small generic Los Angeles storefront building seen from a high top-down angle, with "
              "an awning, a door facing south, and lit windows. Single building, centered.")
    if bld:
        save(fit_height(autocrop(strip_white(bld)), 96), os.path.join(TILE_DIR, "building.png"))

    print("DONE")


if __name__ == "__main__":
    main()
