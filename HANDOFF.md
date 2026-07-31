# HANDOFF

Written 2026-07-31, at the end of the session that finished T2.
Updated 2026-07-31, at the end of the session that finished T4.

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

**Phase 1 is code-complete, T3 and T4 are done on top of it, and none of it has
ever been run on Arch.**

T1 (bootstrap + package manifests), T2 (base config set), T3 (theme engine) and
T4 (keybinds) are all written, all locally verified, all marked `DONE` with the
criteria that need real hardware honestly left unticked — chief among them:
*the VM boots to a Hyprland desktop, logs in, and opens a terminal.*

Everything written so far has been tested by simulation — fake `HOME`
directories, syntax checks, install stages replayed twice against a throwaway
home, mechanical validation that every theme variable resolves. None of it has
met a real Arch install.

The previous two handoffs both said the next thing to happen should be the VM
test. It has not happened either time. **Four tasks now sit on a desktop that
has never booted**, and the pieces that cannot be verified any other way keep
accumulating: Walker's theming, VS Code's theming, and now every keybinding —
no version of Hyprland has parsed a single line MonARCH generates.

`docs/07-VM-TESTING.md` is the whole procedure, start to finish.

Per-task detail, including every decision made and why, is in the **Notes**
under each task in `PROGRESS.md`. Read those before touching a task's output.

---

## The VM test (Phase 0.4 / 0.5, then Phase 1's real verification)

**The full procedure now lives in [`docs/07-VM-TESTING.md`](docs/07-VM-TESTING.md)**
— host VM settings, archinstall answers, snapshot commands, what to check and
in what order. What follows is the short version.

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
- **Walker's config format** (new in T3). `config/walker/config.toml` assumes
  `theme = "monarch"` and a stylesheet at `~/.config/walker/themes/monarch.css`.
  Walker moved this around during its 0.x releases. If the launcher comes up
  unstyled, that pairing is why; if it refuses to start at all, delete
  `config/walker/config.toml` for an unstyled but working launcher.
- **Stage 30 now renders the theme and dies if it cannot.** That is deliberate
  — `hyprland.conf` sources `hypr-colors.conf`, so no palette means no session.
  If the install stops there, the message names the theme that failed.

---

## Two things to know before writing more code

**The theme contract, as T3 left it.** No config file in `config/` contains a
colour — still true, and checked by grep. The palette lives in generated files
the theme engine owns: `~/.config/monarch/theme/{hypr-colors.conf,
waybar-colors.css,alacritty-colors.toml}` as before, plus `mako/config`,
`walker/themes/monarch.css`, `btop/themes/monarch.theme` and a generated VS Code
extension. **They are no longer checked into `config/`** — `install/30-config.sh`
renders them from `themes/_templates/` during the install, so there is exactly
one producer of a colour and no shipped copy to drift from it.

Adding an application to the theme system is adding one file to
`themes/_templates/`. The target path and reload command are declared in the
file's own `#!` header; no code anywhere names an application. See
`themes/_templates/README.md`.

**Reach for `sem.*`, not `term.*`.** `sem.urgent/warning/ok/info/muted` exist so
a module that reports a state asks for meaning rather than colour, and a theme
can decide that urgent is orange. T5's Waybar modules especially.

**Generated files are not shipped.** T3 and T4 settled this the same way, and a
later task should follow it: if `monarch` generates a file, it does not also
live in `config/`. The palette and `bindings.conf` are both rendered by
`install/30-config.sh` during the install, from `themes/_templates/` and
`schema/keybinds.toml`. One producer, no checked-in copy to drift from it. Both
stages are fatal on failure, because `hyprland.conf` sources both files.

**`config/.seed-only`** still matters for the other case: things that are
*yours*. Paths listed there are installed once by `monarch-config-apply` and
never touched again — settings, monitor layout, `btop.conf` (btop rewrites it
itself). **Anything a future task generates into `config/` must be listed
there**, but better still, do not generate into `config/` at all.

**The keymap.** `schema/keybinds.toml` is the source of truth;
`~/.config/monarch/keybinds.toml` overrides it if it exists. `monarch keys
list --porcelain` is tab-separated and is what T9's GUI panel should read —
not the TOML, and not the pretty output.

---

## Open items for the human

Also tracked at the bottom of `PROGRESS.md`.

- Build the Arch VM and take the `clean-arch` snapshot — blocks everything, and
  is now three tasks overdue
- Run `lsblk` with the USB drive plugged in
- Theme palettes in your own colours. T3 shipped three originals as a starting
  point; replacing one is editing `themes/<name>/colors.toml` and running
  `monarch theme apply <name>`
- ASCII crown art for `brand/`
- **Never wipe the internal NVMe before Phase 4**
