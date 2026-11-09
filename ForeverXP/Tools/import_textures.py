"""Converts generated images (e.g. from ChatGPT / gpt-image-bridge) into ForeverXP theme textures.

Run:  python Tools/import_textures.py <source_dir> [name ...]
  <source_dir> holds PNG/JPG files named after the texture (fog_world.png, imperial_seal.png, ...).
  Writes Media/Themes/<name>.tga (32-bit, power-of-two, WoW-ready), replacing the procedural version.

Per texture:
  - backgrounds: centre-cropped to a square, resized to 256x256, made seamless by cross-fading the edges
    with a half-offset copy, then scaled to the brightness of the procedural texture so text stays readable.
  - fog_grate:   the same, and the white background becomes alpha (see-through holes).
  - imperial_seal: not tiled; white background becomes alpha, cropped to the artwork, fit into 64x128.
"""
import os
import sys
import numpy as np
from PIL import Image

OUT = os.path.join(os.path.dirname(__file__), "..", "Media", "Themes")
N = 256

# Mean RGB of the procedural textures (Tools/make_textures.py). The imports are scaled to the same
# luminance so the window text keeps the contrast it was tuned for.
TARGET = {
    "fog_world": (49, 48, 46),
    "fog_rust": (53, 29, 19),
    "fog_grate": (54, 21, 9),
    "hud_hex": (5, 15, 21),
    "ashen_stone": (36, 30, 25),
    "imperial_plate": (43, 7, 5),
}
ALPHA_FROM_WHITE = {"fog_grate", "imperial_seal"}
ALL = list(TARGET) + ["imperial_seal"]


def lum(rgb):
    return 0.299 * rgb[..., 0] + 0.587 * rgb[..., 1] + 0.114 * rgb[..., 2]


def square(img):
    w, h = img.size
    s = min(w, h)
    return img.crop(((w - s) // 2, (h - s) // 2, (w - s) // 2 + s, (h - s) // 2 + s))


def seamless(a, band=0.18):
    """Cross-fades the edges with a half-offset copy so the tile wraps without a seam."""
    n = a.shape[0]
    rolled = np.roll(a, (n // 2, n // 2), axis=(0, 1))
    t = np.minimum(np.arange(n), np.arange(n)[::-1]) / (band * n)  # 0 at the edge, 1 inside the band
    t = np.clip(t, 0, 1)
    t = t * t * (3 - 2 * t)
    w = np.minimum(t[:, None], t[None, :])[..., None]
    return a * w + rolled * (1 - w)


def unmatte_white(rgb):
    """White background -> alpha, recovering the colour as if it had been composited over white."""
    dist = (1.0 - rgb).max(axis=2)
    alpha = np.clip((dist - 0.04) / 0.30, 0, 1)
    a = np.maximum(alpha, 1e-3)[..., None]
    col = np.clip((rgb - (1 - a)) / a, 0, 1)
    return col, alpha


def match_brightness(rgb, alpha, target):
    weight = alpha if alpha is not None else np.ones(rgb.shape[:2])
    cur = (lum(rgb) * weight).sum() / max(weight.sum(), 1)
    want = lum(np.array(target, float) / 255.0)
    return np.clip(rgb * (want / max(cur, 1e-4)), 0, 1)


def write(name, rgb, alpha):
    if alpha is None:
        alpha = np.ones(rgb.shape[:2])
    rgba = np.dstack([np.clip(rgb, 0, 1), np.clip(alpha, 0, 1)])
    os.makedirs(OUT, exist_ok=True)
    path = os.path.join(OUT, name + ".tga")
    Image.fromarray((rgba * 255 + 0.5).astype(np.uint8), "RGBA").save(path)
    return path


def convert_tile(name, src):
    img = square(Image.open(src).convert("RGB")).resize((N, N), Image.LANCZOS)
    rgb = np.asarray(img, float) / 255.0
    alpha = None
    if name in ALPHA_FROM_WHITE:
        rgb, alpha = unmatte_white(rgb)
        both = seamless(np.dstack([rgb * alpha[..., None], alpha]), band=0.12)
        alpha = both[..., 3]
        rgb = both[..., :3] / np.maximum(alpha, 1e-3)[..., None]
    else:
        rgb = seamless(rgb)
    rgb = match_brightness(rgb, alpha, TARGET[name])
    return write(name, rgb, alpha)


def convert_seal(src, W=64, H=128):
    rgb = np.asarray(Image.open(src).convert("RGB"), float) / 255.0
    col, alpha = unmatte_white(rgb)
    ys, xs = np.nonzero(alpha > 0.1)
    if len(xs):
        col, alpha = col[ys.min():ys.max() + 1, xs.min():xs.max() + 1], alpha[ys.min():ys.max() + 1, xs.min():xs.max() + 1]
    rgba = Image.fromarray((np.dstack([col * alpha[..., None], alpha]) * 255).astype(np.uint8), "RGBA")
    scale = min(W / rgba.width, H / rgba.height)
    rgba = rgba.resize((max(1, round(rgba.width * scale)), max(1, round(rgba.height * scale))), Image.LANCZOS)
    canvas = Image.new("RGBA", (W, H), (0, 0, 0, 0))
    canvas.paste(rgba, ((W - rgba.width) // 2, 0))  # top-aligned: the wax hangs from the window edge
    a = np.asarray(canvas, float) / 255.0
    pre, alpha = a[..., :3], a[..., 3]
    return write("imperial_seal", pre / np.maximum(alpha, 1e-3)[..., None], alpha)


def find_source(src_dir, name):
    for ext in (".png", ".jpg", ".jpeg", ".webp"):
        p = os.path.join(src_dir, name + ext)
        if os.path.exists(p):
            return p
    return None


if __name__ == "__main__":
    if len(sys.argv) < 2:
        sys.exit(__doc__)
    src_dir, names = sys.argv[1], sys.argv[2:] or ALL
    for name in names:
        if name not in ALL:
            sys.exit("unknown texture: " + name)
        src = find_source(src_dir, name)
        if not src:
            print("skip", name, "(no source image)")
            continue
        out = convert_seal(src) if name == "imperial_seal" else convert_tile(name, src)
        print("wrote", os.path.normpath(out))
