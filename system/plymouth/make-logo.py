#!/usr/bin/env python3
"""Draws the LatteOS logo, a cup with steam, as a PNG with nothing but the standard library.

  make-logo.py OUT.png [SIZE]

watermark.png beside this file is its output at 192 px: the boot splash shows it and the login screen starts
from the same picture, so run this again whenever the drawing changes.
"""
import math, struct, sys, zlib

out = sys.argv[1]
N = int(sys.argv[2]) if len(sys.argv) > 2 else 256
SS = 4                                   # samples per pixel each way, for smooth edges
CUP = (0xD9, 0x91, 0x3B)
STEAM = (0xCD, 0xBF, 0xAF)


def shape(x, y):
    """What is at (x, y) on a 256 × 256 canvas: (colour, alpha), or None."""
    for cx in (100, 128, 156):           # steam: three waves
        if 40 <= y <= 108:
            wx = cx + 7 * math.sin((y - 40) / 68 * 2 * math.pi + cx)
            if abs(x - wx) < 4.5:
                return STEAM, 0.85
    if 122 <= y <= 206:                  # the cup: a trapezoid with round bottom corners
        half = 70 - 14 * (y - 122) / 84
        if abs(x - 128) <= half:
            if y > 186:
                r = 20
                corner_x = 128 + (half - r) * (1 if x > 128 else -1)
                if abs(x - 128) > half - r and math.hypot(x - corner_x, y - 186) > r:
                    return None
            return CUP, 1.0
    if x > 190 and 14 <= math.hypot(x - 196, y - 158) <= 26:      # the handle
        return CUP, 1.0
    if ((x - 128) / 96) ** 2 + ((y - 218) / 9) ** 2 <= 1:         # the saucer
        return CUP, 0.9
    return None


rows = []
for py in range(N):
    row = bytearray([0])
    for px in range(N):
        r = g = b = a = 0.0
        for sy in range(SS):
            for sx in range(SS):
                s = shape((px + (sx + 0.5) / SS) * 256 / N, (py + (sy + 0.5) / SS) * 256 / N)
                if s:
                    (cr, cg, cb), ca = s
                    r += cr * ca; g += cg * ca; b += cb * ca; a += ca
        row += bytes((int(r / a), int(g / a), int(b / a), int(255 * a / (SS * SS)))) if a else b"\0\0\0\0"
    rows.append(bytes(row))


def chunk(kind, data):
    c = struct.pack(">I", len(data)) + kind + data
    return c + struct.pack(">I", zlib.crc32(kind + data) & 0xFFFFFFFF)


png = b"\x89PNG\r\n\x1a\n" + chunk(b"IHDR", struct.pack(">IIBBBBB", N, N, 8, 6, 0, 0, 0))
png += chunk(b"IDAT", zlib.compress(b"".join(rows), 9)) + chunk(b"IEND", b"")
open(out, "wb").write(png)
