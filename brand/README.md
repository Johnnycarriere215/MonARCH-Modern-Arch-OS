# brand

MonARCH's identity. Swappable without touching code — nothing here is
referenced by anything except by path.

## `monarch.ascii`

The wordmark, in the "bloody" figlet style. Used by the installer banner, the
greetd login screen and `monarch --version`.

**It contains block-drawing and shade characters** (`█ ▓ ▒ ░ ▄ ▀`), so it needs
a font with full box-drawing coverage. JetBrainsMono Nerd Font — MonARCH's
terminal font — has it. In a font that does not, it degrades to a rectangle of
tofu rather than to something merely ugly, which is why the installer checks
before printing it.

Regenerate with:

```bash
figlet -f bloody MonARCH
```

Do not hand-edit it. The shading only lines up at this exact width, and a
one-character slip is invisible in a diff and obvious on screen.

## What else belongs here

| File | Used by | Status |
|---|---|---|
| `monarch.ascii` | installer banner, greetd, `monarch --version` | done |
| `plymouth/` | boot splash | Phase 4 |
| `greetd/` | login screen theme | Phase 4 |
| `icon.svg` | `.desktop` entries, the GUI's window icon | not yet |

## Licence

The wordmark is MonARCH's own. figlet fonts are not copyrightable as output;
the `bloody` font itself is distributed with figlet under its own terms and is
not vendored here — only its output.
