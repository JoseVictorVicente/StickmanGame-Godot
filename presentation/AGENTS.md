# Presentation layer

- UI emits commands; never mutates `GameState` directly
- All visible strings via `tr(LocaleKeys.*)` and `locales/*.po`
- `shared/` — window manager, icons, coin VFX
- `worlds/` — world map UI
- `inventory/` — inventory panels

## UI scene checklist

**Canonical layout guide:** [`docs/conventions/ui-layout.md`](../docs/conventions/ui-layout.md)

1. **Structure in `.tscn`** — use `VBoxContainer` / `HBoxContainer` / `GridContainer` + `custom_minimum_size`; avoid manual `layout_mode = 0` except documented exceptions (dynamic canvases, full-bleed overlays via `PanelLayout.align_overlays`).
2. **Prefabs for repeats** — `item_slot.tscn`, `equipment_grid.tscn`, `inventory_slots_grid.tscn` (50 baked slots), `equipment_grid_left.tscn` / `equipment_grid_right.tscn` (all 6 classes baked in `hero_section.tscn`), `warehouse_slots_grid.tscn` (8 tabs × 40), `forge_slots_grid.tscn`, `attribute_row.tscn` (12 rows), `party_hero_slot_button.tscn`, `formation_party_slot.tscn`, `formation_hero_grid.gd`, `skills_active_grid.tscn` (6 slots), `skills_passive_grid.tscn` (10 slots), `skill_slot_active.tscn`, `skill_slot_passive.tscn`.
3. **Hub prefabs** — `hero_section.tscn`, `inventory_row.tscn`, `bottom_nav.tscn` instanced from `inventory_menu.tscn`; edit layout in each `.tscn` (WYSIWYG).
4. **`%UniqueName`** — mark nodes referenced from scripts; bind with `@onready var foo = %Foo`.
5. **Layout resource** — `InventoryLayout` (`inventory_layout_default.tres`): `base_unit` scales portrait, party, equip, and **10×5** inventory grid; `_apply_panel_layout()` applies tokens at runtime without overwriting designer sizes in the editor.
6. **Runtime loops** — `InventorySlotsGrid.setup(connect)` wires signals to baked slots; `EquipmentGrid.build_slots()` reuses baked children when counts match. `configure()` for data-driven panels only.
7. **Signals up, calls down** — child widgets emit or call parent controller; domain code never references `Control` nodes.
8. **`@tool`** — slot-grid helpers that auto-fill empty grids in the editor; overlay panels and `inventory_menu.gd` stay non-`@tool`.

## Inventory menu layout

- Shell: `OverlayVBox` (`TopSpacer` + `MenuArea` HBox + `BottomSpacer`) — see [`ui-layout.md`](../docs/conventions/ui-layout.md).
- Main panel: [`inventory_menu.tscn`](inventory/inventory_menu.tscn) + [`inventory_menu.gd`](inventory/inventory_menu.gd) (controller).
- Hub blocks: `AreaHeroi` → `hero_section.tscn`, `LinhaInventario` → `inventory_row.tscn`, `MenuInferior` → `bottom_nav.tscn`.
- Equipment: six class pairs (`EquipLeft_*` / `EquipRight_*`) baked in `hero_section.tscn`; runtime toggles `visible` only.
- Party row: three `party_hero_slot_button.tscn` under `TeamArea/%PartySlots`; `TeamSelectionUI` updates state only.
- Visual offsets: `HeroSection.apply_layout_offsets()` applies `portrait_region_offset` and `formation_button_offset` from `InventoryLayout`.
- Side panels (warehouse, forge, worlds): children of `MenuArea` (`HBoxContainer`); width from `MenuArea.get_combined_minimum_size()`.
- Full-bleed swaps (formation, skills, attributes, skill tree): hub `Panel` (`PanelContainer`) + [`panel_layout.gd`](inventory/panel_layout.gd) `align_overlays`.
- Overlay constants: [`ui_constants.gd`](shared/ui_constants.gd); `set_below_combat()` toggles spacers, not fixed window offsets.

## Create / edit screens (agents)

**Skill:** `/edit-ui-screens` — full workflow including **mandatory visual capture** after layout edits.

**Doc:** [`docs/workflows/ui-screens.md`](../docs/workflows/ui-screens.md)

After any `presentation/inventory/` layout change:

```powershell
powershell -ExecutionPolicy Bypass -File tools/run_inventory_menu_visual_capture.ps1
```

Then read all ten PNGs in `artifacts/inventory_layout/`. See `/capture-menu-screens`.

## Manual check (inventory hub)

1. Open `inventory_menu.tscn` → hero section, **50-slot grid**, sort button, chest, bottom nav visible without F5.
2. Open `inventory_slots_grid.tscn` → tweak slot size/separation; confirm change propagates to menu instance.
3. F5 → pickup, sort, drag, equip, save/load unchanged.
4. Open each overlay `.tscn` in isolation → no parse errors in Output.
5. Run visual capture (above) and confirm all ten screens look correct.
