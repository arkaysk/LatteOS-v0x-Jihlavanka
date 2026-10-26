#!/usr/bin/env python3
"""pointer.py WIDTHxHEIGHT STEP…: a mouse for the compositor of tests/screen.sh, which has none.

`pleamar --mouse` is a scene's own fake mouse; this one is the compositor's, so it can press a window's title,
drag it and let it go. Steps, in order:
  X,Y      go there (pixels of a screen WIDTH × HEIGHT), in small moves, as a hand does
  down     press the left button          up     let it go          rdown, rup   the right one
  mdown, mup   the middle one         bdown, bup   the mouse's back button
  wheelup, wheeldown   one notch of the wheel
  0.5      wait that many seconds
For the DO of tests/screen.sh:   pointer.py 1920x1080 400,300 down 2,300 0.3 up

It speaks Wayland's wire format itself (wlr-virtual-pointer-unstable-v1): there is nothing to install.
"""
import os
import socket
import struct
import sys
import time

BTN_LEFT = 0x110


class Wire:
    def __init__(self):
        path = os.path.join(os.environ["XDG_RUNTIME_DIR"], os.environ.get("WAYLAND_DISPLAY", "wayland-0"))
        self.sock = socket.socket(socket.AF_UNIX, socket.SOCK_STREAM)
        self.sock.connect(path)
        self.buf, self.last_id = b"", 1

    def new_id(self):
        self.last_id += 1
        return self.last_id

    def send(self, obj, opcode, payload=b""):
        self.sock.sendall(struct.pack("<IHH", obj, opcode, 8 + len(payload)) + payload)

    def events(self):
        """Every message that has arrived, as (object, opcode, payload); waits for at least one."""
        self.buf += self.sock.recv(65536)
        out = []
        while len(self.buf) >= 8:
            obj, opcode, size = struct.unpack("<IHH", self.buf[:8])
            if len(self.buf) < size: break
            out.append((obj, opcode, self.buf[8:size]))
            self.buf = self.buf[size:]
        return out

    def roundtrip(self, each=lambda *a: None):
        done = self.new_id()
        self.send(1, 0, struct.pack("<I", done))                    # wl_display.sync
        while True:
            for obj, opcode, payload in self.events():
                if obj == done: return
                if obj == 1 and opcode == 0:                          # wl_display.error
                    sys.exit("pointer.py: the compositor refused: " + payload[12:].split(b"\0")[0].decode())
                each(obj, opcode, payload)


def string(s):
    b = s.encode() + b"\0"
    return struct.pack("<I", len(b)) + b + b"\0" * (-len(b) % 4)


def main(a):
    if len(a) < 2 or "x" not in a[0]:
        print(__doc__.strip())
        return 2
    width, height = (int(v) for v in a[0].split("x"))
    w = Wire()
    registry, found = w.new_id(), {}
    w.send(1, 1, struct.pack("<I", registry))                       # wl_display.get_registry

    def global_(obj, opcode, payload):
        if obj == registry and opcode == 0:
            name, length = struct.unpack("<II", payload[:8])
            found[payload[8:8 + length - 1].decode()] = (name, struct.unpack("<I", payload[8 + length + (-length % 4):][:4])[0])
    w.roundtrip(global_)
    if "zwlr_virtual_pointer_manager_v1" not in found:
        sys.exit("pointer.py: this compositor has no virtual pointer")
    name, _ = found["zwlr_virtual_pointer_manager_v1"]
    manager, pointer = w.new_id(), w.new_id()
    w.send(registry, 0, struct.pack("<I", name) + string("zwlr_virtual_pointer_manager_v1") + struct.pack("<II", 1, manager))
    w.send(manager, 0, struct.pack("<II", 0, pointer))               # create_virtual_pointer(no seat)
    now = lambda: int(time.monotonic() * 1000) & 0xFFFFFFFF
    at = None

    def go(x, y):
        w.send(pointer, 1, struct.pack("<IIIII", now(), int(x), int(y), width, height))   # motion_absolute
        w.send(pointer, 4)                                                              # frame

    for step in a[1:]:
        if step in ("down", "up", "rdown", "rup", "mdown", "mup", "bdown", "bup"):
            button = BTN_LEFT + {"r": 1, "m": 2, "b": 3}.get(step[0], 0)        # left, right, middle, side (back)
            w.send(pointer, 2, struct.pack("<III", now(), button, 1 if step.endswith("down") else 0))
            w.send(pointer, 4)
        elif step in ("wheelup", "wheeldown"):
            w.send(pointer, 5, struct.pack("<I", 0))                                    # axis_source: wheel
            w.send(pointer, 3, struct.pack("<IIi", now(), 0, (-15 if step == "wheelup" else 15) * 256))  # axis: vertical
            w.send(pointer, 4)
        elif "," in step:
            x, y = (float(v) for v in step.split(","))
            x0, y0 = at or (x, y)
            n = max(1, int(max(abs(x - x0), abs(y - y0)) / 12))
            for i in range(1, n + 1):
                go(x0 + (x - x0) * i / n, y0 + (y - y0) * i / n)
                w.roundtrip()
                time.sleep(0.008)
            at = (x, y)
        else:
            time.sleep(float(step))
        w.roundtrip()
    return 0


if __name__ == "__main__":
    sys.exit(main(sys.argv[1:]))
