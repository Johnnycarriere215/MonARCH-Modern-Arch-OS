# MonARCH — Decision Log

Every decision, locked, with rationale. **If it's here, it's settled.** Reopen only by editing this file with a reason and a date.

Section 0 lists decisions that were previously *inherited constraints* from Omarchy. Now that MonARCH is independent, they are genuine choices — recorded with reasoning rather than assumed.

---

## 0. Architecture

| # | Decision | Rationale |
|---|---|---|
| 1 | **Independent repo on Arch**, not a fork of Omarchy | Nearly everything planned is new code. A fork bought a config set and a theme engine — roughly a week's porting — in exchange for permanent coupling to a project with the opposite philosophy |
| 2 | Omarchy credited as inspiration; MIT notice retained on any file copied substantially verbatim | Honest, legally correct, and costs nothing |
| 3 | Never imply endorsement by Omarchy, Basecamp, or DHH | |
| 4 | Compositor: **Hyprland** | Animations, tiling, mature IPC, best-in-class on Intel graphics |
| 5 | Bar: **Waybar** | Standard, scriptable, themeable |
| 6 | Launcher: **Walker** | Fuzzy launch plus clipboard history in one tool |
| 7 | Terminal: **Alacritty** | Fast, light, no Electron. Ghostty/Kitty as optional installs |
| 8 | Login: **greetd + tuigreet** | Lighter than SDDM, matches the RAM goal, less to theme |
| 9 | Filesystem: **Btrfs + Snapper** | Snapshot rollback is the single best safety feature in a rolling release |
| 10 | Bootloader: **Limine** | Integrates with Snapper to give bootable snapshot entries. GRUB works but is heavier |
| 11 | Encryption: **LUKS on by default, optional in the installer** | Security matters, but this is our installer now and forcing it is not required |
| 12 | Shell: **Bash + Starship** | Familiar to the owner; no reason to diverge |
| 13 | GUI toolkit: **Tauri**, never Electron | ~40MB idle vs ~150MB. Uses existing web skills |
| 14 | Install path: `bootstrap.sh` on fresh Arch (Phase 1), own ISO (Phase 3) | This is how Omarchy shipped before it had an ISO. Defers the hardest work |

## 1. Identity

| # | Decision | Rationale |
|---|---|---|
| 15 | Name: **MonARCH**, CLI `monarch` | mon-**ARCH** contains the base OS, and the meaning is the thesis: you rule your machine |
| 16 | License: **MIT** | Matches the ecosystem, keeps redistribution simple |

## 2. System

| # | Decision | Rationale |
|---|---|---|
| 17 | Editor: **VS Code** | Owner's editor. Configure keyring + disable internal auto-update in favor of pacman |
| 18 | Coding agent: **Claude Code inside Claude Desktop** | Preferred workflow |
| 19 | Browser: **Chromium** ships, Chrome one-click | Chrome's binary is not redistributable |
| 20 | `GDK_SCALE=1` | Target panel is 1920×1080, not retina |
| 21 | **5 workspaces**, `Super+6` adds a 6th on demand | Hyprland creates dynamically, destroys when empty |
| 22 | Bare `Super` tap opens the launcher | `bindr = SUPER, SUPER_L`. Matches Windows muscle memory |
| 23 | Dropdown terminal: **native** special workspace | pyprland would add a persistent Python daemon for something Hyprland does natively |
| 24 | **One master password** (LUKS + user in sync) | `monarch password change` does LUKS first, verifies, then user |
| 25 | **LUKS recovery key mandatory** when encryption is on | One password with no recovery key means total unrecoverable data loss |
| 26 | zram, sized at half physical RAM, zstd | Cheap effective memory |

## 3. Packages

| # | Decision | Rationale |
|---|---|---|
| 27 | We curate our own manifests: `base`, `optional`, `aur` | The main practical benefit of not forking — no inherited bloat |
| 28 | Base stays lean | Compositor stack, terminal, browser, editor, core CLI tools. Everything else optional |
| 29 | Preinstall **Claude Desktop** (AUR) | Repackages Anthropic's official Linux `.deb`. Needs `CLAUDE_USE_WAYLAND=1` and `/dev/kvm` for Cowork |
| 30 | Preinstall **GitHub Desktop** (shiftkey fork) | AUR comments report Hyprland segfaults; runs fine on this setup. Logged as a watch item |
| 31 | Preinstall Git, Spotify, Neovim, `nwg-displays` | |
| 32 | Never bundle Chrome, Spotify, or Typora binaries in an ISO | Not redistributable. Installers only |
| 33 | `.deb` via `debtap`, with warnings; PKGBUILD preferred for our own apps | debtap is unreliable by nature |
| 34 | Windows VM: optional, never preinstalled | ~30GB disk and 4–8GB RAM. Nothing in the workflow needs it |

## 4. Interface

| # | Decision | Rationale |
|---|---|---|
| 35 | **GUI never writes config directly** — always via `monarch` | Prevents GUI and CLI drifting. A settings screen that lies about system state is the Windows 11 failure mode |
| 36 | GUI v1 panels: Keybinds · Theme · Monitors · Startup Apps · Performance | Everything else in Extras, off by default |
| 37 | `keybinds.toml` is the source of truth | Generates bindings, the `Super+K` cheatsheet, and the manual. Docs cannot drift |
| 38 | **Desktop icons: cut** | No Wayland protocol. Every workaround breaks with multi-monitor and scaling |
| 39 | Modes are **config fragments**, not code branches | Adding a mode should require no code |
| 40 | Windows mode: `hyprbars` + `wlr/taskbar` + floating default + bottom bar | Minimize = move to `special:minimized`; Hyprland has no true minimize |
| 41 | `hyprbars` **must fail gracefully** | Compiles against a pinned Hyprland version. Updates will break it. Fall back to tiling, never a broken session |
| 42 | Theme schema: `colors.toml` → generated app configs | Borrowed from Omarchy because it is genuinely the right design |
| 43 | Ship our own theme set, Vantablack-style dark default | Omarchy's themes are MIT and portable, but we curate rather than take wholesale |
| 44 | Build our own theme creator (Phase 4) | Omarchy's Aether is not ours to ship. Not v1 |
| 45 | Display panel must reach **Linux Mint parity** | Arrange, resolution, refresh, orientation, per-monitor scale, primary, mirror. Mixed 141/92 PPI makes per-monitor scaling first-class |
| 46 | First-run wizard asks mode **twice** | "Use now" and "default from now on" are separate questions |
| 47 | macOS theme cut from v1 | Marketing idea for later |

## 5. Distribution

| # | Decision | Rationale |
|---|---|---|
| 48 | **Slim online-install ISO** | GitHub caps release assets at 2GB. Dropping an offline mirror fits under it and costs nothing to host |
| 49 | ISO published via GitHub Releases on tag push | Zero hosting cost |
| 50 | Channels: `stable` (master) + `dev` | Owner runs `dev` so untested changes never ship twice |
| 51 | Update polling max once per 30 min, cached | Unauthenticated GitHub API allows 60 requests/hour/IP |
| 52 | **Snapshot before every update**, never optional | A rolling release plus an unattended update equals an unbootable laptop |

## 6. Process

| # | Decision | Rationale |
|---|---|---|
| 53 | Test loop: **VM primary**, USB for hardware validation, internal NVMe at Phase 3 | 32GB RAM makes VMs nearly free. A VM can't validate suspend, dock, audio, or battery |
| 54 | Never wipe the internal drive before Phase 3 | The current install is the fallback |
| 55 | Every behavior change ships a migration | The only way to update existing installs without clobbering user edits |
| 56 | Sonnet for mechanical tasks, Opus for design tasks | Most tasks are transcription. See `04-TASKS.md` |
| 57 | EdgeHop ships as a MonARCH feature | Windows↔Linux input sharing. A genuine differentiator |
