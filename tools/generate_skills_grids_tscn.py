#!/usr/bin/env python3
"""Generate skills_active_grid.tscn and skills_passive_grid.tscn with baked slots."""
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
INV = ROOT / "presentation" / "inventory"


def write_active_grid() -> None:
    out = INV / "skills_active_grid.tscn"
    lines = [
        '[gd_scene load_steps=3 format=3 uid="uid://c8skillsact1"]',
        "",
        '[ext_resource type="Script" path="res://presentation/inventory/skills_active_grid.gd" id="1_grid"]',
        '[ext_resource type="PackedScene" path="res://presentation/inventory/skill_slot_active.tscn" id="2_slot"]',
        "",
        '[node name="ActiveGrid" type="GridContainer"]',
        "layout_mode = 2",
        "theme_override_constants/h_separation = 8",
        "theme_override_constants/v_separation = 8",
        "columns = 5",
        'script = ExtResource("1_grid")',
    ]
    for index in range(1, 7):
        lines += [
            "",
            f'[node name="ActiveSkillSlot_{index:02d}" parent="." instance=ExtResource("2_slot")]',
            "layout_mode = 2",
            "custom_minimum_size = Vector2(64, 64)",
            "disabled = true",
        ]
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
        "theme_override_constants/h_separation = 8",
        "theme_override_constants/v_separation = 8",
        "columns = 5",
        'script = ExtResource("1_grid")',
    ]
    for index in range(1, 11):
        lines += [
            "",
            f'[node name="PassiveSkillSlot_{index:02d}" parent="." instance=ExtResource("2_slot")]',
            "layout_mode = 2",
            "custom_minimum_size = Vector2(64, 64)",
            "disabled = true",
        ]
    out.write_text("\n".join(lines) + "\n", encoding="utf-8")
    print(f"Wrote {out}")


if __name__ == "__main__":
    write_active_grid()
    write_passive_grid()
