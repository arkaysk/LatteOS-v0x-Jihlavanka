# Patches on pleamar

LatteOS runs on [pleamar](https://github.com/k4ditano/pleamar) built from its source with these changes. They
apply to pleamar **0.7.10** (tag `v0.7.10`, commit `0fdca2d`), each on its own (`git apply`), `pleamar-speed-edges-wheel.patch` after the others, and each is meant to be offered to pleamar's author:
none is specific to LatteOS. The scenes work without them, only slower or less sharp.

| Patch | What it does | Why |
| --- | --- | --- |
| `pleamar-speed-edges-wheel.patch` | `body-speed`: a long body with many shapes is painted in vertical strips, each with only the shapes that reach it; a shape of no size is left out. `sharp-edges`: the edge of a body follows how much the distance really changes per pixel. `wheel-x`: only the sideways turn of the wheel. | A body's shader works out every shape for every pixel: without strips the bar alone fills an RX 640 (100 % of the card, 115 ms a frame). |
| `pleamar-steady-glass.patch` | The glass keeps the last three frames it showed and works out the background only where all three agree; under a dense tint it is not worked out at all. | The capture the compositor hands over may be of an older frame. Unmixing it against the newest one left ghosts of text that had gone, and grain along moving edges. |
| `pleamar-windows-and-icons.patch` | `PLEAMAR_GENERIC=window` takes only the window list from the generic protocols and leaves the rest to Hyprland; the list has any number of listeners. (The icons part went: since 0.4.22 pleamar finds icons the freedesktop way itself.) | On Hyprland the `window` service reports only the window in front. One listener pushed the other out, so drops stayed for windows that were gone. |
| `pleamar-right-selection.patch` | A press of the right button puts what is selected into `text selected_text`, if the scene declares it. | A menu on the right button could not copy a selection: the logic did not know it. |
| `pleamar-window-carry.patch` | `carry`, an effect: in a rule fired by a press, the scene's `kind: window` is carried by the mouse, as from a title bar (xdg-shell's move with the press's serial). Documented in the reference beside `quit`. | A pleamar window that draws its own header —LatteOS's windows look like its other apps, ROADMAP 10L.01— could not be moved at all: only a frame drawn by the compositor carried it. |
| `pleamar-field-select.patch` | `select: all \| stem` on an `input`: focused, the field chooses all it holds, or what is before its last dot (a file's name without its ending). Documented in the reference. | Renaming a file as Windows and Nautilus offer it (ROADMAP 10L.02): the name chosen, the ending kept. A field could only put its cursor at the end. |
| `pleamar-apps-reload.patch` | Watching `apps` again reads the list again, for every listener. | The list was read once: an app installed while the desktop ran did not show up until the next login. |

On [pleamar-wm](https://github.com/k4ditano/pleamar-wm) 0.6.9 (tag `v0.6.9`, commit `42c8fee`, beside `../pleamar`):

| Patch | What it does | Why |
| --- | --- | --- |
| `pleamar-wm-scanout-layouts.patch` | A monitor that refuses a layout gets the next one the card can paint in, linear at the end. | On GFX6 to GFX8 (RX 640) with Linux 7.3 and Mesa 26.3 the card paints in layouts its display cannot show: the session stopped at "the monitor does not take the buffer". |
| `pleamar-wm-tap-keys.patch` | A binding that only acts on release (`bind super_l release …`) is called off when another key or a mouse button is pressed while it is held. | The Windows key alone opens LatteOS's launcher: without this, Super+Q or a window carried with Super opened it too when Super was let go. |
| `pleamar-wm-shell-fact.patch` | The scene is told which windows have a shell of their own through the terminal layer (`shell.N`, 1 or 0). | A wire can only do something with such a window (`pleamar-wm link` reads, types in and hands tasks to shells); LatteOS shows the port on a canvas only there. |
| `pleamar-wm-gamma-at-start.patch` | At the start of a session the monitors are told with `publish()`, their colour ramps' sizes too, not with `register` alone. | A night light (gammastep, wlsunset) got `failed` on every monitor until monitors changed: Night light did nothing on pleamar-wm. Issue text in `issues/`. |

To build: `sh patches/build-pleamar.sh` (what `sudo ./install --go` does). It fetches both into
`build/pleamar-src`, applies the patches (pleamar's `speed-edges-wheel` after its other four, pleamar-wm's on
pleamar-wm) and builds both into `build/pleamar-src/target/release`; install puts them in `/usr/bin`.

When pleamar moves on: apply each patch to the new tag; one that no longer applies was either taken upstream
(drop it) or needs its context moved (the change itself is small).

## Quickshell with a web engine

LatteOS's apps run in [Quickshell](https://github.com/quickshell-mirror/quickshell). Its 0.3.2 (revision `9b0f339`)
cannot hold a web page: Chromium stops at once ("Argument list is empty"), and QtWebView, which is Chromium too on
Linux, the same. `quickshell-webengine.patch` is [PR #351](https://github.com/quickshell-mirror/quickshell/pull/351)
(not merged yet) brought to that revision: `//@ pragma EnableQtWebEngineQuick` initialises QtWebEngine before the app
is made, and the app gets its program's name. One change of LatteOS's own: the library is loaded by its versioned
name, which is the one the runtime package has. With it LensAI shows the services' own pages in tabs (ROADMAP 10B.35).
Built without jemalloc: with it the PR's author and Quickshell's saw a crash at the start.

```sh
git clone https://github.com/quickshell-mirror/quickshell.git && cd quickshell && git checkout 9b0f339
git apply /path/to/patches/quickshell-webengine.patch
cmake -GNinja -B build -DCMAKE_BUILD_TYPE=RelWithDebInfo -DUSE_JEMALLOC=OFF -DCRASH_HANDLER=OFF && ninja -C build
```

## Author's reply (9. 11. 2026)

- Covered upstream, to be dropped once released: `window-carry` (frameless windows, `decorations: none` + `handle: self`, pleamar 0.8 experimental branch) and `body-speed` of `speed-edges-wheel` (bodies painted in tiles since 0.7.18). Only `body-speed` is covered, `sharp-edges` and `wheel-x` of the same patch stay unless he says otherwise.
- Not planned, keep as local patches: `steady-glass`, `field-select`, `right-selection`, `apps-reload`, `windows-and-icons`, and the pleamar-wm ones (`scanout-layouts`, `gamma-at-start`, `tap-keys`, `shell-fact`).
- He asked for no PRs/issues; documenting the patches here is enough. He will mention taken patches in release notes.
- pleamar 0.8 (pre-release first): multi-line fields, markdown, per-word colours, long lists, images from clipboard, file chooser, buttons/tabs/selects/menus/tables/toasts.
