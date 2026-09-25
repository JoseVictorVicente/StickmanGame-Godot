"""Extract warrior boar GIF frames (one full pose per frame) into sprites/heroes/warrior_boar/."""
from __future__ import annotations

from pathlib import Path

from PIL import Image

REPO = Path(__file__).resolve().parents[1]
ASSETS = REPO.parents[0] / ".cursor" / "projects" / "d-Desktop-Tudo-Godot-Projetos-StickmanGame" / "assets"
if not ASSETS.exists():
    ASSETS = Path(
        r"C:\Users\JOSÉ VICTOR\.cursor\projects\d-Desktop-Tudo-Godot-Projetos-StickmanGame\assets"
    )

OUT = REPO / "sprites" / "heroes" / "warrior_boar"
RUN_GIF = ASSETS / (
    "c__Users_JOS__VICTOR_AppData_Roaming_Cursor_User_workspaceStorage_098f0db4257eb69add82d568288cd2b1_"
    "images_run-edc25c16-fc97-465b-b588-935fa16140bd.gif"
)
ATK_GIF = ASSETS / (
    "c__Users_JOS__VICTOR_AppData_Roaming_Cursor_User_workspaceStorage_098f0db4257eb69add82d568288cd2b1_"
    "images_attack-adbf16d6-9fc3-40ad-90b8-d1c4ab4234c8.gif"
)
IDLE_FRAMES = 4
HIT_FRAMES = 3


def load_frames(path: Path) -> list[Image.Image]:
    image = Image.open(path)
    frames: list[Image.Image] = []
    for index in range(image.n_frames):
        image.seek(index)
        frames.append(image.convert("RGBA"))
    return frames


def save(image: Image.Image, path: Path) -> None:
    path.parent.mkdir(parents=True, exist_ok=True)
    image.save(path)


def main() -> None:
    if not RUN_GIF.exists():
        raise SystemExit(f"Missing run GIF: {RUN_GIF}")
    if not ATK_GIF.exists():
        raise SystemExit(f"Missing attack GIF: {ATK_GIF}")

    run = load_frames(RUN_GIF)
    attack_gif = load_frames(ATK_GIF)
    if len(run) < IDLE_FRAMES:
        raise SystemExit(f"Run GIF too short: {len(run)} frames")
    if len(attack_gif) < HIT_FRAMES + 1:
        raise SystemExit(f"Attack GIF too short: {len(attack_gif)} frames")

    hit = attack_gif[-HIT_FRAMES:]
    attack = attack_gif[IDLE_FRAMES : len(attack_gif) - HIT_FRAMES]

    for sub in ("", "run"):
        folder = OUT / sub if sub else OUT
        if folder.exists():
            for frame_path in folder.glob("frame_*.png"):
                frame_path.unlink()

    index = 0
    for frame in attack_gif[:IDLE_FRAMES]:
        save(frame, OUT / f"frame_{index:03d}.png")
        index += 1
    for frame in attack:
        save(frame, OUT / f"frame_{index:03d}.png")
        index += 1
    for frame in hit:
        save(frame, OUT / f"frame_{index:03d}.png")
        index += 1

    for frame_index, frame in enumerate(run):
        save(frame, OUT / "run" / f"frame_{frame_index:03d}.png")

    attack_start = IDLE_FRAMES
    attack_end = attack_start + len(attack) - 1
    hit_start = attack_end + 1
    hit_end = hit_start + len(hit) - 1
    print(
        f"Exported warrior_boar: idle 0-{IDLE_FRAMES - 1}, attack {attack_start}-{attack_end}, "
        f"hit {hit_start}-{hit_end}, run {len(run)} (no death)"
    )


if __name__ == "__main__":
    main()
