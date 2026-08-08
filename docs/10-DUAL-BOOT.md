# Dual-booting MonARCH alongside Linux Mint

Keep Mint exactly where it is, install MonARCH beside it on the same drive, and
choose which one to boot at power-on. Nothing here erases Mint.

This is the more involved cousin of [`08-USB-INSTALL.md`](08-USB-INSTALL.md).
The USB route touches nothing internal; this one repartitions the internal
drive, which is where the real risk lives. Read the whole page before starting.

---

## Read this first

**Three things are true at once, and all three matter:**

1. **MonARCH has never booted.** Not once, on any machine. Putting an unproven
   OS on the disk your daily laptop depends on is the wrong order of
   operations. **Prove it boots from a USB drive first**
   ([`08-USB-INSTALL.md`](08-USB-INSTALL.md)). When it works from USB, come
   back here.

2. **Repartitioning can lose data.** Shrinking a filesystem is routine and
   usually fine, but "usually" is not "always" — a power cut mid-resize, or the
   wrong number typed, takes the partition with it. **Back up first**, to
   external media, and check the backup opens. This is Phase 0.1 in
   `PROGRESS.md` and it is still unchecked.

3. **One mistake is unrecoverable-in-place, the rest are not.** Formatting the
   wrong partition, or the shared boot partition, is the one that hurts.
   Everything else can be fixed from a live USB. The steps below are ordered to
   keep you away from that one mistake.

**On the locked decision.** `MONARCH.md` says *never wipe the internal NVMe
before Phase 4*. Dual-boot is not a wipe — Mint survives — so this does not
break that rule, and it is the safer of the "on the real machine" options. But
it is your call as the owner, made with eyes open: the disk gets a new
partition table, and the OS going onto it has not been booted yet.

**This machine is well-suited.** The internal drive has ~759 GB free on the
Mint partition to shrink into, and the boot partition is 512 MB with only ~6 MB
used — room to share comfortably.

---

## How it will end up

```
nvme0n1  (931 GB internal)
├─ nvme0n1p1   512M  vfat   EFI System Partition   SHARED by both OSes
├─ nvme0n1p2   ~680G ext4   Linux Mint  (shrunk from 916G)
└─ nvme0n1p3   ~230G btrfs  MonARCH     (new, in the freed space)
```

Both operating systems put their bootloader into the one shared EFI partition,
each in its own subdirectory, without touching the other's. At power-on you
press **F9** and pick. That is the whole mechanism, and it is deliberately the
simplest one: there is no shared bootloader config for the two distros to fight
over, and Mint is always reachable from the firmware menu no matter what
MonARCH does.

**Why MonARCH-on-top is safe here:** MonARCH's own installer never touches the
bootloader — it checks that UEFI exists and stops there. All the partitioning
and boot setup is done by Arch's installer in step 3. Once Arch dual-boots,
running `bootstrap.sh` cannot disturb Mint's boot.

---

## What you need

- The **backup** from "read this first". Non-negotiable.
- MonARCH **already proven to boot from USB**. Non-negotiable.
- A **USB stick with the Arch ISO** ([archlinux.org/download](https://archlinux.org/download)).
- 30–60 minutes and no reason to rush.

---

## 1. Back up, and verify the backup

Copy `~` to external media and **open a few files from the copy** to prove it
is real. A backup you have not tested is a hope, not a backup.

```bash
# example — adjust the destination to your external drive
rsync -aP --exclude '.cache' /home/$USER/ /run/media/$USER/BACKUP/home-$USER/
```

Note down anything not in `~` you would miss: `/etc` tweaks, installed package
list (`apt list --installed > ~/mint-packages.txt` — include it in the backup).

## 2. Free up space by shrinking Mint

You cannot resize a mounted filesystem, so this is done from a **live USB**, not
from inside Mint.

**Easiest — GParted from a Mint live USB:**

1. Write the Mint ISO you originally installed from to a USB stick (or any
   distro's live image that includes GParted).
2. Boot it (**F9**), choose "Try Linux Mint" / live session.
3. Open **GParted**.
4. Select `/dev/nvme0n1p2` (the big ext4 partition). If there is a small lock
   icon, right-click → deactivate/swapoff any swap first.
5. Right-click → **Resize/Move**. Drag the *right* edge left, or type a new
   size, to leave the space you want for MonARCH free **after** it. Leave
   `nvme0n1p2` at, say, 680 GB (leaving ~230 GB free). Do **not** move the
   start of the partition — only shrink from the end. Moving the start is slow
   and risky and buys nothing.
6. Apply. This takes a while; **do not interrupt it or let the battery die** —
   plug in the charger.

Leave the freed space **unallocated**. Arch's installer will make the MonARCH
partition itself in step 3, as btrfs.

> **How much to leave for MonARCH?** 100 GB is enough to live in; 200–250 GB is
> comfortable with room for projects, containers and package caches. You have
> the space — err large.

Reboot back into Mint once and confirm it still works normally before going on.
If Mint boots fine, the risky part is behind you.

## 3. Install Arch into the freed space

Boot the **Arch ISO** (F9). You reach `root@archiso ~ #`.

Get online and start the installer exactly as in
[`09-ARCH-INSTALL.md`](09-ARCH-INSTALL.md) — the WiFi steps and everything else
are identical. The **only** part that differs is disk configuration, and it is
the part that matters, so here it is in full.

In `archinstall`, choose **Disk configuration → Manual partitioning**, select
`/dev/nvme0n1`, and then:

**The EFI partition — `nvme0n1p1` (512M):**
- Assign it. Set its mountpoint to **`/boot`**.
- **Do NOT mark it for formatting / wiping.** This is the one that shares with
  Mint. Formatting it erases Mint's bootloader. Leave format **off**.

**The new MonARCH partition — the unallocated space:**
- Create a new partition filling the free space.
- Filesystem: **btrfs** (bootstrap.sh refuses anything else).
- Mountpoint: **`/`**.
- Format: **yes** — it is empty space, there is nothing to lose.

**Leave `nvme0n1p2` (Mint's ext4) completely alone.** No mountpoint, no format,
do not select it. If archinstall shows a format/wipe mark next to it or next to
`p1`, clear it before continuing.

Then the rest of the archinstall menu, same as the standalone guide:

| Setting | Answer |
|---|---|
| Bootloader | **GRUB** (see the note below) |
| Profile | **Minimal** |
| Audio | pipewire |
| Network | **NetworkManager** |
| User | create one, **with sudo** |

> **Bootloader choice.** GRUB and systemd-boot both work, and either way the
> firmware **F9** menu is your guaranteed way to reach Mint. GRUB has one nice
> extra: after install you can run `os-prober` and it will add a Mint entry to
> Arch's boot menu, giving you a single list instead of using F9. That is
> optional and covered at the bottom. If unsure, pick GRUB.

**Before you confirm, read the summary screen.** It lists what will be
formatted. It must show the **new btrfs partition only**. If it names
`nvme0n1p1` or `nvme0n1p2`, stop and fix it — that is the one irreversible
mistake.

Install, then reboot.

## 4. Check both operating systems boot

At power-on, press **F9** for the firmware boot menu. You should see entries for
both — something like "Linux Boot Manager"/"GRUB"/"arch" and
"ubuntu"/"Linux Mint".

1. Boot **Mint** first. Confirm it is completely normal. This is the thing you
   care about most; check it before anything else.
2. Reboot, F9, boot **Arch**. Log in at the text prompt.

If both boot, the dangerous work is done and it worked.

## 5. Install MonARCH

Booted into the new Arch, follow [`09-ARCH-INSTALL.md`](09-ARCH-INSTALL.md) §7 —
it is the same from here:

```bash
sudo pacman -S --needed git
git clone https://github.com/Johnnycarriere215/MonARCH-Modern-Arch-OS
cd MonARCH-Modern-Arch-OS
./bootstrap.sh
```

`bootstrap.sh` checks it is on Arch with a btrfs root under UEFI — all true now
— and **does not touch the bootloader**, so Mint's boot is safe throughout.
Reboot when it finishes; greetd brings up MonARCH.

Then run the checks in [`08-USB-INSTALL.md`](08-USB-INSTALL.md) §6 — this is
real hardware, so the panel, graphics, battery and the rest all count.

---

## Choosing which OS boots

**Always available: F9 at power-on**, pick from the firmware menu. This works
no matter what either OS does to its bootloader, which is why the whole setup
leans on it.

**To set the default** (which one boots if you do not press F9), from either
Linux:

```bash
efibootmgr                       # lists entries with boot numbers, e.g. 0000, 0001
sudo efibootmgr -o 0001,0000     # try this order; put the default first
```

**Optional — one menu instead of F9.** If you chose GRUB for Arch and want
Arch's menu to list Mint too, from the Arch/MonARCH side:

```bash
sudo pacman -S --needed os-prober
sudo sed -i 's/^#\?GRUB_DISABLE_OS_PROBER=.*/GRUB_DISABLE_OS_PROBER=false/' /etc/default/grub
sudo grub-mkconfig -o /boot/grub/grub.cfg
```

Mint should now appear in MonARCH's GRUB menu. Note that a Mint kernel update
re-runs *its* GRUB and may take the default EFI entry back — F9 still works
regardless, and `efibootmgr -o` puts the order back.

---

## If something went wrong

**Mint won't boot after installing Arch.** Its files are intact — only the boot
entry or order changed. Boot a Mint live USB and reinstall its bootloader:

```bash
# from a Mint live session, as root
mount /dev/nvme0n1p2 /mnt
mount /dev/nvme0n1p1 /mnt/boot/efi
for d in /dev /dev/pts /proc /sys /run; do mount --bind $d /mnt$d; done
chroot /mnt
grub-install --target=x86_64-efi --efi-directory=/boot/efi --bootloader-id=ubuntu
update-grub
exit
```

Then F9 → Mint.

**Arch won't boot but Mint does.** Less urgent — you have a working system.
Boot the Arch ISO, mount the btrfs root and the shared ESP, `arch-chroot`, and
reinstall the bootloader (`grub-install` / `bootctl install`). The Arch wiki's
"GRUB" and "systemd-boot" pages have the exact commands for your choice.

**Neither boots.** F9 → boot a live USB → your backup is on the external drive.
This is why step 1 was non-negotiable.

**The resize failed partway.** If GParted errored mid-resize, do not touch the
partition again — boot a live USB and run `e2fsck -f /dev/nvme0n1p2` before
anything else. If it will not mount, this is what the backup is for.

---

## The honest summary

Dual-boot is genuinely fine on this machine and this is a well-trodden path.
The residual risk is not the concept, it is that **MonARCH itself is unproven**
— so the single most important line on this page is the one that says prove it
from USB first. Do that, keep the backup, and the worst realistic outcome is an
afternoon reinstalling a bootloader, not a lost laptop.
