# MonARCH — Human-Only Checklist

Things no AI can do. Your hands, your hardware, your judgment.

---

## Before T1

- [ ] **Back up `~`.** Your Mint install is one 931GB ext4 partition with no separate `/home`. If it goes, everything goes.
      ```bash
      whoami
      ls /media/$(whoami)/
      mkdir -p /media/$(whoami)/YOUR_DRIVE/home-backup
      rsync -aAXv --progress ~/ /media/$(whoami)/YOUR_DRIVE/home-backup/
      ```
      `~/` always expands correctly, so it can't be wrong.
- [ ] Save separately: SSH keys (`~/.ssh`), `.env` files, bookmarks (or confirm Chrome sync)
- [ ] **Identify the USB drive.** Plug it in, then `lsblk -o NAME,MODEL,TRAN,SIZE,ROTA`. Samsung T7 / SanDisk Extreme → SSD, fine to install onto. Cruzer / DataTraveler / Ultra Fit → flash stick; use it for the ISO and validation boots only
- [ ] BIOS: Secure Boot off, TPM off, VT-x on, VT-d on
- [ ] Create an empty GitHub repo named `monarch`
- [ ] Unzip this starter into it, `git init`, commit
- [ ] Add an MIT `LICENSE` with your name
- [ ] Build the Arch VM (12GB RAM, 4 CPUs, 80GB disk, UEFI/OVMF, virtio + 3D accel)
- [ ] **Snapshot the VM immediately after base Arch install, before MonARCH.** Name it `clean-arch`. Every bootstrap test resets to it

---

## After every task

- [ ] Reset the VM to `clean-arch` and run the full bootstrap
- [ ] Commit only what works
- [ ] Tick the matching item in `03-ROADMAP.md`

---

## Real-hardware checkpoints

- [ ] **After T2** — boot the USB, confirm `GDK_SCALE=1` looks right on the 1080p panel
- [ ] **After T6** — test Windows mode on metal. `hyprbars` is the fragile piece
- [ ] **After T7** — deliberately break an update and roll back from a snapshot. Do this once before you ever trust it
- [ ] **After T12** — install from your own ISO in the VM before touching the internal NVMe

---

## Decisions only you can make

- [ ] ASCII crown art for boot splash, greeter, and About screen → `brand/`
- [ ] The three shipped theme palettes — write your own colors
- [ ] Wallpapers, **with a recorded license per file**
- [ ] When to wipe the internal drive. Phase 4, not before

---

## Never delegate

- [ ] **Saving the LUKS recovery key off the machine.** One forgotten password without it means total, unrecoverable data loss. No reset link, no support line
- [ ] Deciding the internal drive is ready to be wiped
- [ ] Wallpaper licensing before any public release

---

## Still outstanding

- [ ] Run `whoami` and fix the backup path
- [ ] Run `lsblk` with the USB drive actually plugged in
- [ ] Fill in the baseline table in `02-HARDWARE.md`
