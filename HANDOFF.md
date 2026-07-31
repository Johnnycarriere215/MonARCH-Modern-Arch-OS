# HANDOFF

Written 2026-07-31, at the end of the session that finished T2.

This file is a **pointer, not a summary.** It deliberately does not restate the
project — `MONARCH.md` and `PROGRESS.md` do that, and a second copy of the same
facts would be the first thing to go stale.

---

## Starting a new chat

Paste this:

> Read MONARCH.md, then PROGRESS.md, then HANDOFF.md. Follow the session
> protocol in MONARCH.md.

That is the whole onboarding. `MONARCH.md` carries the stack, the golden rules
and the locked decisions; `PROGRESS.md` carries the state of every task and the
notes each one left for the next.

The repo is at `github.com/Johnnycarriere215/MonARCH-Modern-Arch-OS`, branch
`main`.

---

## Where the build actually is

**Phase 1 is code-complete and has never been run on Arch.**

T1 (bootstrap + package manifests) and T2 (base config set) are both written,
both locally verified, both marked `DONE` with one criterion honestly left
unticked: *the VM boots to a Hyprland desktop, logs in, and opens a terminal.*

Everything written so far has been tested by simulation — fake `HOME`
directories, syntax checks, mechanical validation that every theme variable
resolves. None of it has met a real Arch install. **The next thing that happens
should be the VM test, not T3.** A theme engine layered on an unbooted desktop
is building on sand.

Per-task detail, including every decision made and why, is in the **Notes**
under each task in `PROGRESS.md`. Read those before touching a task's output.

---

## The VM test (Phase 0.4 / 0.5, then Phase 1's real verification)

Not written down anywhere else, so it lives here until it earns a place in
`docs/`.

**Build the VM.** 12GB RAM, 4 CPUs, 80GB disk, UEFI/OVMF firmware, virtio with
3D acceleration. Install base Arch with a **Btrfs root** — bootstrap.sh refuses
to run without one, deliberately. Create a normal user with sudo. Get the
network up.

**Snapshot it as `clean-arch` before installing MonARCH.** This is the reset
point for every subsequent attempt, and taking it after MonARCH has touched the
system makes it worthless.

**Then, in the VM:**

```bash
curl -fsSL https://raw.githubusercontent.com/Johnnycarriere215/MonARCH-Modern-Arch-OS/main/bootstrap.sh | bash
```

**What to check, in order:**

1. It reaches `50-finish.sh` without dying. If it dies, the failing stage name
   and `/var/log/monarch-install.log` are printed — both are worth pasting back.
2. **Run it a second time without resetting the snapshot.** This is the T1
   criterion that matters most and the one least likely to be right. Watch for:
   duplicated PATH lines in `~/.bashrc`, a second snapper config attempt,
   clobbered configs.
3. Reboot. greetd/tuigreet should appear — it is enabled but deliberately not
   started during install, since starting it would kill the installer's own TTY.
4. Log in to Hyprland. **Open a terminal (`Super+Return`).** That is T2's bar.
5. `monarch doctor` and paste the output into the next chat. It is built to be
   pasted.

**Most likely to break, in rough order:**

- An AUR package failing to build. By design this warns and continues rather
  than aborting — check the summary at the end of stage 20 for what didn't make it.
- `snapper create-config` failing if the Arch installer already made a
  `/.snapshots` subvolume. Warns and continues; snapshots just won't be set up.
- `walker-bin` — the launcher. If it didn't install, `Super` does nothing.
- Hyprland config syntax. Every variable and sourced path was validated
  mechanically, but no version of Hyprland has ever parsed these files.

---

## Two things to know before writing more code

**The theme contract (T3 must honour it).** No config file in `config/` contains
a colour. Three generated files under `~/.config/monarch/theme/` hold the whole
palette — `hypr-colors.conf`, `waybar-colors.css`, `alacritty-colors.toml`.
`monarch theme apply` rewrites those three and nothing else. The checked-in
defaults are an original palette called "midnight".

**`config/.seed-only` (T3 and T4 must respect it).** Paths listed there are
installed once by `monarch-config-apply` and never touched again — the user's
settings, their monitor layout, and anything another `monarch` command
generates. Without it, running `monarch config apply` after an update would
silently undo `monarch theme apply`. **Anything a future task generates into
`config/` must be listed there**, and T4 will need to overwrite the
`bindings.conf` placeholder once, which a plain `config apply` will not do.

---

## Open items for the human

Also tracked at the bottom of `PROGRESS.md`.

- Build the Arch VM and take the `clean-arch` snapshot — blocks everything
- Run `lsblk` with the USB drive plugged in
- Three theme palettes in your own colours, for T3
- ASCII crown art for `brand/`
- **Never wipe the internal NVMe before Phase 4**
