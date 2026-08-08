# Installing base Arch, step by step

Everything below is the **base Arch install** — the part before MonARCH. It is
the same whether you are installing into a VM (`docs/07-VM-TESTING.md`) or onto
an external drive (`docs/08-USB-INSTALL.md`). Both of those link here rather
than repeating it.

No prior Arch knowledge assumed. Nothing here needs the wiki.

---

## First, the thing nobody tells you

Arch has a reputation for a difficult install. That reputation is about ten
years out of date. The ISO now ships **`archinstall`** — a menu. You arrow up
and down, press Enter, pick answers. It takes about fifteen minutes and is not
meaningfully harder than Ubuntu's installer; it is just text instead of
graphics.

What *is* genuinely harder about Arch is living with it: it is rolling-release,
so updates arrive constantly and occasionally one breaks something. That is a
real difference from Ubuntu, and it is the specific problem MonARCH's update
system exists to solve — `monarch update` takes a Btrfs snapshot before it
touches anything, and a broken update is undone by picking the previous
snapshot at the boot menu.

So: the install is easy, the maintenance is handled. Neither is the reason to
be nervous.

---

## Before you start

You need three answers ready:

1. **A hostname** — what the machine calls itself. `monarch` is fine.
2. **A username** — lower case, no spaces. Whatever you like.
3. **A password.** You will set two: root, and your user. They can differ.

And one decision: **which disk**. If you are installing to an external drive,
read the "one step that can go wrong" section of `docs/08-USB-INSTALL.md`
first. Getting this wrong is the only irreversible mistake available.

---

## 1. Boot the ISO

Download from [archlinux.org/download](https://archlinux.org/download) — the
file is `archlinux-x86_64.iso`, about 1.2GB.

**In a VM:** attach it as a CD and boot. Make sure the VM's firmware is set to
**UEFI/OVMF** — see `docs/07-VM-TESTING.md` §1, it cannot be changed later.

**On hardware:** write it to a USB stick and boot from it.
```bash
lsblk -o NAME,SIZE,MODEL,TRAN          # identify the stick FIRST
sudo dd if=archlinux-x86_64.iso of=/dev/sdX bs=4M status=progress oflag=sync
```
`sdX` is the whole device, not a partition. On the EliteBook, **F9** at power
on gives the boot menu; pick the UEFI entry for the stick.

At the boot menu choose **"Arch Linux install medium (x86_64, UEFI)"** and wait.
You end at:

```
root@archiso ~ #
```

That is a working Linux system running entirely in RAM. Nothing is installed
yet, and nothing on your disks has been touched.

## 2. Check you are in UEFI mode

```bash
ls /sys/firmware/efi
```

**Output means you are fine.** "No such file or directory" means the machine
booted in legacy BIOS mode — `bootstrap.sh` will refuse to install MonARCH
later. Reboot, enter firmware setup (**F10** on an EliteBook), disable
CSM/Legacy boot, and try again.

## 3. Get on the network

**Ethernet** is already up. Test it:
```bash
ping -c2 archlinux.org
```

**WiFi** needs three commands:
```bash
iwctl
```
You are now at an `[iwd]#` prompt.
```
device list                                # find your adapter, usually wlan0
station wlan0 scan
station wlan0 get-networks                 # your SSID should be listed
station wlan0 connect YOUR_SSID            # it will prompt for the password
exit
```
Then confirm:
```bash
ping -c2 archlinux.org
```

If the ping fails, nothing after this will work. Fix it here.

## 4. Run the installer

```bash
archinstall
```

A menu appears. **Arrow keys** move, **Enter** selects, **Esc** or Tab goes
back. Items you do not touch keep sensible defaults.

Work down the list. The ones that matter for MonARCH are in **bold**.

### Archinstall language
English. Enter to accept.

### Locales
Keyboard layout, language, encoding. Set the **keyboard layout** to match your
physical keyboard — if you type your password with the wrong layout you will
not be able to log in and will not know why. `uk` or `us` for most people.

### Mirrors
Pick your region (United Kingdom, United States, etc). This is download speed
only. Skipping it works, just slower.

### **Disk configuration** — the important one

1. Choose **Partitioning**.
2. Choose **"Use a best-effort default partition layout"**.
3. **Select the disk.** Read the size carefully.
   - In a VM: there is only one, 80G.
   - On hardware with an external drive: pick the external. The internal
     931.5G NVMe must have **no mark next to it**.
4. It asks for a filesystem. **Choose `btrfs`.**
5. It asks about subvolumes — **yes, use the default structure.**
6. It may ask about compression — yes is fine.

> **btrfs is not optional.** `bootstrap.sh` checks for it and refuses to
> install on anything else. Snapshots are how MonARCH recovers from a bad
> update, and only btrfs gives them. Choosing ext4 here means reinstalling.

### Disk encryption
Optional now. MonARCH's locked decision is LUKS on by default with a mandatory
recovery key, but that is the Phase 3 wizard's job. **For a first test install,
skip it** — one less thing between you and a booting desktop.

### Bootloader
**systemd-boot** or GRUB, either works. MonARCH targets Limine eventually
(Phase 4) because it integrates with snapper's boot menu, but that is not
wired up yet and nothing here depends on it.

### Swap
Yes. Leave the default.

### **Hostname**
`monarch`, or whatever you like.

### **Root password**
Set one. This is your way back in if your user account breaks.

### **User account**
1. Add a user.
2. Set a password.
3. **Answer YES to "should this user be a superuser?"**

> **sudo is not optional either.** `bootstrap.sh` refuses to run as root, and it
> needs sudo for package installation. A user without it cannot install
> MonARCH.

### **Profile**
Choose **Minimal**.

Do *not* pick a desktop environment. MonARCH is the desktop — installing GNOME
or KDE here gives you two competing desktops and a login screen fight.

### Audio
**pipewire.**

### Kernels
`linux`. The default.

### **Network configuration**
**"Copy ISO network configuration"** or **NetworkManager** — either, but pick
one. The default is *no* network manager, and then you reboot into a machine
with no internet and no obvious way to get any.

NetworkManager is the better answer: MonARCH's Waybar network module expects
it, and `nm-connection-editor` is what the bar's network icon opens.

### Additional packages
Leave empty. MonARCH installs what it needs.

### Timezone
Yours.

### Automatic time sync
Enable it.

### Optional repositories
Leave alone. `multilib` is a user decision — MonARCH deliberately does not
enable it (see T1's notes in `PROGRESS.md`).

---

## 5. Install

Choose **Install** at the bottom of the menu.

It shows a summary first — **read the disk line.** That is your last chance to
catch the wrong drive. If it names the disk you meant, confirm.

Ten to twenty minutes depending on your mirror. When it finishes it offers to
`chroot` into the new system for manual configuration — **say no**, you do not
need it.

```bash
reboot
```

Remove the ISO: in a VM, detach the CD. On hardware, pull the installer stick
(leave the *target* drive in).

## 6. First boot

You get a text prompt again — but a different one. This is now **your installed
Arch**, not the live environment:

```
monarch login:
```

Log in with the username and password you created.

Check the network survived:
```bash
ping -c2 archlinux.org
```

If it did not, and you chose NetworkManager:
```bash
nmcli device wifi connect YOUR_SSID password YOUR_PASSWORD
```

**This is a complete, working Arch system.** No desktop — that is expected and
correct. MonARCH is the desktop, and it goes on next.

---

## 7. Install MonARCH

You cannot paste into a bare text console — there is no clipboard. Two ways
round it:

**Best: SSH in from your other machine**, then paste normally.
```bash
sudo systemctl start sshd
ip a                                    # note the address, e.g. 192.168.122.50
```
From Mint: `ssh youruser@192.168.122.50`

**Or clone it**, which is less typing than the one-liner and lets you edit
files in place when something breaks — which it will, since none of this has
ever run:
```bash
sudo pacman -S --needed git
git clone https://github.com/Johnnycarriere215/MonARCH-Modern-Arch-OS
cd MonARCH-Modern-Arch-OS
./bootstrap.sh
```

`bootstrap.sh` detects it is already inside a checkout and skips re-cloning.

**Or the one-liner**, if you would rather type a URL than clone:
```bash
curl -fsSL https://raw.githubusercontent.com/Johnnycarriere215/MonARCH-Modern-Arch-OS/main/bootstrap.sh | bash
```

It refuses to run as root and checks Arch / x86_64 / btrfs / UEFI first, naming
whichever one failed. Everything is logged to `/var/log/monarch-install.log`.

When it finishes:
```bash
reboot
```

greetd should appear. Log in, and you are in Hyprland. **`Super+Return` opens a
terminal** — that is the bar Phase 1 has to clear.

Then follow the checks in `docs/07-VM-TESTING.md` §5, or
`docs/08-USB-INSTALL.md` §6 if you are on real hardware.

---

## When it goes wrong

It has never been run. Something will fail. That is what the VM and the
snapshot are for.

**The install stops partway.** The failing stage is named on screen. Paste that
plus the tail of `/var/log/monarch-install.log` into the next Claude session.

**An AUR package fails to build.** Expected and non-fatal by design — the
install warns and carries on. Check the summary at the end of stage 20 for what
did not make it. `walker-bin` failing is the one that matters: without it, the
Super key does nothing.

**greetd appears but login bounces back to greetd.** Hyprland did not start.
**Ctrl+Alt+F2** for a text console, log in, and look:
```bash
tail -50 ~/.local/share/hyprland/hyprland.log
```

**Black screen after login.** Same — Ctrl+Alt+F2. Almost certainly a config
parse error; no version of Hyprland has ever read the files MonARCH generates.

**You want to start over.** In a VM, revert to the `clean-arch` snapshot — ten
seconds, and it is why you took it. On hardware, re-run `archinstall`.
