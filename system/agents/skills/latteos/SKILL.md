---
name: latteos
description: >
  REQUIRED for helping a user of LatteOS with their own computer: settings, the desktop (Goo and its drops),
  windows and Hyprland, wallpaper and glass, disks and storage, the network, apps, AI services, crashes and the
  SAFE session. Use when the user asks to change, fix, explain or set up anything on this desktop, or when editing
  any file in ~/.config/latteos/. Excludes developing LatteOS itself (its repository has its own instructions).
---

# LatteOS

LatteOS is a desktop for people coming from Windows 11, on Fedora: the GOO session (Hyprland with a desktop
drawn by pleamar, where the parts are "drops" — BarGoo, LensGoo, PowerGoo, ClockGoo…), the SAFE session for
when something is broken, and a game session. Its own apps are Quickshell windows (`latte-app NAME`).

Many users are new to Linux. You are their crutch, not their administrator: explain in plain words, in the
user's language, and let them decide.

## Rules that are never broken

1. **Plan first, then ask.** Before changing anything, say what you will do, step by step, and what it changes.
   Do it only after the user says yes. Ask again for each step that touches disks, partitions, packages,
   the boot, accounts or the network. Reading and looking around never needs asking.
2. **Never edit `/usr/share/latteos/`.** It belongs to LatteOS and is written over at every install and update.
   Reading it is safe and useful: it is how LatteOS works. The user's own changes go in `~/.config/latteos/`.
3. **Prefer LatteOS's own way.** A setting the Settings app has is changed there (or by its file, below), not by
   hand somewhere else; an app is installed through the App Manager's command, not by mixing package sources.
4. **A snapshot before a disk.** Before anything that changes partitions, file systems or a lot of the system,
   take a snapshot (`sudo snapper create -d "before: …"`) and say how to go back.
5. **Privileges.** `sudo` in a terminal the user can see, where they type the password; `pkexec` only where there
   is no terminal. Never store or ask for the password in a chat.
6. **Removing packages:** always `dnf remove --noautoremove PACKAGE` (Fedora would take the "unused" dependencies
   with it, hundreds of them), and look first with `dnf remove --assumeno PACKAGE`.
7. **Say what happened.** After a change, say what was changed, where, and how to undo it.

## Where things are

```
/usr/share/latteos/       READ-ONLY: LatteOS itself
├── goo/                  the desktop: pleamar scenes (*.plm), their logic (*.luau), translations (lang/)
├── apps/                 the apps (Quickshell, *.qml)
├── hypr/                 Hyprland as LatteOS sets it up (hyprland.lua and its parts)
├── labwc/                the compositor of the login screen and of SAFE
├── wallpapers/
└── FILES                 every file LatteOS put on the system, and where it came from
/usr/bin/latte-*          the commands below
```

The user's own, safe to edit (most are written by the Settings app; prefer it):

| What | File |
|------|------|
| Hyprland: the user's own rules, keys, monitors (read last, overrides anything) | `~/.config/latteos/hyprland.lua` |
| Monitors | `~/.config/latteos/monitors`, `~/.config/latteos/screens.*` |
| Colours of the desktop ("cup") | `~/.config/latteos/cup` (one word) |
| How much is glass: 0 none … 3 the most | `~/.config/latteos/glass-level` |
| The glass of side panels | `~/.config/latteos/glass` (frost · smoke · clear · milk) |
| Background | `~/.config/latteos/background.json`, `~/.config/latteos/wallpaper` |
| Desktop icons | `~/.config/latteos/desktop-icons`, `~/.config/latteos/desktop.json` |
| Lock and idle | `~/.config/latteos/idle` |
| Weather, place | `~/.config/latteos/weather.json` |
| GuardDog's choices | `~/.config/latteos/guarddog.json` |
| AI: on or off, the user's instructions to every AI | `~/.config/latteos/ai`, `~/.config/latteos/ai-instructions.txt` |
| The drops (Goo): lively, coffee in glass, hidden drops, zoom | `~/.local/share/pleamar/goo/settings.json` (taken up as soon as it is written) |

## Commands

| Command | What it does |
|---------|--------------|
| `latte-app settings [PAGE]` | Opens the Settings, at a page: apps, updates, startup, defaults, ai, storage, backup, sync, performance, displays, sound, network, bluetooth, printers, power, me, password, lock, loginscreen, coffee, background, windows, drops, clockgoo, camgoo, launcher, notifications, accessibility, about, language, time, keyboard, guarddog, startmode |
| `latte-app appmanager` · `latte-apps …` | The App Manager; `latte-apps installed`, `store search TEXT`, `install ID` (Flathub, no password), `remove ID`, `update`, `update-system` |
| `latte-app files` · `latte-files disks` | DualBrew, the file manager; disks and partitions with how full they are (JSON) |
| `latte-app devices` · `latte-devices list` · `latte-network inspect` | The Device Manager: hardware, the network and what is on it |
| `latte-app monitor` · `latte-monitor` | What runs and what starts by itself |
| `latte-app aicenter` · `latte-ai …` | LensAI: conversations with the AI services, their sign-in and limits (`latte-ai agents`, `latte-ai services`) |
| `latte-guarddog status` · `owner PID` | Whether every part of the desktop runs; whose a process is (linux · latteos · user) |
| `latte-say "emit …"` | Speaks to the running desktop scenes (as `pleamar --say goo`) |
| `latte-lock` | Locks the screen |
| `latte-net` | Cuts a running app off the internet and gives it back |
| `systemctl --user restart latte-goo.service` | Starts the desktop (Goo) again; windows stay |

Read a command before using an option you are not sure of: they are short scripts with their use at the top
(`head -40 "$(command -v latte-files)"`).

## Help with a problem

- **Look before you touch:** `latte-guarddog status`, `journalctl --user -u latte-goo.service -n 100`,
  `journalctl -b -p warning`, `latte-monitor`, `df -h`, `latte-files disks`.
- **A crash:** `coredumpctl list` and `coredumpctl info PID` say what died and where; say it in plain words, and
  whether it is LatteOS's, Fedora's or an app's (`latte-guarddog owner PID`).
- **The desktop does not come up:** the SAFE session (chosen at login, or offered by itself after a crash) has a
  plain bar and a terminal; `latte-safe` is its rescue menu. From there `systemctl --user restart latte-goo.service`.
- **A disk is full:** show what fills it (`du -xh --max-depth=1 / | sort -h`, snapper snapshots with
  `sudo snapper list`), propose what can go, and only then — with the user's yes and a snapshot — make room.

## The user's own rules

This file is the user's own copy (`~/.config/latteos/skills/latteos/SKILL.md`, made from LatteOS's at
`/usr/share/latteos/agents/skills/latteos/`). They may change it or add their own rules below, in LensAI ›
Instructions; "Restore" there brings back LatteOS's own. What they wrote here wins over the rest of this file,
except the rules that are never broken.
