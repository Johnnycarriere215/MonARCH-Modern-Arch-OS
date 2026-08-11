# Omarchy Feature Implementation — Agent Prompt

> **What this is:** A prompt written for an AI coding agent to implement two MonARCH-inspired features into **Omarchy** (the live Arch + Hyprland desktop on this machine). The work is done; this file is the record of the brief and the deliverable map.
>
> **Where the code lives:** Omarchy runs from user-owned configs and apps — everything below is installed live on the system, *not* in this repo. This repo (MonARCH) is where the prompt and design notes are kept.

---

## The brief

Omarchy is a speed-first Arch + Hyprland desktop. Two things about it are painful:

1. **Monitor setup is a nightmare.** Monitors are configured by hand-editing `~/.config/hypr/monitors.conf`. And the worst part: **when you plug in a new monitor, Hyprland gives it its own workspace number** — a second screen becomes "workspace 2" instead of joining your desktop. Users want a Windows-like settings page: pick a layout ("two horizontals", "a vertical on the left + horizontal in the middle", etc.) and have the whole arrangement *just work*. And they want their main + vertical monitors to feel like **one merged workspace**: Claude on one screen and Clickup on the other, both "in workspace 1", switching together.

2. **There's no performance mode.** A one-switch "make it snappy" toggle — turn off blur/shadows/animations, relax polling — is missing.

### Deliverables

- [x] **Configurable monitor layouts** (declarative, persisted, hot-applied)
- [x] **Merged desktops** — one workspace across all monitors, switched together
- [x] **New-monitor handling** — a plugged-in screen joins the current desk instead of stealing a workspace number
- [x] **Performance mode** toggle (Hyprland effects + waybar polling)
- [x] **Monitors settings page** — themed, Windows-like, reachable from the Omarchy Menu
- [x] **Edge-crossing window moves** — arrow keys send a window to the monitor next door when it's at the screen edge, with a GUI toggle
- [x] **This prompt** saved in the MonARCH repo

---

## Architecture

### 1. Monitor engine

| File | Role |
|---|---|
| `~/.config/omarchy/monitors.toml` | Source of truth: `layout`, `scale`, `primary`, `disabled`, `span`, optional per-monitor `[monitors."NAME"]` overrides |
| `~/.local/bin/omarchy-monitor-apply` | Reads the toml, generates + hot-applies `~/.config/hypr/monitors.conf`, `~/.config/hypr/workspace-pairs.conf`, `~/.config/omarchy/workspace-map.json`. Supports `--dry-run` and `--json` |
| `~/.local/bin/omarchy-workspace` | **The merged-desktop switcher.** `Super+1..0` calls it; it switches every monitor to the same virtual desktop at once |
| `~/.local/bin/omarchy-monitor-listen` | Hyprland event-socket listener. On `monitoradded` it re-applies the layout and joins the new screen to the current desk. Autostarted from `~/.config/hypr/autostart.conf` |

**Merged-desktop trick (the important bit):** Hyprland can only show one workspace number on one monitor at a time. So a "desk" is a *virtual desktop spanning all screens*: the primary monitor shows workspace `N`, every other monitor shows `N + offset` (`workspace-map.json` records offsets, e.g. HDMI-A-1 → `100`). `omarchy-workspace 1` therefore dispatches `1` to VGA-1 *and* `101` to HDMI-A-1 — one keypress, the whole set. The offset ids (`101..110`) are bound to their monitor in `workspace-pairs.conf` so they never leak onto the primary.

**New-monitor behavior:** workspaces `2..10` are bound to the primary, so a freshly plugged monitor can't take a number the primary uses. The listener then re-applies geometry (so the new screen lands in the layout, rotated/positioned correctly) and switches the desk to the primary's current workspace — the new screen joins the action, not workspace 2.

### 2. Performance mode

| File | Role |
|---|---|
| `~/.local/bin/omarchy-performance` | `on | off | toggle | status`. Writes `~/.config/hypr/performance.conf` (blur/shadows/animations off, zero rounding, tight gaps), relaxes waybar poll intervals in `~/.config/waybar/config.jsonc` (`.bak` kept per change), reloads Hyprland, restarts waybar |

### 3. Edge-crossing window moves

| File | Role |
|---|---|
| `~/.local/bin/omarchy-window-edge-move` | Focus a window and press a direction: if the window is at its monitor's edge in that direction **and** a monitor lies beyond it, the window crosses to that monitor. Otherwise it falls back to Hyprland's native layout move (`movewindow D`), so repeated presses walk a window across its monitor and then across the boundary. Works with the merged-desktop mirror workspaces (moving across keeps the window on the same desk). Reads `~/.config/omarchy/edge-crossing` (`on`/`off`, default on) — when `off` it is a no-op |

**Keybinds** (`~/.config/hypr/bindings.conf`): `Super+Ctrl+Shift+arrows` — the only arrow combo Omarchy hadn't already taken (`Super`=focus, `Super+Shift`=swap, `Super+Alt`=group, `Super+Shift+Alt`=move workspace). The four binds carry descriptions beginning **"Edge crossing: …"** so they are findable in the keybindings learning tab (`Super+K` → walker picker), which reads descriptions from `hyprctl binds`. A priority rule in `omarchy-menu-keybindings` sorts them with the other window-move entries (that file lives in the Omarchy checkout, so the rule may need re-adding after an update — the descriptions themselves live in user-owned `bindings.conf` and survive).

**Hyprland 0.56 note:** `movewindowtomonsilent` no longer exists — the dispatcher is `movewindow mon:<name>` (moves the focused window to the monitor and keeps it focused). Verified live: window crosses HDMI-A-1 ↔ VGA-1 in both directions.

### 4. Settings page (Windows-like)

| File | Role |
|---|---|
| `~/.local/share/omarchy-monitors/server.py` | Stdlib-only Python server (port 18423), idle-exits after ~90s. API: `GET /api/state`, `GET /api/theme`, `POST /api/save`, `POST /api/desk`, `GET/POST /api/performance`, `GET/POST /api/edge-crossing` |
| `~/.local/share/omarchy-monitors/public/` | `index.html`, `style.css` (theme-driven), `app.js` |
| `~/.local/bin/omarchy-monitors` | Launcher: starts the server on demand, opens the page. Also `status` / `apply` / `desk N` subcommands |

The page shows a live arrangement preview (click a screen to make it primary), layout presets (side-by-side, vertical-left, vertical-right, primary-only), the **Merged desktops** toggle, a **Performance mode** toggle, an **Edge crossing** toggle (writes `~/.config/omarchy/edge-crossing`), a jump-to-desk strip, and the detected-display list — all colored from the current Omarchy theme.

**Menu wiring** (`~/.local/share/omarchy/bin/omarchy-menu`, backups kept as `.bak.<ts>`):
- `Setup → Monitors` now runs `omarchy-monitors` (the settings page) instead of opening `monitors.conf` in an editor.
- `Trigger → Toggle → Performance` runs `omarchy-performance toggle`.

> ⚠️ `omarchy-update` may overwrite `omarchy-menu` (it lives in the Omarchy install checkout).
> Re-apply the two edits with: `sed -i 's|\*Monitors\*) open_in_editor ~/.config/hypr/monitors.conf ;;|*Monitors*) omarchy-monitors ;;|' ~/.local/share/omarchy/bin/omarchy-menu` and insert `*Performance*) omarchy-performance toggle ;;` after the `*Gaps*)` case in `show_toggle_menu`. The engine scripts and settings page live outside the checkout (`~/.local/bin`, `~/.config/omarchy`, `~/.local/share/omarchy-monitors`) and survive updates.

---

## Live wiring (already applied)

- `hyprland.conf` sources `~/.config/hypr/workspace-pairs.conf` and `~/.config/hypr/performance.conf` (both generated, both safe to source when minimal).
- `bindings.conf` rebinds `Super+1..0` to `omarchy-workspace N` (10 binds, verified via `hyprctl binds`).
- `bindings.conf` adds `Super+Ctrl+Shift+arrows` → `omarchy-window-edge-move l/r/u/d` (4 binds).
- `autostart.conf` runs `exec-once = omarchy-monitor-listen`.
- Current live layout: `vertical-left` — VGA-1 primary at `812x0` scale 1.33, HDMI-A-1 rotated left at `0x0`, `span = true`.

## How to verify

```bash
omarchy-monitors status                      # live monitor summary
omarchy-monitor-apply --dry-run              # preview generated configs
omarchy-workspace 2 && omarchy-workspace 1   # both screens follow together
hyprctl monitors -j                          # check per-monitor workspace ids
hyprctl configerrors                         # must be clean
omarchy-performance on && omarchy-performance off
curl -fsS http://127.0.0.1:18423/api/state   # settings-server state
```
