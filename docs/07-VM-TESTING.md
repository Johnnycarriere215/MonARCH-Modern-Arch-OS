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

Boot the Arch ISO and run `archinstall`.

Answers that matter:

- **Filesystem: btrfs**, with subvolumes. `bootstrap.sh` checks for a Btrfs root
  and stops without one — deliberately, because snapshots are the rollback plan.
- **Bootloader:** anything for now. MonARCH targets Limine; Phase 4 owns that.
- **Profile:** minimal. No desktop. MonARCH is the desktop.
- **User:** create one, **with sudo**. Do not plan to run as root.
- **Network:** NetworkManager, so the VM has a network on first boot.
- **Audio:** pipewire.

Reboot, log in as your user, confirm `ping archlinux.org` works.

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
6. **The theme engine** (T3, and the parts it cannot verify itself):
   ```bash
   monarch theme list
   monarch theme apply parchment    # the whole desktop should go light
   monarch theme apply midnight
   ```
   Specifically check: the Waybar colours change, the terminal colours change,
   a notification (`notify-send hello`) is themed, **and whether Walker
   (`Super`) is styled at all**. Walker is the one MonARCH is least sure of.

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
output, and which of the six checks in section 5 passed. `PROGRESS.md` has
unticked criteria waiting on exactly this.
