"""
TrustyDr canonical PWA icon generator (shared core).

This module is byte-identical across TrustyDr-pwa, doctor_portal, and
trustydr-commerce/app so all three surfaces are driven by the exact same
numbers. Each repo has its own tiny build_<app>_icons.py that supplies only
that app's label word, background gradient colors, and output paths.

Rendering method: Pillow (FreeType) drawing directly from Cairo-ExtraBold.ttf
glyph outlines. No AI generation, no screenshots, no raster upscaling -
every output size is rendered fresh from vector outlines at its own target
resolution.

Why Cairo-ExtraBold: it is already the TrustyDr brand font family. The exact
weight was chosen by rendering "T" from Bold/SemiBold/ExtraBold/Black at a
matched cap-height and comparing stroke thickness (bar/stem width as a
fraction of cap-height) against Doctor's existing icon-512.png, which was
the pre-existing hand-built reference. ExtraBold was the closest match
(bar-thickness ratio 0.194 vs master's 0.179; stem-width ratio 0.229 vs
master's 0.221 - both closer than Bold, SemiBold, or Black).

Why these proportions: the internal "TDr." glyph-spacing ratios (T/D/r/dot
widths and gaps, dot undershoot below baseline) and the product-label
letter-tracking ratio were measured pixel-for-pixel from Doctor's existing
icon-512.png. The overall composition SCALE and vertical rhythm were
redesigned (not copied 1:1) per approved direction: combine Patient's
bolder/larger TDr. prominence with Doctor/Commerce's TDr. -> divider ->
LABEL structure. See PWA_ICON_SPEC.md for the full numeric spec and how it
was derived.
"""
import math
import os
from PIL import Image, ImageDraw, ImageFont

_HERE = os.path.dirname(os.path.abspath(__file__))
FONT_PATH = os.path.join(_HERE, "Cairo-ExtraBold.ttf")

# ---- Measured from Doctor master (doctor_portal/web/icons/icon-512.png) ----
T_FRAC = 115 / 400
GAP_TD_FRAC = 20 / 400
D_FRAC = 128 / 400
GAP_DR_FRAC = 22 / 400
R_FRAC = 67 / 400
GAP_RDOT_FRAC = 11 / 400
DOT_FRAC = 37 / 400
CAP_H_OF_WIDTH = 145 / 400          # TDr cap-height as a fraction of TDr total width
DOT_UNDERSHOOT_OF_CAPH = 3 / 145    # dot sinks this far below the T/D/r baseline
DIVIDER_WIDTH_OF_TDR = 442 / 400    # divider is wider than the TDr text above it
LABEL_TRACKING_OF_CAPH = 12.2 / 26  # label letter-spacing as a fraction of label cap-height

SAFE_R_FRAC = 0.39  # maskable safe-zone radius as a fraction of canvas size

# ---- Canonical layout, as fractions of canvas size (locked 2026-08-06) ----
STANDARD = dict(
    tdr_cap_h_frac=0.282,
    top_off_frac=0.27,
    gap1_frac=0.048,
    divider_h_frac=0.0098,
    gap2_frac=0.036,
    label_cap_h_frac=0.050,
)
MASKABLE = dict(
    tdr_cap_h_frac=0.224,
    top_off_frac=0.31,
    gap1_frac=0.048,
    divider_h_frac=0.0098,
    gap2_frac=0.036,
    label_cap_h_frac=0.050,
)


def font_for_cap_height(font_path, target_cap_h, probe_size=400):
    probe = ImageFont.truetype(font_path, probe_size)
    bbox = probe.getbbox("T")
    natural_cap_h = bbox[3] - bbox[1]
    size = max(1, round(probe_size * target_cap_h / natural_cap_h))
    return ImageFont.truetype(font_path, size)


def render_tdr(cap_height_px):
    tdr_width_px = cap_height_px / CAP_H_OF_WIDTH
    font = font_for_cap_height(FONT_PATH, cap_height_px)

    pad = max(2, int(cap_height_px * 0.5))
    work = Image.new("RGBA", (int(tdr_width_px * 2) + pad, int(cap_height_px * 3)), (0, 0, 0, 0))
    d = ImageDraw.Draw(work)

    x = pad
    y_top = pad

    bbox_T = font.getbbox("T")
    d.text((x - bbox_T[0], y_top - bbox_T[1]), "T", font=font, fill=(255, 255, 255, 255))
    w_T = bbox_T[2] - bbox_T[0]
    x += w_T + w_T * (GAP_TD_FRAC / T_FRAC)

    bbox_D = font.getbbox("D")
    d.text((x - bbox_D[0], y_top - bbox_D[1]), "D", font=font, fill=(255, 255, 255, 255))
    w_D = bbox_D[2] - bbox_D[0]
    x += w_D + w_D * (GAP_DR_FRAC / D_FRAC)

    bbox_r = font.getbbox("r")
    d.text((x - bbox_r[0], y_top - bbox_r[1]), "r", font=font, fill=(255, 255, 255, 255))
    w_r = bbox_r[2] - bbox_r[0]
    r_h = bbox_r[3] - bbox_r[1]
    x += w_r + w_r * (GAP_RDOT_FRAC / R_FRAC)

    baseline_y = y_top + (bbox_T[3] - bbox_T[1])
    dot_d = r_h * (37 / 105)  # dot diameter relative to r's x-height, measured from master
    dot_bottom = baseline_y + cap_height_px * DOT_UNDERSHOOT_OF_CAPH
    dot_top = dot_bottom - dot_d
    d.ellipse([x, dot_top, x + dot_d, dot_bottom], fill=(255, 255, 255, 255))

    bbox = work.getbbox()
    return work.crop(bbox)


def render_label(text, cap_height_px):
    font = font_for_cap_height(FONT_PATH, cap_height_px)
    tracking = cap_height_px * LABEL_TRACKING_OF_CAPH

    pad = max(2, int(cap_height_px * 1.5))
    work = Image.new(
        "RGBA",
        (int(cap_height_px * len(text) * 3 + pad * 2), int(cap_height_px * 3)),
        (0, 0, 0, 0),
    )
    d = ImageDraw.Draw(work)

    x = pad
    y_top = pad
    for ch in text.upper():
        bbox = font.getbbox(ch)
        if bbox[2] - bbox[0] == 0:
            x += cap_height_px * 0.28 + tracking
            continue
        d.text((x - bbox[0], y_top - bbox[1]), ch, font=font, fill=(255, 255, 255, 255))
        w = bbox[2] - bbox[0]
        x += w + tracking

    bbox = work.getbbox()
    return work.crop(bbox)


def gradient_bg(size, c_tl, c_br):
    img = Image.new("RGB", (size, size))
    px = img.load()
    denom = max(1, (size - 1) + (size - 1))
    for y in range(size):
        for x in range(size):
            t = (x + y) / denom
            r = round(c_tl[0] + (c_br[0] - c_tl[0]) * t)
            g = round(c_tl[1] + (c_br[1] - c_tl[1]) * t)
            b = round(c_tl[2] + (c_br[2] - c_tl[2]) * t)
            px[x, y] = (r, g, b)
    return img.convert("RGBA")


def compose(size, bg_tl, bg_br, label_text, params):
    canvas = gradient_bg(size, bg_tl, bg_br)

    cap_h = size * params["tdr_cap_h_frac"]
    tdr_img = render_tdr(cap_h)
    tdr_w, tdr_h = tdr_img.size

    label_cap_h = size * params["label_cap_h_frac"]
    label_img = render_label(label_text, label_cap_h)
    label_w, label_h = label_img.size

    divider_w = tdr_w * DIVIDER_WIDTH_OF_TDR
    divider_h = max(1, round(size * params["divider_h_frac"]))

    tdr_x = (size - tdr_w) / 2
    tdr_y = size * params["top_off_frac"]

    divider_y = tdr_y + tdr_h + size * params["gap1_frac"]
    divider_x = (size - divider_w) / 2

    label_y = divider_y + divider_h + size * params["gap2_frac"]
    label_x = (size - label_w) / 2

    canvas.alpha_composite(tdr_img, (round(tdr_x), round(tdr_y)))
    d = ImageDraw.Draw(canvas)
    d.rectangle([divider_x, divider_y, divider_x + divider_w, divider_y + divider_h], fill=(255, 255, 255, 255))
    canvas.alpha_composite(label_img, (round(label_x), round(label_y)))

    geometry = dict(
        tdr_x=tdr_x, tdr_y=tdr_y, tdr_w=tdr_w, tdr_h=tdr_h,
        divider_x=divider_x, divider_y=divider_y, divider_w=divider_w, divider_h=divider_h,
        label_x=label_x, label_y=label_y, label_w=label_w, label_h=label_h,
    )
    return canvas.convert("RGB").convert("RGBA"), geometry


def worst_corner_dist(size, geometry):
    cx = cy = size / 2
    dists = []
    for (x, y, w, h) in [
        (geometry["tdr_x"], geometry["tdr_y"], geometry["tdr_w"], geometry["tdr_h"]),
        (geometry["divider_x"], geometry["divider_y"], geometry["divider_w"], geometry["divider_h"]),
        (geometry["label_x"], geometry["label_y"], geometry["label_w"], geometry["label_h"]),
    ]:
        for cxp, cyp in [(x, y), (x + w, y), (x, y + h), (x + w, y + h)]:
            dists.append(math.hypot(cxp - cx, cyp - cy))
    return max(dists)


def build_icon_set(label_text, bg_tl, bg_br, outputs):
    """outputs: list of (path, size_px, variant) where variant is 'standard' or 'maskable'.
    Saves a PNG (or ICO, inferred from extension) at each path, rendered fresh at size_px."""
    for path, size_px, variant in outputs:
        params = STANDARD if variant == "standard" else MASKABLE
        img, geo = compose(size_px, bg_tl, bg_br, label_text, params)
        os.makedirs(os.path.dirname(path), exist_ok=True)
        if path.lower().endswith(".ico"):
            img.convert("RGB").save(path, format="ICO", sizes=[(size_px, size_px)])
        else:
            img.convert("RGB").save(path, format="PNG")
        if variant == "maskable":
            wcd = worst_corner_dist(size_px, geo)
            safe_r = SAFE_R_FRAC * size_px
            status = "OK" if wcd <= safe_r else "*** UNSAFE ***"
            print(f"  {os.path.basename(path)} ({size_px}px maskable): worst_corner_dist={wcd:.1f} safe_r={safe_r:.1f} {status}")
        else:
            print(f"  {os.path.basename(path)} ({size_px}px standard): ok")
