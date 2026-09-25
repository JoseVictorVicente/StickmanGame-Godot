from pathlib import Path
from PIL import Image

ROOT = Path(__file__).resolve().parents[1]
SRC = ROOT / "sprites/enemies/flying_demon/source"
SHEET = next(SRC.glob("*IDLE_ANIMATION*.png"), None)
if SHEET is None:
    raise SystemExit("IDLE_ANIMATION sheet not found")

img = Image.open(SHEET)
frame_w = img.height
frames_total = img.width // frame_w
side = [5, 6, 7]
for folder in ("idle", "run", "attack", "death"):
    out_dir = ROOT / "sprites/enemies/flying_demon" / folder
    out_dir.mkdir(parents=True, exist_ok=True)
    for j, idx in enumerate(side):
        if idx >= frames_total:
            continue
        crop = img.crop((idx * frame_w, 0, (idx + 1) * frame_w, img.height))
        crop.save(out_dir / f"frame_{j:03d}.png")
print(f"sliced {SHEET.name} -> 3 frames x 4 folders ({frame_w}x{frame_w})")
