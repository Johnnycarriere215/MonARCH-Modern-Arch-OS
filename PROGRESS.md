# PROGRESS

**The single source of truth for where this build is.**
Read at the start of every session. Updated at the end of every session.

Status values: `TODO` · `IN PROGRESS` · `PARTIAL` · `DONE` · `BLOCKED`

---

## Current state

**Phase:** 2 complete — Phase 3 next, after the VM test and a week of living in it
**Next task:** T9 — Settings GUI (Phase 3)
**Blocked on:** the VM, now genuinely. **Phase 2 is complete and none of T1–T8 has ever been run on Arch.** The task list says *stop here and live in it for a week* before Phase 3 — that week cannot start until the desktop boots. T7 also has one criterion that is untestable any other way: rolling back a deliberately broken update from a snapshot. The VM test (Phase 0.4/0.5, full procedure in `docs/07-VM-TESTING.md`) is overdue and gets more expensive to defer with every task.

---

## Phase 0 — Baseline (human only, no AI)

| | Task | Status |
|---|---|---|
| 0.1 | Back up `~` to external media | TODO |
| 0.2 | BIOS: Secure Boot off, TPM off, VT-x on, VT-d on | TODO |
| 0.3 | GitHub repo `monarch` created, starter committed, MIT `LICENSE` added | DONE — pushed to `main` 2026-07-31, so the raw-URL curl path in `bootstrap.sh` works |
| 0.4 | Arch VM built — 12GB RAM, 4 CPUs, 80GB disk, UEFI/OVMF, virtio + 3D accel, **Btrfs root** | TODO |
| 0.5 | VM snapshot `clean-arch` taken **right after base Arch install, before MonARCH** | TODO |
| 0.6 | USB drive identified (`lsblk -o NAME,MODEL,TRAN,SIZE,ROTA` with it plugged in) | TODO |

**Phase 0 must be complete before T1.** T1's output is untestable without a clean Arch VM to run it on.

---

## Phase 1 — A bootable desktop

### T1 — Bootstrap + package manifests · Sonnet
**Status:** DONE (code complete, locally verified — **awaiting first run on Arch**)

**Done when:**
- [x] `packages/base.packages`, `optional.packages`, `aur.packages` exist — 68 / 21 / 5 packages, all parse clean
- [x] `bootstrap.sh` refuses to run as root and guards on Arch / x86_64 / Btrfs / UEFI with a clear message naming what failed — verified: on this Mint box it exits `This is not Arch Linux (/etc/os-release ID='linuxmint')`
- [x] `install/10-preflight.sh` … `50-finish.sh` exist and are sourced in order — globbed and `sort -V`'d, not hardcoded
- [x] `bin/monarch` dispatcher works; bare `monarch` prints grouped help discovered by scanning `bin/` — grouping verified against simulated `theme-*` / `keys-*` / `mode-*` commands
- [x] `bin/monarch-doctor` and `bin/monarch-version` run — doctor degrades every probe to `n/a` on a non-Arch box
- [x] Root `version` file contains `0.1.0-dev`
- [~] **Running `bootstrap.sh` twice in a row does not break anything** — stage 30 proven idempotent over 3 runs against a fake `HOME`; stages 10/20/40 are idempotent by construction but **need the VM to confirm**
- [x] All output logged to `/var/log/monarch-install.log` — appends, never truncates, so a re-run keeps the first run's history

**Notes:**

- **`walker` is not in the official repos.** The T1 spec lists it under the compositor stack in `base.packages`; it is actually `walker-bin` in the AUR, so that is where it lives. `base.packages` carries a comment pointing at it. If it should be built from source instead, that is a one-line change.
- **`hyprbars` is deliberately not in `aur.packages`** — it is a hyprpm plugin, not an AUR package. T6 owns installing it and its fallback-to-tiling behaviour.
- **greetd is enabled but not started** (`systemctl enable`, no `--now`). Starting it would kill the TTY session running the installer. It takes over on the next boot.
- **multilib is left alone.** `steam` in `optional.packages` needs it; enabling it is a user decision, not an installer's.
- **`ufw` opens SSH automatically if `$SSH_CONNECTION` is set**, otherwise a remote install would cut itself off at stage 40.
- **Snapper failure is non-fatal.** A pre-existing `/.snapshots` subvolume is the usual cause; the install warns and continues, since a system without snapshots still boots.
- Every `monarch-*` script advertises itself to the dispatcher with a `#DESC:` line on line 2. **New commands must carry one** or they show up in help as `-`.
- `bootstrap.sh` detects being run from an existing checkout and skips the clone, so local edits can be tested in the VM without pushing first.
- `config/` is still empty — T2 fills it. `install/30-config.sh` already deploys whatever is there and backs up user-edited files to `.bak`.

---

### T2 — Base config set · Sonnet
**Status:** DONE (code complete, locally verified — **the VM test has not been run**)

**Done when:**
- [x] `config/hypr/hyprland.conf` sources monitors, input, looknfeel, windows, autostart, bindings, monarch — all 7, plus the theme colours first; every sourced path verified to exist
- [x] `GDK_SCALE=1` set (target panel is 1080p, not retina) — `config/hypr/monarch.conf`
- [x] 5 workspaces configured; a 6th is created dynamically — 1–5 `persistent:true`, 6 deliberately not, so Hyprland destroys it with its last window
- [x] Dropdown terminal on a native special workspace — **not** pyprland — `workspace = special:dropdown, on-created-empty:...`
- [x] Waybar and Alacritty configs exist, no hardcoded colors anywhere — checked mechanically: zero hex outside `config/monarch/theme/`, and every `$var` / `@color` referenced resolves to a definition
- [x] `bin/monarch-config-apply` is idempotent and backs up user-modified files to `.bak` rather than overwriting — all four cases exercised against a fake `HOME`
- [ ] **The VM boots to a Hyprland desktop, logs in, and opens a terminal** — **NOT VERIFIED.** Needs Phase 0.4/0.5. This is the one that counts.

**Notes:**

- **The theme contract, which T3 must honour.** Configs carry no colours. Three generated files under `~/.config/monarch/theme/` hold the palette — `hypr-colors.conf` (`$bg`, `$accent`, …), `waybar-colors.css` (`@define-color`), `alacritty-colors.toml`. `monarch theme apply` rewrites those three and nothing else. The checked-in defaults are the original "midnight" palette; T3 replaces them with real themes.
- **`config/.seed-only` is new.** Paths listed there are installed once and never touched again — your settings, your monitor layout, and anything another command generates. Without it, `monarch config apply` on update would undo `monarch theme apply`. **T3 and T4 must add nothing to `config/` that they also generate without listing it here.**
- **Autostart is split in two.** `autostart.conf` = essentials, stays MonARCH's, keeps receiving updates. `autostart-user.conf` = your apps, seed-only, holds the `>>> monarch startup apps >>>` managed block. They were one file until it became clear that mixing them means one `monarch startup add` freezes the essentials forever.
- **`bindings.conf` is a hand-written placeholder** and is marked seed-only. T4 replaces it from `schema/keybinds.toml`. **T4 must stamp the generated file and will need to overwrite the placeholder once** — a plain `config apply` will not do it, since seed-only means "never overwrite".
- **`Super+/` for the keybind list is commented out** in `bindings.conf`. T4 uncomments it once `monarch keys list` exists; binding a key to a missing command now would give a key that silently does nothing.
- **Two files beyond the spec:** `hypridle.conf` and `hyprlock.conf`. `autostart.conf` launches hypridle, and hypridle with no config exits immediately; hyprlock with no config locks to a black screen with no password field, which is indistinguishable from a hang.
- **Pango markup cannot use theme colours.** The Waybar calendar and the hyprlock placeholder text are styled with weight/underline only. Any hex there would be a colour the theme engine could never reach.
- **Alacritty's `import` moved under `[general]` in 0.14.** If a future Arch downgrade lands on 0.13, colours silently fall back to defaults — that is the first thing to check.
- `install/30-config.sh` now shells out to `monarch-config-apply` rather than deploying itself, so the installer and a later update take the identical path (golden rule 1). `deploy_user_file` in `install/_common.sh` was removed as dead code.
- **`bin/_lib.sh` and `bin/_startup-lib.sh` are shared libraries, not commands** — the leading underscore keeps them out of the dispatcher's scan and out of the `~/.local/bin` symlinks. The three T1 scripts still carry their own copy of the symlink-resolve preamble and should adopt `_lib.sh` in a later pass.

> **T1 + T2 = the milestone that matters.** `curl … | bash` on a clean Arch VM produces a working desktop. Verify on real hardware next (USB boot, check `GDK_SCALE`) before moving on.

---

## Phase 2 — The system layer

### T3 — Theme engine · Opus
**Status:** DONE (code complete, locally verified — **awaiting first run on Arch**)

**Done when:**
- [x] `schema/theme.toml` documented, with an inline comment crediting Omarchy's schema as the inspiration — the file is both the documentation and the defaults every theme merges onto
- [~] `monarch-theme-apply <name>` restyles Hyprland, Hyprlock, Waybar, Alacritty, Mako, Walker, btop, VS Code in one command — all eight render and write; **Walker and VS Code cannot be confirmed until the VM test**, see notes
- [x] Templates live in `themes/_templates/`, one file per app — eight templates (VS Code needs two, which is VS Code's shape, not the engine's)
- [x] Adding a new app to the theme system = adding one template file, nothing else — the target and reload command are declared *in* the template's `#!` header; no registry, no code path names an application
- [x] Three themes ship with **original** palettes — `midnight` (near-black, violet/brass), `parchment` (warm light, indigo), `harbor` (mid-contrast slate, teal/amber). Written for this project
- [x] **No wallpaper files committed without a recorded licence** — originally shipped none; a later session added three per theme, generated from each palette by `brand/wallpapers/generate.py`, licence recorded as MIT (ours) in each `backgrounds/README.md`. The locked rule is honoured, not the stricter no-images reading

**Notes:**

- **The theme contract is honoured and extended.** T2's three files (`hypr-colors.conf`, `waybar-colors.css`, `alacritty-colors.toml`) are still the only colours Hyprland/Waybar/Alacritty see, and every `$var` and `@color` those configs reference was checked mechanically against the rendered output. `theme apply` now also writes four more: `mako/config`, `walker/themes/monarch.css`, `btop/themes/monarch.theme`, and a generated VS Code extension under `~/.vscode/extensions/monarch-theme/`. Zero hex outside them — verified by grep over all of `config/`.
- **The shipped palette files are gone from `config/`.** `config/monarch/theme/*` was three hand-written files that duplicated what the engine now generates, and duplicates drift. `install/30-config.sh` gained `stage_30_apply_theme`, which renders them right after the config deploy. **It is fatal on failure by design** — `hyprland.conf` sources `hypr-colors.conf`, so no palette means no session, and the install should stop where the reason is still on screen. The `monarch/theme/*` entry in `.seed-only` is kept as a guard with a comment saying it matches nothing today.
- **`migrations/1785505659.sh` ships with this task** (golden rule 5). Almost certainly a permanent no-op — nothing has ever been installed from this repo — but a pre-T3 checkout would have stale hand-written palette files that seed-only protects from being replaced, and this is the explicit trigger. T7's `monarch migrate` will run it.
- **Mako owns its whole config, and that is not a mistake.** Mako has no include directive — there is no colours-only file to hand it. So `themes/_templates/mako.conf` carries layout keys (width, margin, font) as well as colours. Nothing else in MonARCH writes `mako/config`, so there is nothing to conflict with. Same shape of problem, different answer, for btop and Walker: they get a *named* theme file (`monarch.theme` / `monarch.css`) and a one-line config in `config/` pinning that name, so apply only ever rewrites contents.
- **Walker theming is unverified and is the likeliest thing here to be wrong.** `walker-bin` has never been installed — the VM test has not been run — and Walker's config layout moved during its 0.x releases. `config/walker/config.toml` assumes `theme = "monarch"` and themes at `~/.config/walker/themes/<name>.css`. Both that file and the template say so in comments. **If the launcher comes up unstyled or refuses to start, delete `config/walker/config.toml` — that gets an unstyled but working launcher.**
- **VS Code gets a generated extension, not a settings.json edit.** The only other way in is `workbench.colorCustomizations`, which means merging JSON, which means a JSON parser, which golden rule 6 rules out. So `theme apply` writes a minimal real extension always called "MonARCH" whose palette changes underneath it. **Setting `workbench.colorTheme` is left to T8's VS Code installer**, which already has to edit `settings.json`; until then it is one manual pick. `meta.vscode_ui` in the schema is the one place an app name appears there — templates have no logic, so a light theme cannot derive `"vs"` from `light = true`.
- **Semantic roles are the interface T5 should use.** `sem.urgent/warning/ok/info/muted` are aliases (`@term.red` and so on) resolved after the theme merges, so a theme can make "urgent" orange without touching a module. They land as `$urgent`/`@urgent` in the Hyprland and Waybar palettes. **T5's system-stat modules should reach for those, never for `@red`.**
- **`hyprpaper` is new in `base.packages`** and in `autostart.conf`. There was no wallpaper daemon at all before this. `~/.config/hypr/hyprpaper.conf` is generated by `monarch background set`, which also swaps the image live over hyprpaper's IPC rather than restarting it. With no wallpaper set — the shipped state — hyprpaper sits running with nothing loaded.
- **`config/btop/btop.conf` is seed-only** because btop rewrites its own config on exit, filling in every default it did not find. MonARCH ships it only to pin `color_theme = "monarch"`; an update that reset it would throw away everything btop had written since.
- **Rendering is all-or-nothing.** Every template is rendered into memory before any file is written, and an unknown key or filter aborts the whole apply. A desktop styled by the old theme is recoverable; one styled half by each is not. `theme install` renders every template as part of validation, so a theme that satisfies the schema but breaks a template is caught before it is installed rather than at apply time.
- **`monarch theme remove` refuses to delete a shipped theme** and tells you to shadow it instead — a user theme of the same name in `~/.config/monarch/themes` wins over the repo's. Deleting one in the repo would just come back on the next update.
- **T4 should bind these.** `monarch background next` and theme switching have no keybinds; `bindings.conf` is still the seed-only placeholder. Worth a `Super+Shift+W` or similar when the keybind generator lands.
- **The palettes are mine, not the human's.** The open item "three theme palettes — your own colors" is still open: these are original and defensible, but they are a starting point. Replacing one is editing `themes/<name>/colors.toml` and running `monarch theme apply` — no other file is involved.

---

### T4 — Keybinds · Sonnet
**Status:** DONE (code complete, locally verified — **awaiting first run on Arch**)

**Done when:**
- [x] `schema/keybinds.toml` covers windows, workspaces 1–6, app launches, system, clipboard, dropdown terminal — 65 bindings across 9 groups, plus screenshot, media and appearance
- [x] `bindr = SUPER, SUPER_L` → Walker (bare Super tap opens the launcher) — `flags = "r"`, marked `editable = false`
- [x] `monarch-keys-apply` writes `bindings.conf` with a `# GENERATED BY MONARCH — DO NOT EDIT` header
- [x] `monarch-keys-check` catches duplicates and builtin shadowing; `-apply` refuses to write on conflict — verified: apply exits 1 and writes nothing
- [~] `monarch-keys-list` output is what **`Super+/`** shows — not `Super+K`, see notes
- [x] TOML parsed inline in bash — no Python or Rust dependency — arrays-of-tables parser in `bin/_keys-lib.sh`

**Notes:**

- **`Super+/`, not `Super+K`.** This criterion said `Super+K`, but `Super+K` is focus-up in the hjkl set that T2 shipped and that the placeholder had bound for two tasks. Rebinding a vim direction key to a help screen is the kind of change that annoys you on day three. `Super+/` is what T2's own note reserved and what the placeholder had commented out awaiting this task, so that is what it is. **Say if you want `Super+K` instead** — it is one line in `schema/keybinds.toml`.
- **The placeholder is gone, not overwritten.** T2 warned that seed-only means `config apply` would never replace `config/hypr/bindings.conf`. Rather than special-case it, the file is deleted from the repo and `install/30-config.sh` gained `stage_30_apply_keys` — identical arrangement to T3's palette, for the identical reason: one producer, no shipped copy to drift from it. Fatal on failure, because `hyprland.conf` sources `bindings.conf` and a session you cannot open a terminal in is not a session.
- **`migrations/1785529604.sh` ships with this task** (golden rule 5). It keeps any pre-T4 `bindings.conf` as `bindings.conf.pre-t4` before regenerating — that file was hand-written, so if the user edited it those edits are the only record of what they wanted.
- **A second TOML parser, deliberately.** `keybinds_load` in `bin/_keys-lib.sh` is separate from the theme engine's `toml_load` because arrays-of-tables need to know when a record ends, and flattening `bind.id` into one namespace loses the 65 records. Quoted values are taken to the *last* quote on the line so `grim -g "$(slurp)"` survives; the theme parser takes the first, since a colour never contains one.
- **New fields beyond the task's schema:** `args` (a Hyprland dispatcher's argument, kept separate from `action` so the GUI can show "movefocus" and "l" apart) and `flags` (letters appended to `bind` — `r` release, `e` repeat, `l` while-locked, `m` mouse). Without `flags` there is no way to express `bindr`, which the locked Super-tap decision requires.
- **`[vars]` is emitted as `$mod`/`$term`/`$browser`/`$files`/`$editor`.** Changing your terminal is one line, not six. `bind_line` rewrites a leading `SUPER` back to `$mod` on the way out, so the generated file stays readable.
- **`monarch keys list --porcelain`** is tab-separated: id, keys, label, group, dispatcher, action, args, editable, flags. **T9's keybind panel should use this** rather than parsing the pretty output or reading the TOML itself.
- **`editable = false` on two bindings only:** the bare-Super launcher (the key *is* the feature) and `Super+Shift+R` reload Hyprland (the way back from a bad config, including a bad keymap).
- **Reserved-combination checking is thin, and that is honest.** Hyprland has no built-in keymap — an unconfigured session has no bindings at all — so there is nothing of its own to shadow. What `keys check` knows about is the layers underneath: `Ctrl+Alt+F1..F12` (kernel VT switch) and `Ctrl+Alt+Backspace`. If something else turns out to be swallowed on real hardware, `reserved_reason` in `monarch-keys-check` is the one function to add it to.
- **`cliphist` is new in `base.packages`**, with two `wl-paste --watch` lines in `autostart.conf` — text and images are separate Wayland selections and need a watcher each. `Super+X` pipes the history through Walker.
- **Two bindings reference commands that do not exist yet:** `Super+Shift+W` → `monarch background next` (T3, exists) is fine, but the dropdown terminal depends on `monarch.conf`'s special workspace and the clipboard bindings depend on cliphist actually installing. Both are first-boot checks.

---

### T5 — Waybar system stats · Sonnet
**Status:** DONE (code complete, locally verified — **awaiting first run on Arch**)

**Done when:**
- [x] CPU, RAM, GPU, network, disk modules exist — `config/waybar/modules-system.jsonc`
- [x] Poll intervals: 5s CPU/RAM, 10s net, 60s disk — no faster; GPU is 10s because it is the only one that forks
- [x] GPU module degrades gracefully when `intel_gpu_top` is absent — three tiers, and **the fallback tier was exercised on this Intel laptop**, which is the one thing in T3–T5 that has run on real Intel hardware
- [x] Colors read from the active theme, nothing hardcoded — and they are the **semantic** names (`@warning`, `@urgent`), not `@yellow`/`@red`
- [x] `monarch-bar-modules` enables/disables individual modules — plus `order`, `reset`, `--performance` / `--standard`
- [~] Total added idle CPU under 1% on an i7-8665U — **estimated at ~0.2%**, with a per-module table in `modules-system.jsonc`. Estimated, not measured: that needs the VM or the metal

**Notes:**

- **Waybar's `include` is the seam.** `config.jsonc` no longer defines `modules-right` at all. It includes two files: `modules-active.jsonc` (a symlink to whichever definitions variant is in use) and `modules-enabled.jsonc` (generated — the list and its order). **Waybar's own config takes precedence over an include**, so leaving `modules-right` in `config.jsonc` would have made the generated file silently do nothing. There is a comment in `config.jsonc` saying so, because that bug would be invisible.
- **The variant switch is a symlink, not a copy**, and it points into `~/.config/waybar/`, **not into the repo**. A link to the repo would bypass the deployed copy, so a file the user had edited would have no effect — exactly the surprise `monarch-config-apply` exists to prevent. It falls back to the repo copy only during a first install, before `config apply` has run.
- **`bar_modules` in `settings.toml` must stay on one line.** It is the only array MonARCH rewrites in place, and a single-line array is something `awk` can replace without a TOML writer. The comment above it says this; reformatting it across several lines breaks `monarch bar modules`.
- **`monarch-bar-gpu` deliberately does not source `_lib.sh`** and does not walk symlinks. It forks every 10 seconds, and sourcing a library to print one line of JSON would roughly double the cost of the only module that costs anything. It is the one command with that exemption, and it says so in the file.
- **The GPU number is a proxy unless `intel-gpu-tools` is installed.** There is no i915 equivalent of amdgpu's `gpu_busy_percent`, so the fallback reports `gt_cur_freq_mhz` over `gt_max_freq_mhz` — clock speed, not utilisation. The tooltip says so in as many words. `intel-gpu-tools` is in `optional.packages`; even installed, `intel_gpu_top` needs `CAP_PERFMON` or `perf_event_paranoid <= 1`, so the fallback may still be what you see.
- **Deliberately never coloured by state:** network throughput (high throughput is what a network is for) and the GPU's frequency-fallback reading (a GPU parked at maximum clock is not a problem, and colouring it red would train you to ignore the colour).
- **Disk's thresholds are inverted on purpose.** It reports FREE space, so `warning: 85` fires as the number falls. Both `modules-system.jsonc` and `style.css` carry a comment saying not to "fix" them to match CPU and memory.
- **btop preset indices are a contract between two files.** `config/btop/btop.conf` defines `presets = "cpu,mem,net,proc"` and the `on-click` handlers in `modules-system.jsonc` call `btop -p 0|1|2`. Change one, change the other. Disk clicks through to the mem preset because btop draws disks inside the memory box.
- **The performance variant is `config/waybar/modules-system-performance.jsonc`** — CPU and RAM only, both at 10s, nothing forking. **T6 should point performance mode's `waybar-overrides.jsonc` at it** rather than writing a third copy; until then it is `monarch bar modules --performance` by hand.
- **`monarch bar modules` restarts Waybar rather than reloading it.** `SIGUSR2` re-reads the config but the widgets are built at start-up, so a changed module *list* needs a restart. That is why this is not a thing to call in a loop.
- **No allowlist of module names.** `enable custom/weather` works and writes it straight through. Waybar ignores a placed module it has no definition for, so the cost of being wrong is a missing widget, not a broken bar — and the alternative is a list to maintain every time Waybar gains a module.
- **`migrations/1785531465.sh` ships with this task** (golden rule 5). `settings.toml` is seed-only, so `bar_modules` would never arrive on an existing install; the migration appends it and generates the list. It checks first and leaves a customised bar alone.

---

### T6 — Mode system · Opus
**Status:** DONE (code complete, locally verified — **awaiting first run on Arch**)

**Done when:**
- [x] `modes/{tiling,windows,performance}/` each have `hypr.conf`, `waybar-overrides.jsonc`, `meta.toml`
- [x] `monarch-mode-set` persists and survives reboot — writes `mode.conf` and `mode = ` in `settings.toml`
- [x] `monarch-mode-session` applies for one session **without** changing the saved default — cleared at next login by `monarch mode session-end`, which `autostart.conf` runs
- [x] Windows mode gives title bars, close buttons, floating default, bottom bar, taskbar
- [x] Minimize = `movetoworkspacesilent special:minimized`, restore via `wlr/taskbar`
- [x] **`hyprbars` failure falls back to tiling with a clear warning** — exercised: with no `hyprpm` on this box, `mode set windows` warns, explains the pinned-version problem, lands in tiling and exits 1
- [x] No `if mode == ...` anywhere. Modes are data — no script names a mode. One near-miss: `current_variant` in `monarch-bar-modules` matches `*performance*`, but that is T5's **bar variant** filename, not a mode; the two happen to share a word

**Notes:**

- **The merge is Hyprland's, not ours.** `hyprland.conf` sources `mode.conf` and `mode-session.conf` LAST, and a later assignment overrides an earlier one. So a fragment states only its deltas, and switching modes is only changing which file gets sourced. **There is no undo step and no diffing** — `hyprctl reload` re-parses the whole config from defaults, so leaving a mode is enough to leave its settings behind. Window rules are cleared and rebuilt on reload for the same reason.
- **`modes/tiling/hypr.conf` is deliberately empty**, and the comment in it is the argument for the whole design. The base config *is* tiling mode. My first draft restated the blur/animation/gap settings there as "restore" lines and added `windowrulev2 = tile, class:^(.*)$` — **that rule would have clobbered the dialog float rules in `windows.conf`**, since it is sourced later. Both were wrong; the file being empty is right.
- **Two overlay files, not one.** `mode.conf` = saved, `mode-session.conf` = this session. The session file cannot be removed before Hyprland parses it — nothing runs that early — so `monarch mode session-end` runs from `autostart.conf`, clears it and reloads *only if there was something to clear*. A session mode set yesterday is on screen for about a second today, then goes. That second is the honest cost of the design.
- **`hyprland.conf` sources `mode-session.conf` unconditionally**, so `monarch mode set` creates an empty one when it is missing. **This was a real bug found in testing:** a fresh install had no `mode-session.conf` at all, and on some Hyprland versions a missing `source` is a parse error — which would have meant a desktop that does not come up.
- **Waybar: `config.jsonc` no longer defines `position`, `height`, `modules-left` or `modules-center`.** Waybar's own config takes precedence over an include, so a mode could never have overridden them. They live only in `modes/<name>/waybar-overrides.jsonc` now. This is the same trap T5 hit with `modules-right` and the second time it has bitten — the comment in `config.jsonc` names all five keys.
- **`requires` and `fallback` are data, and that is what keeps golden rule 4.** `mode_ensure_plugins` iterates `requires` and hands each name to `hyprpm`; it does not know what hyprbars is, only that windows mode asks for it and names tiling as where to go if it cannot have it. Adding a plugin-dependent mode is adding a directory.
- **`mode set` verifies the plugin actually loaded, and this matters more than it looks.** Hyprland keeps configuration for plugins that are not loaded rather than erroring, so the `plugin { hyprbars { … } }` block in windows mode is silently inert on failure. Without the check you would get floating windows with no title bars and no explanation — worse than either mode.
- **`mode session` does not fall back**, unlike `mode set`. Nothing has been written at that point, so doing nothing leaves the desktop as it was, which for a temporary change is clearer than silently landing in a third mode.
- **`monarch mode cycle` (SUPER+SHIFT+D) skips modes it cannot apply.** With hyprbars broken, cycling goes tiling → performance → tiling rather than appearing to do nothing. Session-only on purpose: a key you can hit by accident should not change what the machine boots into.
- **`modes/` is read from the repo**, with `~/.config/monarch/modes/<name>/` shadowing — the same arrangement as `themes/`, and unlike `config/`, which is deployed. That is why `mode.conf` contains an absolute path into the checkout.
- **The performance mode's savings are honestly ranked in its `meta.toml`:** blur is most of it on UHD 620, shadows and rounding are a little, and turning animations off saves almost nothing — it is in there because a struggling machine *feels* faster without them.
- **`migrations/1785533308.sh` ships with this task, and is the first FATAL migration.** Every other one warns and continues. This one creates the two files `hyprland.conf` now sources unconditionally; without them an updated machine gets a Hyprland that cannot parse its config, which is a blank screen rather than a degraded desktop.
- **`exec-once = hyprpm reload -n` is new in `autostart.conf`.** Plugins do not survive a Hyprland update and need reloading each session.

### T7 — Update system · Sonnet
**Status:** DONE (code complete, locally verified — **awaiting first run on Arch**)

**Done when:**
- [x] `monarch-update-check` caches for 30 min and **never polls GitHub more than once per 30 min** — the bar module's own interval is also 1800s, so even a restart loop cannot exceed it
- [x] Network failure is silent — never blocks the bar. `--max-time 8`, no `set -e`, and a failed probe leaves the old cache rather than replacing it
- [x] Waybar shows an update icon; click runs `monarch update` — `custom/update`, empty output when up to date so Waybar hides it entirely
- [x] `monarch-update` snapshots **first**, always, before anything else — with `--required`, so no snapshot means no update
- [x] `hyprpm update` failure warns but does not abort the update
- [x] `monarch-channel-set stable|dev` works
- [x] `monarch-migrate` runs each migration once, tracked in state — verified: a deliberately failing migration stops the run, is **not** marked done, and the one after it does not run
- [ ] **A deliberately broken update has been rolled back from a snapshot, by hand, successfully** — **NOT VERIFIED.** Needs the VM. This is T7's equivalent of T2's "the desktop boots"

**Notes:**

- **The rate limit is the design, not a detail.** Unauthenticated GitHub is 60 requests/hour/IP, shared by everyone behind the same NAT. The bar reads a cache; only the cache talks to GitHub, at most twice an hour. Polling the module faster does not make the answer fresher — it forks bash more often for the same cached string. The 1800s in both places is a floor.
- **Step order is load-bearing and commented in the file.** Snapshot before pull (a snapshot of a half-updated machine is worthless); migrations after pacman (one may need a package the update brings in); hyprpm after pacman (it compiles against the Hyprland pacman just installed); config apply last.
- **A dirty checkout skips the git pull and says so**, rather than letting `git pull` fail with its own message or clobbering local edits. The rest of the update continues.
- **`monarch migrate --mark-all-run` is what a fresh install uses**, wired into `install/30-config.sh`. A fresh install already has everything a migration would produce, and some migrations would undo what the install stages just did. On a re-run it is a no-op.
- **A failed migration is not recorded as run**, so it is retried on the next update — which is why every migration is written to be idempotent. The run stops at the first failure because a later one may assume it succeeded.
- **`monarch snapshot restore` uses `snapper rollback`, which takes effect at the NEXT BOOT** and does not touch the running system. It says so loudly and asks you to retype the number. **The recommended route is the Limine boot menu**, which lets you look at a snapshot before committing. Home is a separate subvolume and is not rolled back — usually what you want after a bad update, and a nasty surprise otherwise.
- **Known flaw, low priority: on the `dev` channel, being AHEAD of the remote reads as "update available."** The check compares remote HEAD to local HEAD for inequality, not ancestry. It only affects someone committing to their own checkout — which is me, while building this.
- **`--monarch-only` exists for the case the dirty-checkout path points at:** commit, then update MonARCH and its migrations without a full `pacman -Syu`.

### T8 — Packages + app installers · Sonnet
**Status:** DONE (code complete, locally verified — **awaiting first run on Arch**)

**Done when:**
- [x] `monarch-install-claude-desktop` sets `CLAUDE_USE_WAYLAND=1` and warns clearly if `/dev/kvm` is missing — it **verifies** rather than sets the env var, see notes
- [x] `monarch-install-chrome` works and Chrome is **never** bundled in the ISO
- [x] VS Code installer configures gnome-libsecret and disables internal auto-update in favor of pacman — and sets `workbench.colorTheme`, which T3 could not
- [x] `monarch-app-install` handles `.pkg.tar.zst`, `.AppImage`, and `.deb` (debtap, with a loud best-effort warning)
- [x] `monarch-webapp-add` generates a working `.desktop` entry and icon — verified against a fake `HOME`; each web app gets its own `--user-data-dir`

**Notes:**

- **`CLAUDE_USE_WAYLAND=1` is verified, not set.** It already lives in `config/hypr/monarch.conf`, so it applies to everything the session launches rather than only to a terminal launch. The installer checks it is there and tells you to run `monarch config apply` if not. Two places setting the same variable is how they end up disagreeing.
- **`/dev/kvm` gets its own check with three named causes** (BIOS VT-x, nested virt, `kvm_intel` not loaded) because Cowork fails *silently* without it — no error, the features simply are not there. The install continues after the warning; a Claude Desktop without Cowork is still worth having.
- **T3's loose end is closed here.** The theme engine generates a VS Code extension but could not select it — that needs `settings.json`, which needs a JSON parser to merge safely. This installer already has to edit that file, so it adds `workbench.colorTheme = "MonARCH"`. The `add_setting` helper is deliberately conservative: it adds a key only when the key is **absent entirely**, never changes one you set, and backs the file up first.
- **AUR installs are not `--noconfirm`.** An AUR build shows you a PKGBUILD for a reason, and an installer that hides it installs whatever the AUR happened to contain today. `monarch update` uses `--noconfirm` for *upgrades* of already-trusted packages; first installs ask.
- **`monarch pkg drop` refuses to remove anything in `packages/base.packages`** and says to edit the manifest first. Otherwise the next update reinstalls it and the removal looks like it silently failed.
- **The `.deb` warning is three paragraphs and a confirm prompt on purpose.** debtap rewrites metadata; it cannot rewrite a binary built against Debian's library versions. The failure mode people hit is a package that installs cleanly and segfaults — so the warning names that outcome and points at `monarch pkg search` first.
- **AppImages are explicitly untracked**, and the command says so after installing one: nothing upgrades it, `monarch update` will never touch it. It also checks for FUSE, whose absence produces a `dlopen(): libfuse.so.2` error that says nothing useful.
- **Web apps get `--class=monarch-webapp-<slug>`**, so Hyprland window rules can target one like any other application — a per-webapp workspace or float rule is a line in `windows.conf`. Icons come from Google's favicon service, which handles sites that put theirs somewhere non-standard; a generic icon is the fallback and is not an error.
- **`monarch webapp remove` keeps the browser profile unless `--purge`.** Re-adding leaves you signed in, which is usually what is wanted.
- **`install/45-branding.sh` is a new stage** (between services and finish) and makes the system say MonARCH rather than Arch Linux: `/etc/os-release`, `/etc/issue` on every TTY, the tuigreet greeting, and a fastfetch config pointed at `brand/monarch.ascii`. All of it reads that one file, so changing the art and re-running the stage updates every surface. Migration `1786226624` applies it to an existing install.
- **`/etc/os-release` gets `ID=monarch` and `ID_LIKE=arch`, and the `ID_LIKE` is load-bearing.** `bootstrap.sh`'s guard already accepted `ID=arch` OR `ID_LIKE` containing arch — a lucky bit of T1 foresight — so a re-run still works, and so does every third-party script that checks for Arch. Stock Arch has `/etc/os-release` as a symlink to `/usr/lib/os-release`; the stage replaces the symlink with a real file, which is how every Arch derivative does it. pacman keeps owning and updating `/usr/lib/os-release`, ours shadows it, and a `filesystem` upgrade may leave a harmless `.pacnew`.
- **The greeting is set in stage 40, not stage 45, and that was a bug fix.** Stage 45 originally `sed`-ed `--greeting "..."` into `config.toml`, which produced nested double quotes inside a double-quoted TOML value — invalid TOML, and greetd with an unparseable config is a machine that boots to **no login screen at all**. It now lives in stage 40's heredoc with single quotes, verified against a real TOML parser and `shlex`; stage 45 only reports on it.
- **tuigreet's greeting is one line** — it renders above the login box and clips multi-line art rather than wrapping. The full wordmark goes to `/etc/issue` instead, which is also the surface you see when greetd has failed, which is exactly when you want to know what machine you are on.
- **The editor is now MonARCH Code, not VS Code** — a locked decision changed by the human, recorded in `MONARCH.md`. `monarch install monarch-code` builds it from source (Rust + Node + Tauri, 10–20 min first time) because the only published artifact is a `.deb`, which on Arch means debtap and a package pacman cannot own. `visual-studio-code-bin` moved from `aur.packages` to `optional.packages`; `monarch install vscode` still works and still sets the theme.
- **MonARCH Code needed a theme bridge.** It searches `~/.config/monarch/themes`, `/usr/share/monarch/themes`, `/usr/local/share/monarch/themes`, `/opt/monarch/themes` — and MonARCH installs to `~/.local/share/monarch`, which is none of them. The installer symlinks `$MONARCH_HOME/themes` → `/usr/share/monarch/themes`, so the three shipped themes are visible and `monarch update` pulling a new one needs no further step. `--link-themes-only` does just that part.
- **No theme template for the editor, deliberately.** It parses `colors.toml` itself in Rust, so it follows `monarch theme apply` natively — unlike VS Code, which needs a generated extension. Adding a template would create a second renderer for the same palette.
- **Flagged for the MonARCH Code repo, not fixed here:** `src-tauri/src/commands/theme.rs` shells out to `monarch theme apply` (correct, golden rule 1) but on failure falls back to rendering `hypr-colors.conf` and `waybar-colors.css` **itself**. That is a second renderer for files `themes/_templates/` owns, and the two will drift. The fallback should report the failure instead of writing.
- **Spotify's PKGBUILD needs a signing key** imported first or the build fails with a gpg error that reads like a broken package. The installer imports it unconditionally — `gpg --import` is idempotent, and checking would mean hardcoding a key id Spotify rotates.

> **Stop here and live in it for a week** before Phase 3. What annoys you that week should reshape the GUI before it's built.

---

## Phase 3 — The GUI layer

### T9 — Settings GUI · Opus
**Status:** TODO

**Done when:**
- [ ] Tauri v2, Rust + HTML/CSS/vanilla JS. No framework. **Not Electron**
- [ ] **The GUI never reads or writes a config file.** Every action shells out to `monarch`
- [ ] Panel 1 (Keybinds) complete: searchable, click-to-rebind, live conflict warning
- [ ] Other four panels stubbed, pattern reviewed by the human before building them
- [ ] Accent color read from the active theme, nothing hardcoded

**Notes:**
_(empty)_

---

### T10 — First-run wizard · Opus
**Status:** TODO

**Done when:**
- [ ] A route in the existing `gui/` app — **not** a second binary
- [ ] Mode step asks **two separate questions**: "use now?" and "default from now on?"
- [ ] **LUKS recovery key step cannot be silently skipped.** Generated, displayed, confirmation required
- [ ] Hardware check covers `/dev/kvm`, battery health, missing firmware
- [ ] Gated on `~/.local/state/monarch/first-run-complete`, re-runnable via `monarch welcome`

**Notes:**
_(empty)_

---

## Phase 4 — The ISO

### T12 — ISO + release CI · Sonnet
**Status:** TODO

**Done when:**
- [ ] archiso profile in `iso/`, slim online-install, **under 1.8GB**
- [ ] Installer reuses `install/` — no duplicated logic
- [ ] Branding art all in `brand/`, swappable without touching code
- [ ] Tag push → Actions builds → ISO + sha256 on the GitHub releases page
- [ ] **CI fails loudly if the ISO exceeds 1.9GB** (GitHub caps release assets at 2GB)
- [ ] Nightly `dev` build reports size only, creates no release

**Notes:**
_(empty)_

---

## Track B — parallel, any time after Phase 1

### T11 — EdgeHop on Wayland · Opus
**Status:** TODO

**Done when:**
- [ ] A written porting plan exists — **no code yet**
- [ ] Confirms whether injection uses `/dev/uinput` (if so, Wayland doesn't care)
- [ ] Recommends `EVIOCGRAB` or libei for capture, with reasoning
- [ ] Addresses edge detection cost against the no-new-daemons rule
- [ ] Covers `wl-clipboard` migration and mixed-PPI multi-monitor behavior

**Notes:**
_(empty)_

---

## Real-hardware checkpoints

These need the EliteBook, not the VM.

| After | Check | Status |
|---|---|---|
| T2 | Boot USB — is `GDK_SCALE=1` right on the 1080p panel? | TODO |
| T2 | Run the full hardware validation checklist in `docs/02-HARDWARE.md` | TODO |
| T3 | Walker and VS Code actually pick up their generated themes — the two the engine cannot verify itself | TODO |
| T6 | Windows mode on metal — `hyprbars` is the fragile piece | TODO |
| T7 | Break an update deliberately, roll back from a snapshot | TODO — **the one unticked criterion in Phase 2** |
| T12 | Install from our own ISO in the VM, before touching the internal NVMe | TODO |

---

## Open items for the human

- [ ] Run `whoami` — the backup command failed because the username was guessed wrong
- [ ] Run `lsblk` with the USB drive **plugged in** (last run showed only the internal NVMe)
- [ ] Fill in the baseline measurement table in `docs/02-HARDWARE.md`
- [x] ~~ASCII crown art → `brand/`~~ — `brand/monarch.ascii`, the bloody-figlet wordmark. The installer prints it, and skips it outside a UTF-8 locale where it would come out as tofu
- [ ] Three theme palettes — your own colors. **T3 shipped originals as a starting point** (`midnight`, `parchment`, `harbor`); replacing one is editing `themes/<name>/colors.toml` and running `monarch theme apply <name>`, nothing else
- [x] ~~Wallpapers~~ — three per theme now ship, generated from the palette (`brand/wallpapers/generate.py`), plus `monarch background pick`. Drop your own in `themes/<name>/backgrounds/` or `~/.config/monarch/backgrounds/`; record a licence before committing any
- [ ] **Never wipe the internal NVMe before Phase 4**

---

## Session log

Append one line per session. Newest at the bottom.

```
DATE | TASK | OUTCOME | NOTES FOR NEXT SESSION
```

```
2026-07-31 | seed + T1 | DONE (unverified on Arch) | Starter tree laid down from monarch-starter(1).zip, LICENSE + .gitignore + version added. bootstrap.sh, 5 install stages, 3 manifests, monarch/-doctor/-version written. Nothing committed — commit and push before testing in the VM, since the raw-URL curl path needs main to exist. Next: T2.
2026-07-31 | T2 | DONE (unverified on Arch) | Full Hyprland/Waybar/Alacritty config set, settings.toml, monarch-config-apply + startup add/list/remove. Established the theme contract T3 must honour and the config/.seed-only mechanism. Phase 1 is now code-complete — the ONLY thing left is running it on a clean Arch VM (Phase 0.4/0.5 first). Do that before T3; a theme engine on top of an unbooted desktop is building on sand.
2026-07-31 | T3 | DONE (unverified on Arch) | Theme engine: schema/theme.toml, 8 self-describing templates, theme apply/list/current/install/remove, background set/next, 3 original palettes, hyprpaper added. Palette files no longer shipped in config/ — install stage 30 renders them. Migration 1785505659 ships with it. NOTE: the previous session said do the VM test before T3 and it still has not happened — three tasks now sit on a desktop that has never booted. Walker and VS Code theming are the two pieces that CANNOT be verified without it. Next: T4 (keybinds), or better, the VM.
2026-07-31 | T4 | DONE (unverified on Arch) | schema/keybinds.toml (65 binds), _keys-lib.sh with an arrays-of-tables TOML parser, keys apply/check/list/reset. Placeholder bindings.conf deleted from the repo — install stage 30 generates it, same as the palette. Migration 1785529604 keeps any pre-T4 copy. Bound the help screen to Super+/ not Super+K, reasons in the T4 notes. cliphist added. Still nothing has booted; docs/07-VM-TESTING.md is the procedure. Next: T5 (Waybar stats) — its notes already say to use the semantic colours.
2026-07-31 | T5 | DONE (unverified on Arch) | Waybar stats: modules-system.jsonc (cpu/memory/custom-gpu/network throughput/disk) wired through Waybar's include, monarch-bar-modules for enable/disable/order/reset/--performance, monarch-bar-gpu with a three-tier degrade. config.jsonc no longer defines modules-right — the generated modules-enabled.jsonc does, because an include cannot override the parent. btop presets pinned so a click drills into the right box. Migration 1785531465. Idle cost ESTIMATED at ~0.2%, not measured. The GPU fallback is the only thing in T3-T5 that has run on real Intel hardware. Next: T6 (modes) — or the VM, which is now five tasks overdue.
2026-07-31 | T6 | DONE (unverified on Arch) | Mode system as a sourced overlay: hyprland.conf sources mode.conf + mode-session.conf last, so Hyprland does the merging and nothing needs undoing. tiling/windows/performance fragments, mode set/session/session-end/current/list/cycle. hyprbars handled generically through requires[]/fallback in meta.toml — verified the fallback fires. Waybar's position/height/left/center moved out of config.jsonc into the mode fragment (the include-precedence trap, second time). Found and fixed a real bug: fresh installs had no mode-session.conf for a file hyprland.conf sources unconditionally. Migration 1785533308 is FATAL on failure, unlike the others. Next: T7 (updates) — and the task list says stop and live in it for a week after T8.
2026-07-31 | T7 + T8 | DONE (unverified on Arch) | Update system: update-check (30-min cache, GitHub 60/hr limit is the whole design), update with the strict 8-step order, snapshot create/list/restore, migrate, channel-set. Waybar custom/update module. Then T8: install-{claude-desktop,chrome,vscode,github-desktop,spotify}, app-install (.pkg.tar.zst/.AppImage/.deb), pkg add/drop/search, webapp add/remove. VS Code installer closes T3's loose end by setting workbench.colorTheme. PHASE 2 IS COMPLETE. Everything from here needs the VM: T7's rollback criterion is untestable without it, and the task list says live in it for a week before T9. Next: build the VM (docs/07-VM-TESTING.md).
```

2026-08-08 | review | 3 bugs fixed | Full bug sweep of the repo. All three were the same root cause — a trailing `&&`/short-circuit as the last command under `set -e`, which turns success into a non-zero exit. (1) `monarch update --dry-run` aborted at step 2/8 on a clean checkout: step_pull ended in `[[ dry ]] && ok`. (2) `monarch mode session <x> --no-reload` exited 1 despite succeeding — main ended in `[[ reload ]] && mode_reload`; matters because the GUI reads exit codes. (3) `monarch theme install <localdir>` (and `--help`) exited 1: the EXIT-trap cleanup ended in `[[ clone ]] && rm`. All now if/fi + return 0. No logic/parser bugs found; the TOML parsers, alias resolution, dispatcher and `$(())` counters are sound.

2026-08-08 | wallpapers | shipped 9 + picker | Three wallpapers per theme (gradient / accent glow / aurora bands), generated from each palette by brand/wallpapers/generate.py (Pillow+numpy, JPEG q90, ~480KB each, 4.3MB total) — NOT downloaded photos: I cannot verify a stranger's licence from here, and generated art has a clean MIT one. New `monarch background pick` (Walker dmenu in-session, numbered prompt over SSH), refactored the shared candidate logic into bin/_background-lib.sh, bound Super+Ctrl+W. `theme apply` now auto-sets a theme's first wallpaper (fresh installs land on one). Migration 1786229066 regenerates keybinds + sets a default on existing installs. Reconciled the now-stale 'ships no wallpapers' comments. Still unbooted — hyprpaper has never rendered these.
