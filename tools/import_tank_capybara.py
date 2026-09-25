"""Extract tank capybara GIF frames into sprites/heroes/tank_capybara/."""
from __future__ import annotations

from pathlib import Path

from PIL import Image

REPO = Path(__file__).resolve().parents[1]
ASSETS = REPO.parents[0] / ".cursor" / "projects" / "d-Desktop-Tudo-Godot-Projetos-StickmanGame" / "assets"
if not ASSETS.exists():
    ASSETS = Path(
        r"C:\Users\JOSÉ VICTOR\.cursor\projects\d-Desktop-Tudo-Godot-Projetos-StickmanGame\assets"
    )

OUT = REPO / "sprites" / "heroes" / "tank_capybara"
RUN_GIF = ASSETS / (
    "c__Users_JOS__VICTOR_AppData_Roaming_Cursor_User_workspaceStorage_098f0db4257eb69add82d568288cd2b1_"
    "images_run_animation-d9cbf2a4-0848-4d38-8430-0f2026b0ce38.gif"
)
ATK_GIF = ASSETS / (
    "c__Users_JOS__VICTOR_AppData_Roaming_Cursor_User_workspaceStorage_098f0db4257eb69add82d568288cd2b1_"
    "images_melee_attack-8ccf5434-4c10-434d-b57b-71bc34a25bc5.gif"
)
DEATH_GIF = ASSETS / (
    "c__Users_JOS__VICTOR_AppData_Roaming_Cursor_User_workspaceStorage_098f0db4257eb69add82d568288cd2b1_"
    "images_death_animation-65ea8243-76c2-460c-8bb3-5b986976ffc3.gif"
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
    run = load_frames(RUN_GIF)
    attack = load_frames(ATK_GIF)
    death = load_frames(DEATH_GIF)

    for sub in ("", "run", "death"):
        folder = OUT / sub if sub else OUT
        if folder.exists():
            for frame_path in folder.glob("frame_*.png"):
                frame_path.unlink()

    index = 0
    for frame in run[:4]:
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
        f"Exported tank_capybara: idle 0-3, attack {attack_start}-{attack_end}, "
        f"hit {hit_start}-{hit_end}, run {len(run)}, death {len(death)}"
    )


if __name__ == "__main__":
    main()
