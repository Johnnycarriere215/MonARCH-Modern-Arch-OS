# parchment — backgrounds

Wallpapers for the **parchment** theme (warm paper indigo). `monarch background next` cycles
them; `monarch background pick` shows a menu; `monarch theme apply parchment` sets
the first one.

## Shipped

Generated from this theme's own palette by `brand/wallpapers/generate.py` —
so they match the desktop by construction, and their licence is clean.

| File | Style | Source | Licence |
|---|---|---|---|
| `monarch-parchment-01-gradient.jpg` | diagonal wash | generated from `colors.toml` | MIT (MonARCH) |
| `monarch-parchment-02-glow.jpg`     | accent bloom  | generated from `colors.toml` | MIT (MonARCH) |
| `monarch-parchment-03-aurora.jpg`   | colour bands  | generated from `colors.toml` | MIT (MonARCH) |

Regenerate: `python3 brand/wallpapers/generate.py` (needs `pillow` and `numpy`).

## Your own

Drop `.jpg`, `.jpeg`, `.png` or `.webp` here and the commands pick them up
immediately — no index to update. Images that should follow you across *every*
theme go in `~/.config/monarch/backgrounds/` instead.

**Committing an image?** Add a row to the table above first, with a real source
and licence. "Found it online" is not a licence, and the locked rule in
`MONARCH.md` is: never write a wallpaper into the repo without a recorded one.
Safe: your own work, CC0, or anything explicitly cleared for redistribution.
