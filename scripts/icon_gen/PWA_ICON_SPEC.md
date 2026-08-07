# TrustyDr PWA Icon Family — Canonical Spec

Locked 2026-08-06. Drives Patient (`TrustyDr-pwa`), Doctor (`doctor_portal`),
and Commerce (`trustydr-commerce/app`) via the identical `generate_icons.py`
core in each repo's `scripts/icon_gen/`. Only label text and background
gradient colors vary per app (see each repo's `build_<app>_icons.py`).

## Method

Rendered directly from `Cairo-ExtraBold.ttf` vector outlines with Pillow/FreeType
at each output's native resolution (no raster upscaling of a single master, no
AI generation, no screenshots). Every output size is a fresh render.

## Font choice

Cairo-ExtraBold — already the TrustyDr brand font family. Chosen by rendering
"T" from Cairo-Bold / SemiBold / ExtraBold / Black at a matched cap-height and
comparing stroke-thickness ratios against Doctor's pre-existing `icon-512.png`:

| Weight | bar-thickness/capH | stem-width/capH |
|---|---|---|
| Master (measured) | 0.179 | 0.221 |
| SemiBold | 0.14 (visibly thinner) | — |
| Bold | 0.172 | 0.200 |
| **ExtraBold (chosen)** | **0.194** | **0.229** |
| Black | 0.215 (too heavy) | 0.264 (too heavy) |

## "TDr." internal proportions (measured pixel-for-pixel from Doctor's master)

As fractions of TDr total width (400px in the 400×148 master crop):

| Element | Fraction of TDr width |
|---|---|
| T | 0.2875 |
| gap T→D | 0.0500 |
| D | 0.3200 |
| gap D→r | 0.0550 |
| r | 0.1675 |
| gap r→dot | 0.0275 |
| dot | 0.0925 |

- Cap-height = 0.3625 × TDr total width
- Dot diameter = 0.352 × r's x-height (= 37/105 measured)
- Dot sinks 0.0207 × cap-height below the T/D/r baseline (optical undershoot)
- Divider width = 1.105 × TDr total width (442/400 measured)
- Label letter-tracking = 0.4692 × label cap-height (12.2/26 measured)

Note: the master's own divider pixels carried alpha=90 (translucent) in the
source PNG — invisible in most previews (which flatten onto white) but would
render as a faint wash against real device chrome. The regenerated dividers
are fully opaque; this is a deliberate, reported deviation from the pixel
data, not an oversight.

## Canonical layout (fractions of canvas size — same ratios at every output resolution)

| Param | Standard | Maskable |
|---|---|---|
| `tdr_cap_h_frac` | 0.282 | 0.224 |
| `top_off_frac` | 0.27 | 0.31 |
| `gap1_frac` (TDr → divider) | 0.048 | 0.048 |
| `divider_h_frac` | 0.0098 | 0.0098 |
| `gap2_frac` (divider → label) | 0.036 | 0.036 |
| `label_cap_h_frac` | 0.050 | 0.050 |

At the 512px reference canvas:

- Standard: cap-height 144.4px, TDr width ≈ 398px, top 138.2px, gap1 24.6px,
  divider 5.0px thick / ≈440px wide, gap2 18.4px, label cap-height 25.6px.
- Maskable: cap-height 114.7px, TDr width ≈ 316px, top 158.7px (same gaps/
  divider-thickness/label-height ratios as standard).

Maskable safe-zone: `SAFE_R = 0.39 × canvas`. The maskable layout above was
solved (see `scripts/icon_gen/generate_icons.py` + the original search in
`solve_layout.py`) to maximize `tdr_cap_h_frac` subject to every element
corner (TDr, divider, label — using "COMMERCE", the longest word, as the
worst case) staying ≥8px inside `SAFE_R` at 512px. Measured worst-case
corner distance: 191.5px vs a 199.68px limit (8.2px margin, deliberate, not
touching the boundary).

At 192px the same ratios give a worst-case corner distance of 72.4px vs a
74.9px limit (2.5px margin — tighter at small size due to integer pixel
rounding, still compliant).

## Why this differs from a literal crop of Doctor's master

Doctor's own `icon-512.png` used a much larger raw gap between "TDr." and the
divider (139px, ~28% of canvas) than the maskable safe zone can afford once
"TDr." is scaled up to match Patient's bolder presence. The composition here
keeps Doctor/Commerce's structural relationship (TDr. → divider → LABEL,
letterform shapes, tracking) but uses a deliberately tighter, canvas-relative
rhythm so the same design can (a) scale up for a bold standard icon and
(b) still satisfy the maskable safe zone — instead of inheriting a spacing
constant that was only ever validated for Doctor's specific old layout.

## Required outputs per app

- `icons/<name>-512.png` — standard
- `icons/<name>-192.png` — standard
- `icons/<name>-512-maskable.png` — maskable, `purpose: "maskable"`
- `icons/<name>-192-maskable.png` — maskable, `purpose: "maskable"`
- `icons/apple-touch-icon*.png` — 180×180, standard layout, fully opaque
- `favicon.ico` / `favicon.png` — standard layout at each app's existing size
  (32px Patient, 48px Doctor/Commerce)

## Per-app colors (unchanged — sourced from each app's own manifest.json)

| App | Gradient top-left | Gradient bottom-right |
|---|---|---|
| Patient | `#5CC6BA` (background_color) | `#4A90E2` (theme_color) |
| Doctor | `#0C4A6E` (background_color) | `#0E7490` (theme_color) |
| Commerce | `#0C4A6E` (background_color) | `#0E7490` (theme_color) |

Patient's icon was previously a circular badge clipped on a transparent
square (inconsistent shape vs. Doctor/Commerce's full-bleed square gradient).
It is now a full-bleed square gradient like the other two — same treatment,
same structure, only the color and label word differ, per the approved
family direction.
