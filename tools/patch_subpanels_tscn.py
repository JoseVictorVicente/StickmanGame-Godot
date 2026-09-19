#!/usr/bin/env python3
"""Patch formation, skills, forge, warehouse tscn files for UI migration."""
from __future__ import annotations

from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
INV = ROOT / "presentation/inventory"


def patch_formation() -> None:
    path = INV / "formation_panel.tscn"
    text = path.read_text(encoding="utf-8")
    if "FormationSlot0" in text:
        return
    if 'id="10_formslot"' not in text:
        text = text.replace(
            '[ext_resource type="Script" path="res://presentation/inventory/formation_panel.gd" id="1_formacao"]\n',
            '[ext_resource type="Script" path="res://presentation/inventory/formation_panel.gd" id="1_formacao"]\n'
            '[ext_resource type="PackedScene" uid="uid://c8formslot01" '
            'path="res://presentation/inventory/formation_party_slot.tscn" id="10_formslot"]\n',
        )
    slots = ""
    for i in range(3):
        slots += (
            f'\n[node name="FormationSlot{i}" parent="Conteudo/CorpoFormacao/FormationSlots" '
            f'instance=ExtResource("10_formslot")]\n'
            f"unique_name_in_owner = true\n"
            f"layout_mode = 2\n"
        )
    text = text.replace(
        '[node name="FormationSlots" type="HBoxContainer" parent="Conteudo/CorpoFormacao"]\n'
        "unique_name_in_owner = true\n"
        "layout_mode = 2\n"
        "theme_override_constants/separation = 8\n"
        "alignment = 1\n",
        '[node name="FormationSlots" type="HBoxContainer" parent="Conteudo/CorpoFormacao"]\n'
        "unique_name_in_owner = true\n"
        "layout_mode = 2\n"
        "theme_override_constants/separation = 8\n"
        "alignment = 1\n"
        + slots,
    )
    path.write_text(text, encoding="utf-8")
    print("Patched formation_panel.tscn")


def patch_skills() -> None:
    path = INV / "skills_panel.tscn"
    text = path.read_text(encoding="utf-8")
    if "EquippedActiveSlot0" in text:
        return
    active = ""
    for i in range(2):
        active += (
            f'\n[node name="EquippedActiveSlot{i}" type="Button" '
            f'parent="Conteudo/SkillsPanelCorpo/RolagemSkills/ConteudoSkills/EquippedSection/LinhaEquipadas/ColunaEquipAtivas/CentralEquipAtivas/EquippedActiveGrid"]\n'
            f"unique_name_in_owner = true\n"
            f"custom_minimum_size = Vector2(120, 64)\n"
            f"layout_mode = 2\n"
            f'theme_override_font_sizes/font_size = 10\n'
            f'theme_override_styles/normal = SubResource("StyleBoxFlat_slot_skill")\n'
            f'text = "+"\n'
            f"autowrap_mode = 3\n"
        )
    passive = ""
    for i in range(2):
        passive += (
            f'\n[node name="EquippedPassiveSlot{i}" type="Button" '
            f'parent="Conteudo/SkillsPanelCorpo/RolagemSkills/ConteudoSkills/EquippedSection/LinhaEquipadas/ColunaEquipPassivas/CentralEquipPassivas/EquippedPassiveGrid"]\n'
            f"unique_name_in_owner = true\n"
            f"custom_minimum_size = Vector2(120, 64)\n"
            f"layout_mode = 2\n"
            f'theme_override_font_sizes/font_size = 10\n'
            f'theme_override_styles/normal = SubResource("StyleBoxFlat_slot_skill")\n'
            f'text = "+"\n'
            f"autowrap_mode = 3\n"
        )
    text = text.replace(
        '[node name="EquippedActiveGrid" type="GridContainer"',
        '[node name="EquippedActiveGrid" type="GridContainer"',
    )
    marker = (
        '[node name="EquippedActiveGrid" type="GridContainer" '
        'parent="Conteudo/SkillsPanelCorpo/RolagemSkills/ConteudoSkills/EquippedSection/LinhaEquipadas/ColunaEquipAtivas/CentralEquipAtivas"]\n'
        "unique_name_in_owner = true\n"
        "layout_mode = 2\n"
        "theme_override_constants/h_separation = 10\n"
        "theme_override_constants/v_separation = 10\n"
        "columns = 2\n"
    )
    text = text.replace(marker, marker + active)
    marker2 = (
        '[node name="EquippedPassiveGrid" type="GridContainer" '
        'parent="Conteudo/SkillsPanelCorpo/RolagemSkills/ConteudoSkills/EquippedSection/LinhaEquipadas/ColunaEquipPassivas/CentralEquipPassivas"]\n'
        "unique_name_in_owner = true\n"
        "layout_mode = 2\n"
        "theme_override_constants/h_separation = 10\n"
        "theme_override_constants/v_separation = 10\n"
        "columns = 2\n"
    )
    text = text.replace(marker2, marker2 + passive)
    path.write_text(text, encoding="utf-8")
    print("Patched skills_panel.tscn")


def patch_forge() -> None:
    path = INV / "forge_panel.tscn"
    text = path.read_text(encoding="utf-8")
    if 'forge_slots_grid.gd' in text:
        return
    text = text.replace(
        '[ext_resource type="Script" path="res://presentation/inventory/forge_panel.gd" id="1_ferraria"]\n',
        '[ext_resource type="Script" path="res://presentation/inventory/forge_panel.gd" id="1_ferraria"]\n'
        '[ext_resource type="Script" path="res://presentation/inventory/forge_slots_grid.gd" id="10_forgegrid"]\n',
    )
    for grid_name in ("SynthesisGrid", "DismantleGrid"):
        text = text.replace(
            f'[node name="{grid_name}" type="GridContainer" parent="Conteudo/ForgeBody"]\n'
            f"unique_name_in_owner = true\n",
            f'[node name="{grid_name}" type="GridContainer" parent="Conteudo/ForgeBody"]\n'
            f"unique_name_in_owner = true\n"
            f'script = ExtResource("10_forgegrid")\n',
        )
    path.write_text(text, encoding="utf-8")
    print("Patched forge_panel.tscn")


def patch_warehouse() -> None:
    path = INV / "warehouse_panel.tscn"
    text = path.read_text(encoding="utf-8")
    if "GradeAba_0" in text:
        return
    if 'id="10_whgrid"' not in text:
        text = text.replace(
            '[ext_resource type="Script" uid="uid://d1rs5e5nat6rx" '
            'path="res://presentation/inventory/warehouse_panel.gd" id="1_armazem"]\n',
            '[ext_resource type="Script" uid="uid://d1rs5e5nat6rx" '
            'path="res://presentation/inventory/warehouse_panel.gd" id="1_armazem"]\n'
            '[ext_resource type="PackedScene" uid="uid://c8whslots01" '
            'path="res://presentation/inventory/warehouse_slots_grid.tscn" id="10_whgrid"]\n',
        )
    tabs = ""
    for i in range(8):
        label = str(i + 1) if i == 0 else "🔒"
        disabled = "false" if i == 0 else "true"
        tabs += (
            f'\n[node name="Tab_{i + 1}" type="Button" parent="Conteudo/TabRow"]\n'
            f"custom_minimum_size = Vector2(0, 28)\n"
            f"layout_mode = 2\n"
            f"size_flags_horizontal = 3\n"
            f"size_flags_vertical = 4\n"
            f'theme_override_font_sizes/font_size = 12\n'
            f'text = "{label}"\n'
            f"disabled = {disabled}\n"
        )
    grids = ""
    for i in range(8):
        grids += (
            f'\n[node name="GradeAba_{i}" parent="Conteudo/CentralizarGrade/WarehouseGrid" '
            f'instance=ExtResource("10_whgrid")]\n'
            f"visible = {'true' if i == 0 else 'false'}\n"
            f"layout_mode = 2\n"
        )
    text = text.replace(
        '[node name="TabRow" type="GridContainer" parent="Conteudo"]\n'
        "unique_name_in_owner = true\n"
        "layout_mode = 2\n"
        "theme_override_constants/h_separation = 4\n"
        "theme_override_constants/v_separation = 4\n"
        "columns = 4\n",
        '[node name="TabRow" type="GridContainer" parent="Conteudo"]\n'
        "unique_name_in_owner = true\n"
        "layout_mode = 2\n"
        "theme_override_constants/h_separation = 4\n"
        "theme_override_constants/v_separation = 4\n"
        "columns = 4\n"
        + tabs,
    )
    text = text.replace(
        '[node name="WarehouseGrid" type="GridContainer" parent="Conteudo/CentralizarGrade"]\n'
        "unique_name_in_owner = true\n"
        "layout_mode = 2\n"
        "columns = 1\n",
        '[node name="WarehouseGrid" type="GridContainer" parent="Conteudo/CentralizarGrade"]\n'
        "unique_name_in_owner = true\n"
        "layout_mode = 2\n"
        "columns = 1\n"
        + grids,
    )
    path.write_text(text, encoding="utf-8")
    print("Patched warehouse_panel.tscn")


def main() -> None:
    patch_formation()
    patch_skills()
    patch_forge()
    patch_warehouse()


if __name__ == "__main__":
    main()
