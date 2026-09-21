#!/usr/bin/env python3
"""Add baked equipment grids for all classes in hero_section.tscn."""
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
HERO = ROOT / "presentation" / "inventory" / "hero_section.tscn"

CLASSES = ["priest", "tank", "assassin", "archer", "mage"]


def main() -> None:
    text = HERO.read_text(encoding="utf-8")
    for class_id in CLASSES:
        left_name = f"EquipLeft_{class_id}"
        right_name = f"EquipRight_{class_id}"
        if left_name in text:
            continue
        left_insert = text.find("\n[node name=\"ColunaPersonagem\"")
        if left_insert == -1:
            raise SystemExit("ColunaPersonagem not found")
        left_block = (
            f'\n[node name="{left_name}" parent="EquipLeft" instance=ExtResource("3_ext")]\n'
            "visible = false\n"
            "layout_mode = 2\n"
        )
        text = text[:left_insert] + left_block + text[left_insert:]

        right_marker = '[node name="EquipRight" type="VBoxContainer" parent="."'
        right_start = text.find(right_marker)
        gold_end = text.find("\n[node name=\"EquipRight_warrior\"", right_start)
        if gold_end == -1:
            gold_end = text.find("\n[node name=\"ColunaPersonagem\"", right_start)
        right_block = (
            f'\n[node name="{right_name}" parent="EquipRight" instance=ExtResource("4_ext")]\n'
            "visible = false\n"
            "layout_mode = 2\n"
        )
        text = text[:gold_end] + right_block + text[gold_end:]

    HERO.write_text(text, encoding="utf-8")
    print(f"Patched {HERO}")


if __name__ == "__main__":
    main()
