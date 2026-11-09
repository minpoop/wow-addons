"""Procedurally generates ForeverXP's theme textures (original art, no game assets).

Run:  python Tools/make_textures.py    -> writes Media/Themes/*.tga (32-bit, power-of-two, WoW-ready)
Backgrounds are periodic (FFT noise / periodic patterns), so they tile seamlessly with REPEAT wrap.
"""
import os
import numpy as np
from PIL import Image, ImageDraw, ImageFilter

OUT = os.path.join(os.path.dirname(__file__), "..", "Media", "Themes")
N = 256
rng = np.random.default_rng(1977)


def fft_noise(size=N, falloff=2.0, seed=None):
    """Periodic (tileable) fractal noise in [0,1]."""
    r = np.random.default_rng(seed) if seed is not None else rng
    white = r.standard_normal((size, size))
    f = np.fft.fft2(white)
    ky = np.fft.fftfreq(size)[:, None]
    kx = np.fft.fftfreq(size)[None, :]
    k = np.sqrt(kx * kx + ky * ky)
    k[0, 0] = 1
    f /= k ** falloff
    f[0, 0] = 0
    n = np.real(np.fft.ifft2(f))
    n -= n.min()
    return n / n.max()


def periodic_blur(a, radius):
    """Gaussian blur that wraps around the edges (keeps tiling)."""
    pad = int(radius * 3) + 1
    big = np.pad(a, ((pad, pad), (pad, pad)) + ((0, 0),) * (a.ndim - 2), mode="wrap")
    img = Image.fromarray(np.clip(big * 255, 0, 255).astype(np.uint8))
    img = img.filter(ImageFilter.GaussianBlur(radius))
    out = np.asarray(img).astype(float) / 255
    return out[pad:-pad, pad:-pad]


def save(name, rgb, alpha=None):
    rgb = np.clip(rgb, 0, 1)
    if alpha is None:
        alpha = np.ones(rgb.shape[:2])
    rgba = np.dstack([rgb, np.clip(alpha, 0, 1)])
    img = Image.fromarray((rgba * 255).astype(np.uint8), "RGBA")
    os.makedirs(OUT, exist_ok=True)
    img.save(os.path.join(OUT, name + ".tga"))
    return img


def lerp(a, b, t):
    t = t[..., None] if np.ndim(t) == 2 else t
    return a + (np.asarray(b) - a) * t


# ---------------------------------------------------------------------------
# Fog Town
# ---------------------------------------------------------------------------
def fog_world():
    """Weathered plaster / damp concrete with ash specks - the 'normal' foggy town."""
    base = fft_noise(falloff=1.6, seed=11)
    fine = fft_noise(falloff=0.6, seed=12)
    stains = fft_noise(falloff=2.4, seed=13)
    v = 0.16 + 0.07 * base + 0.03 * fine - 0.05 * np.clip(stains - 0.55, 0, 1) * 3
    col = np.dstack([v * 1.00, v * 0.98, v * 0.94])
    ash = rng.random((N, N)) > 0.985
    col[ash] *= 0.5
    return save("fog_world", col)


def fog_rust():
    """Corroded steel plating: rust blooms, seams, rivets and old dark stains."""
    rust = fft_noise(falloff=1.8, seed=21)
    grit = fft_noise(falloff=0.5, seed=22)
    blotch = fft_noise(falloff=2.6, seed=23)
    steel = np.array([0.20, 0.19, 0.18])
    orange = np.array([0.42, 0.17, 0.06])
    brown = np.array([0.20, 0.08, 0.04])
    t = np.clip((rust - 0.35) * 2.2, 0, 1)
    col = lerp(np.broadcast_to(steel, (N, N, 3)).copy(), orange, t)
    col = lerp(col, brown, np.clip((blotch - 0.5) * 2.5, 0, 1))
    col *= (0.75 + 0.35 * grit)[..., None]
    # dark, dried stains running downward (dark red-brown, tileable vertically)
    stain = np.zeros((N, N))
    for _ in range(9):
        x = rng.integers(0, N)
        y = rng.integers(0, N)
        length = rng.integers(40, 140)
        w = rng.integers(2, 6)
        for i in range(length):
            yy = (y + i) % N
            fade = 1 - i / length
            for dx in range(-w, w + 1):
                stain[yy, (x + dx + int(3 * np.sin(i / 9))) % N] = max(stain[yy, (x + dx) % N], fade * 0.8)
    stain = periodic_blur(stain, 1.5)
    col = lerp(col, np.array([0.12, 0.02, 0.015]), stain * 0.85)
    # plate seams every 128 px + rivets
    for s in (0, 128):
        col[s:s + 2, :] *= 0.35
        col[:, s:s + 2] *= 0.35
        col[s + 2:s + 3, :] *= 1.25
    for cy in (12, 116, 140, 244):
        for cx in (12, 116, 140, 244):
            yy, xx = np.ogrid[:N, :N]
            d = np.sqrt((yy - cy) ** 2 + (xx - cx) ** 2)
            col[d < 4] = col[d < 4] * 0.55 + np.array([0.30, 0.22, 0.18]) * 0.45
            col[(d >= 4) & (d < 5)] *= 0.5
            col[(d < 2) & (yy < cy)] *= 1.4
    return save("fog_rust", col * 0.9)


def fog_grate():
    """Rusted diamond-mesh grating overlay with see-through holes (tileable)."""
    yy, xx = np.mgrid[:N, :N].astype(float)
    p = 32  # 8 diamonds across the tile
    a = np.abs(((xx + yy) % p) - p / 2)
    b = np.abs(((xx - yy) % p) - p / 2)
    wire = np.minimum(a, b)
    alpha = np.clip(3.4 - wire, 0, 1)
    shade = 0.55 + 0.6 * np.clip(2.0 - wire, 0, 1)
    rust = fft_noise(falloff=1.4, seed=31)
    col = np.dstack([0.33 * shade, 0.13 * shade, 0.06 * shade]) * (0.7 + 0.6 * rust)[..., None]
    # broken / missing wires here and there
    holes = fft_noise(falloff=2.2, seed=32) > 0.82
    alpha[holes] *= 0.15
    return save("fog_grate", col, alpha)


# ---------------------------------------------------------------------------
# Spartan HUD
# ---------------------------------------------------------------------------
def hud_hex():
    """Dark visor glass with a faint hexagonal energy grid (tileable: 8 x 4 hex periods)."""
    yy, xx = np.mgrid[:N, :N].astype(float)
    w, h = 32.0, 64.0  # two interleaved lattices -> Voronoi cells are hexagons
    d1 = np.full((N, N), 1e9)
    d2 = np.full((N, N), 1e9)
    for ox, oy in ((0.0, 0.0), (w / 2, h / 2)):
        for i in range(int(N / w)):
            for j in range(int(N / h)):
                cx, cy = ox + i * w, oy + j * h
                dx = (xx - cx + N / 2) % N - N / 2
                dy = ((yy - cy + N / 2) % N - N / 2) * (w / (h / 1.732))  # squash so cells read as hexes
                d = np.sqrt(dx * dx + dy * dy)
                d2 = np.where(d < d1, d1, np.minimum(d2, d))
                d1 = np.minimum(d1, d)
    edge = np.clip(1 - (d2 - d1) / 1.6, 0, 1)
    base = 0.025 + 0.02 * fft_noise(falloff=2.0, seed=41)
    col = np.dstack([base * 0.6, base * 1.4, base * 2.0])
    pulse = 0.6 + 0.4 * fft_noise(falloff=2.2, seed=42)
    col += (edge * pulse)[..., None] * np.array([0.05, 0.24, 0.32])
    col *= (0.9 + 0.1 * (np.arange(N) % 4 < 2))[:, None, None]  # scanlines
    return save("hud_hex", col)


# ---------------------------------------------------------------------------
# Ashen Bonfire
# ---------------------------------------------------------------------------
def ashen_stone():
    """Charred, cracked flagstone with ember light glowing through the cracks."""
    stone = fft_noise(falloff=1.7, seed=51)
    grit = fft_noise(falloff=0.7, seed=52)
    v = 0.07 + 0.06 * stone + 0.025 * grit
    col = np.dstack([v * 1.05, v * 0.98, v * 0.9])
    # cracks: ridges of a periodic noise field (|n-0.5| near 0)
    c1 = np.abs(fft_noise(falloff=2.1, seed=53) - 0.5)
    c2 = np.abs(fft_noise(falloff=2.4, seed=54) - 0.5)
    crack = np.clip(1 - np.minimum(c1, c2 * 1.3) * 40, 0, 1)
    heat = fft_noise(falloff=2.0, seed=55)
    ember = crack * np.clip(heat * 1.6 - 0.3, 0, 1)
    halo = periodic_blur(ember, 3.0)
    col *= (1 - 0.6 * crack)[..., None]
    col += ember[..., None] * np.array([1.0, 0.42, 0.08]) * 0.5
    col += halo[..., None] * np.array([0.55, 0.18, 0.03]) * 0.35
    # ash flecks
    ash = rng.random((N, N)) > 0.992
    col[ash] = col[ash] * 0.5 + 0.18
    return save("ashen_stone", col)


# ---------------------------------------------------------------------------
# Imperial Gothic
# ---------------------------------------------------------------------------
def imperial_plate():
    """Crimson lacquered plate with gothic tracery etched in tarnished gold (tileable)."""
    lac = fft_noise(falloff=1.9, seed=61)
    grain = fft_noise(falloff=0.8, seed=62)
    v = 0.55 + 0.35 * lac + 0.1 * grain
    col = np.dstack([0.20 * v, 0.025 * v, 0.025 * v])
    yy, xx = np.mgrid[:N, :N].astype(float)
    gold = np.array([0.55, 0.42, 0.16])
    mask = np.zeros((N, N))
    # repeating gothic arch tracery: pointed arches every 64 px
    period = 64.0
    lx = (xx % period) - period / 2
    ly = yy % 128
    for cx in (-12.0, 12.0):  # two intersecting circles -> pointed arch
        d = np.sqrt((lx - cx) ** 2 + (ly - 70) ** 2)
        ring = np.abs(d - 30) < 0.9
        mask[ring & (ly < 70)] = 1
    mask[(np.abs(lx) > 29) & (np.abs(lx) < 31) & (ly >= 70)] = 1  # pillars
    mask[(ly > 124)] = 1  # horizontal band
    mask[(ly > 120) & (ly < 121)] = 1
    mask = periodic_blur(mask, 0.6)
    tarnish = fft_noise(falloff=1.2, seed=63)
    col = lerp(col, gold * (0.6 + 0.5 * tarnish)[..., None], np.clip(mask * 0.45, 0, 1))
    return save("imperial_plate", col)


def imperial_seal():
    """Red wax seal with parchment strips (64x128, hangs off the window)."""
    W, H = 64, 128
    img = Image.new("RGBA", (W, H), (0, 0, 0, 0))
    d = ImageDraw.Draw(img)
    # parchment strips with ragged ends and scribbled 'script'
    for i, (x0, ln) in enumerate(((14, 112), (30, 98), (44, 106))):
        w = 12
        pts = [(x0, 30), (x0 + w, 30), (x0 + w + 1, ln - 6), (x0 + w - 3, ln), (x0 + 4, ln - 4), (x0 - 1, ln)]
        d.polygon(pts, fill=(205, 186, 140, 255), outline=(120, 96, 60, 255))
        for y in range(40, ln - 8, 6):
            ww = rng.integers(4, 10)
            d.line([(x0 + 2, y), (x0 + 2 + ww, y)], fill=(60, 35, 25, 220), width=1)
    # wax disc
    d.ellipse([4, 2, 60, 58], fill=(130, 12, 10, 255), outline=(70, 4, 4, 255))
    d.ellipse([12, 10, 52, 50], outline=(175, 40, 30, 255), width=2)
    # embossed generic emblem: skull-ish rounded shape + crossed bars (original, not any faction mark)
    d.ellipse([22, 18, 42, 36], fill=(160, 28, 22, 255))
    d.ellipse([25, 24, 30, 29], fill=(80, 6, 6, 255))
    d.ellipse([34, 24, 39, 29], fill=(80, 6, 6, 255))
    d.rectangle([27, 35, 37, 41], fill=(160, 28, 22, 255))
    d.line([(16, 44), (48, 16)], fill=(185, 50, 40, 255), width=2)
    d.line([(16, 16), (48, 44)], fill=(185, 50, 40, 255), width=2)
    # drips of wax
    for x in (10, 52):
        d.ellipse([x - 3, 50, x + 3, 62], fill=(130, 12, 10, 255))
    img = img.filter(ImageFilter.SMOOTH)
    os.makedirs(OUT, exist_ok=True)
    img.save(os.path.join(OUT, "imperial_seal.tga"))
    return img


if __name__ == "__main__":
    for fn in (fog_world, fog_rust, fog_grate, hud_hex, ashen_stone, imperial_plate, imperial_seal):
        fn()
        print("wrote", fn.__name__)
