"""Extract mage rabbit GIF frames into sprites/heroes/mage_rabbit/."""
from __future__ import annotations

from pathlib import Path

from PIL import Image

REPO = Path(__file__).resolve().parents[1]
ASSETS = REPO.parents[0] / ".cursor" / "projects" / "d-Desktop-Tudo-Godot-Projetos-StickmanGame" / "assets"
if not ASSETS.exists():
    ASSETS = Path(
        r"C:\Users\JOSÉ VICTOR\.cursor\projects\d-Desktop-Tudo-Godot-Projetos-StickmanGame\assets"
    )

OUT = REPO / "sprites" / "heroes" / "mage_rabbit"
IDLE_GIF = ASSETS / (
    "c__Users_JOS__VICTOR_AppData_Roaming_Cursor_User_workspaceStorage_098f0db4257eb69add82d568288cd2b1_"
    "images_idle_mage-4a31a32e-f11a-413f-9fb4-cef39a036681.gif"
)
RUN_GIF = ASSETS / (
    "c__Users_JOS__VICTOR_AppData_Roaming_Cursor_User_workspaceStorage_098f0db4257eb69add82d568288cd2b1_"
    "images_run_mage-195fa21f-2a11-4948-a4f7-6bd6f10e6ed4.gif"
)
ATK_GIF = ASSETS / (
    "c__Users_JOS__VICTOR_AppData_Roaming_Cursor_User_workspaceStorage_098f0db4257eb69add82d568288cd2b1_"
    "images_attack_mage-27346ba1-9c2f-4dd2-b9f8-6d8891fbb769.gif"
)
DEATH_GIF = ASSETS / (
    "c__Users_JOS__VICTOR_AppData_Roaming_Cursor_User_workspaceStorage_098f0db4257eb69add82d568288cd2b1_"
    "images_death_mage-ba063bba-534c-46ce-a08c-76d3c2e1aa5b.gif"
)


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
    if not IDLE_GIF.exists():
        raise SystemExit(f"Missing idle GIF: {IDLE_GIF}")
    if not RUN_GIF.exists():
        raise SystemExit(f"Missing run GIF: {RUN_GIF}")
    if not ATK_GIF.exists():
        raise SystemExit(f"Missing attack GIF: {ATK_GIF}")
    if not DEATH_GIF.exists():
        raise SystemExit(f"Missing death GIF: {DEATH_GIF}")

    idle = load_frames(IDLE_GIF)
    run = load_frames(RUN_GIF)
    attack = load_frames(ATK_GIF)
    death = load_frames(DEATH_GIF)

    for sub in ("", "run", "death"):
        folder = OUT / sub if sub else OUT
        if folder.exists():
            for frame_path in folder.glob("frame_*.png"):
                frame_path.unlink()

    index = 0
    for frame in idle:
        save(frame, OUT / f"frame_{index:03d}.png")
        index += 1
    for frame in attack:
        save(frame, OUT / f"frame_{index:03d}.png")
        index += 1
    for frame in attack[:3]:
        save(frame, OUT / f"frame_{index:03d}.png")
        index += 1

    for frame_index, frame in enumerate(run):
        save(frame, OUT / "run" / f"frame_{frame_index:03d}.png")
    for frame_index, frame in enumerate(death):
        save(frame, OUT / "death" / f"frame_{frame_index:03d}.png")

    attack_start = 4
    attack_end = attack_start + len(attack) - 1
    hit_start = attack_end + 1
    hit_end = hit_start + 2
    print(
        f"Exported mage_rabbit: idle 0-3, attack {attack_start}-{attack_end}, "
        f"hit {hit_start}-{hit_end}, run {len(run)}, death {len(death)}"
    )


if __name__ == "__main__":
    main()
