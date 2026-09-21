#!/usr/bin/env python3
"""Bake 12 attribute rows into attributes_panel.tscn."""
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
PANEL = ROOT / "presentation" / "inventory" / "attributes_panel.tscn"

ROWS = [
    "attack", "hp", "xp", "xp_bonus", "gold_bonus", "attack_speed",
    "crit_chance", "crit_damage", "evasion", "phys_res", "arcane_res", "elemental_res",
]

EXT = '[ext_resource type="PackedScene" path="res://presentation/inventory/attribute_row.tscn" id="10_row"]'


def main() -> None:
    text = PANEL.read_text(encoding="utf-8")
    if "attribute_row.tscn" not in text:
        insert_at = text.find("[sub_resource type=")
        text = text[:insert_at] + EXT + "\n\n" + text[insert_at:]
        text = text.replace("load_steps=2", "load_steps=3", 1)

    marker = '[node name="AttributesList" type="VBoxContainer" parent="Conteudo/RolagemAtributos"]'
    start = text.find(marker)
    if start == -1:
        raise SystemExit("AttributesList not found")
    end = text.find("\n\n[node name=", start + 1)
    if end == -1:
        end = len(text)

    block = (
        '[node name="AttributesList" type="VBoxContainer" parent="Conteudo/RolagemAtributos"]\n'
        "unique_name_in_owner = true\n"
        "layout_mode = 2\n"
        "size_flags_vertical = 3\n"
        "theme_override_constants/separation = 4\n"
    )
    for key in ROWS:
        block += (
            f'\n[node name="AttrRow_{key}" parent="Conteudo/RolagemAtributos/AttributesList" instance=ExtResource("10_row")]\n'
            "layout_mode = 2\n"
            f'row_key = "{key}"\n'
        )

    text = text[:start] + block + "\n" + text[end:]
    PANEL.write_text(text, encoding="utf-8")
    print(f"Patched {PANEL}")


if __name__ == "__main__":
    main()
