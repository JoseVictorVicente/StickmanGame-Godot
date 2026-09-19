#!/usr/bin/env python3
"""Generate equipment_grid_left.tscn and equipment_grid_right.tscn with baked slots."""
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
INV = ROOT / "presentation" / "inventory"

LEFT = [
    ("Weapon", "WEAPON"),
    ("Offhand", "OFFHAND"),
    ("Helmet", "HELMET"),
    ("Chest", "CHEST"),
    ("Gloves", "GLOVES"),
    ("Pants", "PANTS"),
    ("Boots", "BOOTS"),
]
RIGHT = [
    ("Belt", "BELT"),
    ("Pendant", "PENDANT"),
    ("Ring", "RING"),
    ("Bracelet", "BRACELET"),
    ("Pet", "PET"),
]


def write_grid(path: Path, uid: str, node_name: str, slots: list[tuple[str, str]]) -> None:
    lines = [
        f'[gd_scene load_steps=3 format=3 uid="{uid}"]',
        "",
        '[ext_resource type="Script" path="res://presentation/inventory/equipment_grid.gd" id="1_grid"]',
        '[ext_resource type="PackedScene" uid="uid://c8itemslot01" path="res://presentation/inventory/item_slot.tscn" id="2_slot"]',
        "",
        f'[node name="{node_name}" type="GridContainer"]',
        "columns = 2",
        "theme_override_constants/h_separation = 4",
        "theme_override_constants/v_separation = 3",
        'script = ExtResource("1_grid")',
    ]
    for label, _tipo in slots:
        lines.append("")
        lines.append(f'[node name="Slot{label}" parent="." instance=ExtResource("2_slot")]')
        lines.append("custom_minimum_size = Vector2(36, 36)")
        lines.append("layout_mode = 2")
    path.write_text("\n".join(lines) + "\n", encoding="utf-8")
    print(f"Wrote {path}")


write_grid(INV / "equipment_grid_left.tscn", "uid://c8equipleft1", "EquipmentGridLeft", LEFT)
write_grid(INV / "equipment_grid_right.tscn", "uid://c8equipright1", "EquipmentGridRight", RIGHT)
