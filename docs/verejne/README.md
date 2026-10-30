# LatteOS — Jihlavanka (0.x)

**A Linux desktop for people coming from Windows — made of liquid coffee.**

LatteOS is a desktop built on Fedora and Hyprland for people who know Windows, want a computer that is simply
theirs, and never want to open a terminal. The taskbar, Start menu, clock and system tray are replaced by
**liquid coffee droplets ("goo")** that stretch, stick to the screen edge and react to the cursor. Everything
works with the mouse; keyboard shortcuts are a bonus, never a requirement.

> **Status: early development (0.x "Jihlavanka").** Things change daily and can break. Install it on a test
> machine only. The first stable release will be 1.0 "Arabica".

![Desktop with the coffee droplets](../screenshots/desktop.png)

## How it is made

LatteOS is designed by **Arkay** (Slovakia) — the ideas, look and behaviour. The code is written together with an
AI assistant (**Claude** by Anthropic). We say this openly: every feature is described, reviewed and tested by a
human on a real PC, and borrowed code is always credited (see *Credits* below).

## What it looks like

| | |
|---|---|
| ![Login](../screenshots/login.png) **Login** — a coffee sea at sunset, weather, clock and news. | ![LensShore](../screenshots/lensshore.png) **LensShore** — search, apps, quick actions, clipboard, emoji and AI in one bar. |
| ![DualBrew](../screenshots/dualbrew-two-panels.png) **DualBrew** — two-panel file manager (Total Commander habits, Windows looks). | ![DualBrew icons](../screenshots/dualbrew-icons.png) **DualBrew** — single panel with icons. |
| ![Background](../screenshots/settings-background-pegboard.png) **Background** — the *pegboard*: drag pictures, films or slideshows onto your screens as layers. | ![Windows](../screenshots/settings-windows.png) **Windows** — each screen chooses how windows are arranged: floating, tape, tiles, glance. |
| ![Clock](../screenshots/clockgoo.png) **ClockGoo** — time, weather, world clocks, digital wellbeing. | ![Performance](../screenshots/powergoo-strip.png) **PowerGoo strip** — CPU, RAM, GPU and VRAM at a glance. |

## What makes it different

- **Mouse first, Windows habits.** No feature is reachable only by keyboard or terminal. Right-click works
  everywhere, always with the same menu order.
- **Liquid desktop (Goo).** The shell is a set of droplets drawn by [pleamar](https://github.com/k4ditano/pleamar):
  they move, merge and breathe. Glass, metal and coffee themes; a plain *FPS* theme with no effects for gaming.
- **The pegboard.** Your monitors laid out as they really stand on the desk — for cursor movement, window
  modes per screen and wallpapers stretched across screens (pictures, videos, slideshows).
- **NET button.** Cut any app off the internet instantly — Windows apps too.
- **Made for games.** Steam, Proton and current drivers; **Barista** prepares Windows programs and games for you.
- **AI you can switch off.** Local AI (also in Slovak) can help with settings and files; online AIs live in their
  own tabs. Generative AI can be turned off completely in the installer or in Settings.
- **No telemetry, no ads, no account required.**

## Platform

- Fedora 44 + Hyprland, Quickshell (QML) apps, Rust tools; Fedora Atomic (bootc) planned for 1.0.
- Must boot without a GPU: a **SAFE** session (labwc) always works; acceleration only adds effects.
- Target: any PC with Vulkan that is less than ~10 years old, AMD, NVIDIA and Intel.

## Credits

LatteOS stands on other people's work. Every borrowed project, file, shader, font and icon is listed — who made it,
what LatteOS uses it for and under which licence — in [TRETIE-STRANY.md](../../TRETIE-STRANY.md). Highlights:
[pleamar](https://github.com/k4ditano/pleamar), [Hyprland](https://github.com/hyprwm/Hyprland),
[Hyprglass](https://github.com/hyprnux/hyprglass), [Quickshell](https://github.com/quickshell-mirror/quickshell),
[skwd-wall](https://github.com/liixini/skwd-wall), [whyd](https://github.com/vmaltarello/whyd),
[labwc](https://github.com/labwc/labwc), [Tabler Icons](https://github.com/tabler/tabler-icons).

Wallpapers in the screenshots belong to their artists and are not part of LatteOS.

## Licence

MIT for LatteOS's own code for now ([LICENSE](../../LICENSE)). The final licence will be chosen before 1.0 so that
it fits every borrowed part.

---

*Slovensky:* LatteOS je linuxová plocha pre ľudí z Windowsu, z tekutých kávových kvapiek, ovládaná myšou.
Navrhuje ju Arkay, kód vzniká s pomocou AI (Claude). Raný vývoj — iba na testovací počítač.
