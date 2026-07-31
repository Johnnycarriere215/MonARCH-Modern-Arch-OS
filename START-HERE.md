# START HERE

**If you are an AI assistant and this is the start of a session, read this file first.**

---

## What you're working on

MonARCH — a Linux distribution built directly on **Arch Linux** with **Hyprland** as the compositor. Independent project, inspired by Omarchy, **not a fork**. Every file in this repo is ours to change. There is no upstream and nothing to merge.

The goal: as fast as Omarchy, but configurable through a real settings app instead of hand-edited dotfiles.

---

## Session protocol

Follow these steps in order, every session.

**1. Read `MONARCH.md`** (repo root). Short. Contains the stack, the golden rules, the repo layout, and every locked decision. **Do not relitigate anything in it.** If you believe something in it is wrong, say so and stop — do not quietly engineer around it.

**2. Read `PROGRESS.md`** (repo root). Find the first task not marked `DONE`. That is the current task.

**3. Read that task's prompt in `docs/04-TASKS.md`.** Only that task. Don't read the others.

**4. Build the whole task.** Don't ask permission between steps. Don't half-build and check in. Everything is tested in a VM that resets in five seconds — bias toward writing it all and letting the human find the breakage.

**5. Verify against the "Done when" criteria** for that task in `PROGRESS.md`. State honestly which criteria you have and haven't met.

**6. Update `PROGRESS.md`** — mark the task `DONE` (or `PARTIAL` with a note on what's missing), and add anything the next session needs to know under Notes.

---

## Reading rules — important

This repo will grow large. **Only read files a task explicitly names.** Do not explore `bin/`, `config/`, or `docs/` to "get oriented." `MONARCH.md` plus `PROGRESS.md` is all the orientation you need, and unprompted exploration burns the human's usage budget before you write a line.

`docs/00-BRIEF.md` through `06-RELEASE.md` exist for reference. Read one only when a task points you there, or when the human asks.

---

## How the human works

- One task per session
- Full spec given up front — build it all, then show output
- When editing existing files, **show only changed lines**
- If a spec is genuinely ambiguous, ask **one** question before writing. Not a list

---

## The plan, in brief

| Phase | What | Status |
|---|---|---|
| 1 | `bootstrap.sh` + packages + base configs → a fresh Arch VM becomes a working desktop with one command | ← **start here** |
| 2 | Theme engine, keybinds, Waybar stats, modes, update system |  |
| 3 | Tauri settings GUI + first-run wizard |  |
| 4 | Own ISO, published to GitHub Releases on tag push |  |

**Phase 1 is the only thing that matters right now.** Nothing counts until `curl … | bash` on a clean Arch install produces a desktop that logs in.
