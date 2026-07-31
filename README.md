```
   ▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄
   █  ▄   ▄   ▄  █
   █ ███ ███ ███ █
   █▄▄▄▄▄▄▄▄▄▄▄▄▄█
    M o n A R C H
```

# MonARCH

**Arch Linux, made yours.**

A fast, keyboard-first Linux desktop that doesn't require a terminal to configure. Built on Arch Linux and Hyprland. Tiling by default, with a real settings app when you want one.

*Placeholder logo — final art pending.*

---

## ⚠️ BIOS SETTINGS — READ BEFORE INSTALLING

MonARCH will not install unless these are set. On HP laptops, press **`F10`** at the boot splash.

| Setting | Must be | Why |
|---|---|---|
| Secure Boot | **Disabled** | Arch's bootloader is not Microsoft-signed |
| TPM | **Disabled** | Interferes with LUKS disk encryption setup |
| Virtualization (VT-x / AMD-V) | **Enabled** | Required for Claude Desktop's Cowork tab |
| VT-d / IOMMU | **Enabled** | Required for virtualization features |

**If the installer stops immediately, or the USB won't boot, it is almost always Secure Boot.** Check that first.

> **The installer erases the drive you select.** Confirm the drive before continuing. Back up anything you cannot afford to lose. If you enable full-disk encryption, setup gives you a **recovery key — save it somewhere off the machine.** A forgotten password without it means permanent, unrecoverable data loss.

---

## Install

### From the ISO (recommended)

1. Download the latest ISO from [Releases](../../releases)
2. Verify: `sha256sum -c monarch.iso.sha256`
3. Write to USB:
   ```bash
   lsblk                      # find your drive FIRST
   sudo dd if=monarch.iso of=/dev/sdX bs=4M status=progress oflag=sync
   ```
   On Windows or macOS, use [balenaEtcher](https://etcher.balena.io/).
4. Set the BIOS options above, boot the USB (`F9` on HP)
5. Follow the installer, then the first-run wizard

An internet connection is required during install — MonARCH downloads packages rather than shipping a 4GB ISO.

### Onto an existing Arch install

Requires a Btrfs root, UEFI, and a user with sudo.

```bash
curl -fsSL https://raw.githubusercontent.com/Johnnycarriere215/MonARCH-Modern-Arch-OS/main/bootstrap.sh | bash
```

---

## What you get

- **Hyprland** tiling with smooth animations, or a **Windows-like mode** with title bars and a taskbar — one toggle
- **Settings app** for keybindings, themes, monitors, startup apps, and performance. No terminal required
- **Every hotkey discoverable** — press `Super + K`
- **Snapshot rollback** — a bad update is recoverable from the bootloader
- **Optional full-disk encryption** with a mandatory recovery key
- **Preinstalled:** VS Code, Claude Desktop, Chromium, Spotify, GitHub Desktop, Git, Neovim

---

## First steps

| Key | Does |
|---|---|
| `Super` (tap) | App launcher — type three letters, hit Enter |
| `Super + K` | Every keyboard shortcut |
| `Super + Return` | Terminal |
| `Super + W` | Close window |

Open **MonARCH Settings** from the launcher to change any of it.

---

## Modes

| Mode | For |
|---|---|
| **Tiling** | Windows arrange themselves. Fastest once learned |
| **Windows** | Floating windows, title bars, close buttons, taskbar. Familiar |
| **Performance** | Effects off. Older machines, or battery life |

Switch in Settings, or `monarch mode set <name>`.

---

## Docs

| | |
|---|---|
| [`START-HERE.md`](START-HERE.md) | Session protocol for AI assistants |
| [`PROGRESS.md`](PROGRESS.md) | Current build state |
| [`docs/00-BRIEF.md`](docs/00-BRIEF.md) | What MonARCH is and why |
| [`docs/01-DECISIONS.md`](docs/01-DECISIONS.md) | Every design decision, with rationale |
| [`docs/02-HARDWARE.md`](docs/02-HARDWARE.md) | Target hardware, known risks, validation |
| [`docs/03-ROADMAP.md`](docs/03-ROADMAP.md) | Phases and acceptance criteria |
| [`docs/04-TASKS.md`](docs/04-TASKS.md) | Build tasks |
| [`docs/05-CHECKLIST.md`](docs/05-CHECKLIST.md) | Human-only actions |
| [`docs/06-RELEASE.md`](docs/06-RELEASE.md) | ISO and release process |

---

## Credit where it's due

MonARCH is built on **Arch Linux** and **Hyprland**, and was **inspired by [Omarchy](https://github.com/basecamp/omarchy)** by DHH and 37signals — which showed that this kind of desktop could be beautiful as well as fast.

MonARCH is an independent project, **not a fork**, and is **not affiliated with or endorsed by** Omarchy, Basecamp, 37signals, or DHH. Please don't send them MonARCH bugs. See [ATTRIBUTION.md](ATTRIBUTION.md).

MIT licensed.
