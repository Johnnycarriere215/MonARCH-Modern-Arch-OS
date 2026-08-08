# Testing MonARCH in a VM

The full procedure. Nothing here needs the EliteBook — that comes later, and
only after this passes.

**Never test on the internal NVMe before Phase 4.**

---

## 1. Build the host VM

Use `virt-manager` (Mint: `sudo apt install virt-manager qemu-system-x86 ovmf`),
or GNOME Boxes if you prefer, but Boxes hides the firmware setting and you need
it.

| Setting | Value | Why |
|---|---|---|
| RAM | 12 GB | AUR builds are memory-hungry |
| CPUs | 4 | |
| Disk | 80 GB, qcow2 | |
| Firmware | **UEFI / OVMF** | `bootstrap.sh` refuses to run on BIOS |
| Video | virtio, **3D acceleration on** | Hyprland needs a GPU it recognises |
| Network | NAT | |

In virt-manager the firmware option only appears if you tick **Customize
configuration before install** on the last page of the new-VM wizard. Set
Firmware to `UEFI x86_64 ...OVMF...` there. It cannot be changed afterwards.

## 2. Install base Arch

**[docs/09-ARCH-INSTALL.md](09-ARCH-INSTALL.md) is the step-by-step**, menu item
by menu item. It is written for someone who has never installed Arch.

The three answers that MonARCH depends on, so you can spot them going past:

- **Filesystem: btrfs.** `bootstrap.sh` refuses anything else — snapshots are
  the rollback plan.
- **Profile: minimal.** No desktop environment. MonARCH is the desktop.
- **User: with sudo.** `bootstrap.sh` refuses to run as root.

Stop when you reach the end of §6 (first boot) in that document. Come back here
before installing MonARCH — the snapshot below has to be taken first.

## 3. Snapshot it as `clean-arch` — before MonARCH

```
virsh snapshot-create-as --domain <vm-name> clean-arch "base arch, pre-monarch"
```

Or virt-manager's camera icon. **Take it now.** A snapshot taken after MonARCH
has touched the system is worthless as a reset point, and you will want to reset
several times.

To roll back later: `virsh snapshot-revert --domain <vm-name> clean-arch`

## 4. Install MonARCH

In the VM, as your normal user:

```bash
curl -fsSL https://raw.githubusercontent.com/Johnnycarriere215/MonARCH-Modern-Arch-OS/main/bootstrap.sh | bash
```

It refuses to run as root, and guards on Arch / x86_64 / Btrfs / UEFI — if one
of those fails it says which. Everything is logged to
`/var/log/monarch-install.log`, appended, never truncated.

## 5. What to check, in order

1. **It reaches `50-finish.sh`.** If it dies, the failing stage is named on
   screen. Paste that and the tail of the log into the next chat.
2. **Run it a second time without reverting the snapshot.** This is the
   criterion least likely to be right. Watch for: duplicated PATH lines in
   `~/.bashrc`, a second snapper config attempt, clobbered configs.
3. **Reboot.** greetd/tuigreet should appear. It is enabled but deliberately not
   started during install — starting it would kill the installer's own TTY.
4. **Log in to Hyprland. Press `Super+Return`.** A terminal should open. That is
   the bar Phase 1 has to clear.
5. **`monarch doctor`** — built to be pasted. Paste it.
6. **The keymap** (T4). `Super+/` should open a floating terminal listing every
   binding. Then spot-check the ones with awkward quoting, which are the ones
   most likely to have been generated wrong:
   ```
   Super+X        clipboard history through walker (needs cliphist installed)
   Print          region screenshot to clipboard  (grim + slurp)
   Super+grave    dropdown terminal
   Super+Shift+W  next wallpaper (says so and does nothing if you have none)
   ```
   `monarch keys check` should report 65 bindings and no conflicts.

7. **The theme engine** (T3, and the parts it cannot verify itself):
   ```bash
   monarch theme list
   monarch theme apply parchment    # the whole desktop should go light
   monarch theme apply midnight
   ```
   Specifically check: the Waybar colours change, the terminal colours change,
   a notification (`notify-send hello`) is themed, **and whether Walker
   (`Super`) is styled at all**. Walker is the one MonARCH is least sure of.

8. **The bar** (T5). The right-hand group should read, left to right: CPU, RAM,
   GPU, network throughput, disk free, then tray/bluetooth/network/audio/
   battery/clock. Then:
   ```bash
   monarch bar modules              # what is on
   monarch bar modules disable gpu  # the bar restarts, GPU vanishes
   monarch bar modules --performance
   monarch bar modules reset
   ```
   Click CPU — btop should open floating showing the CPU box only. **And the
   number T5 could not measure:** leave the desktop idle a minute, then
   `top -bn2 | grep -i waybar | tail -1`. The budget is under 1% of one core;
   the estimate was ~0.2%.

   The GPU module says a percentage that is *clock speed*, not utilisation,
   unless `intel-gpu-tools` is installed — the tooltip says which you are
   looking at.

9. **Modes** (T6). This is the fragile one — hyprbars is a plugin compiled
   against one Hyprland version.
   ```bash
   monarch mode list
   monarch mode session performance   # effects off, bar thins out, keys unchanged
   monarch mode set windows           # THE ONE THAT MATTERS
   ```
   Windows mode should give every window a title bar with three buttons, the
   bar at the bottom with a taskbar, and floating windows. **If hyprbars will
   not load it must say so and land you in tiling** — never floating windows
   with no title bars. Either outcome is a pass for the fallback; a session
   with no title bars and no message is the failure.

   Then `SUPER+M` to minimise and click the taskbar entry to bring it back,
   which is the whole point of the mode.

   Reboot and confirm windows mode survived. Then `monarch mode session tiling`,
   reboot again, and confirm you are back in windows mode — a session mode must
   not persist.

10. **The update system** (T7). This has the one criterion nothing else can
    check — the rollback. Do it deliberately, while you have a clean snapshot
    to come back to:
    ```bash
    monarch snapshot list
    monarch update --dry-run          # read the eight steps, change nothing
    monarch update                    # snapshots first, always
    ```
    Then break something on purpose and roll back:
    ```bash
    monarch snapshot create "before I break it"
    sudo rm -rf /usr/share/hyprland   # or anything else obviously fatal
    monarch snapshot list             # note the number
    ```
    **Reboot and pick the snapshot from the Limine menu.** That is the
    recommended path and the one worth rehearsing — `monarch snapshot restore`
    exists but only takes effect at the next boot and does not let you look
    first. Confirm the desktop comes back.

    Also check the bar: with no releases published yet there should be **no**
    update icon at all.

11. **The installers** (T8). At least:
    ```bash
    monarch install claude-desktop --check   # reports /dev/kvm, installs nothing
    monarch pkg search ripgrep
    monarch webapp add "Google Messages" messages.google.com/web
    ```
    The web app should appear in Walker and open in its own window with no
    address bar. `monarch install vscode` then wants a VS Code restart, after
    which its theme should match the desktop.

12. **`monarch keys reset --yes`** and confirm the desktop still has keys. It is
   the recovery path if a rebind goes wrong, so it is worth knowing it works
   before you need it.

## 6. Most likely to break

In rough order of probability:

- **An AUR package failing to build.** By design this warns and continues
  rather than aborting — check the summary at the end of stage 20.
- **`snapper create-config` failing** if archinstall already made a
  `/.snapshots` subvolume. Warns and continues; snapshots just won't be set up.
- **`walker-bin`** — the launcher. If it didn't install, `Super` does nothing.
- **Walker's theme.** `config/walker/config.toml` assumes `theme = "monarch"`
  and a stylesheet at `~/.config/walker/themes/monarch.css`. Walker moved this
  around during its 0.x releases. Unstyled launcher = that pairing is wrong.
  Launcher won't start at all = delete `config/walker/config.toml`.
- **Hyprland config syntax.** Every variable and sourced path has been validated
  mechanically, but no version of Hyprland has ever parsed these files.
- **Stage 30 stopping on the theme.** That is deliberate:
  `hyprland.conf` sources `hypr-colors.conf`, so no palette means no session.

## 7. Testing local edits without pushing

`bootstrap.sh` detects being run from an existing checkout and skips the clone.
So: share a folder into the VM (or `git clone` your branch), then

```bash
cd /path/to/checkout && ./bootstrap.sh
```

## 8. What to bring back

Paste into the next session: the failing stage name if any, `monarch doctor`
output, and which of the twelve checks in section 5 passed. `PROGRESS.md` has
unticked criteria waiting on exactly this.
