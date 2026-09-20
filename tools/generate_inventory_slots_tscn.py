#!/usr/bin/env python3
"""Generate inventory_slots_grid.tscn with 50 baked ItemSlot instances."""
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
OUT = ROOT / "presentation" / "inventory" / "inventory_slots_grid.tscn"

SLOT_SIZE = 42
H_SEP = 2
V_SEP = 2
COLS = 10
ROWS = 5
GRID_W = COLS * SLOT_SIZE + (COLS - 1) * H_SEP
GRID_H = ROWS * SLOT_SIZE + (ROWS - 1) * V_SEP

lines = [
    '[gd_scene load_steps=3 format=3 uid="uid://c8invslots01"]',
    "",
    '[ext_resource type="Script" path="res://presentation/inventory/inventory_slots_grid.gd" id="1_grid"]',
    '[ext_resource type="PackedScene" uid="uid://c8itemslot01" path="res://presentation/inventory/item_slot.tscn" id="2_slot"]',
    "",
    '[node name="InventoryGrid" type="GridContainer"]',
    f"custom_minimum_size = Vector2({GRID_W}, {GRID_H})",
    f"columns = {COLS}",
    f"theme_override_constants/h_separation = {H_SEP}",
    f"theme_override_constants/v_separation = {V_SEP}",
    'script = ExtResource("1_grid")',
]
for index in range(1, 51):
    lines.append("")
    lines.append(f'[node name="SlotInventario_{index:02d}" parent="." instance=ExtResource("2_slot")]')
    lines.append(f"custom_minimum_size = Vector2({SLOT_SIZE}, {SLOT_SIZE})")
    lines.append("layout_mode = 2")
OUT.write_text("\n".join(lines) + "\n", encoding="utf-8")
print(f"Wrote {OUT}")
