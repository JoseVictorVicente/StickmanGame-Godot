#!/usr/bin/env python3
"""Bake jewelry slots into forge_panel.tscn GemsArea."""
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
PANEL = ROOT / "presentation" / "inventory" / "forge_panel.tscn"

EXT_SLOT = '[ext_resource type="PackedScene" path="res://presentation/inventory/item_slot.tscn" id="11_itemslot"]'
EXT_ARROW = '[ext_resource type="Script" path="res://presentation/inventory/imbue_arrow.gd" id="12_arrow"]'


def main() -> None:
    text = PANEL.read_text(encoding="utf-8")
    if "imbue_arrow.gd" not in text:
        insert_at = text.find("[sub_resource type=")
        additions = EXT_SLOT + "\n" + EXT_ARROW + "\n\n"
        text = text[:insert_at] + additions + text[insert_at:]
        load_steps = int(text.split("load_steps=")[1].split()[0])
        text = text.replace(f"load_steps={load_steps}", f"load_steps={load_steps + 2}", 1)

    marker = '[node name="GemsArea" type="HBoxContainer" parent="Conteudo/ForgeBody"]'
    start = text.find(marker)
    if start == -1:
        raise SystemExit("GemsArea not found")
    end = text.find("\n\n[node name=", start + 1)
    if end == -1:
        end = len(text)

    block = (
        '[node name="GemsArea" type="HBoxContainer" parent="Conteudo/ForgeBody"]\n'
        "unique_name_in_owner = true\n"
        "visible = false\n"
        "z_index = 2\n"
        "layout_mode = 0\n"
        "mouse_filter = 2\n"
        "theme_override_constants/separation = 0\n"
        "alignment = 1\n"
        '\n[node name="SlotJoiaAlvo" parent="Conteudo/ForgeBody/GemsArea" instance=ExtResource("11_itemslot")]\n'
        "unique_name_in_owner = true\n"
        "layout_mode = 2\n"
        "custom_minimum_size = Vector2(44, 44)\n"
        '\n[node name="SetaImbuir" type="Control" parent="Conteudo/ForgeBody/GemsArea"]\n'
        "unique_name_in_owner = true\n"
        "layout_mode = 2\n"
        "custom_minimum_size = Vector2(32, 44)\n"
        'script = ExtResource("12_arrow")\n'
        '\n[node name="SlotJoiaGema" parent="Conteudo/ForgeBody/GemsArea" instance=ExtResource("11_itemslot")]\n'
        "unique_name_in_owner = true\n"
        "layout_mode = 2\n"
        "custom_minimum_size = Vector2(44, 44)\n"
    )

    text = text[:start] + block + "\n" + text[end:]
    PANEL.write_text(text, encoding="utf-8")
    print(f"Patched {PANEL}")


if __name__ == "__main__":
    main()
