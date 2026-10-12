#!/usr/bin/env python3
"""gen.py: writes what the Goo scene needs once per place and the language cannot loop over.

A `body` takes no `repeat`, and a name cannot be indexed by a number that is only known while the scene
runs. So two parts are written here, from the number of places the scene declares (`model goo max N` in
parts/drops.plm):

  parts/shapes.plm   the shapes of every drop and of the ripples, for the one body they melt in
  parts/picks.plm    the values of ONE drop, chosen by a fact: the drop a card grows from

  gen.py             write both
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
    # the neck of the one drop being dragged, from its home to where it is
    out.append("    line {{ from: {hx}, {hy}; to: {x}, {y}; width: if(carried >= 0, {w}, 0); blend: 22 }}\n".format(
        hx=pick("carried", "home.x.{k}", n), hy=pick("carried", "home.y.{k}", n), x=pick("carried", "x.{k}", n),
        y=pick("carried", "y.{k}", n), w=pick("carried", "rr.{k} * 0.7 * neck.{k}", n)))
    out.append("}\n")
    return "".join(out)


def picks(n):
    out = [NOTE, "part Picks {\n"]
    # A property that follows, not a `let`: a `let` written here does not see the places' own names.
    for name, what in (("own.x", "home.x.{k}"), ("own.y", "home.y.{k}"), ("own.r", "goo.{k}.r * goo.{k}.zoom"),
                       ("own.edge", "goo.{k}.edge")):
        out.append("    prop %s = 0 ~0ms\n    follow %s = %s\n" % (name, name, pick("card_owner", what, n)))
    out.append("}\n")
    return "".join(out)


def main():
    if "--slots" in sys.argv:
        set_slots(int(sys.argv[sys.argv.index("--slots") + 1]))
    n = slots()
    stale = []
    for name, text in (("shapes.plm", shapes(n)), ("picks.plm", picks(n))):
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
