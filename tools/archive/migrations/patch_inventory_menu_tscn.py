#!/usr/bin/env python3
"""Patch inventory_menu.tscn for UI migration phase A."""
from __future__ import annotations

import re
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
MENU = ROOT / "presentation/inventory/inventory_menu.tscn"


def main() -> None:
    text = MENU.read_text(encoding="utf-8")

    text = text.replace("HeroVisualSection/Conteudo/", "HeroVisualSection/")
    text = text.replace(
        '[ext_resource type="Script" uid="uid://ddxrgmur5t12s" '
        'path="res://presentation/inventory/section_visual_offset.gd" id="11_offset_visual"]\n',
        "",
    )
    text = text.replace('script = ExtResource("11_offset_visual")\n', "")
    text = text.replace(
        '[node name="HeroVisualSection" type="Control"',
        '[node name="HeroVisualSection" type="VBoxContainer"',
    )
    text = text.replace(
        "custom_minimum_size = Vector2(208, 137)\n"
        "layout_mode = 2\n"
        "size_flags_horizontal = 3\n"
        "mouse_filter = 2\n",
        "layout_mode = 2\n"
        "size_flags_horizontal = 3\n"
        "theme_override_constants/separation = 0\n",
    )

    text = re.sub(
        r'\n\[node name="Conteudo" type="VBoxContainer" '
        r'parent="CenterAnchor/MenuArea/Panel/Conteudo/AreaHeroi/ColunaPersonagem/HeroVisualSection"[^\]]*\]\n'
        r'layout_mode = [^\n]*\n'
        r'(?:offset_right = [^\n]*\n)?'
        r'(?:offset_bottom = [^\n]*\n)?'
        r'(?:size_flags_horizontal = [^\n]*\n)?'
        r'theme_override_constants/separation = 2\n',
        "\n",
        text,
    )

    text = text.replace(
        "CenterAnchor/MenuArea/Panel/Conteudo/AreaHeroi/ColunaPersonagem/TeamArea/FormationButtonHost/",
        "CenterAnchor/MenuArea/Panel/Conteudo/AreaHeroi/ColunaPersonagem/TeamArea/",
    )
    text = re.sub(
        r'\n\[node name="FormationButtonHost" type="Control"[^\]]*\]\n'
        r'(?:unique_name_in_owner = true\n)?'
        r'(?:custom_minimum_size = [^\n]*\n)?'
        r'layout_mode = [^\n]*\n'
        r'(?:mouse_filter = [^\n]*\n)?',
        "\n",
        text,
    )
    text = text.replace(
        "layout_mode = 0\n"
        "offset_right = 77.0\n"
        "offset_bottom = 31.0\n"
        "size_flags_horizontal = 3",
        "layout_mode = 2\nsize_flags_horizontal = 3",
    )

    quit_match = re.search(
        r'(\[node name="QuitGameButton" type="Button" parent="CenterAnchor/MenuArea/Panel/Conteudo"[^\]]*\]\n'
        r'(?:unique_name_in_owner = true\n)?'
        r'custom_minimum_size = Vector2\(96, 36\)\n'
        r'layout_mode = 2\n'
        r'size_flags_vertical = 4\n'
        r'(?:theme_override[^\n]*\n)*'
        r'text = "Sair do jogo"\n)',
        text,
    )
    if quit_match:
        quit_block = quit_match.group(1)
        quit_header = quit_block.replace(
            'parent="CenterAnchor/MenuArea/Panel/Conteudo"',
            'parent="CenterAnchor/MenuArea/Panel/Conteudo/Header"',
        )
        text = text.replace(quit_block, "")
        text = text.replace(
            '[node name="Header" type="HBoxContainer" parent="CenterAnchor/MenuArea/Panel/Conteudo"',
            quit_header
            + '[node name="Header" type="HBoxContainer" parent="CenterAnchor/MenuArea/Panel/Conteudo"',
        )

    if 'id="14_equipgrid"' not in text:
        text = text.replace(
            '[ext_resource type="PackedScene" uid="uid://c8invslots01" '
            'path="res://presentation/inventory/inventory_slots_grid.tscn" id="13_invslots"]\n',
            '[ext_resource type="PackedScene" uid="uid://c8invslots01" '
            'path="res://presentation/inventory/inventory_slots_grid.tscn" id="13_invslots"]\n'
            '[ext_resource type="PackedScene" uid="uid://c8equipgrid1" '
            'path="res://presentation/inventory/equipment_grid.tscn" id="14_equipgrid"]\n'
            '[ext_resource type="PackedScene" uid="uid://c8partybtn01" '
            'path="res://presentation/inventory/party_hero_slot_button.tscn" id="15_partybtn"]\n'
            '[ext_resource type="Resource" uid="uid://layoutinv001" '
            'path="res://presentation/inventory/inventory_layout_default.tres" id="12_layout_padrao"]\n',
        )

    if 'layout_inventario = ExtResource("12_layout_padrao")' not in text:
        text = text.replace(
            'script = ExtResource("1_menu")\n',
            'script = ExtResource("1_menu")\nlayout_inventario = ExtResource("12_layout_padrao")\n',
        )

    if "EquipLeft_warrior" not in text:
        equip_left = (
            '\n[node name="EquipLeft_warrior" parent="CenterAnchor/MenuArea/Panel/Conteudo/AreaHeroi/EquipLeft" '
            'instance=ExtResource("14_equipgrid")]\n'
            'layout_mode = 2\n'
            '\n[node name="EquipRight_warrior" parent="CenterAnchor/MenuArea/Panel/Conteudo/AreaHeroi/EquipRight" '
            'instance=ExtResource("14_equipgrid")]\n'
            'layout_mode = 2\n'
        )
        text = text.replace(
            '[node name="GoldSpacer" type="Control" parent="CenterAnchor/MenuArea/Panel/Conteudo/AreaHeroi/EquipRight"',
            equip_left
            + '[node name="GoldSpacer" type="Control" parent="CenterAnchor/MenuArea/Panel/Conteudo/AreaHeroi/EquipRight"',
        )

    if "PartySlot0" not in text:
        party_slots = ""
        for i in range(3):
            party_slots += (
                f'\n[node name="PartySlot{i}" parent="CenterAnchor/MenuArea/Panel/Conteudo/AreaHeroi/ColunaPersonagem/HeroVisualSection/PartySlots" '
                f'instance=ExtResource("15_partybtn")]\n'
                f"unique_name_in_owner = true\n"
                f"visible = false\n"
                f"layout_mode = 2\n"
            )
        text = text.replace(
            '[node name="PartySlots" type="HBoxContainer" parent="CenterAnchor/MenuArea/Panel/Conteudo/AreaHeroi/ColunaPersonagem/HeroVisualSection"',
            '[node name="PartySlots" type="HBoxContainer" parent="CenterAnchor/MenuArea/Panel/Conteudo/AreaHeroi/ColunaPersonagem/HeroVisualSection"'
            + party_slots,
        )

    text = text.replace(
        "offset_left = 190.0\noffset_right = 770.0\noffset_bottom = 520.0",
        "offset_left = 20.0\noffset_top = 0.0\noffset_right = 600.0\noffset_bottom = 520.0",
    )

    MENU.write_text(text, encoding="utf-8")
    print("Patched", MENU)


if __name__ == "__main__":
    main()
