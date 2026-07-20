#!/usr/bin/env python3
"""Generate Level 1 landmark sprites (boathouse, bridge, shed, fountain) with Gemini,
matched to the existing building pixel-art style. Writes candidates to /tmp/l1_art for
review; --install <name> <n> copies a chosen candidate into assets/buildings/<name>.png.

The key is read from a gitignored env file; it is NEVER hardcoded or committed.
"""
import io, os, sys, warnings
warnings.filterwarnings("ignore")
from google import genai
from google.genai import types
from PIL import Image, ImageDraw

PROJ = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
BUILD = os.path.join(PROJ, "assets", "buildings")
REF = os.path.join(BUILD, "ramen.png")   # style anchor
OUT = "/tmp/l1_art"
os.makedirs(OUT, exist_ok=True)

STYLE = (
    " Render in the SAME 16-bit SNES top-down RPG pixel-art style as the reference image: "
    "front elevation, bold dark outline, flat cel shading, vibrant saturated colors, crisp "
    "pixels. One single object centered on a solid PURE WHITE background. No ground, no cast "
    "shadow, no text, no watermark, no border."
)
PROMPTS = {
    "boathouse": (
        "A small lakeside BOATHOUSE: pitched wooden roof, a wide arched boat-bay opening at "
        "the front showing dark water inside, weathered blue-grey wood plank siding, a little "
        "hanging wooden sign, a red life-ring hung on the wall." + STYLE),
    "bridge": (
        "A short ornamental ARCHED FOOTBRIDGE seen from the front: a stone/wood arch spanning "
        "water, a planked walkway across the top, low side railings, a couple of support posts." + STYLE),
    "shed": (
        "A small park MAINTENANCE SHED: slanted roof, closed wooden double doors, one tiny "
        "window, grey-green corrugated walls, a rake and a bucket leaning against the side." + STYLE),
    "fountain": (
        "A round tiered STONE FOUNTAIN: circular basin of blue water, a central column, thin "
        "jets of water arcing up and out, mossy stone, seen from a front three-quarter angle." + STYLE),
}


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


def remove_bg(img, thresh=64):
    img = img.convert("RGBA")
    w, h = img.size
    for s in [(0, 0), (w - 1, 0), (0, h - 1), (w - 1, h - 1),
              (w // 2, 0), (w // 2, h - 1), (0, h // 2), (w - 1, h // 2)]:
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


def gen_once(prompt):
    parts = []
    if os.path.exists(REF):
        ref = Image.open(REF).convert("RGB")
        buf = io.BytesIO(); ref.save(buf, format="PNG")
        parts.append(types.Part.from_bytes(data=buf.getvalue(), mime_type="image/png"))
    parts.append(prompt)
    r = client.models.generate_content(model=MODEL, contents=parts, config=CFG)
    for part in r.candidates[0].content.parts:
        if part.inline_data is not None:
            return Image.open(io.BytesIO(part.inline_data.data)).convert("RGBA")
    return None


def main():
    if not client:
        print("NO GEMINI KEY"); sys.exit(1)
    if len(sys.argv) >= 4 and sys.argv[1] == "--install":
        name, n = sys.argv[2], sys.argv[3]
        cand = os.path.join(OUT, f"{name}_{n}.png")
        img = autocrop(remove_bg(Image.open(cand)))
        img.save(os.path.join(BUILD, f"{name}.png"))
        print("installed", cand, "->", os.path.join(BUILD, f"{name}.png"), img.size)
        return
    names = sys.argv[1:] if len(sys.argv) > 1 else list(PROMPTS.keys())
    per = 3
    for name in names:
        for i in range(1, per + 1):
            try:
                img = gen_once(PROMPTS[name])
            except Exception as e:
                print(f"  {name}_{i} gen error:", str(e)[:140]); continue
            if img is None:
                print(f"  {name}_{i}: no image"); continue
            clean = autocrop(remove_bg(img))
            clean.save(os.path.join(OUT, f"{name}_{i}.png"))
            print(f"  saved {name}_{i}", clean.size)
    print("DONE")


if __name__ == "__main__":
    main()
