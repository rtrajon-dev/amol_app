#!/usr/bin/env python3
"""Generates the Amol365 launcher icon and splash mark.

Kept in the repo so the artwork is reproducible: a PNG someone exported once
from a design tool is unmaintainable the moment the brand colour changes.
Re-run with `python3 tool/generate_logo.py`.

THE MARK
--------
A gold ring enclosing a white crescent, on emerald.

The ring is not decoration. The app already uses a progress ring as its visual
signature — the amal summary card and the tasbeeh counter are both rings — so
the icon says the same thing the interface does. It also reads as a tasbeeh
loop, which is the app's most-used screen.

The crescent carries the "Islamic app" meaning that has to survive at 48dp on
a crowded launcher, where a mosque silhouette or Arabic calligraphy would
collapse into noise.

THREE COLOURS, as specified:
  emerald #0A7454  brand (AppColors.primary700)
  gold    #D9A82C  accent (AppColors.accent500)
  white   #FFFFFF

Everything is drawn at 4x and downsampled with LANCZOS. PIL's ellipse and arc
primitives are hard-edged; supersampling is what keeps the crescent's cusps
from looking chewed at small sizes.
"""

from PIL import Image, ImageDraw
from pathlib import Path

EMERALD = (10, 116, 84, 255)
GOLD = (217, 168, 44, 255)
WHITE = (255, 255, 255, 255)

SUPERSAMPLE = 4
# NOT under lib/assets/. That directory is declared in pubspec and ships in
# the APK, but these are build INPUTS — the launcher and splash read the
# generated native resources, never these files. Bundling them was ~240 KB of
# dead weight in an app aimed at low-storage devices.
OUT = Path("brand")


def draw_mark(size: int, scale: float = 1.0) -> Image.Image:
    """The ring + crescent, on transparency.

    `scale` shrinks the mark within its canvas. Android adaptive icons crop to
    roughly the middle 66%, so the foreground layer needs its artwork well
    inside that or the launcher will clip the ring.
    """
    s = size * SUPERSAMPLE
    img = Image.new("RGBA", (s, s), (0, 0, 0, 0))
    draw = ImageDraw.Draw(img)

    c = s / 2
    # Tuned against a 48dp render, not a 1024px one. At the size a launcher
    # actually shows this, a thinner ring became a hairline and a larger
    # crescent closed the gap between the two into a blob.
    ring_r = 0.368 * s * scale
    ring_w = 0.072 * s * scale

    # Ring. Drawn as an outline ellipse rather than an arc so the stroke closes
    # cleanly — an arc from 0 to 360 leaves a visible seam at the join.
    draw.ellipse(
        [c - ring_r, c - ring_r, c + ring_r, c + ring_r],
        outline=GOLD,
        width=int(ring_w),
    )

    # Crescent, built as a mask: a disc with a second disc punched out of it.
    # Drawing the carve circle in the background colour would only work on an
    # opaque canvas, and the adaptive foreground has none.
    outer_r = 0.196 * s * scale
    carve_r = 0.160 * s * scale
    carve_dx = 0.060 * s * scale
    carve_dy = -0.025 * s * scale

    mask = Image.new("L", (s, s), 0)
    mdraw = ImageDraw.Draw(mask)
    mdraw.ellipse([c - outer_r, c - outer_r, c + outer_r, c + outer_r], fill=255)
    mdraw.ellipse(
        [
            c + carve_dx - carve_r,
            c + carve_dy - carve_r,
            c + carve_dx + carve_r,
            c + carve_dy + carve_r,
        ],
        fill=0,
    )

    crescent = Image.new("RGBA", (s, s), WHITE)
    img.paste(crescent, (0, 0), mask)

    return img.resize((size, size), Image.LANCZOS)


def on_emerald(mark: Image.Image, size: int, radius_ratio: float = 0.0) -> Image.Image:
    """Composites the mark onto a solid emerald field.

    `radius_ratio` rounds the corners. iOS and most Android launchers apply
    their own mask, so the shipped icon stays square and lets the platform
    decide — a pre-rounded icon inside a platform mask gets double-rounded.
    """
    bg = Image.new("RGBA", (size, size), EMERALD)

    if radius_ratio > 0:
        s = size * SUPERSAMPLE
        mask = Image.new("L", (s, s), 0)
        ImageDraw.Draw(mask).rounded_rectangle(
            [0, 0, s - 1, s - 1], radius=int(radius_ratio * s), fill=255
        )
        bg.putalpha(mask.resize((size, size), Image.LANCZOS))

    bg.alpha_composite(mark)
    return bg


def main() -> None:
    OUT.mkdir(parents=True, exist_ok=True)

    # Full icon: iOS, and Android's legacy square launcher.
    on_emerald(draw_mark(1024), 1024).save(OUT / "app_icon.png")

    # Adaptive foreground: transparent, mark held inside the safe zone. 0.62
    # keeps the ring clear of the ~66% crop every launcher shape applies.
    draw_mark(1024, scale=0.62).save(OUT / "app_icon_fg.png")

    # Splash: flutter_native_splash centres this on its own background colour,
    # so it ships transparent. Smaller than the icon — a splash mark that fills
    # the screen reads as a loading error rather than a brand.
    draw_mark(768, scale=0.78).save(OUT / "splash.png")

    # Android 12+ draws the splash icon inside a 240dp circle and masks
    # anything outside it, so this one needs a tighter margin still.
    draw_mark(768, scale=0.58).save(OUT / "splash_android12.png")

    # A preview sheet for judging the mark at real launcher sizes. Written to
    # /tmp rather than the repo: it is a thing to look at once, not an asset.
    preview = Image.new("RGBA", (760, 260), (245, 247, 246, 255))
    x = 30
    for px in (192, 96, 64, 48):
        preview.alpha_composite(
            on_emerald(draw_mark(px), px, radius_ratio=0.22), (x, 40)
        )
        x += px + 30
    preview.save("/tmp/amol365_logo_preview.png")
    print("preview: /tmp/amol365_logo_preview.png")

    for f in sorted(OUT.glob("*.png")):
        print(f"{f}  {Image.open(f).size}")


if __name__ == "__main__":
    main()
