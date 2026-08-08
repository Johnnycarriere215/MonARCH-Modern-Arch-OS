```
 ███▄ ▄███▓ ▒█████   ███▄    █  ▄▄▄       ██▀███   ▄████▄   ██░ ██
▓██▒▀█▀ ██▒▒██▒  ██▒ ██ ▀█   █ ▒████▄    ▓██ ▒ ██▒▒██▀ ▀█  ▓██░ ██▒
▓██    ▓██░▒██░  ██▒▓██  ▀█ ██▒▒██  ▀█▄  ▓██ ░▄█ ▒▒▓█    ▄ ▒██▀▀██░
 ▒██    ▒██ ▒██   ██░▓██▒  ▐▌██▒░██▄▄▄▄██ ▒██▀▀█▄  ▒▓▓▄ ▄██▒░▓█ ░██
▒██▒   ░██▒░ ████▓▒░▒██░   ▓██░ ▓█   ▓██▒░██▓ ▒██▒▒ ▓███▀ ░░▓█▒░██▓
░ ▒░   ░  ░░ ▒░▒░▒░ ░ ▒░   ▒ ▒  ▒▒   ▓▒█░░ ▒▓ ░▒▓░░ ░▒ ▒  ░ ▒ ░░▒░▒
░  ░      ░  ░ ▒ ▒░ ░ ░░   ░ ▒░  ▒   ▒▒ ░  ░▒ ░ ▒░  ░  ▒    ▒ ░▒░ ░
░      ░   ░ ░ ░ ▒     ░   ░ ░   ░   ▒     ░░   ░ ░         ░  ░░ ░
       ░       ░ ░           ░       ░  ░   ░     ░ ░       ░  ░  ░
                                                  ░
```

# MonARCH

**Arch Linux, made yours.**

A fast, keyboard-first Linux desktop that doesn't require a terminal to
configure. Built on Arch Linux and Hyprland. Tiling by default, with a real
settings app when you want one.

---

## ⚠ Not ready to install

**MonARCH has never been booted.** Phases 1 and 2 are code-complete and
verified locally — fake `HOME` directories, install stages replayed, every
generated file checked mechanically — but **no version of Hyprland has yet
parsed a single line this repository produces.** The first VM test has not been
run.

There is no ISO. There are no releases.

Read it, take ideas from it, follow along. Don't put it on a machine you care
about. This notice goes when it boots.

---

## What it is

A curated Arch stack plus a management layer. Not a desktop environment written
from scratch, and not just a theme.

Windows 11 is full of ads and Copilot. Linux Mint is comfortable but rigid
where it matters. [Omarchy](https://github.com/basecamp/omarchy) is fast and
beautiful but deliberately terminal-only.

MonARCH goes for Omarchy's speed and looks, with a real settings GUI, a
first-run wizard, a Windows-like mode for when you want one, and documentation
that generates itself from the configuration instead of drifting away from it.

## The stack

| | |
|---|---|
| Base | Arch Linux, x86_64 |
| Compositor | Hyprland |
| Bar | Waybar |
| Launcher | Walker — bare `Super` tap |
| Editor | [MonARCH Code](https://github.com/Johnnycarriere215/MonARCH-Code) — Tauri + Monaco |
| Terminal | Alacritty |
| Notifications | Mako |
| Lock | Hyprlock |
| Login | greetd + tuigreet |
| Filesystem | Btrfs + Snapper, bootable snapshots |
| GUI toolkit | Tauri. **Never Electron** |

## The ideas it's built on

**One TOML, one desktop.** `schema/keybinds.toml` is the source of truth for
every key; `bindings.conf` is generated from it with a DO-NOT-EDIT header. A
theme is one `colors.toml`, and applying it restyles Hyprland, Hyprlock,
Waybar, Alacritty, Mako, Walker, btop, the editor and VS Code in one command.
No second place to keep in step.

**Adding an app to the theme system is adding one file.** Templates in
`themes/_templates/` declare their own destination and reload command in a
header the renderer strips. No code anywhere names an application.

**Modes are data, not code.** `modes/{tiling,windows,performance}/` are config
fragments layered over the base. No `if mode == "windows"` anywhere — and
windows mode falls back to tiling *with a warning* rather than dropping you
into a session with no title bars and no explanation.

**Every update snapshots first.** `monarch update` takes a Btrfs snapshot
before touching anything and refuses to run if it can't. A bad update is undone
from the boot menu. That's the answer to the one real downside of a rolling
release.

**The CLI is the only thing that writes config.** The settings GUI shells out
to `monarch`; it never edits a file itself. If the two could disagree, the
design would be wrong.

## The CLI

44 commands. Bare `monarch` prints them, grouped, discovered by scanning
`bin/` — nothing hardcoded.

```
monarch theme apply harbor          restyle the whole desktop
monarch keys list                   every binding, generated not written
monarch mode set windows            title bars, taskbar, floating
monarch bar modules disable gpu     bar composition
monarch update                      snapshot, pull, upgrade, migrate
monarch snapshot restore 42         roll it back
monarch webapp add "Messages" messages.google.com/web
```

---

## BIOS settings — read before installing

MonARCH will not install unless these are set. On HP laptops press **`F10`** at
the boot splash.

| Setting | Must be | Why |
|---|---|---|
| Secure Boot | **Disabled** | Arch's bootloader is not Microsoft-signed |
| TPM | **Disabled** | Interferes with LUKS setup |
| Virtualization (VT-x) | **Enabled** | Claude Desktop's Cowork needs `/dev/kvm` |
| VT-d / IOMMU | **Enabled** | Required alongside VT-x |

**If the USB won't boot, it is almost always Secure Boot.** Check that first.

> **The installer erases the drive you select.** Confirm which drive before
> continuing, and back up anything you cannot lose. With full-disk encryption
> you get a **recovery key — save it off the machine.** A forgotten password
> without it is permanent, unrecoverable data loss.

## Installing

There is no ISO yet (Phase 4). MonARCH installs onto a fresh Arch system with a
**Btrfs root**, UEFI, and a user with sudo:

```bash
curl -fsSL https://raw.githubusercontent.com/Johnnycarriere215/MonARCH-Modern-Arch-OS/main/bootstrap.sh | bash
```

It refuses to run as root and checks Arch / x86_64 / Btrfs / UEFI first, naming
whichever one failed.

| Guide | |
|---|---|
| [`docs/09-ARCH-INSTALL.md`](docs/09-ARCH-INSTALL.md) | Base Arch, step by step. No prior knowledge assumed |
| [`docs/07-VM-TESTING.md`](docs/07-VM-TESTING.md) | Test it in a VM — **do this first** |
| [`docs/08-USB-INSTALL.md`](docs/08-USB-INSTALL.md) | Daily-drive it from an external drive, internal disk untouched |
| [`docs/10-DUAL-BOOT.md`](docs/10-DUAL-BOOT.md) | Install beside Linux Mint on the internal drive, choose at boot |

## First keys

| Key | Does |
|---|---|
| `Super` (tap) | Launcher — type three letters, Enter |
| `Super + /` | Every keyboard shortcut, generated from the keymap |
| `Super + Return` | Terminal |
| `Super + Q` | Close window |
| `Super + C` | Editor |
| `` Super + ` `` | Dropdown terminal |

`monarch keys list` prints the same thing. It is never hand-written.

## Modes

| Mode | For |
|---|---|
| **Tiling** | Windows arrange themselves. Fastest once learned |
| **Windows** | Floating, title bars, close buttons, taskbar. Familiar |
| **Performance** | Effects off, bar polls slower. Battery, or a heavy build |

`monarch mode set <name>`, or `monarch mode session <name>` for one session
without changing the default.

## Where the build is

| Phase | | |
|---|---|---|
| 1 | A bootable desktop | code complete, **unbooted** |
| 2 | Themes, keys, bar, modes, updates, installers | code complete, **unbooted** |
| 3 | Settings GUI, first-run wizard | not started |
| 4 | The ISO | not started |

`PROGRESS.md` is the real answer — updated every session, with per-task notes
on every decision and why it was made.

Phase 3 is deliberately gated on **a week of daily use**. What annoys you that
week should shape the GUI, rather than the GUI being guessed at first.

## Hardware

Developed against an HP EliteBook 850 G6 — i7-8665U, 32GB, **Intel UHD 620
only**, 1080p. No NVIDIA and no hybrid graphics anywhere in the assumptions.
Other hardware is untested, which right now means "as untested as the target".

## Docs

| | |
|---|---|
| [`MONARCH.md`](MONARCH.md) | Golden rules, locked decisions, session protocol |
| [`PROGRESS.md`](PROGRESS.md) | Build state. Read every session, updated every session |
| [`HANDOFF.md`](HANDOFF.md) | Cold-start pointers |
| [`docs/00-BRIEF.md`](docs/00-BRIEF.md) | What MonARCH is and why |
| [`docs/01-DECISIONS.md`](docs/01-DECISIONS.md) | Every design decision, with rationale |
| [`docs/02-HARDWARE.md`](docs/02-HARDWARE.md) | Target hardware, known risks, validation |
| [`docs/03-ROADMAP.md`](docs/03-ROADMAP.md) | Phases and acceptance criteria |
| [`docs/04-TASKS.md`](docs/04-TASKS.md) | Build tasks |
| [`docs/05-CHECKLIST.md`](docs/05-CHECKLIST.md) | Human-only actions |
| [`docs/06-RELEASE.md`](docs/06-RELEASE.md) | ISO and release process |
| [`docs/MonARCH-install-card.pdf`](docs/MonARCH-install-card.pdf) | **Two-page printable card** — BIOS, archinstall answers, first keys, what to do when it breaks |

## Credit where it's due

Built on **Arch Linux** and **Hyprland**, and **inspired by
[Omarchy](https://github.com/basecamp/omarchy)** by DHH and 37signals — which
showed this kind of desktop could be beautiful as well as fast.

MonARCH is an independent project, **not a fork**, and is **not affiliated with
or endorsed by** Omarchy, Basecamp, 37signals, or DHH. Please don't send them
MonARCH bugs. See [ATTRIBUTION.md](ATTRIBUTION.md).

Wallpapers are never committed without a recorded licence, and nothing
non-redistributable — Chrome, Spotify — is ever bundled; those ship as
installers that fetch on your machine.

MIT licensed.
