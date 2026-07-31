# MonARCH — Roadmap

Five phases. **Do not reorder.** The most common way projects like this die is starting at the ISO because it's the exciting part.

---

## Phase 0 — Baseline
- Back up `~` to external media
- BIOS configured (Secure Boot off, VT-x on)
- Arch VM built, **`clean-arch` snapshot taken immediately after base install** — this is the reset point for every bootstrap test
- Baseline measurements recorded (`02-HARDWARE.md`)

**Exit:** a minimal Arch VM with Btrfs root that you can reset to in five seconds.

---

## Phase 1 — A bootable desktop
*Tasks T1–T2. This is the milestone that matters most.*

`bootstrap.sh`, package manifests, staged installers, the `monarch` CLI dispatcher, and MonARCH's own Hyprland / Waybar / Alacritty configuration.

**Exit:** `curl … | bash` on a fresh Arch VM produces a working MonARCH desktop that logs in, tiles windows, and opens a terminal. Nothing else matters until this works.

---

## Phase 2 — The system layer
*Tasks T3–T8. Mostly Sonnet.*

Theme engine. Keybind system with generated cheatsheet. Waybar stats. Mode system including Windows mode. Update system with `stable`/`dev` channels. App installers.

**Exit:** daily-drivable from the USB drive. A fresh bootstrap reproduces the setup exactly. An update has been deliberately broken and rolled back from a snapshot.

**Then live in it for a week.** What annoys you that week should reshape Phase 3 before any of it is built.

---

## Phase 3 — The GUI layer
*Tasks T9–T10. The expensive half. Opus.*

Tauri settings app: Keybinds, Theme, Monitors, Startup Apps, Performance. First-run wizard including the mandatory LUKS recovery key. In-system manual generated from `keybinds.toml`.

**Exit:** someone who has never used Linux changes a keybinding and a theme without opening a terminal. That's the test — not "the panel exists."

---

## Phase 4 — The ISO
*Task T12.*

archiso profile, guided installer reusing `install/`, branding (Plymouth, greetd, ASCII crown), GitHub Actions publishing to Releases on tag push, slim online-install under 2GB.

**Exit:** MonARCH installed onto the EliteBook's **internal NVMe** from your own ISO. The commitment point — the first time the fallback install gets wiped.

---

## Phase 5 — Optional, if going public
See `06-RELEASE.md` first.

Live "Try MonARCH" USB mode. Theme creator GUI. Mint migration tooling. YouTube walkthrough. Wallpaper licensing audit. Issue templates and a support channel.

---

## Track B — EdgeHop
*Task T11. Parallel, any time after Phase 1.* Port from X11 to Wayland. Plan first, code second.

---

## v1.0 acceptance criteria

- [ ] `bootstrap.sh` on fresh Arch produces a working desktop, twice in a row, idempotently
- [ ] Boots from our own ISO on real hardware, UEFI, Secure Boot off
- [ ] Cold boot to desktop under 12 seconds
- [ ] A keybinding can be changed, saved, and applied entirely from the GUI, with conflict detection
- [ ] Tiling ↔ Windows mode toggles in one action and survives reboot
- [ ] Performance mode measurably improves frame pacing
- [ ] Three themes ship; switching restyles every app at once
- [ ] `monarch update` snapshots, migrates, and recovers cleanly from a forced mid-update failure
- [ ] A non-Linux user completes first-run setup unaided
- [ ] LUKS recovery key generated and confirmed saved during install
- [ ] Manual reachable offline via hotkey and launcher search
- [ ] Multi-monitor including one vertical display configures from the GUI and persists
- [ ] Rollback from a Snapper snapshot tested deliberately at least once
- [ ] EdgeHop works between the Windows machine and MonARCH
