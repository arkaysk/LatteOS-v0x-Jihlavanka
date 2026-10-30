# Patches on pleamar

LatteOS runs on [pleamar](https://github.com/k4ditano/pleamar) built from its source with these changes. They
apply to the tag **v0.4.31**, each on its own (`git apply`), and each is meant to be offered to pleamar's author:
none is specific to LatteOS. The scenes work without them, only slower or less sharp.

| Patch | What it does | Why |
| --- | --- | --- |
| `pleamar-body-speed.patch` | A long body with many shapes is painted in vertical strips, each with only the shapes that reach it; a shape of no size is left out of the body. | A body's shader works out every shape for every pixel. A bar of 17 drops is 85 shapes across the whole screen: on an RX 640 the idle engine took 70 % of the card and takes 35 % with strips. With 192 hidden shapes a frame in software took 102 ms and takes 18 ms. The picture is the same to the pixel. |
| `pleamar-sharp-edges.patch` | The edge of a body follows how much the distance really changes per pixel. | Where shapes melt into each other the distance is squeezed, and an edge of fixed width smeared over several pixels: the holes left between melted drops had blurred rims. |
| `pleamar-steady-glass.patch` | The glass keeps the last three frames it showed and works out the background only where all three agree; under a dense tint it is not worked out at all. | The capture the compositor hands over may be of an older frame. Unmixing it against the newest one left ghosts of text that had gone, and grain along moving edges. |
| `pleamar-windows-and-icons.patch` | `PLEAMAR_GENERIC=window` takes only the window list from the generic protocols and leaves the rest to Hyprland; the list has any number of listeners. (The icons part went: since 0.4.22 pleamar finds icons the freedesktop way itself.) | On Hyprland the `window` service reports only the window in front. One listener pushed the other out, so drops stayed for windows that were gone. |
| `pleamar-wheel-x.patch` | `wheel.x`: only the sideways turn of the wheel (a tilted wheel, two fingers to the side), right positive; `wheel` keeps counting it too, as before. The agent's `wheel NAME n x` turns it sideways. | A scene could not tell a sideways swipe from a turn up or down: LensShore's modes turn as a tape with two fingers to the side (ROADMAP 6B.28). |
| `pleamar-right-selection.patch` | A press of the right button puts what is selected into `text selected_text`, if the scene declares it. | A menu on the right button could not copy a selection: the logic did not know it. |
| `pleamar-apps-reload.patch` | Watching `apps` again reads the list again, for every listener. | The list was read once: an app installed while the desktop ran did not show up until the next login. |

To build:

```sh
git clone --depth 1 --branch v0.4.31 https://github.com/k4ditano/pleamar.git
cd pleamar && for p in /path/to/patches/pleamar-*.patch; do git apply "$p"; done
cargo build --release          # target/release/pleamar goes to /usr/bin/pleamar
```

When pleamar moves on: apply each patch to the new tag; one that no longer applies was either taken upstream
(drop it) or needs its context moved (the change itself is small in all six).

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
