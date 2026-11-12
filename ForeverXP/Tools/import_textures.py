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
# Luminance targets (0-1) for textures without a procedural original. The Ascension tiers get a little
# brighter as they climb, so the late tiers keep their shine while text stays readable.
LUM = {"abyss_scale": 0.10, "frost_ice": 0.13}
for i in range(13):
    LUM["asc_%02d" % i] = 0.13 + 0.004 * i
LUM["asc_12"] = 0.17  # the level-60 galaxy may shine a little more
# Busy, high-contrast art gets its contrast squeezed (1 = unchanged) so text on top stays readable.
CONTRAST = {"abyss_scale": 0.55, "asc_10": 0.6, "asc_11": 0.6, "asc_12": 0.7}
ALPHA_FROM_WHITE = {"fog_grate", "imperial_seal"}
ALL = list(TARGET) + list(LUM) + ["imperial_seal"]


def lum(rgb):
    return 0.299 * rgb[..., 0] + 0.587 * rgb[..., 1] + 0.114 * rgb[..., 2]


def square(img):
    w, h = img.size
    s = min(w, h)
    return img.crop(((w - s) // 2, (h - s) // 2, (w - s) // 2 + s, (h - s) // 2 + s))


def needs_blend(a, axis):
    """True if wrapping along this axis shows a seam (edge jump clearly bigger than a typical step)."""
    edge = np.take(a, 0, axis) - np.take(a, -1, axis)
    steps = np.abs(np.diff(a, axis=axis)).mean()
    return np.abs(edge).mean() > 1.6 * steps + 0.01


def seamless(a, band=0.18):
    """Cross-fades the edges with a half-offset copy so the tile wraps without a seam.
    Axes that already wrap cleanly (generated "seamless" images often do) are left alone, so regular
    patterns like hex grids or arches don't get ghosted double lines."""
    n = a.shape[0]
    t = np.minimum(np.arange(n), np.arange(n)[::-1]) / (band * n)  # 0 at the edge, 1 inside the band
    t = np.clip(t, 0, 1)
    t = t * t * (3 - 2 * t)
    for axis in (0, 1):
        if not needs_blend(a, axis):
            continue
        rolled = np.roll(a, n // 2, axis=axis)
        w = (t[:, None] if axis == 0 else t[None, :])[..., None]
        a = a * w + rolled * (1 - w)
    return a


def unmatte_white(rgb):
    """White background -> alpha, recovering the colour as if it had been composited over white."""
    dist = (1.0 - rgb).max(axis=2)
    alpha = np.clip((dist - 0.04) / 0.30, 0, 1)
    a = np.maximum(alpha, 1e-3)[..., None]
    col = np.clip((rgb - (1 - a)) / a, 0, 1)
    return col, alpha


def match_brightness(rgb, alpha, name):
    weight = alpha if alpha is not None else np.ones(rgb.shape[:2])
    cur = (lum(rgb) * weight).sum() / max(weight.sum(), 1)
    want = LUM[name] if name in LUM else lum(np.array(TARGET[name], float) / 255.0)
    return np.clip(rgb * (want / max(cur, 1e-4)), 0, 1)


def write(name, rgb, alpha):
    if alpha is None:
        alpha = np.ones(rgb.shape[:2])
    rgba = np.dstack([np.clip(rgb, 0, 1), np.clip(alpha, 0, 1)])
    os.makedirs(OUT, exist_ok=True)
    path = os.path.join(OUT, name + ".tga")
    Image.fromarray((rgba * 255 + 0.5).astype(np.uint8), "RGBA").save(path)
    return path


def period_crop(a, axis, min_keep=0.8):
    """For regular patterns (mesh, hex grid, arches): trims this axis so it holds a whole number of
    repeats, choosing the length whose first line best matches the line just past its end.
    Returns the trimmed array, or None if no length wraps cleanly (then the edges get blended)."""
    n = a.shape[axis]
    small = a[::4, ::4] if a.shape[0] > 512 else a
    k = n / small.shape[axis]
    first = np.take(small, 0, axis)
    steps = np.abs(np.diff(small, axis=axis)).mean()
    best, best_len = None, None
    for ln in range(int(small.shape[axis] * min_keep), small.shape[axis]):
        d = np.abs(np.take(small, ln, axis) - first).mean()
        if best is None or d < best:
            best, best_len = d, ln
    if best is None or best > 1.2 * steps + 0.01:
        return None
    return np.take(a, range(int(best_len * k)), axis)


def convert_tile(name, src):
    img = square(Image.open(src).convert("RGB"))
    rgb = np.asarray(img, float) / 255.0
    small = np.asarray(img.resize((N, N), Image.LANCZOS), float) / 255.0
    for axis in (0, 1):  # crop to whole pattern repeats where the image doesn't already wrap
        if needs_blend(small, axis):
            cropped = period_crop(rgb, axis)
            if cropped is not None:
                rgb = cropped
    img = Image.fromarray((rgb * 255 + 0.5).astype(np.uint8)).resize((N, N), Image.LANCZOS)
    rgb = np.asarray(img, float) / 255.0
    alpha = None
    if name in ALPHA_FROM_WHITE:
        rgb, alpha = unmatte_white(rgb)
        both = seamless(np.dstack([rgb * alpha[..., None], alpha]), band=0.12)
        alpha = both[..., 3]
        rgb = both[..., :3] / np.maximum(alpha, 1e-3)[..., None]
    else:
        rgb = seamless(rgb)
    if name in CONTRAST:
        mean = rgb.reshape(-1, 3).mean(axis=0)
        rgb = mean + (rgb - mean) * CONTRAST[name]
    rgb = match_brightness(rgb, alpha, name)
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
