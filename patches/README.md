# Patches on pleamar

LatteOS runs on [pleamar](https://github.com/k4ditano/pleamar) built from its source with these changes. They
apply to the tag **v0.3.2**, each on its own (`git apply`), and each is meant to be offered to pleamar's author:
none is specific to LatteOS. The scenes work without them, only slower or less sharp.

| Patch | What it does | Why |
| --- | --- | --- |
| `pleamar-body-speed.patch` | A long body with many shapes is painted in vertical strips, each with only the shapes that reach it; a shape of no size is left out of the body. | A body's shader works out every shape for every pixel. A bar of 17 drops is 85 shapes across the whole screen: on an RX 640 the idle engine took 70 % of the card and takes 35 % with strips. With 192 hidden shapes a frame in software took 102 ms and takes 18 ms. The picture is the same to the pixel. |
| `pleamar-sharp-edges.patch` | The edge of a body follows how much the distance really changes per pixel. | Where shapes melt into each other the distance is squeezed, and an edge of fixed width smeared over several pixels: the holes left between melted drops had blurred rims. |
| `pleamar-steady-glass.patch` | The glass keeps the last three frames it showed and works out the background only where all three agree; under a dense tint it is not worked out at all. | The capture the compositor hands over may be of an older frame. Unmixing it against the newest one left ghosts of text that had gone, and grain along moving edges. |
| `pleamar-windows-and-icons.patch` | `PLEAMAR_GENERIC=window` takes only the window list from the generic protocols and leaves the rest to Hyprland; the list has any number of listeners; icons are looked up in every `icons` folder of `XDG_DATA_DIRS`, in Breeze's layout and in Adwaita's `legacy`. | On Hyprland the `window` service reports only the window in front. One listener pushed the other out, so drops stayed for windows that were gone. Flatpak apps and several system icons had no picture. |
| `pleamar-apps-reload.patch` | Watching `apps` again reads the list again, for every listener. | The list was read once: an app installed while the desktop ran did not show up until the next login. |

To build:

```sh
git clone --depth 1 --branch v0.3.2 https://github.com/k4ditano/pleamar.git
cd pleamar && for p in /path/to/patches/pleamar-*.patch; do git apply "$p"; done
cargo build --release          # target/release/pleamar goes to /usr/bin/pleamar
```

When pleamar moves on: apply each patch to the new tag; one that no longer applies was either taken upstream
(drop it) or needs its context moved (the change itself is small in all five).
