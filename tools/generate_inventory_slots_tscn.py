#!/usr/bin/env python3
"""Generate inventory_slots_grid.tscn with 50 baked ItemSlot instances."""
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
OUT = ROOT / "presentation" / "inventory" / "inventory_slots_grid.tscn"

lines = [
    '[gd_scene load_steps=3 format=3 uid="uid://c8invslots01"]',
    "",
    '[ext_resource type="Script" path="res://presentation/inventory/inventory_slots_grid.gd" id="1_grid"]',
    '[ext_resource type="PackedScene" uid="uid://c8itemslot01" path="res://presentation/inventory/item_slot.tscn" id="2_slot"]',
    "",
    '[node name="InventoryGrid" type="GridContainer"]',
    "custom_minimum_size = Vector2(378, 196)",
    "columns = 10",
    "theme_override_constants/h_separation = 2",
    "theme_override_constants/v_separation = 2",
    'script = ExtResource("1_grid")',
]
for index in range(1, 51):
    lines.append("")
    lines.append(f'[node name="SlotInventario_{index:02d}" parent="." instance=ExtResource("2_slot")]')
    lines.append("custom_minimum_size = Vector2(36, 36)")
    lines.append("layout_mode = 2")
OUT.write_text("\n".join(lines) + "\n", encoding="utf-8")
print(f"Wrote {OUT}")
