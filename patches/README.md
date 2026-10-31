# Patches on pleamar

LatteOS runs on [pleamar](https://github.com/k4ditano/pleamar) built from its source with these changes. They
apply to pleamar **0.6.1** (commit `8bc81cc`), each on its own (`git apply`), `pleamar-speed-edges-wheel.patch` after the other four, and each is meant to be offered to pleamar's author:
none is specific to LatteOS. The scenes work without them, only slower or less sharp.

| Patch | What it does | Why |
| --- | --- | --- |
| `pleamar-speed-edges-wheel.patch` | `body-speed`: a long body with many shapes is painted in vertical strips, each with only the shapes that reach it; a shape of no size is left out. `sharp-edges`: the edge of a body follows how much the distance really changes per pixel. `wheel-x`: only the sideways turn of the wheel. | A body's shader works out every shape for every pixel: without strips the bar alone fills an RX 640 (100 % of the card, 115 ms a frame). |
| `pleamar-steady-glass.patch` | The glass keeps the last three frames it showed and works out the background only where all three agree; under a dense tint it is not worked out at all. | The capture the compositor hands over may be of an older frame. Unmixing it against the newest one left ghosts of text that had gone, and grain along moving edges. |
| `pleamar-windows-and-icons.patch` | `PLEAMAR_GENERIC=window` takes only the window list from the generic protocols and leaves the rest to Hyprland; the list has any number of listeners. (The icons part went: since 0.4.22 pleamar finds icons the freedesktop way itself.) | On Hyprland the `window` service reports only the window in front. One listener pushed the other out, so drops stayed for windows that were gone. |
| `pleamar-right-selection.patch` | A press of the right button puts what is selected into `text selected_text`, if the scene declares it. | A menu on the right button could not copy a selection: the logic did not know it. |
| `pleamar-apps-reload.patch` | Watching `apps` again reads the list again, for every listener. | The list was read once: an app installed while the desktop ran did not show up until the next login. |

On [pleamar-wm](https://github.com/k4ditano/pleamar-wm) 0.6.2 (commit `314b979`, beside `../pleamar`):

| Patch | What it does | Why |
| --- | --- | --- |
| `pleamar-wm-scanout-layouts.patch` | A monitor that refuses a layout gets the next one the card can paint in, linear at the end. | On GFX6 to GFX8 (RX 640) with Linux 7.3 and Mesa 26.3 the card paints in layouts its display cannot show: the session stopped at "the monitor does not take the buffer". |

To build:

```sh
git clone https://github.com/k4ditano/pleamar.git
cd pleamar && git checkout 8bc81cc && for p in /path/to/patches/pleamar-*.patch; do git apply "$p"; done
cargo build --release          # target/release/pleamar goes to /usr/bin/pleamar
```

When pleamar moves on: apply each patch to the new tag; one that no longer applies was either taken upstream
(drop it) or needs its context moved (the change itself is small).

## The title bars' plugin

Windows that draw no header of their own get one from the compositor: [hyprbars](https://github.com/hyprwm/hyprland-plugins),
built for the Hyprland that is installed, with `hyprbars-latte.patch`:

| What it does | Why |
| --- | --- |
| The buttons, dragging and the double click answer the left button only; the right button on the title runs `on_right_click`; the pointer resting on a button runs `on_button_hover`. `{x}`, `{y}`, `{address}` and `{index}` in those commands are the pointer, the window and the button. | A right click on a title opens the window's menu, as on Windows; upstream treats every button alike. |

```sh
git clone https://github.com/hyprwm/hyprland-plugins.git && cd hyprland-plugins
# hyprpm.toml pins a commit for each Hyprland: take the one for `pkg-config --modversion hyprland`
# (0.57.0 has no pin yet: main at d2427d4 builds against it, and the patch is made on that)
git checkout "$(grep -E "# $(pkg-config --modversion hyprland)\s*$" hyprpm.toml | sed -E 's/.*", "([0-9a-f]+)".*/\1/')"
git apply /path/to/patches/hyprbars-latte.patch
make -C hyprbars          # needs hyprland-devel; hyprbars/hyprbars.so goes to /usr/lib64/latteos/hyprbars.so
```

Without the plugin the desktop works: a window is moved with Win and the mouse and closed from the window bar.

The glass windows are [Hyprglass](https://github.com/hyprnux/hyprglass), built as its README says and put at
`/usr/lib64/latteos/hyprglass.so`; LatteOS changes nothing in it.

LatteOS's own plugin, `plugins/latte-events` (it tells the configuration when a window is let go, for laying it
against an edge), is built the same way: `make -C plugins/latte-events`, the result goes to
`/usr/lib64/latteos/latte-events.so`. Both have to be built again whenever Hyprland is updated.
