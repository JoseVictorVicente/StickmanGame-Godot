# Presentation layer

- UI emits commands; never mutates `GameState` directly
- All visible strings via `tr(LocaleKeys.*)` and `locales/*.po`
- `shared/` — window manager, icons, coin VFX
- `worlds/` — **Portals UI** (`WorldsPanel`: hall → briefing → trail). Canon: `docs/architecture/portals-saga.md`, data: `data/world_catalog.gd`
- `inventory/` — inventory panels

## UI scene checklist

**Canonical layout guide:** [`docs/conventions/ui-layout.md`](../docs/conventions/ui-layout.md)

1. **Structure in `.tscn`** — use `VBoxContainer` / `HBoxContainer` / `GridContainer` + `custom_minimum_size`; avoid manual `layout_mode = 0` except documented exceptions (dynamic canvases, full-bleed overlays via `PanelLayout.align_overlays`).
2. **Prefabs for repeats** — `item_slot.tscn`, `hero_equip_left_panel.tscn` / `hero_character_panel.tscn` / `hero_equip_right_panel.tscn`, `inventory_slots_grid.tscn` (5×10 baked slots), `warehouse_slots_grid.tscn` (8 tabs × 40), `forge_slots_grid.tscn`, `attribute_row.tscn` (12 rows), `party_hero_slot_button.tscn`, formation/skills slot prefabs.
3. **Hub prefabs** — five hub panels + `bottom_nav.tscn` + `settings_panel.tscn` instanced from `inventory_menu.tscn`; edit layout in each `.tscn` (WYSIWYG). Hub panels are `@tool` and apply `InventoryLayout` in the editor.
4. **`%UniqueName`** — mark nodes referenced from scripts; bind with `@onready var foo = %Foo`.
5. **Layout resource** — `InventoryLayout` (`inventory_layout_default.tres`): `base_unit` scales portrait, party, equip, and **5×10** inventory grid; each hub prefab calls `apply_layout()` for its zone; shell `_apply_panel_layout()` orchestrates at runtime.
6. **Runtime loops** — `InventorySlotsGrid.setup(connect)` wires signals to baked slots only. Equip/jewelry/pet/sort slots are baked in hub panel `.tscn` files; scripts resize via `apply_layout()` — no `add_child` / `queue_free` at runtime.
7. **Signals up, calls down** — child widgets emit or call parent controller; domain code never references `Control` nodes.
8. **`@tool`** — hub panels (`hero_equip_*`, `hero_character_panel`, `inventory_panel`, `bottom_nav`) and `inventory_slots_grid` preview layout in the editor; `inventory_menu.gd` stays non-`@tool`.

## Inventory menu architecture

Shell (`inventory_menu.gd`) is a thin orchestrator. Extracted controllers:

| Class | Role |
|-------|------|
| `InventoryDragController` | Slot click/drag/drop, selection |
| `InventoryPanelRouter` | Overlay vs side panel exclusivity, nav open/close |
| `InventoryPersistenceBridge` | Serialize/apply inventory, equipment, warehouse, skill tree |

Hub prefab public API:

- **`HeroEquipLeftPanel`** — `configure(menu)`, `apply_layout()`, `connect_equipment_slots()`, `all_equipment_slots()`, signal `skill_slot_pressed` (active)
- **`HeroCharacterPanel`** — `configure(menu)`, `apply_layout()`, `wire_character_selector()`, portrait/XP/party; signal `attributes_requested`
- **`HeroEquipRightPanel`** — `configure(menu)`, `apply_layout()`, `slots()`, `get_sort_button()`, signal `skill_slot_pressed` (passive)
- **`InventoryPanel`** — `configure(menu, layout)`, `apply_layout()`, exposes `inventory_grid`
- **`BottomNav`** — `configure(menu, layout)`, `apply_layout()`, signal `nav_requested(action)`
- **`SettingsPanel`** — volume/locale UI; wired by `InventoryMenu`

## Inventory menu layout

- Shell: `OverlayVBox` (`TopSpacer` + `MenuArea` HBox + `BottomSpacer`) — see [`ui-layout.md`](../docs/conventions/ui-layout.md).
- Main panel: [`inventory_menu.tscn`](inventory/inventory_menu.tscn) + [`inventory_menu.gd`](inventory/inventory_menu.gd) (controller).
- Hub shell: `HubColumn` (`HubChromeBar` above `%HubBody`) → `%HubContent`: `%HubUpperRow` (three hero panels) + `%InventoryPanel` + `%BottomNav`. Heights from `_apply_hub_content_heights()` + `InventoryLayout`.
- Sort button: baked in `hero_equip_right_panel.tscn` (`%SortInventoryButton`).
- Equipment slots: baked in `hero_equip_left_panel.tscn` / `hero_equip_right_panel.tscn`; per-class loadouts in `EquipmentLoadoutRegistry`.
- Party row: three `party_hero_slot_button.tscn` under `HeroCharacterPanel/TeamArea/%PartySlots`.
- Formation nav: `bottom_nav.tscn` `%FormationButton` → `nav_requested("formation")`.
- Hub visibility for overlays: `InventoryPanelRouter.set_inventory_visible()` — hides `%HubContent`, not `%HubBody`.
- Side panels (warehouse, forge, worlds): children of `MenuArea` (`HBoxContainer`).
- Full-bleed overlays: `%OverlayStack` under `%HubBody` + [`panel_layout.gd`](inventory/panel_layout.gd) `align_overlays(..., overlay_stack)`.
- Settings overlay: `settings_panel.tscn` instance in `%OverlayStack`.
- Overlay constants: [`ui_constants.gd`](shared/ui_constants.gd); `set_below_combat()` toggles spacers, not fixed window offsets.

## Create / edit screens (agents)

**Skill:** `/edit-ui-screens` — full workflow including **mandatory visual capture** after layout edits.

**Doc:** [`docs/workflows/ui-screens.md`](../docs/workflows/ui-screens.md)

After any `presentation/inventory/` layout change:

```powershell
powershell -ExecutionPolicy Bypass -File tools/run_inventory_menu_visual_capture.ps1
```

Then read the PNG(s) for the screen(s) you changed (see `/edit-ui-screens` Step 3 map). Use `/capture-menu-screens` when you need all ten screens reviewed.

## Manual check (inventory hub)

1. Open `inventory_menu.tscn` → hero section, **5×10 grid**, sort button, bottom nav visible without F5.
2. Open `inventory_slots_grid.tscn` → tweak slot size/separation; confirm change propagates to menu instance.
3. F5 → pickup, sort, drag, equip, save/load unchanged.
4. Open each overlay `.tscn` in isolation → no parse errors in Output.
5. Run visual capture (above) and confirm the edited screen(s) look correct in the matching PNG(s).
