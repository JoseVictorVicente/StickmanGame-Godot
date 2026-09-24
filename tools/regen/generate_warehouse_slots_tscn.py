#!/usr/bin/env python3
"""Generate warehouse_slots_grid.tscn with 35 baked ItemSlot instances (5x7)."""
from pathlib import Path

ROOT = Path(__file__).resolve().parents[2]
OUT = ROOT / "presentation" / "inventory" / "warehouse_slots_grid.tscn"

lines = [
    '[gd_scene load_steps=3 format=3 uid="uid://c8whslots01"]',
    "",
    '[ext_resource type="Script" path="res://presentation/inventory/warehouse_slots_grid.gd" id="1_grid"]',
    '[ext_resource type="PackedScene" uid="uid://c8itemslot01" path="res://presentation/inventory/item_slot.tscn" id="2_slot"]',
    "",
    '[node name="WarehouseSlotsGrid" type="GridContainer"]',
    "columns = 5",
    "theme_override_constants/h_separation = 4",
    "theme_override_constants/v_separation = 4",
    'script = ExtResource("1_grid")',
]
for index in range(1, 36):
    lines.append("")
    lines.append(f'[node name="SlotArmazem_{index:02d}" parent="." instance=ExtResource("2_slot")]')
    lines.append("custom_minimum_size = Vector2(42, 42)")
    lines.append("layout_mode = 2")
OUT.write_text("\n".join(lines) + "\n", encoding="utf-8")
print(f"Wrote {OUT}")
