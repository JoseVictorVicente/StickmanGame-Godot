#!/usr/bin/env python3
"""Generate skills_active_grid.tscn and skills_passive_grid.tscn with baked slots."""
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
INV = ROOT / "presentation" / "inventory"
SKILLS_ROW_WIDTH = 5 * 48 + 4 * 6


def write_active_grid() -> None:
    out = INV / "skills_active_grid.tscn"
    lines = [
        '[gd_scene load_steps=4 format=3 uid="uid://c8skillsact1"]',
        "",
        '[ext_resource type="Script" path="res://presentation/inventory/skills_active_grid.gd" id="1_grid"]',
        '[ext_resource type="PackedScene" path="res://presentation/inventory/skill_slot_active.tscn" id="2_slot"]',
        '[ext_resource type="PackedScene" path="res://presentation/inventory/skill_type_slot.tscn" id="3_type"]',
        "",
        '[node name="ActiveGrid" type="VBoxContainer"]',
        "layout_mode = 2",
        "theme_override_constants/separation = 8",
        "alignment = 1",
        'script = ExtResource("1_grid")',
    ]
    slot_index = 1
    for row_index in range(1, 4):
        lines += [
            "",
            f'[node name="ActiveRow_{row_index:02d}" type="HBoxContainer" parent="."]',
            "layout_mode = 2",
            "theme_override_constants/separation = 8",
            "alignment = 1",
            "",
            f'[node name="TypeSlot_{row_index:02d}" parent="ActiveRow_{row_index:02d}" instance=ExtResource("3_type")]',
            "layout_mode = 2",
            "custom_minimum_size = Vector2(56, 56)",
            "",
            f'[node name="SkillsRow_{row_index:02d}" type="HBoxContainer" parent="ActiveRow_{row_index:02d}"]',
            "layout_mode = 2",
            f"custom_minimum_size = Vector2({SKILLS_ROW_WIDTH}, 48)",
            "theme_override_constants/separation = 6",
            "alignment = 1",
        ]
        for _ in range(5):
            lines += [
                "",
                f'[node name="ActiveSkillSlot_{slot_index:02d}" parent="ActiveRow_{row_index:02d}/SkillsRow_{row_index:02d}" instance=ExtResource("2_slot")]',
                "layout_mode = 2",
                "custom_minimum_size = Vector2(48, 48)",
                "disabled = true",
            ]
            slot_index += 1
    out.write_text("\n".join(lines) + "\n", encoding="utf-8")
    print(f"Wrote {out}")


def write_passive_grid() -> None:
    out = INV / "skills_passive_grid.tscn"
    lines = [
        '[gd_scene load_steps=3 format=3 uid="uid://c8skillspas1"]',
        "",
        '[ext_resource type="Script" path="res://presentation/inventory/skills_passive_grid.gd" id="1_grid"]',
        '[ext_resource type="PackedScene" path="res://presentation/inventory/skill_slot_passive.tscn" id="2_slot"]',
        "",
        '[node name="PassiveGrid" type="GridContainer"]',
        "layout_mode = 2",
        "theme_override_constants/h_separation = 6",
        "theme_override_constants/v_separation = 6",
        "columns = 5",
        'script = ExtResource("1_grid")',
    ]
    for index in range(1, 11):
        lines += [
            "",
            f'[node name="PassiveSkillSlot_{index:02d}" parent="." instance=ExtResource("2_slot")]',
            "layout_mode = 2",
            "custom_minimum_size = Vector2(48, 48)",
            "disabled = true",
        ]
    out.write_text("\n".join(lines) + "\n", encoding="utf-8")
    print(f"Wrote {out}")


if __name__ == "__main__":
    write_active_grid()
    write_passive_grid()
