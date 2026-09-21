#!/usr/bin/env python3
"""Generate TSCN-first hub prefab scenes for inventory menu rebuild."""
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
INV = ROOT / "presentation" / "inventory"
SLOT = 42
SEP_H = 4
SEP_V = 3
SKILL_STYLE = """bg_color = Color(0.06, 0.05, 0.04, 1)
border_width_left = 2
border_width_top = 2
border_width_right = 2
border_width_bottom = 2
border_color = Color(0.55, 0.44, 0.26, 1)
corner_radius_top_left = 4
corner_radius_top_right = 4
corner_radius_bottom_right = 4
corner_radius_bottom_left = 4"""


def slot_node(name: str, parent: str = ".") -> list[str]:
    return [
        "",
        f'[node name="{name}" parent="{parent}" instance=ExtResource("2_slot")]',
        f"custom_minimum_size = Vector2({SLOT}, {SLOT})",
        "layout_mode = 2",
    ]


def spacer_node(name: str, parent: str = ".") -> list[str]:
    return [
        "",
        f'[node name="{name}" type="Control" parent="{parent}"]',
        f"custom_minimum_size = Vector2({SLOT}, {SLOT})",
        "layout_mode = 2",
        "mouse_filter = 2",
    ]


def skill_button(name: str, parent: str = ".", unique: bool = False) -> list[str]:
    lines = [
        "",
        f'[node name="{name}" type="Button" parent="{parent}"]',
    ]
    if unique:
        lines.append("unique_name_in_owner = true")
    lines += [
        f"custom_minimum_size = Vector2({SLOT}, {SLOT})",
        "layout_mode = 2",
        'theme_override_font_sizes/font_size = 9',
        'theme_override_styles/normal = SubResource("StyleBoxFlat_slot_skill")',
        'theme_override_styles/pressed = SubResource("StyleBoxFlat_botao_pressed")',
        'theme_override_styles/hover = SubResource("StyleBoxFlat_botao_hover")',
        'text = "+"',
        "autowrap_mode = 3",
    ]
    return lines


def write_left_panel() -> None:
    w = 3 * SLOT + 2 * SEP_H
    h = 4 * SLOT + 3 * SEP_V
    lines = [
        '[gd_scene format=3 uid="uid://c8heroeqleft"]',
        "",
        '[ext_resource type="Script" path="res://presentation/inventory/hero_equip_left_panel.gd" id="1_script"]',
        '[ext_resource type="PackedScene" uid="uid://c8itemslot01" path="res://presentation/inventory/item_slot.tscn" id="2_slot"]',
        "",
        '[sub_resource type="StyleBoxFlat" id="StyleBoxFlat_slot_skill"]',
        SKILL_STYLE,
        "",
        '[sub_resource type="StyleBoxFlat" id="StyleBoxFlat_botao_pressed"]',
        "bg_color = Color(0.1, 0.08, 0.07, 1)",
        "",
        '[sub_resource type="StyleBoxFlat" id="StyleBoxFlat_botao_hover"]',
        "bg_color = Color(0.32, 0.24, 0.16, 1)",
        "",
        '[node name="HeroEquipLeftPanel" type="GridContainer"]',
        "unique_name_in_owner = true",
        f"custom_minimum_size = Vector2({w}, {h})",
        "size_flags_horizontal = 0",
        "size_flags_vertical = 0",
        "theme_override_constants/h_separation = 4",
        "theme_override_constants/v_separation = 3",
        "columns = 3",
        'script = ExtResource("1_script")',
    ]
    lines += slot_node("SlotWeapon")
    lines += slot_node("SlotOffhand")
    lines += skill_button("SlotSkillAtiva0", unique=True)
    lines += slot_node("SlotHelmet")
    lines += slot_node("SlotChest")
    lines += skill_button("SlotSkillAtiva1", unique=True)
    lines += slot_node("SlotPants")
    lines += slot_node("SlotGloves")
    lines += spacer_node("CellSpacer22")
    lines += slot_node("SlotBoots")
    lines += spacer_node("CellSpacer31")
    lines += spacer_node("CellSpacer32")
    (INV / "hero_equip_left_panel.tscn").write_text("\n".join(lines) + "\n", encoding="utf-8")


def write_right_panel() -> None:
    grid_w = 3 * SLOT + 2 * SEP_H
    grid_h = 2 * SLOT + SEP_V
    pet_w = grid_w
    pet_h = int(SLOT * 1.55) + SEP_V
    lines = [
        '[gd_scene format=3 uid="uid://c8heroeqright"]',
        "",
        '[ext_resource type="Script" path="res://presentation/inventory/hero_equip_right_panel.gd" id="1_script"]',
        '[ext_resource type="PackedScene" uid="uid://c8itemslot01" path="res://presentation/inventory/item_slot.tscn" id="2_slot"]',
        "",
        '[sub_resource type="StyleBoxFlat" id="StyleBoxFlat_slot_skill"]',
        SKILL_STYLE,
        "",
        '[sub_resource type="StyleBoxFlat" id="StyleBoxFlat_botao_pressed"]',
        "bg_color = Color(0.1, 0.08, 0.07, 1)",
        "",
        '[sub_resource type="StyleBoxFlat" id="StyleBoxFlat_botao_hover"]',
        "bg_color = Color(0.32, 0.24, 0.16, 1)",
        "",
        '[sub_resource type="StyleBoxFlat" id="StyleBoxFlat_sort_normal"]',
        "bg_color = Color(0.06, 0.05, 0.04, 1)",
        "border_width_left = 2",
        "border_width_top = 2",
        "border_width_right = 2",
        "border_width_bottom = 2",
        "border_color = Color(0.72, 0.58, 0.28, 1)",
        "",
        '[node name="HeroEquipRightPanel" type="VBoxContainer"]',
        "unique_name_in_owner = true",
        f"custom_minimum_size = Vector2({grid_w}, {grid_h + 4 + pet_h + 4 + SLOT})",
        "theme_override_constants/separation = 4",
        'script = ExtResource("1_script")',
        "",
        '[node name="MainGrid" type="GridContainer" parent="."]',
        f"custom_minimum_size = Vector2({grid_w}, {grid_h})",
        "layout_mode = 2",
        "theme_override_constants/h_separation = 4",
        "theme_override_constants/v_separation = 3",
        "columns = 3",
    ]
    lines += skill_button("SlotSkillMenuPassiva0", parent="MainGrid", unique=True)
    lines += slot_node("SlotRing", "MainGrid")
    lines += slot_node("SlotPendant", "MainGrid")
    lines += skill_button("SlotSkillMenuPassiva1", parent="MainGrid", unique=True)
    lines += slot_node("SlotBracelet", "MainGrid")
    lines += slot_node("SlotBelt", "MainGrid")
    lines += [
        "",
        '[node name="SlotPet" parent="." instance=ExtResource("2_slot")]',
        "unique_name_in_owner = true",
        f"custom_minimum_size = Vector2({pet_w}, {pet_h})",
        "layout_mode = 2",
        "",
        '[node name="SortRow" type="HBoxContainer" parent="."]',
        f"custom_minimum_size = Vector2({pet_w}, {SLOT})",
        "layout_mode = 2",
        "",
        '[node name="SortRowSpacer" type="Control" parent="SortRow"]',
        "layout_mode = 2",
        "size_flags_horizontal = 3",
        "mouse_filter = 2",
        "",
        '[node name="SortInventoryButton" type="Button" parent="SortRow"]',
        "unique_name_in_owner = true",
        f"custom_minimum_size = Vector2({SLOT}, {SLOT})",
        "layout_mode = 2",
        'tooltip_text = "Organizar inventário"',
        'theme_override_styles/normal = SubResource("StyleBoxFlat_sort_normal")',
        'text = "F"',
    ]
    (INV / "hero_equip_right_panel.tscn").write_text("\n".join(lines) + "\n", encoding="utf-8")


def main() -> None:
    write_left_panel()
    write_right_panel()
    print("Wrote hero_equip_left_panel.tscn and hero_equip_right_panel.tscn")


if __name__ == "__main__":
    main()
