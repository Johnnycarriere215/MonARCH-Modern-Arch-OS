# MonARCH — Master Brief

The single source of truth for what this project is. Everything in `docs/` elaborates on this.

---

## 1. What MonARCH is

A Linux distribution built **directly on Arch Linux**, using Hyprland as the compositor.

**It is not a fork of Omarchy.** It is an independent project inspired by Omarchy, borrowing a small number of MIT-licensed pieces where they were already the right answer. There is no upstream remote and nothing to merge. Every file in this repo can be changed without negotiating with anyone else's roadmap.

MonARCH's own tagline: *Arch Linux, made yours.*

---

## 2. Why it exists

Windows 11 puts Copilot in every corner, serves ads in the operating system, and installs vendor software when you plug in a monitor. It is a machine you rent.

Linux Mint is comfortable but rigid where it matters — changing a keyboard shortcut is harder than it should be, and window management can't keep up with a fast workflow.

Omarchy solves the speed problem beautifully, but is unapologetically for terminal-native developers. Configuration means editing dotfiles in Neovim. Its own manual calls the aesthetic an acquired taste.

**The thesis: you should not have to choose between a system that is fast and one that is approachable.**

Take the ideas that make Omarchy good — keyboard-first, tiling, a theme system that restyles everything at once, snapshot rollback. Add what it deliberately refuses: a settings GUI, a first-run wizard, a Windows-like mode, and documentation that cannot go stale.

---

## 3. Relationship to Omarchy

Stated plainly, because it should be:

**MonARCH was inspired by Omarchy.** It is built on the same foundations — Arch Linux and Hyprland — and adopts several of Omarchy's good ideas: the `colors.toml` theme schema, the timestamped migration pattern, and the snapshot-before-update discipline. Omarchy is MIT licensed, and where MonARCH copies a file substantially verbatim, that file retains its original copyright notice.

**MonARCH is not a fork, not a derivative distribution, and not affiliated with or endorsed by Omarchy, Basecamp, 37signals, or DHH.** Bugs in MonARCH are MonARCH's.

The projects also want different things. Omarchy is deliberately opinionated and terminal-only — that is a feature, and it is why it is good. MonARCH is aimed at someone who wants that speed without needing to memorize dotfile paths. Being a fork would mean permanently fighting the parent project's direction.

---

## 4. What gets built

Nearly all of it. That is the trade accepted by not forking.

| Component | Notes |
|---|---|
| `bootstrap.sh` | One command onto fresh Arch. The Phase 1 install path |
| `monarch` CLI | The entire command surface |
| Package manifests | Base, optional, AUR. Ours to curate |
| Hyprland config set | Written for MonARCH, not inherited |
| Waybar config + system stats | CPU, RAM, GPU, network, disk |
| Theme engine | `colors.toml` → every app's config. Schema borrowed, engine ours |
| Keybind system | `keybinds.toml` → bindings, cheatsheet, and manual |
| Mode system | Tiling / Windows / Performance as config data |
| Settings GUI | Tauri: Keybinds, Theme, Monitors, Startup Apps, Performance |
| First-run wizard | Includes mandatory LUKS recovery key |
| Update system | GitHub Releases, `stable` + `dev` channels, snapshot-first |
| ISO | Phase 3. Slim online-install, under GitHub's 2GB cap |
| EdgeHop | Windows↔Linux input sharing, ported to Wayland |

**Borrowed from Arch's ecosystem, not written by us:** Hyprland, Waybar, Walker, Mako, Hyprlock, Alacritty, Snapper, Limine, greetd. Standard packages, configured by us.

---

## 5. The differentiators

1. **A real settings GUI.** Change a keybinding or theme without a terminal.
2. **Self-generating documentation.** Keymap, `Super+K` cheatsheet, and manual all generate from one TOML file. They cannot drift.
3. **A Windows-like mode.** Title bars, close buttons, floating windows, taskbar — one toggle.
4. **EdgeHop.** Seamless keyboard/mouse sharing with a Windows machine. Nobody in this space ships it.

---

## 6. Success definition

- Daily driver on an HP EliteBook 850 G6 — no dual boot, no fallback
- Someone who has never used Linux can change a keybinding and a theme without opening a terminal
- `git tag` publishes an ISO to the GitHub releases page automatically
- An update has been deliberately broken and rolled back from a snapshot
- Cold boot to desktop under 12 seconds
- Every hotkey discoverable in-system, offline

---

## 7. Non-goals

| Not doing | Why |
|---|---|
| Forking Omarchy | Permanent coupling to a project heading the opposite direction |
| Writing a compositor, bar, or launcher | Hyprland, Waybar, and Walker are excellent. Configure, don't rebuild |
| Desktop icons | No Wayland protocol. Every workaround is fragile |
| macOS theme | Cut from v1. Marketing idea for later |
| Custom ISO before Phase 3 | `bootstrap.sh` on fresh Arch works fine and is far less work |
| Our own pacman mirror | Unnecessary until there are real users |
| Electron anywhere | Violates the RAM-efficiency goal |
| Offline-install ISO | Doubles ISO size and forces paid hosting |

---

## 8. Guiding principles

1. **We own everything.** No upstream, no merges, no negotiating.
2. **The CLI is the source of truth.** The GUI shells out to `monarch`.
3. **Generate, don't hand-maintain.** Configs and docs come from TOML.
4. **Modes are data.**
5. **Every change ships a migration.**
6. **No new daemons** for what Hyprland does natively.
7. **Snapshot before every update.** Never optional.
8. **Credit generously.** Omarchy earned it. Say so clearly, and never imply endorsement.

---

## 9. How this gets built

There is no single prompt that produces an operating system. What works: **a stable brief that never changes** (this file plus `MONARCH.md`), and **small, scoped, testable tasks** drawn from it (`04-TASKS.md`).

Phase 1 targets a bootable, usable desktop via `bootstrap.sh` on a fresh Arch install. Every task after that replaces one piece with something better. A Btrfs snapshot means a bad task costs five seconds.
