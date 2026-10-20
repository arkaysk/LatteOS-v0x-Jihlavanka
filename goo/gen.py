#!/usr/bin/env python3
"""gen.py: writes what the Goo scene needs once per place and the language cannot loop over.

A `body` takes no `repeat`, and a name cannot be indexed by a number that is only known while the scene
runs. So two parts are written here, from the number of places the scene declares (`model goo max N` in
parts/drops.plm):

  parts/shapes.plm   the shapes of every drop, of the ripples and of a falling window, for the one body they melt in
  parts/picks.plm    the values of ONE drop, chosen by a fact: the drop a card grows from, the one chosen from the keyboard, the ones with a strip

  parts/waves.plm    the login screen's coffee surface: where each point of it is, from a sum of Gerstner waves
  parts/surface.plm  the lines that join those points, for the login screen's body

  gen.py             write them all
  gen.py --check     fail if they are not what would be written (tests/check.sh)
  gen.py --slots N   change the number of places in the scene, then write both
"""
import os
import re
import sys

HERE = os.path.dirname(os.path.abspath(__file__))
DROPS = os.path.join(HERE, "parts", "drops.plm")
NOTE = "// Written by goo/gen.py from the number of places in parts/drops.plm. Do not edit: run gen.py.\n"


def slots():
    """The number of places, which the model, the loop over the places and the fact for the logic must agree on."""
    s = open(DROPS).read()
    found = set(re.findall(r"model goo max (\d+)", s) + re.findall(r"repeat k in 0\.\.(\d+)", s) + re.findall(r"fact slots = (\d+)", s))
    for part in ("faces.plm", "body.plm"):
        found |= set(re.findall(r"repeat k in 0\.\.(\d+)", open(os.path.join(HERE, "parts", part)).read()))
    if len(found) != 1:
        sys.exit("gen.py: the parts disagree on the number of places: " + ", ".join(sorted(found)))
    return int(found.pop())


def set_slots(n):
    for part in ("drops.plm", "faces.plm", "body.plm"):
        path = os.path.join(HERE, "parts", part)
        s = open(path).read()
        s = re.sub(r"model goo max \d+", "model goo max %d" % n, s)
        s = re.sub(r"repeat k in 0\.\.\d+", "repeat k in 0..%d" % n, s)
        s = re.sub(r"fact slots = \d+", "fact slots = %d" % n, s)
        open(path, "w").write(s)


def pick(by, what, n):
    """The value `what` (with {k} for the place) of the place the fact `by` names."""
    return "pick(max(%s, 0), %s)" % (by, ", ".join(what.format(k=k) for k in range(n)))


def shapes(n):
    out = [NOTE, "part Shapes {\n"]
    for k in range(n):
        # along its edge: the x axis at the bottom and the top, the y axis on the sides
        ax = "if(goo.{k}.edge == 1 or goo.{k}.edge == 3, 0, 1)".format(k=k)
        ay = "if(goo.{k}.edge == 1 or goo.{k}.edge == 3, 1, 0)".format(k=k)
        out.append((
            # the puddle at the edge and the stalk up to the drop
            "    ellipse {{ at: base.x.{k}, base.y.{k}; radius: rr.{k} * 0.5 * base.{k}; scale: base.w.{k}, 2.1 - base.w.{k}; blend: 14 }}\n"
            "    line {{ from: base.x.{k}, base.y.{k}; to: x.{k}, y.{k}; width: rr.{k} * 2 * stalk.{k}; blend: 14 }}\n"
            # the water to the neighbour, the drop itself, the thread to the neighbour
            "    line {{ from: water.ax.{k}, water.ay.{k}; to: water.bx.{k}, water.by.{k}; width: water.w.{k} * 2; blend: 16 }}\n"
            "    ellipse {{ at: x.{k}, y.{k}; radius: rr.{k}; scale: 1 + wide.{k}, 1 - wide.{k}; blend: link.{k} }}\n"
            "    line {{ from: thread.ax.{k}, thread.ay.{k}; to: thread.bx.{k}, thread.by.{k}; width: thread.w.{k}; blend: thread.root.{k} }}\n"
            # the straight part of a capsule, along the edge
            "    line {{ from: x.{k} + {ax} * cap.{k} * (goo.{k}.cap_dir - 1), y.{k} + {ay} * cap.{k} * (goo.{k}.cap_dir - 1); "
            "to: x.{k} + {ax} * cap.{k} * (goo.{k}.cap_dir + 1), y.{k} + {ay} * cap.{k} * (goo.{k}.cap_dir + 1); "
            "width: rr.{k} * 2 * if(cap.{k} > 0.5, 1, 0); blend: link.{k} }}\n"
        ).format(k=k, ax=ax, ay=ay))
    # the ripples: a stone thrown in is two crests running apart, a tremble a hump shivering on the spot
    for i in range(4):
        for sign in "-+":
            out.append("    ellipse {{ at: rip.x.{i} {s} age.{i} * 420, H - LEVEL + ripple.{i}.force * 1.2; "
                       "radius: rip.a.{i} * 2.2 * if(ripple.{i}.kind > 0.5, 0, 1); scale: 2.2, 1; blend: 14 }}\n".format(i=i, s=sign))
        out.append("    ellipse {{ at: rip.x.{i}, H - LEVEL + 4; radius: rip.a.{i} * (1.2 + 0.6 * sin(time * 1900)) * "
                   "if(ripple.{i}.kind > 0.5, 1, 0); scale: 2.6, 1; blend: 12 }}\n".format(i=i))
    # The swell: crests that travel along the bottom edge, out of sight under it until `swell` lifts them.
    # Flat humps, not the login screen's sum of waves: that one costs half a millisecond a frame even at rest,
    # and here there are a few px of surface to show it on.
    for i in range(SWELL):
        speed, high, pace = 46 + 17 * (i * 5 % 7), 14 + 2.5 * (i * 3 % 5), 31 + 9 * (i % 4)
        out.append("    ellipse {{ at: mod(W * {i} / {n} + {speed} * time, W + 400) - 200, H + 38 - swell * {high} * (0.7 + 0.3 * sin(time * {pace} + {ph})); "
                   "radius: 120; scale: 2.3, 0.24; blend: 14 }}\n".format(i=i, n=SWELL, speed=speed, high=high, pace=pace, ph=i * 67))
    # a window put away, on its way down into the bar
    out.append("    ellipse { at: going.x, going.y; radius: 16 * if(going.k >= 1, going.on, 0) * clamp((gone.for + 0.45 - going.t) / 0.3, 0, 1); "
               "scale: 1 - 0.12 * clamp(going.t, 0, 1), 1 + 0.2 * clamp(going.t, 0, 1); blend: 16 }\n")
    # the neck of the one drop being dragged, from its home to where it is
    out.append("    line {{ from: {hx}, {hy}; to: {x}, {y}; width: if(carried >= 0, {w}, 0); blend: 22 }}\n".format(
        hx=pick("carried", "home.x.{k}", n), hy=pick("carried", "home.y.{k}", n), x=pick("carried", "x.{k}", n),
        y=pick("carried", "y.{k}", n), w=pick("carried", "rr.{k} * 0.7 * neck.{k}", n)))
    out.append("}\n")
    return "".join(out)


def picks(n):
    out = [NOTE, "part Picks {\n"]
    # A property that follows, not a `let`: a `let` written here does not see the places' own names.
    for by, values in (
        # the drop a card grows from
        ("card_owner", (("own.x", "home.x.{k}"), ("own.y", "home.y.{k}"), ("own.r", "goo.{k}.r * goo.{k}.zoom"), ("own.rr", "rr.{k}"), ("own.dx", "x.{k}"), ("own.dy", "y.{k}"))),
        # the drop chosen from the keyboard
        ("kb_at", (("kb.x", "x.{k}"), ("kb.y", "y.{k}"), ("kb.r", "rr.{k}"), ("kb.edge", "goo.{k}.edge"))),
        # the drop that carries the performance strip
        ("strip_owner", (("strip.x", "x.{k}"), ("strip.y", "y.{k}"), ("strip.r", "rr.{k}"), ("strip.cap", "cap.{k}"),
                         ("strip.edge", "goo.{k}.edge"), ("strip.dir", "goo.{k}.cap_dir"))),
        # the drop that carries the quick-launch strip
        ("launch_owner", (("launch.x", "x.{k}"), ("launch.y", "y.{k}"), ("launch.r", "rr.{k}"), ("launch.cap", "cap.{k}"),
                          ("launch.edge", "goo.{k}.edge"), ("launch.dir", "goo.{k}.cap_dir"))),
    ):
        for name, what in values:
            out.append("    prop %s = 0 ~0ms\n    follow %s = %s\n" % (name, name, pick(by, what, n)))
    out.append("}\n")
    return "".join(out)


# The coffee's surface as the side of a few Gerstner waves: (wavelength px, amplitude, degrees per second, phase).
# An amplitude is px or an expression: the fifth is the chop a wind raises, the sixth the long swell it drives. goo/shaders/water.wgsl bends the
# light with the same table (and a few ripples too small to be seen): change both.
WAVES = ((820, "7", 22, 0), (430, "4.2", 31, 70), (250, "2.6", 44, 200), (150, "1.5", 63, 310), (70, "1.8 * gale", 90, 40),
         (1300, "6 * gale", 17, 120))
SPAN = 32                                   # the surface is SPAN lines, from a little left of the screen to a little right
THICK = 30                                  # half the width of a line: how far the coffee reaches up from its centre
SWELL = 8                                   # crests on the desktop's surface, when something stirs it
RAIN = 9                                    # places on the surface where a drop can fall, each at its own pace


def waves():
    out = [NOTE.replace("parts/drops.plm", "WAVES in gen.py"), "part Waves {\n"]
    for i in range(SPAN + 1):
        x0 = "(-80 + (W + 160) * %d / %d)" % (i, SPAN)
        th = ["(360 * %s / %d - %d * time + %d)" % (x0, wl, om, ph) for wl, _, om, ph in WAVES]
        # a crest leans over the way the wave goes: the point moves along as well as up
        out.append("    let wave_x.%d = %s - (2.5 + 1.5 * gale) * chop * (%s)\n" % (
            i, x0, " + ".join("(%s) * sin%s" % (a, t) for (_, a, _, _), t in zip(WAVES, th))))
        out.append("    let wave_y.%d = 0 - chop * (%s)\n" % (
            i, " + ".join("(%s) * cos%s" % (a, t) for (_, a, _, _), t in zip(WAVES, th))))
    # the rain: where each drop falls is worked out again every time it lands, from which time it is
    for k in range(RAIN):
        period = 0.55 + 0.29 * k
        out.append("    let rain_age.%d = fract(time / %g)\n" % (k, period))
        out.append("    let rain_x.%d = (W + 160) * fract(sin(floor(time / %g) * 127.1 + %d * 311.7) * 43758.5453) - 80\n" % (k, period, k))
    out.append("}\n")
    return "".join(out)


def surface():
    out = [NOTE.replace("parts/drops.plm", "WAVES in gen.py"), "part Surface {\n"]
    for i in range(SPAN):
        out.append("    line { from: wave_x.%d, tide_y + %d + wave_y.%d; to: wave_x.%d, tide_y + %d + wave_y.%d; width: %d; blend: 34 }\n" % (
            i, THICK, i, i + 1, THICK, i + 1, 2 * THICK))
    # a drop on the surface: a ring of two crests running apart and dying away, and a hump where it fell
    for k in range(RAIN):
        out.append("    ellipse { at: rain_x.%d - 6 - 46 * rain_age.%d, tide_y + %d; radius: 7 * sin(180 * rain_age.%d) * raining; scale: 2.2, 0.35; blend: 20 }\n" % (k, k, THICK, k))
        out.append("    ellipse { at: rain_x.%d + 6 + 46 * rain_age.%d, tide_y + %d; radius: 7 * sin(180 * rain_age.%d) * raining; scale: 2.2, 0.35; blend: 20 }\n" % (k, k, THICK, k))
        out.append("    ellipse { at: rain_x.%d, tide_y + %d - 4; radius: 5 * clamp(1 - rain_age.%d * 5, 0, 1) * raining; blend: 16 }\n" % (k, THICK, k))
    out.append("}\n")
    return "".join(out)


def main():
    if "--slots" in sys.argv:
        set_slots(int(sys.argv[sys.argv.index("--slots") + 1]))
    n = slots()
    stale = []
    for name, text in (("shapes.plm", shapes(n)), ("picks.plm", picks(n)), ("waves.plm", waves()), ("surface.plm", surface())):
        path = os.path.join(HERE, "parts", name)
        if "--check" in sys.argv:
            if not os.path.exists(path) or open(path).read() != text:
                stale.append(name)
        else:
            open(path, "w").write(text)
    if stale:
        sys.exit("gen.py: out of date, run goo/gen.py: " + ", ".join(stale))
    print("goo: %d places" % n)


if __name__ == "__main__":
    main()
