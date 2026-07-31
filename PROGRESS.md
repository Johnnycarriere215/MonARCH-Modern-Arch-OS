# PROGRESS

**The single source of truth for where this build is.**
Read at the start of every session. Updated at the end of every session.

Status values: `TODO` · `IN PROGRESS` · `PARTIAL` · `DONE` · `BLOCKED`

---

## Current state

**Phase:** 1 — A bootable desktop
**Next task:** T3 — Theme engine (Phase 2)
**Blocked on:** nothing — but **T1 and T2 have never been run on Arch.** The whole of Phase 1 is written and locally verified; the VM test is the outstanding work.

---

## Phase 0 — Baseline (human only, no AI)

| | Task | Status |
|---|---|---|
| 0.1 | Back up `~` to external media | TODO |
| 0.2 | BIOS: Secure Boot off, TPM off, VT-x on, VT-d on | TODO |
| 0.3 | GitHub repo `monarch` created, starter committed, MIT `LICENSE` added | PARTIAL — repo exists, `LICENSE` added; starter is in the working tree but **not committed or pushed yet** |
| 0.4 | Arch VM built — 12GB RAM, 4 CPUs, 80GB disk, UEFI/OVMF, virtio + 3D accel, **Btrfs root** | TODO |
| 0.5 | VM snapshot `clean-arch` taken **right after base Arch install, before MonARCH** | TODO |
| 0.6 | USB drive identified (`lsblk -o NAME,MODEL,TRAN,SIZE,ROTA` with it plugged in) | TODO |

**Phase 0 must be complete before T1.** T1's output is untestable without a clean Arch VM to run it on.

---

## Phase 1 — A bootable desktop

### T1 — Bootstrap + package manifests · Sonnet
**Status:** DONE (code complete, locally verified — **awaiting first run on Arch**)

**Done when:**
- [x] `packages/base.packages`, `optional.packages`, `aur.packages` exist — 68 / 21 / 5 packages, all parse clean
- [x] `bootstrap.sh` refuses to run as root and guards on Arch / x86_64 / Btrfs / UEFI with a clear message naming what failed — verified: on this Mint box it exits `This is not Arch Linux (/etc/os-release ID='linuxmint')`
- [x] `install/10-preflight.sh` … `50-finish.sh` exist and are sourced in order — globbed and `sort -V`'d, not hardcoded
- [x] `bin/monarch` dispatcher works; bare `monarch` prints grouped help discovered by scanning `bin/` — grouping verified against simulated `theme-*` / `keys-*` / `mode-*` commands
- [x] `bin/monarch-doctor` and `bin/monarch-version` run — doctor degrades every probe to `n/a` on a non-Arch box
- [x] Root `version` file contains `0.1.0-dev`
- [~] **Running `bootstrap.sh` twice in a row does not break anything** — stage 30 proven idempotent over 3 runs against a fake `HOME`; stages 10/20/40 are idempotent by construction but **need the VM to confirm**
- [x] All output logged to `/var/log/monarch-install.log` — appends, never truncates, so a re-run keeps the first run's history

**Notes:**

- **`walker` is not in the official repos.** The T1 spec lists it under the compositor stack in `base.packages`; it is actually `walker-bin` in the AUR, so that is where it lives. `base.packages` carries a comment pointing at it. If it should be built from source instead, that is a one-line change.
- **`hyprbars` is deliberately not in `aur.packages`** — it is a hyprpm plugin, not an AUR package. T6 owns installing it and its fallback-to-tiling behaviour.
- **greetd is enabled but not started** (`systemctl enable`, no `--now`). Starting it would kill the TTY session running the installer. It takes over on the next boot.
- **multilib is left alone.** `steam` in `optional.packages` needs it; enabling it is a user decision, not an installer's.
- **`ufw` opens SSH automatically if `$SSH_CONNECTION` is set**, otherwise a remote install would cut itself off at stage 40.
- **Snapper failure is non-fatal.** A pre-existing `/.snapshots` subvolume is the usual cause; the install warns and continues, since a system without snapshots still boots.
- Every `monarch-*` script advertises itself to the dispatcher with a `#DESC:` line on line 2. **New commands must carry one** or they show up in help as `-`.
- `bootstrap.sh` detects being run from an existing checkout and skips the clone, so local edits can be tested in the VM without pushing first.
- `config/` is still empty — T2 fills it. `install/30-config.sh` already deploys whatever is there and backs up user-edited files to `.bak`.

---

### T2 — Base config set · Sonnet
**Status:** DONE (code complete, locally verified — **the VM test has not been run**)

**Done when:**
- [x] `config/hypr/hyprland.conf` sources monitors, input, looknfeel, windows, autostart, bindings, monarch — all 7, plus the theme colours first; every sourced path verified to exist
- [x] `GDK_SCALE=1` set (target panel is 1080p, not retina) — `config/hypr/monarch.conf`
- [x] 5 workspaces configured; a 6th is created dynamically — 1–5 `persistent:true`, 6 deliberately not, so Hyprland destroys it with its last window
- [x] Dropdown terminal on a native special workspace — **not** pyprland — `workspace = special:dropdown, on-created-empty:...`
- [x] Waybar and Alacritty configs exist, no hardcoded colors anywhere — checked mechanically: zero hex outside `config/monarch/theme/`, and every `$var` / `@color` referenced resolves to a definition
- [x] `bin/monarch-config-apply` is idempotent and backs up user-modified files to `.bak` rather than overwriting — all four cases exercised against a fake `HOME`
- [ ] **The VM boots to a Hyprland desktop, logs in, and opens a terminal** — **NOT VERIFIED.** Needs Phase 0.4/0.5. This is the one that counts.

**Notes:**

- **The theme contract, which T3 must honour.** Configs carry no colours. Three generated files under `~/.config/monarch/theme/` hold the palette — `hypr-colors.conf` (`$bg`, `$accent`, …), `waybar-colors.css` (`@define-color`), `alacritty-colors.toml`. `monarch theme apply` rewrites those three and nothing else. The checked-in defaults are the original "midnight" palette; T3 replaces them with real themes.
- **`config/.seed-only` is new.** Paths listed there are installed once and never touched again — your settings, your monitor layout, and anything another command generates. Without it, `monarch config apply` on update would undo `monarch theme apply`. **T3 and T4 must add nothing to `config/` that they also generate without listing it here.**
- **Autostart is split in two.** `autostart.conf` = essentials, stays MonARCH's, keeps receiving updates. `autostart-user.conf` = your apps, seed-only, holds the `>>> monarch startup apps >>>` managed block. They were one file until it became clear that mixing them means one `monarch startup add` freezes the essentials forever.
- **`bindings.conf` is a hand-written placeholder** and is marked seed-only. T4 replaces it from `schema/keybinds.toml`. **T4 must stamp the generated file and will need to overwrite the placeholder once** — a plain `config apply` will not do it, since seed-only means "never overwrite".
- **`Super+/` for the keybind list is commented out** in `bindings.conf`. T4 uncomments it once `monarch keys list` exists; binding a key to a missing command now would give a key that silently does nothing.
- **Two files beyond the spec:** `hypridle.conf` and `hyprlock.conf`. `autostart.conf` launches hypridle, and hypridle with no config exits immediately; hyprlock with no config locks to a black screen with no password field, which is indistinguishable from a hang.
- **Pango markup cannot use theme colours.** The Waybar calendar and the hyprlock placeholder text are styled with weight/underline only. Any hex there would be a colour the theme engine could never reach.
- **Alacritty's `import` moved under `[general]` in 0.14.** If a future Arch downgrade lands on 0.13, colours silently fall back to defaults — that is the first thing to check.
- `install/30-config.sh` now shells out to `monarch-config-apply` rather than deploying itself, so the installer and a later update take the identical path (golden rule 1). `deploy_user_file` in `install/_common.sh` was removed as dead code.
- **`bin/_lib.sh` and `bin/_startup-lib.sh` are shared libraries, not commands** — the leading underscore keeps them out of the dispatcher's scan and out of the `~/.local/bin` symlinks. The three T1 scripts still carry their own copy of the symlink-resolve preamble and should adopt `_lib.sh` in a later pass.

> **T1 + T2 = the milestone that matters.** `curl … | bash` on a clean Arch VM produces a working desktop. Verify on real hardware next (USB boot, check `GDK_SCALE`) before moving on.

---

## Phase 2 — The system layer

### T3 — Theme engine · Opus
**Status:** TODO

**Done when:**
- [ ] `schema/theme.toml` documented, with an inline comment crediting Omarchy's schema as the inspiration
- [ ] `monarch-theme-apply <name>` restyles Hyprland, Hyprlock, Waybar, Alacritty, Mako, Walker, btop, VS Code in one command
- [ ] Templates live in `themes/_templates/`, one file per app
- [ ] Adding a new app to the theme system = adding one template file, nothing else
- [ ] Three themes ship with **original** palettes (not copied from another project)
- [ ] **No wallpaper files committed** — placeholder README in each `backgrounds/` noting every image needs a recorded license

**Notes:**
_(empty)_

---

### T4 — Keybinds · Sonnet
**Status:** TODO

**Done when:**
- [ ] `schema/keybinds.toml` covers windows, workspaces 1–6, app launches, system, clipboard, dropdown terminal
- [ ] `bindr = SUPER, SUPER_L` → Walker (bare Super tap opens the launcher)
- [ ] `monarch-keys-apply` writes `bindings.conf` with a `# GENERATED BY MONARCH — DO NOT EDIT` header
- [ ] `monarch-keys-check` catches duplicates and builtin shadowing; `-apply` refuses to write on conflict
- [ ] `monarch-keys-list` output is what `Super+K` shows
- [ ] TOML parsed inline in bash — no Python or Rust dependency

**Notes:**
_(empty)_

---

### T5 — Waybar system stats · Sonnet
**Status:** TODO

**Done when:**
- [ ] CPU, RAM, GPU, network, disk modules exist
- [ ] Poll intervals: 5s CPU/RAM, 10s net, 60s disk — no faster
- [ ] GPU module degrades gracefully when `intel_gpu_top` is absent
- [ ] Colors read from the active theme, nothing hardcoded
- [ ] `monarch-bar-modules` enables/disables individual modules
- [ ] Total added idle CPU under 1% on an i7-8665U, with per-module cost noted in comments

**Notes:**
_(empty)_

---

### T6 — Mode system · Opus
**Status:** TODO

**Done when:**
- [ ] `modes/{tiling,windows,performance}/` each have `hypr.conf`, `waybar-overrides.jsonc`, `meta.toml`
- [ ] `monarch-mode-set` persists and survives reboot
- [ ] `monarch-mode-session` applies for one session **without** changing the saved default
- [ ] Windows mode gives title bars, close buttons, floating default, bottom bar, taskbar
- [ ] Minimize = `movetoworkspacesilent special:minimized`, restore via `wlr/taskbar`
- [ ] **`hyprbars` failure falls back to tiling with a clear warning** — never a session with no title bars and no explanation
- [ ] No `if mode == ...` anywhere. Modes are data

**Notes:**
_(empty)_

---

### T7 — Update system · Sonnet
**Status:** TODO

**Done when:**
- [ ] `monarch-update-check` caches for 30 min and **never polls GitHub more than once per 30 min** (60 req/hr/IP limit)
- [ ] Network failure is silent — never blocks the bar
- [ ] Waybar shows an update icon; click runs `monarch update`
- [ ] `monarch-update` snapshots **first**, always, before anything else
- [ ] `hyprpm update` failure warns but does not abort the update
- [ ] `monarch-channel-set stable|dev` works
- [ ] `monarch-migrate` runs each migration once, tracked in state
- [ ] **A deliberately broken update has been rolled back from a snapshot, by hand, successfully**

**Notes:**
_(empty)_

---

### T8 — Packages + app installers · Sonnet
**Status:** TODO

**Done when:**
- [ ] `monarch-install-claude-desktop` sets `CLAUDE_USE_WAYLAND=1` and warns clearly if `/dev/kvm` is missing (Cowork fails silently without it)
- [ ] `monarch-install-chrome` works and Chrome is **never** bundled in the ISO
- [ ] VS Code installer configures gnome-libsecret and disables internal auto-update in favor of pacman
- [ ] `monarch-app-install` handles `.pkg.tar.zst`, `.AppImage`, and `.deb` (debtap, with a loud best-effort warning)
- [ ] `monarch-webapp-add` generates a working `.desktop` entry and icon

**Notes:**
_(empty)_

> **Stop here and live in it for a week** before Phase 3. What annoys you that week should reshape the GUI before it's built.

---

## Phase 3 — The GUI layer

### T9 — Settings GUI · Opus
**Status:** TODO

**Done when:**
- [ ] Tauri v2, Rust + HTML/CSS/vanilla JS. No framework. **Not Electron**
- [ ] **The GUI never reads or writes a config file.** Every action shells out to `monarch`
- [ ] Panel 1 (Keybinds) complete: searchable, click-to-rebind, live conflict warning
- [ ] Other four panels stubbed, pattern reviewed by the human before building them
- [ ] Accent color read from the active theme, nothing hardcoded

**Notes:**
_(empty)_

---

### T10 — First-run wizard · Opus
**Status:** TODO

**Done when:**
- [ ] A route in the existing `gui/` app — **not** a second binary
- [ ] Mode step asks **two separate questions**: "use now?" and "default from now on?"
- [ ] **LUKS recovery key step cannot be silently skipped.** Generated, displayed, confirmation required
- [ ] Hardware check covers `/dev/kvm`, battery health, missing firmware
- [ ] Gated on `~/.local/state/monarch/first-run-complete`, re-runnable via `monarch welcome`

**Notes:**
_(empty)_

---

## Phase 4 — The ISO

### T12 — ISO + release CI · Sonnet
**Status:** TODO

**Done when:**
- [ ] archiso profile in `iso/`, slim online-install, **under 1.8GB**
- [ ] Installer reuses `install/` — no duplicated logic
- [ ] Branding art all in `brand/`, swappable without touching code
- [ ] Tag push → Actions builds → ISO + sha256 on the GitHub releases page
- [ ] **CI fails loudly if the ISO exceeds 1.9GB** (GitHub caps release assets at 2GB)
- [ ] Nightly `dev` build reports size only, creates no release

**Notes:**
_(empty)_

---

## Track B — parallel, any time after Phase 1

### T11 — EdgeHop on Wayland · Opus
**Status:** TODO

**Done when:**
- [ ] A written porting plan exists — **no code yet**
- [ ] Confirms whether injection uses `/dev/uinput` (if so, Wayland doesn't care)
- [ ] Recommends `EVIOCGRAB` or libei for capture, with reasoning
- [ ] Addresses edge detection cost against the no-new-daemons rule
- [ ] Covers `wl-clipboard` migration and mixed-PPI multi-monitor behavior

**Notes:**
_(empty)_

---

## Real-hardware checkpoints

These need the EliteBook, not the VM.

| After | Check | Status |
|---|---|---|
| T2 | Boot USB — is `GDK_SCALE=1` right on the 1080p panel? | TODO |
| T2 | Run the full hardware validation checklist in `docs/02-HARDWARE.md` | TODO |
| T6 | Windows mode on metal — `hyprbars` is the fragile piece | TODO |
| T7 | Break an update deliberately, roll back from a snapshot | TODO |
| T12 | Install from our own ISO in the VM, before touching the internal NVMe | TODO |

---

## Open items for the human

- [ ] Run `whoami` — the backup command failed because the username was guessed wrong
- [ ] Run `lsblk` with the USB drive **plugged in** (last run showed only the internal NVMe)
- [ ] Fill in the baseline measurement table in `docs/02-HARDWARE.md`
- [ ] ASCII crown art → `brand/`
- [ ] Three theme palettes — your own colors
- [ ] **Never wipe the internal NVMe before Phase 4**

---

## Session log

Append one line per session. Newest at the bottom.

```
DATE | TASK | OUTCOME | NOTES FOR NEXT SESSION
```

```
2026-07-31 | seed + T1 | DONE (unverified on Arch) | Starter tree laid down from monarch-starter(1).zip, LICENSE + .gitignore + version added. bootstrap.sh, 5 install stages, 3 manifests, monarch/-doctor/-version written. Nothing committed — commit and push before testing in the VM, since the raw-URL curl path needs main to exist. Next: T2.
2026-07-31 | T2 | DONE (unverified on Arch) | Full Hyprland/Waybar/Alacritty config set, settings.toml, monarch-config-apply + startup add/list/remove. Established the theme contract T3 must honour and the config/.seed-only mechanism. Phase 1 is now code-complete — the ONLY thing left is running it on a clean Arch VM (Phase 0.4/0.5 first). Do that before T3; a theme engine on top of an unbooted desktop is building on sand.
```
