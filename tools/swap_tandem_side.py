#!/usr/bin/env python3
"""Swap the two riders' seats on the SIDE tandem sprite via Gemini image editing.

Takes the good original side render (Xiao in front / right) and asks the model to put
ALP in the FRONT seat (right, steering) and XIAO in the BACK seat (left), keeping the
bicycle, camera angle, orientation and pixel-art style identical. Writes candidates to
/tmp for review; --install <n> copies the chosen candidate into assets/characters.
"""
import io, os, sys, warnings
warnings.filterwarnings("ignore")
from google import genai
from google.genai import types
from PIL import Image, ImageDraw

PROJ = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
CHAR = os.path.join(PROJ, "assets", "characters")
SRC = os.path.join(CHAR, "tandem_side.png")   # current = original green-bike, Xiao front
OUT = "/tmp/tandem_side_cand"
os.makedirs(OUT, exist_ok=True)


def load_key():
    k = os.environ.get("GEMINI_API_KEY")
    if k:
        return k
    for p in ["~/la-food-quest/.env", "~/slideforge/.env.local", "~/SteampunkBeachDemo/.env", "~/pose-generator/.env.local"]:
        p = os.path.expanduser(p)
        if os.path.exists(p):
            for line in open(p):
                if line.strip().startswith("GEMINI_API_KEY="):
                    v = line.strip().split("=", 1)[1].strip().strip('"').strip("'")
                    if v:
                        return v
    return ""


KEY = load_key()
client = genai.Client(api_key=KEY) if KEY else None
MODEL = "gemini-2.5-flash-image"
CFG = types.GenerateContentConfig(response_modalities=["TEXT", "IMAGE"])

PROMPT = (
    "This is a pixel-art SIDE VIEW sprite of two men riding ONE green tandem bicycle. Both men are "
    "shown in left-side profile FACING RIGHT (toward the front of the bike). Right now the black-haired "
    "man in the RED hoodie (Xiao) is in the FRONT seat (right) and the grey/silver-haired man in the "
    "blue DENIM jacket (Alp) is in the BACK seat (left). "
    "Edit ONLY their seating so they trade places: put ALP (grey hair, denim jacket) in the FRONT seat "
    "on the RIGHT holding the handlebars, and XIAO (red hoodie) in the BACK seat on the LEFT. "
    "CRITICAL: BOTH men must STILL FACE RIGHT, in side profile, the same direction — do NOT turn them to "
    "face each other and do NOT make them sit back-to-back. Keep the exact same single green tandem "
    "bicycle, the same right-facing side view, level and horizontal, same pixel-art style, colors and "
    "outlines, with ONE set of handlebars at the front (right). Plain solid flat white background, no text."
)


def remove_bg(img, thresh=60):
    img = img.convert("RGBA")
    w, h = img.size
    for s in [(0, 0), (w - 1, 0), (0, h - 1), (w - 1, h - 1)]:
        try:
            ImageDraw.floodfill(img, s, (0, 0, 0, 0), thresh=thresh)
        except Exception:
            pass
    return img


def autocrop(img):
    b = img.getbbox()
    return img.crop(b) if b else img


def fit_h(img, h):
    w = max(1, round(img.width * h / img.height))
    return img.resize((w, h), Image.LANCZOS)


def gen_once():
    src = Image.open(SRC).convert("RGBA")
    white = Image.new("RGBA", src.size, (255, 255, 255, 255))
    white.alpha_composite(src)
    buf = io.BytesIO()
    white.convert("RGB").save(buf, format="PNG")
    contents = [types.Part.from_bytes(data=buf.getvalue(), mime_type="image/png"), PROMPT]
    r = client.models.generate_content(model=MODEL, contents=contents, config=CFG)
    for part in r.candidates[0].content.parts:
        if part.inline_data is not None:
            return Image.open(io.BytesIO(part.inline_data.data)).convert("RGBA")
    return None


def main():
    if not client:
        print("NO GEMINI KEY")
        sys.exit(1)
    if len(sys.argv) >= 3 and sys.argv[1] == "--install":
        cand = os.path.join(OUT, f"cand{sys.argv[2]}.png")
        img = fit_h(autocrop(remove_bg(Image.open(cand))), 98)
        img.save(SRC)
        print("installed", cand, "->", SRC, img.size)
        return
    n = int(sys.argv[1]) if len(sys.argv) > 1 else 4
    for i in range(1, n + 1):
        try:
            img = gen_once()
        except Exception as e:
            print("  gen error:", str(e)[:160]); continue
        if img is None:
            print(f"  cand{i}: no image"); continue
        clean = fit_h(autocrop(remove_bg(img)), 98)
        clean.save(os.path.join(OUT, f"cand{i}.png"))
        print(f"  saved cand{i}", clean.size)
    print("DONE")


if __name__ == "__main__":
    main()
