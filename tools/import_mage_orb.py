"""Copy mage orb projectile frames into sprites/projectiles/mage_orb/."""
from __future__ import annotations

from pathlib import Path
from shutil import copy2

REPO = Path(__file__).resolve().parents[1]
ASSETS = REPO.parents[0] / ".cursor" / "projects" / "d-Desktop-Tudo-Godot-Projetos-StickmanGame" / "assets"
if not ASSETS.exists():
    ASSETS = Path(
        r"C:\Users\JOSÉ VICTOR\.cursor\projects\d-Desktop-Tudo-Godot-Projetos-StickmanGame\assets"
    )

OUT = REPO / "sprites" / "projectiles" / "mage_orb"
FRAME_SOURCES = [
    "c__Users_JOS__VICTOR_AppData_Roaming_Cursor_User_workspaceStorage_098f0db4257eb69add82d568288cd2b1_"
    "images_mage_attack_frame_1-1b80dd27-77c8-4c98-8cc7-b5f8aa442f8f.png",
    "c__Users_JOS__VICTOR_AppData_Roaming_Cursor_User_workspaceStorage_098f0db4257eb69add82d568288cd2b1_"
    "images_mage_attack_frame_2-dd435ae0-4140-40cc-942b-c99a97a7520c.png",
    "c__Users_JOS__VICTOR_AppData_Roaming_Cursor_User_workspaceStorage_098f0db4257eb69add82d568288cd2b1_"
    "images_mage_attack_frame_3-de24ab89-9769-45e5-a32e-e992db55e64c.png",
    "c__Users_JOS__VICTOR_AppData_Roaming_Cursor_User_workspaceStorage_098f0db4257eb69add82d568288cd2b1_"
    "images_mage_attack_frame_4-aada7781-305e-45fc-a29c-6ac5f7c5f032.png",
]


def main() -> None:
    OUT.mkdir(parents=True, exist_ok=True)
    for frame_path in OUT.glob("frame_*.png"):
        frame_path.unlink()
    for index, source_name in enumerate(FRAME_SOURCES):
        source = ASSETS / source_name
        if not source.exists():
            raise SystemExit(f"Missing mage orb frame: {source}")
        copy2(source, OUT / f"frame_{index:03d}.png")
    print(f"Exported mage_orb: {len(FRAME_SOURCES)} frames")


if __name__ == "__main__":
    main()
