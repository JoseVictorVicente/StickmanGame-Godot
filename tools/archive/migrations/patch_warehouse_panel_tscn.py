#!/usr/bin/env python3
"""Patch warehouse_panel.tscn: bake 8 tabs + 8 warehouse_slots_grid instances."""
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
PANEL = ROOT / "presentation" / "inventory" / "warehouse_panel.tscn"

EXT_GRID = '[ext_resource type="PackedScene" path="res://presentation/inventory/warehouse_slots_grid.tscn" id="10_whgrid"]'


def main() -> None:
    text = PANEL.read_text(encoding="utf-8")
    if "warehouse_slots_grid.tscn" not in text:
        insert_at = text.find("[sub_resource type=")
        text = text[:insert_at] + EXT_GRID + "\n\n" + text[insert_at:]
        text = text.replace("load_steps=7", "load_steps=8", 1)

    tab_start = text.find('[node name="TabRow" type="GridContainer" parent="Conteudo"]')
    grid_start = text.find('[node name="WarehouseGrid" type="GridContainer" parent="Conteudo"]')
    footer_start = text.find('[node name="RodapeArmazem" type="HBoxContainer" parent="Conteudo"]')
    if tab_start == -1 or grid_start == -1 or footer_start == -1:
        raise SystemExit("warehouse_panel.tscn structure not found")

    tab_block = (
        '[node name="TabRow" type="GridContainer" parent="Conteudo"]\n'
        "unique_name_in_owner = true\n"
        "layout_mode = 2\n"
        "theme_override_constants/h_separation = 4\n"
        "theme_override_constants/v_separation = 4\n"
        "columns = 4\n"
    )
    for i in range(1, 9):
        locked = i > 1
        tab_block += (
            f'\n[node name="Tab_{i}" type="Button" parent="Conteudo/TabRow"]\n'
            "custom_minimum_size = Vector2(0, 28)\n"
            "layout_mode = 2\n"
            "size_flags_horizontal = 3\n"
            "size_flags_vertical = 4\n"
            "theme_override_font_sizes/font_size = 12\n"
            f'text = "{"🔒" if locked else str(i)}"\n'
            f"disabled = {str(locked).lower()}\n"
        )

    grid_block = (
        '[node name="WarehouseGrid" type="GridContainer" parent="Conteudo"]\n'
        "unique_name_in_owner = true\n"
        "layout_mode = 2\n"
        "size_flags_horizontal = 4\n"
        "size_flags_vertical = 3\n"
        "theme_override_constants/h_separation = 4\n"
        "theme_override_constants/v_separation = 4\n"
        "columns = 1\n"
    )
    for i in range(8):
        grid_block += (
            f'\n[node name="GradeAba_{i}" parent="Conteudo/WarehouseGrid" instance=ExtResource("10_whgrid")]\n'
            f"visible = {str(i == 0).lower()}\n"
            "layout_mode = 2\n"
        )

    text = text[:tab_start] + tab_block + "\n\n" + grid_block + "\n\n" + text[footer_start:]
    PANEL.write_text(text, encoding="utf-8")
    print(f"Patched {PANEL}")


if __name__ == "__main__":
    main()
