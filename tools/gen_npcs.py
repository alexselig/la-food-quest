#!/usr/bin/env python3
"""Generate distinct top-down NPC sprites + environment art for LA Food Quest via Gemini
(gemini-2.5-flash-image). Style-anchored to the approved duo reference for consistency.

Background removal uses flood-fill from the borders so interior whites (aprons, chef hats,
grey hair) are preserved. Never commits the API key.
"""
import io, os, sys, warnings
warnings.filterwarnings("ignore")
from google import genai
from google.genai import types
from PIL import Image, ImageDraw

HERE = os.path.dirname(os.path.abspath(__file__))
PROJ = os.path.dirname(HERE)
REF = os.path.join(PROJ, "design", "reference", "alp_xiao_duo_ref.png")
NPC_DIR = os.path.join(PROJ, "assets", "npcs")
TILE_DIR = os.path.join(PROJ, "assets", "tiles")
PROP_DIR = os.path.join(PROJ, "assets", "props")
for d in (NPC_DIR, TILE_DIR, PROP_DIR):
    os.makedirs(d, exist_ok=True)


def load_key():
    k = os.environ.get("GEMINI_API_KEY")
    if k:
        return k
    for p in ["~/la-food-quest/.env", "~/SteampunkBeachDemo/.env", "~/slideforge/.env.local", "~/pose-generator/.env.local"]:
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

STYLE = ("Top-down 2D RPG overworld sprite in the style of classic Game Boy Pokemon games, high "
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


def remove_bg(img, thresh=60):
    """Flood-fill transparent from the 4 corners (preserves interior whites)."""
    img = img.convert("RGBA")
    w, h = img.size
    seeds = [(0, 0), (w - 1, 0), (0, h - 1), (w - 1, h - 1)]
    for s in seeds:
        try:
            ImageDraw.floodfill(img, s, (0, 0, 0, 0), thresh=thresh)
        except Exception:
            pass
    return img


def autocrop(img):
    bbox = img.getbbox()
    return img.crop(bbox) if bbox else img


def fit_h(img, h):
    w = max(1, round(img.width * h / img.height))
    return img.resize((w, h), Image.LANCZOS)


def save(img, path):
    img.save(path)
    print("  saved", os.path.relpath(path, PROJ), img.size)


NPCS = {
    "remy": "a distinguished older FOOD CRITIC man: tweed blazer, small round glasses, neat grey hair, holding a tiny notepad",
    "nia": "a friendly BIKE MECHANIC young woman: blue denim overalls, a backwards cap, dark ponytail, holding a wrench",
    "mara": "a cheerful NOODLE VENDOR woman: cooking apron and a headband, holding a soup ladle",
    "sol": "a PARK RANGER: khaki ranger uniform with a ranger hat and a badge, sturdy boots",
    "ori": "a warm CAFE CHEF: white apron and tall white chef hat, holding a small plate",
    "han": "an older KOREAN MARKET shopkeeper grandmother: cozy cardigan, glasses, kind smile",
    "mina": "a KOREAN BBQ CHEF woman: dark apron and a bandana, holding a pair of grill tongs",
}


def gen_npc(nid, desc):
    p = (STYLE + f". Match the exact art style, chibi body proportions, outline thickness and overhead "
         f"camera angle of the reference image, but draw ONE single NEW character (do NOT copy the two "
         f"people in the reference): {desc}. Exactly one character, full body head-to-toe, standing and "
         f"facing SOUTH toward the viewer, arms at sides, centered, plain solid white background.")
    img = gen(p, REF)
    if img:
        out = fit_h(autocrop(remove_bg(img)), 96)
        save(out, os.path.join(NPC_DIR, f"{nid}.png"))
        return True
    print("  FAILED", nid)
    return False


# The two heroes as SOLO portraits (extracted from the duo reference) for dialogue.
DUO = {
    "alp": ("the TALLER of the two friends: a tall lanky young Turkish man, fair slightly-tan skin, "
            "mostly grey/silver short spiked hair with a central spike, wearing an open blue denim "
            "jacket over a shirt"),
    "xiao": ("the SHORTER of the two friends: a young Chinese man a bit shorter than Alp, short spiked "
             "black hair with a central spike, wearing a bright red hoodie"),
}


def gen_duo(nid, desc):
    p = (STYLE + f". Using the reference image of the two friends for their exact designs, draw ONLY ONE "
         f"of them as a SOLO character: {desc}. Exactly one single character, full body head-to-toe, "
         f"standing and facing SOUTH toward the viewer, arms at sides, same outfit, colors and hairstyle "
         f"as in the reference, centered, plain solid white background. Do NOT draw the other friend.")
    img = gen(p, REF)
    if img:
        save(fit_h(autocrop(remove_bg(img)), 96), os.path.join(NPC_DIR, f"{nid}.png"))
        return True
    print("  FAILED", nid)
    return False


def main():
    if not client:
        print("NO GEMINI KEY")
        sys.exit(1)
    only = sys.argv[1:]  # optional subset of ids

    for nid, desc in DUO.items():
        if only and nid not in only:
            continue
        print("DUO", nid)
        gen_duo(nid, desc)

    for nid, desc in NPCS.items():
        if only and nid not in only:
            continue
        print("NPC", nid)
        gen_npc(nid, desc)

    if not only or "env" in only:
        print("water tile")
        w = gen("Seamless top-down pixel-art WATER texture tile for a Pokemon-style RPG: calm blue pond "
                "water with subtle lighter cyan ripples, evenly filling the entire square, tileable, no "
                "characters, no text, no border, no shoreline.")
        if w:
            save(w.convert("RGBA").resize((32, 32), Image.LANCZOS), os.path.join(TILE_DIR, "water.png"))

        print("path tile")
        pth = gen("Seamless top-down pixel-art DIRT PATH texture tile for a Pokemon-style RPG: light tan "
                  "packed earth with a few tiny pebbles, evenly filling the entire square, tileable, no "
                  "characters, no text, no border.")
        if pth:
            save(pth.convert("RGBA").resize((32, 32), Image.LANCZOS), os.path.join(TILE_DIR, "path.png"))

        print("sand tile")
        snd = gen("Seamless top-down pixel-art SAND BEACH texture tile for a Pokemon-style RPG: pale warm "
                  "sand with faint ripples, evenly filling the entire square, tileable, no characters, no text.")
        if snd:
            save(snd.convert("RGBA").resize((32, 32), Image.LANCZOS), os.path.join(TILE_DIR, "sand.png"))

        print("tree prop")
        tr = gen(STYLE + ". A single small round leafy TREE seen from a high top-down angle: full green "
                 "canopy with a short brown trunk visible at the bottom, one tree only, centered, plain "
                 "solid white background.", REF)
        if tr:
            save(fit_h(autocrop(remove_bg(tr)), 46), os.path.join(PROP_DIR, "tree.png"))

        print("lotus prop")
        lo = gen(STYLE + ". A single LOTUS water-lily: a round flat green lily pad with a small pink lotus "
                 "flower on it, top-down, one only, centered, plain solid white background.", REF)
        if lo:
            save(fit_h(autocrop(remove_bg(lo)), 14), os.path.join(PROP_DIR, "lotus.png"))

    print("DONE")


if __name__ == "__main__":
    main()
