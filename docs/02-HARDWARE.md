# MonARCH — Hardware Profile

## Target machine

HP EliteBook 850 G6 (9JF98US), confirmed via `lshw`:

| | Value | Implication |
|---|---|---|
| CPU | Intel i7-8665U (Whiskey Lake, vPro, 4c/8t) | VT-x present → KVM works |
| RAM | 32GB — 2× 16GB DDR4, both slots full | VMs are nearly free |
| GPU | **Intel UHD 620 only** — no AMD dGPU | Best-supported Hyprland path. No proprietary drivers |
| Display | eDP-1 **1920×1080** (~141 PPI) | `GDK_SCALE=1` |
| External | HDMI-1 1920×1080 (~92 PPI) | Mixed PPI → per-monitor scaling is first-class |
| Storage | Kingston NV1 1TB NVMe | 512M EFI + 931G ext4 (current install) |
| WiFi/BT | Intel AX200 (Wi-Fi 6) | In-kernel, no firmware drama |
| Ethernet | Intel I219-LM | Works out of the box |
| Thunderbolt | JHL7540 Titan Ridge (TB3) | Two externals off one dock is viable |
| Audio | `sof-hda-dsp` (Sound Open Firmware) | Verify explicitly |
| Touchpad | Synaptics SYNA3092 | Fine |
| Camera | HP HD Camera | No IR camera |
| Fingerprint | **Not present** in `lshw` output | Drop fingerprint auth from the wizard |
| Peripherals | onn mechanical keyboard, Logitech M720, JLab GO Air Pop | |

**Verdict: close to an ideal Hyprland machine.** No hardware landmines.

---

## Known risks

**1. `hyprbars` breaks on Hyprland updates — HIGH.** The plugin compiles against a pinned Hyprland version via `hyprpm`. Every update can break Windows mode until it rebuilds. `monarch-update` runs `hyprpm update` and warns on failure; Windows mode falls back to tiling rather than leaving a session with no title bars and no explanation. This is the most likely recurring breakage in the project.

**2. EdgeHop input capture on Wayland — MEDIUM.** *Injection* is likely fine — virtual devices via `/dev/uinput` are consumed through libinput like real hardware. *Capture* is the hard part: X11 allows global pointer grabs, Wayland forbids them. Routes are `EVIOCGRAB` on `/dev/input/eventX` (device-level, bypasses the display server, needs the user in the `input` group) or libei + xdg-desktop-portal. Also swap `xclip` for `wl-clipboard`.

**3. `sof-hda-dsp` audio — LOW.** Occasionally needs quirks on this generation. Test speakers, jack, mic, HDMI audio explicitly.

**4. Suspend/resume — LOW.** Common laptop failure point. Test on real hardware, not the VM.

---

## Hardware validation checklist

Run on the **USB boot**, on the EliteBook. These are what a VM cannot tell you.

**Display** — resolution correct · UI scale sane · brightness keys · external via HDMI · external via Thunderbolt dock · both at once · one rotated vertical, persists · mirror mode

**Power** — suspend on lid close · resume with no black screen · battery % accurate · charging detected

**Input** — touchpad + two-finger scroll + right-click · onn keyboard all keys · Logitech M720 pairs · HP hotkeys · EdgeHop

**Audio / Network** — speakers · headphone jack · mic · JLab earbuds over Bluetooth · HDMI audio · Wi-Fi 6 holds · Ethernet · webcam

**Software** — `claude-desktop` launches · Cowork tab works (the KVM check) · VS Code · GitHub Desktop no segfault · Chrome installer · Spotify plays

---

## Baseline measurements

Record on real hardware before Phase 2. Every later change is judged against these.

| Metric | How | Value |
|---|---|---|
| Cold boot → desktop | Stopwatch | |
| Idle RAM, no apps | `free -h` after 2 min | |
| + Chrome, 5 tabs | `free -h` | |
| + Chrome + Claude Desktop + VS Code | `free -h` | |
| Idle CPU % | `btop`, 1 min avg | |
| Battery drain, idle | 30 min unplugged | |
| Battery drain, working | 30 min, Chrome + VS Code | |
| Disk used after install | `df -h /` | |

With 32GB, **boot time and battery life matter more than idle RAM.**

---

## BIOS settings

`F10` at the HP splash.

| Setting | Value | Why |
|---|---|---|
| Secure Boot | Disabled | Arch's bootloader isn't Microsoft-signed |
| TPM | Disabled | Interferes with LUKS setup |
| Virtualization (VT-x) | Enabled | VM testing + Claude Desktop Cowork |
| VT-d / IOMMU | Enabled | Required for virtualization |

If the installer stops immediately or the USB won't boot, it is almost always Secure Boot.
