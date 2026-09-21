#!/usr/bin/env python3
"""Bake party hero buttons into formation_panel.tscn FormationHeroGrid."""
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
PANEL = ROOT / "presentation" / "inventory" / "formation_panel.tscn"
CLASS_IDS = ["priest", "tank", "assassin", "archer", "mage", "warrior"]

GRID_SCRIPT = '[ext_resource type="Script" path="res://presentation/inventory/formation_hero_grid.gd" id="11_hero_grid"]'
HERO_BTN = '[ext_resource type="PackedScene" uid="uid://c8partybtn01" path="res://presentation/inventory/party_hero_slot_button.tscn" id="12_hero_btn"]'


def main() -> None:
    text = PANEL.read_text(encoding="utf-8")
    if "formation_hero_grid.gd" not in text:
        insert_at = text.find("[sub_resource type=")
        text = text[:insert_at] + GRID_SCRIPT + "\n" + HERO_BTN + "\n\n" + text[insert_at:]
        text = text.replace("load_steps=3", "load_steps=5", 1)

    grid_start = text.find('[node name="FormationHeroGrid"')
    grid_end = text.find("\n\n[node name=", grid_start + 1)
    if grid_end == -1:
        grid_end = len(text)

    children = []
    for class_id in CLASS_IDS:
        children.append(
            f'\n[node name="Hero_{class_id}" parent="Conteudo/CorpoFormacao/HeroScroll/FormationHeroGrid" instance=ExtResource("12_hero_btn")]'
            f"\nlayout_mode = 2\n"
            f'custom_minimum_size = Vector2(86, 98)\n'
            f'metadata/class_id = "{class_id}"'
        )

    new_grid = (
        '[node name="FormationHeroGrid" type="GridContainer" parent="Conteudo/CorpoFormacao/HeroScroll"]\n'
        "unique_name_in_owner = true\n"
        "layout_mode = 2\n"
        "size_flags_horizontal = 3\n"
        "theme_override_constants/h_separation = 8\n"
        "theme_override_constants/v_separation = 8\n"
        "columns = 3\n"
        'script = ExtResource("11_hero_grid")'
        + "".join(children)
        + "\n"
    )
    text = text[:grid_start] + new_grid + text[grid_end:]
    PANEL.write_text(text, encoding="utf-8")
    print(f"Patched {PANEL}")


if __name__ == "__main__":
    main()
