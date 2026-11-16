#!/usr/bin/env python3
"""make-assets.py OUT: the pictures and logos of LatteOS's boot menu theme (patches/aarambh/latteos.c).

OUT/backgrounds/{latteos,safe,windows}.jpg — the coffee cup of the README (docs/screenshots/goo-ooze.png) cut out of
its cream paper onto espresso, on the right; the top bar and the bottom strip with its fade are baked in, so the theme
does not blend them line by line each frame. OUT/logos/{latteos,safe}.png — white silhouettes (Aarambh tints them)
from Tabler Icons. Windows' logo, Restart and Power Off are Aarambh's own.
"""
import os
import sys

from PIL import Image, ImageDraw, ImageFilter, ImageFont, ImageOps
from fontTools.ttLib import TTFont

REPO = os.path.dirname(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))
W, H = 1920, 1080
ESPRESSO = (20, 13, 9)
# Aarambh's design is 1280x800, scaled by height: the bar is 90 of 800, the strip starts 140 from the bottom
# ponytail: baked for 16:9; on another shape the bars are off by a few pixels — draw them in C if that shows.
BAR, STRIP, FADE = round(90 * H / 800), H - round(140 * H / 800), round(200 * H / 800)


def fade(w, h, power=1.6):
    """Opaque on the left, gone on the right."""
    m = Image.new("L", (w, h))
    d = ImageDraw.Draw(m)
    for x in range(w):
        d.line((x, 0, x, h), fill=int(255 * (1 - x / w) ** power))
    return m


def cup_on_espresso():
    cup = Image.open(os.path.join(REPO, "docs/screenshots/goo-ooze.png")).convert("RGB")
    c = ImageOps.fit(cup, (1140, STRIP - BAR + 120), centering=(0.5, 0.45))
    # the cream paper becomes espresso: bright and unsaturated pixels are the paper
    _, s, v = c.convert("HSV").split()
    paper = Image.new("L", c.size)
    ps, pv, pm = s.load(), v.load(), paper.load()
    for y in range(c.height):
        for x in range(c.width):
            pm[x, y] = max(0, min(255, (pv[x, y] - 175) * 4)) * max(0, min(255, (70 - ps[x, y]) * 5)) // 255
    paper = paper.filter(ImageFilter.GaussianBlur(3))
    img = Image.new("RGB", (W, H), ESPRESSO)
    at = (W - c.width, BAR - 40)
    img.paste(c, at)
    img.paste(Image.new("RGB", c.size, ESPRESSO), at, paper)
    img.paste(Image.new("RGB", (540, c.height), ESPRESSO), at, fade(540, c.height))
    return img


def bars(img):
    d = ImageDraw.Draw(img)
    over = Image.new("RGB", (W, FADE), ESPRESSO)
    img.paste(over, (0, STRIP - FADE), Image.linear_gradient("L").resize((W, FADE)))
    d.rectangle((0, 0, W, BAR), fill=ESPRESSO)
    d.rectangle((0, STRIP, W, H), fill=ESPRESSO)
    return img


def logo(name, path):
    cmap = {v: k for k, v in TTFont(os.path.join(REPO, "assets/fonts/tabler-icons.ttf")).getBestCmap().items()}
    font = ImageFont.truetype(os.path.join(REPO, "assets/fonts/tabler-icons.ttf"), 220)
    im = Image.new("RGBA", (256, 256), (255, 255, 255, 0))
    ImageDraw.Draw(im).text((128, 128), chr(cmap[name]), font=font, fill=(255, 255, 255, 255), anchor="mm")
    im.save(path)


def main(out):
    os.makedirs(os.path.join(out, "backgrounds"), exist_ok=True)
    os.makedirs(os.path.join(out, "logos"), exist_ok=True)
    base = cup_on_espresso()
    bars(base.copy()).save(os.path.join(out, "backgrounds/latteos.jpg"), quality=90)
    # SAFE: the same cup, cooled and dimmer — the same place, something went wrong
    safe = Image.blend(ImageOps.colorize(ImageOps.grayscale(base), ESPRESSO, (170, 160, 150)), Image.new("RGB", (W, H), ESPRESSO), 0.35)
    bars(safe).save(os.path.join(out, "backgrounds/safe.jpg"), quality=90)
    # Windows: the cup in the dark, another system on the same PC
    bars(Image.blend(base, Image.new("RGB", (W, H), ESPRESSO), 0.6)).save(os.path.join(out, "backgrounds/windows.jpg"), quality=90)
    logo("coffee", os.path.join(out, "logos/latteos.png"))
    logo("lifebuoy", os.path.join(out, "logos/safe.png"))


if __name__ == "__main__":
    main(sys.argv[1] if len(sys.argv) > 1 else "build/latteos-assets")
