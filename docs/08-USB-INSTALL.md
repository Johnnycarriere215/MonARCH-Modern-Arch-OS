# Running MonARCH from an external drive

The way to use MonARCH as a daily OS on the EliteBook **without touching the
internal NVMe**. Mint stays where it is; you pick which system to boot at power
on.

This is also the real-hardware checkpoint `PROGRESS.md` asks for after T2 —
Intel UHD 620, the actual 1080p panel, actual battery behaviour. None of which
a VM can tell you.

> **Do the VM test first** (`docs/07-VM-TESTING.md`). Not because this is
> dangerous, but because the install has never succeeded once and the first few
> attempts will fail at something. Failing in a VM costs ten seconds to revert;
> failing here costs a reinstall.

---

## What you need

**An external SSD, ideally NVMe in a USB 3.1+ enclosure.** About £25–40 for the
enclosure plus whatever drive you put in it. On this laptop it will be *faster*
than the internal SATA-era experience, and Hyprland is not disk-bound anyway.

A plain USB 3 flash drive works but is a worse experience — flash sticks have
poor random write, so package installs and updates crawl. Fine for proving it
boots. Not fine for a week of living in it.

**Size:** 64GB is enough. 128GB+ if you want room for your actual files.

You also need a second USB stick for the Arch installer itself, or you can
write the Arch ISO to the same drive first and install onto it later — simpler
to just use two.

---

## The one step that can go wrong

Everything here is safe **except** picking the wrong disk in the installer.
Pick the internal NVMe and Mint is gone.

Before you start anything, run this on Mint with the external drive plugged in
and write down what you see:

```bash
lsblk -o NAME,SIZE,MODEL,TRAN,MOUNTPOINT
```

The internal drive is `nvme0n1`, 931.5G, `TRAN=nvme`, with `/` and `/boot/efi`
mounted from it. **That is the one you must never select.** Your external drive
will appear as `sda` (or `nvme1n1` for some enclosures) with `TRAN=usb`.

Two rules that make a mistake nearly impossible:

1. **Go by size and TRAN, not by name.** Device names change between boots.
   Your external is the one whose size matches what you bought and whose `TRAN`
   is `usb`.
2. **In `archinstall`, the internal disk should have no checkbox next to it.**
   If it does, you have selected it. Back out.

---

## 1. Write the Arch ISO to a stick

On Mint, download from [archlinux.org/download](https://archlinux.org/download),
then:

```bash
lsblk -o NAME,SIZE,MODEL,TRAN          # find the stick, confirm the size
sudo dd if=~/Downloads/archlinux-*.iso of=/dev/sdX bs=4M status=progress oflag=sync
```

Replace `sdX` with the stick — **not** `sdX1`, the whole device. Or use Mint's
built-in USB Image Writer if you would rather click.

## 2. Boot the installer

Plug in **both** drives — the Arch stick and the external SSD. Power on and
press **F9** for the EliteBook's boot menu. Pick the Arch stick, UEFI entry.

If it does not appear: **F10** for BIOS setup, and check Secure Boot is off.
`docs/02-HARDWARE.md` has the BIOS settings; Secure Boot off is Phase 0.2.

You land at a root prompt: `root@archiso ~ #`.

Get networking up. Ethernet just works. For WiFi:

```bash
iwctl
[iwd]# station wlan0 connect YOUR_SSID
[iwd]# exit
ping -c2 archlinux.org
```

## 3. Install Arch onto the external drive

```bash
archinstall
```

**[docs/09-ARCH-INSTALL.md](09-ARCH-INSTALL.md) §4 walks the menu**, item by
item. Follow it, with one difference that matters more here than anywhere else:

> **At "Disk configuration", select the EXTERNAL drive.** Check the size against
> what you bought. The internal 931.5G NVMe must have no mark next to it. The
> installer creates the external drive's own EFI partition, which is what leaves
> Mint's bootloader untouched.

The other answers are as that document has them: **btrfs**, **minimal** profile,
a user **with sudo**, NetworkManager, pipewire.

**Before confirming, read the summary screen.** It names the disk it is about to
erase. If that says `nvme0n1` or 931G, stop.

Install, then reboot — leaving the external drive plugged in.

## 4. Boot the external drive

**F9** at power on, pick the external drive. You get a text login. Log in as
your user.

This is a normal, working, desktop-less Arch install. Nothing MonARCH yet.

## 5. Install MonARCH

Pasting into a bare console does not work — there is no clipboard. Easiest is
to SSH in from Mint:

```bash
sudo systemctl start sshd
ip a                                   # note the address
```

Then from Mint: `ssh youruser@thataddress`, and paste normally.

Otherwise clone it, which is less typing than the curl one-liner and lets you
edit files in place when something breaks:

```bash
git clone https://github.com/Johnnycarriere215/MonARCH-Modern-Arch-OS
cd MonARCH-Modern-Arch-OS && ./bootstrap.sh
```

`bootstrap.sh` notices it is already inside a checkout and skips the clone.

Reboot when it finishes. greetd should come up, and logging in gives you
Hyprland.

---

## 6. What to check on real hardware

The VM cannot answer any of these. This is the whole point of doing it here.

**The panel.** `GDK_SCALE=1` is a locked decision for this 1080p screen. If
everything looks postage-stamp small or comically huge, that is the setting —
`config/hypr/monarch.conf`. Note what you actually find in
`docs/02-HARDWARE.md`.

**Graphics.** Hyprland on Intel UHD 620 with no discrete GPU. Animations should
be smooth. If it tears, stutters, or falls back to software rendering, that is
the single most important thing to report back.

```bash
monarch doctor          # built to be pasted
```

**Battery.** The number that decides whether MonARCH is usable on this laptop:

```bash
upower -i /org/freedesktop/UPower/devices/battery_BAT0 | grep -E 'percentage|time to empty'
```

Check it idle at the desktop, then again after an hour of normal work. Compare
against Mint. `docs/02-HARDWARE.md` has a baseline table waiting to be filled
in — that comparison is exactly what it is for.

**The bar's cost**, which T5 could only estimate:

```bash
top -bn2 | grep -i waybar | tail -1
```

The budget was under 1% of one core; the estimate was ~0.2%.

**`/dev/kvm`**, for Claude Desktop:

```bash
monarch install claude-desktop --check
```

If it is missing, VT-x is off in the BIOS — F10 at boot, Security > System
Security.

**Fingerprint reader, WiFi, Bluetooth, suspend, lid close, external display over
Thunderbolt.** The full list is the hardware validation checklist in
`docs/02-HARDWARE.md`.

---

## Living with it

**Switching systems** is F9 at power on. Mint if the external is unplugged or
you pick the internal; MonARCH if you pick the external.

**Do not unplug it while running.** Obvious, but the failure is uglier than with
a data drive — it is the root filesystem.

**Your files.** Treat the external as its own machine to start with. Once you
trust it, Mint's home directory is readable from MonARCH:

```bash
sudo mkdir -p /mnt/mint
sudo mount /dev/nvme0n1p2 /mnt/mint          # read-only is safer: -o ro
```

**Making it permanent.** If a week goes well, the internal NVMe becomes the
question — and that is Phase 4, after the ISO exists, with a full backup taken
first. `MONARCH.md` is unambiguous: never wipe the internal drive before then.

---

## If it does not boot

**No boot entry for the external drive.** Some UEFI firmware hides removable
devices. F10 > Boot Options > check "USB boot" is enabled and legacy/CSM is off.

**greetd appears, login drops back to greetd.** Hyprland failed to start. Switch
to a text console with **Ctrl+Alt+F2**, log in, and look:

```bash
cat ~/.local/share/hyprland/hyprland.log | tail -50
journalctl -b -u greetd --no-pager | tail -30
```

**Black screen after login.** Also Ctrl+Alt+F2. Most likely a config parse
error — nothing MonARCH generates has ever been read by Hyprland.

**Nothing works and you want out.** Power off, unplug the external drive, power
on. You are in Mint. The external drive being broken has no effect on the
internal one — which is the entire reason for doing it this way.
