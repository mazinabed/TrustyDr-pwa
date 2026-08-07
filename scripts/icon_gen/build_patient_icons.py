import os
import sys

_HERE = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, _HERE)
from generate_icons import build_icon_set

REPO_ROOT = os.path.abspath(os.path.join(_HERE, "..", ".."))
WEB = os.path.join(REPO_ROOT, "web")

LABEL = "PATIENT"
BG_TL = (92, 198, 186)   # #5CC6BA - manifest background_color
BG_BR = (74, 144, 226)   # #4A90E2 - manifest theme_color

OUTPUTS = [
    (os.path.join(WEB, "icons", "app-icon-patient-v2-512.png"), 512, "standard"),
    (os.path.join(WEB, "icons", "app-icon-patient-v2-192.png"), 192, "standard"),
    (os.path.join(WEB, "icons", "app-icon-patient-v2-512-maskable.png"), 512, "maskable"),
    (os.path.join(WEB, "icons", "app-icon-patient-v2-192-maskable.png"), 192, "maskable"),
    (os.path.join(WEB, "icons", "apple-touch-icon-patient-v2.png"), 180, "standard"),
    (os.path.join(WEB, "favicon.ico"), 32, "standard"),
]

if __name__ == "__main__":
    print("Building Patient (TrustyDr-pwa) icon set...")
    build_icon_set(LABEL, BG_TL, BG_BR, OUTPUTS)
