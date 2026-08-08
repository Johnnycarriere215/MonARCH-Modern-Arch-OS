#!/usr/bin/env python3
"""Render MonARCH's shipped wallpapers from each theme's palette.

A BUILD TOOL, run by hand — not part of the system layer, so golden rule 6
(bash for system code, no Python) does not apply, the same way the PDF and
icon tooling is exempt.

    pip install pillow numpy
    python3 brand/wallpapers/generate.py

Why generate rather than ship photographs
-----------------------------------------
The locked rule is "never write a wallpaper into the repo without a recorded
licence." A stranger's photo cannot be committed without verifying its licence
and that it stays live — and a licence record you have not checked is worse than
none. Art rendered from the theme's own colours has a clean, recordable licence
(MIT, MonARCH's) and matches the theme by construction. That is why these exist
and why they look like the desktop rather than like a photo library.

Each theme gets three, so `monarch background next` has something to cycle:

    01-gradient   a calm diagonal wash, bg -> surface, with a soft vignette
    02-glow       one off-centre bloom of the accent over the deep background
    03-aurora     low, wide bands of accent + accent_alt + one cool term colour

Output goes into themes/<name>/backgrounds/. Re-running overwrites them; a
user's own images alongside are left untouched. Deterministic — the dither
seed is fixed, so re-running produces byte-identical files and clean diffs.
"""

import re
from pathlib import Path

import numpy as np
from PIL import Image

REPO = Path(__file__).resolve().parents[2]
THEMES = REPO / "themes"
W, H = 3840, 2160          # 4K: crisp on the 1080p panel and any external display
RNG = np.random.default_rng(0x0D0F14)


# --------------------------------------------------------------------- palette ---

def read_palette(colors_toml: Path) -> dict:
    """Flat hex out of [ui] and [term]. No alias resolution: the shipped themes
    state ui.* and term.* as literal hex, which is all this needs."""
    section, pal = None, {}
    for line in colors_toml.read_text().splitlines():
        line = line.strip()
        if not line or line.startswith("#"):
            continue
        m = re.match(r"\[(\w+)\]", line)
        if m:
            section = m.group(1)
            continue
        m = re.match(r'(\w+)\s*=\s*"?#([0-9a-fA-F]{6})"?', line)
        if m and section in ("ui", "term"):
            pal[f"{section}.{m.group(1)}"] = rgb(m.group(2))
    return pal


def rgb(h):
    h = h.lstrip("#")
    return np.array([int(h[0:2], 16), int(h[2:4], 16), int(h[4:6], 16)], float)


# ------------------------------------------------------------------ coordinates ---

# y[i,j], x[i,j] normalised to 0..1 — shared by every renderer.
YY, XX = np.mgrid[0:H, 0:W].astype(np.float32)
YY /= H
XX /= W


def vignette(img, strength=0.30):
    """Darken toward the corners so the eye settles centre-frame."""
    d = np.hypot((XX - 0.5) * 1.15, (YY - 0.5) * 1.15)      # 0 centre .. ~0.8 corner
    factor = 1.0 - strength * np.clip(d / 0.8, 0, 1) ** 2
    return img * factor[..., None]


def finish(arr):
    """A whisper of noise to break up 8-bit banding, then clamp. Kept small
    because JPEG's DCT already handles smooth gradients well, and heavy noise
    is exactly what JPEG cannot compress — the difference between a 300KB file
    and a 6MB one for an image nobody can tell apart."""
    noise = RNG.integers(-2, 3, size=arr.shape[:2])[..., None]
    arr = np.clip(arr + noise, 0, 255).astype(np.uint8)
    return Image.fromarray(arr, "RGB")


# -------------------------------------------------------------------- renderers ---

def wp_gradient(pal):
    """Diagonal wash, deepest background -> raised surface, then a vignette.
    The quietest of the three."""
    a = pal["ui.bg"]
    b = pal.get("ui.surface", pal["ui.bg_alt"])
    t = ((XX + YY) / 2)[..., None]
    img = a * (1 - t) + b * t
    return finish(vignette(img, 0.30))


def wp_glow(pal):
    """One soft bloom of the accent, low and to one side, over the deep
    background — a light source, not a shape."""
    bg, accent = pal["ui.bg"], pal["ui.accent"]
    cx, cy = 0.32, 0.72
    # aspect-corrected distance so the bloom is round, not an ellipse
    d = np.hypot((XX - cx) * (W / H), (YY - cy))
    t = np.clip(1.0 - d / 0.95, 0, 1) ** 2 * 0.55
    img = bg * (1 - t[..., None]) + accent * t[..., None]
    return finish(vignette(img, 0.22))


def wp_aurora(pal):
    """Low, wide horizontal bands in accent, accent_alt and one cool term colour
    over the background — soft enough to sit behind windows."""
    bg = pal["ui.bg"]
    cool = pal.get("term.cyan", pal.get("term.blue", pal["ui.accent"]))
    img = np.broadcast_to(bg, (H, W, 3)).astype(np.float32).copy()
    bands = [
        (0.58, pal["ui.accent"],     0.42),
        (0.72, cool,                 0.32),
        (0.86, pal["ui.accent_alt"], 0.24),
    ]
    # a gentle horizontal tilt so the bands are not dead flat
    tilt = (XX - 0.5) * 0.06
    for centre, col, peak in bands:
        t = np.exp(-((YY + tilt - centre) ** 2) / (2 * 0.16 ** 2)) * peak
        t = t[..., None]
        img = img * (1 - t) + col * t
    return finish(vignette(img, 0.25))


RENDERERS = {
    "01-gradient": wp_gradient,
    "02-glow": wp_glow,
    "03-aurora": wp_aurora,
}


def main():
    for theme_dir in sorted(THEMES.iterdir()):
        colors = theme_dir / "colors.toml"
        if not colors.is_file():
            continue
        name = theme_dir.name
        pal = read_palette(colors)
        out_dir = theme_dir / "backgrounds"
        out_dir.mkdir(exist_ok=True)
        for slug, fn in RENDERERS.items():
            # JPEG, not PNG: these are smooth full-screen gradients, which is
            # the one thing JPEG compresses well and PNG compresses badly. q90
            # is visually lossless here and ~20x smaller. hyprpaper reads jpg,
            # and monarch-background-set accepts it.
            dest = out_dir / f"monarch-{name}-{slug}.jpg"
            fn(pal).save(dest, "JPEG", quality=90, optimize=True, progressive=True)
            kb = dest.stat().st_size // 1024
            print(f"  {name:10s} {slug:12s} {kb:5d}KB  {dest.relative_to(REPO)}")


if __name__ == "__main__":
    main()
