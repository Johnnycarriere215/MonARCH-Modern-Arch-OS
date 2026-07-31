# MonARCH — Release & Distribution

## The ISO size constraint

**GitHub caps release assets at 2GB per file.** Distros that bundle an offline package mirror exceed this and need paid hosting.

MonARCH avoids that with a **slim online-install ISO**: it boots, runs the installer, and pulls packages from Arch mirrors during install.

| | Fat ISO | **Slim ISO (ours)** |
|---|---|---|
| Size | 2.5–4GB | **~800MB–1.5GB** |
| Fits GitHub Releases | No | **Yes** |
| Hosting needed | R2 / S3 + signing pipeline | **None** |
| Installs without network | Yes | No |
| Cost | ~$5/mo + setup | **$0** |

Requiring a network connection to install is completely normal. If MonARCH goes public and people ask for offline install, add a fat ISO on R2 then.

**CI must fail loudly if the ISO exceeds 1.9GB** rather than silently producing something that can't upload.

---

## Release flow

```
git tag v0.1.0 && git push --tags
        │
        ▼
GitHub Actions: build ISO → sha256 → create Release → upload ISO + checksum
        │
        ▼
Users' Waybar shows an update icon within 30 min
        │  click
        ▼
monarch update:
  1. monarch-snapshot create       ← never skipped
  2. git pull (user's channel)
  3. pacman -Syu
  4. monarch-migrate
  5. AUR + orphan cleanup
  6. hyprpm update                 ← warn, don't abort
  7. monarch-config-apply
  8. restart prompt if kernel or Hyprland changed
```

A nightly workflow builds from `dev` and reports size only — no release.

---

## Channels

| Channel | Branch | Who |
|---|---|---|
| `stable` | `master` | Everyone else |
| `dev` | `dev` | You |

Run `dev` yourself so an untested change never reaches you twice.

**Rate limit:** the unauthenticated GitHub API allows 60 requests/hour/IP. Poll at most every 30 minutes, cache the result, fail silently on network errors.

---

## Going public

### Do now — free insurance

- [ ] MIT `LICENSE` with your name, from the first commit
- [ ] `ATTRIBUTION.md` from the first commit. Retrofitting attribution looks bad
- [ ] Never imply endorsement by Omarchy, Basecamp, 37signals, or DHH
- [ ] If you ever copy an Omarchy file substantially verbatim, keep its MIT notice in that file

### Do before going public

- [ ] **Wallpaper audit.** Every bundled image needs a recorded license. Generate your own if in doubt — a near-black theme set is gradients you can produce in an afternoon
- [ ] Confirm no Chrome, Spotify, 1Password, Typora, or Zoom binaries in the ISO — installers only
- [ ] Test the ISO on at least one machine that isn't the EliteBook
- [ ] Issue templates, a support channel, and a `monarch doctor` output format people can paste
- [ ] Decide whether you need your own pacman mirror. Arch + AUR is fine until there are real users

### Do not do now

Don't build the live ISO, register domains, or stand up a package mirror. All reversible later, none of it makes MonARCH better for you today.

---

## Licensing summary

| Component | License | Obligation |
|---|---|---|
| MonARCH | MIT | Yours |
| Arch packages | Various | Standard distribution |
| Hyprland | BSD 3-Clause | Retain notice |
| Any file copied from Omarchy | MIT | **Retain its copyright notice in that file** |
| Wallpapers | **Unknown — audit required** | The actual risk |
| Chrome / Spotify / Typora / Zoom | Proprietary | **Never redistribute.** Installers only |
