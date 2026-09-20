# UI Layout Conventions

Godot UI should express **relationships between widgets** (stack, row, grid, margin) instead of manual pixel placement. This matches common practice in Android (`ConstraintLayout` / `LinearLayout`) and in Godot’s own editor UI.

**Required reading for inventory work:** [`workflows/ui-screens.md`](../workflows/ui-screens.md), [`presentation/AGENTS.md`](../../presentation/AGENTS.md), [`architecture/overlay-desktop.md`](../architecture/overlay-desktop.md).

## Core rules

1. **Containers own child positions** — if a node is inside a `Container`, do not set `position` or fight layout with manual offsets.
2. **Anchors for screen shells only** — root HUD nodes use Full Rect; internal layout uses `VBoxContainer` / `HBoxContainer` / `GridContainer`.
3. **`custom_minimum_size` + size flags** — prefer these over fixed `offset_*` for slot sizes and toolbars.
4. **`InventoryLayout` / `.tres`** — scale repeated slot grids; do not scatter magic numbers in scripts.
5. **WYSIWYG in editor** — open the `.tscn` and confirm layout without F5 when possible.

Shared overlay numbers live in [`presentation/shared/ui_constants.gd`](../../presentation/shared/ui_constants.gd) (`WINDOW_HEIGHT`, `COMBAT_RESERVED_SPACE`, etc.).

## Layout patterns

| Pattern | Structure | When to use | Project example |
|---------|-----------|-------------|-----------------|
| **Screen shell** | `CanvasLayer` → `Control` (Full Rect) | Any HUD / menu root | `scenes/main.tscn` → `InventoryHud` |
| **Form column** | `MarginContainer` → `VBoxContainer` → `HBoxContainer` per row | Settings, label + control rows | `SettingsPanel`, forge body |
| **Panel inset** | `FundoPainel` (full bleed) + `MarginContainer` → content | Frame texture padding | `warehouse_panel`, `forge_panel` |
| **Toolbar row** | `HBoxContainer` + `Control` (Expand) + buttons | Headers, bottom nav | `bottom_nav.tscn`, menu header |
| **Grid body** | `GridContainer` or baked slot prefab | Inventory, skills, warehouse | `inventory_slots_grid.tscn` |
| **Overlay stack** | `VBoxContainer` + Expand spacers + central band | Desktop overlay (menu vs combat) | `inventory_menu.tscn` → `OverlayVBox` |
| **Sidecar row** | `HBoxContainer` + center block + side panels | Warehouse / forge / worlds beside hub | `MenuArea` in `inventory_menu.tscn` |
| **Full-bleed swap** | `PanelContainer` hub + overlay children (Full Rect) | Replace hub content in place | Formation, Skills, Attributes, Skill tree |
| **Dynamic canvas** | Manual positions in script | Radial maps, node graphs | `worlds_panel`, `skill_tree_map` |
| **Layout resource** | `InventoryLayout` `.tres` | Token scaling for slot UIs | `inventory_layout_default.tres` |

## Inventory hub (overlay)

```text
Menu (Control, Full Rect)
└─ OverlayVBox (VBoxContainer)
   ├─ TopSpacer (Control, Expand or fixed combat reserve)
   ├─ MenuArea (HBoxContainer, separation=8, center)
   │  ├─ WarehousePanel
   │  ├─ Panel (PanelContainer: Conteudo VBox + full-bleed overlays)
   │  ├─ ForgePanel
   │  └─ WorldsPanel
   └─ BottomSpacer (Control, combat reserve or Expand)
```

- **`set_below_combat(false)`** (combat at bottom): `TopSpacer` expands; `BottomSpacer` reserves `COMBAT_RESERVED_SPACE` (320px).
- **`set_below_combat(true)`** (combat at top): `TopSpacer` reserves combat band; `BottomSpacer` expands.
- Horizontal width: `MenuArea.get_combined_minimum_size()` → `WindowManager.adjust_width`.
- [`panel_layout.gd`](../../presentation/inventory/panel_layout.gd) aligns full-bleed overlays on the hub `Panel` — not side panels.

## New UI scene checklist

1. Pick a pattern from the table above.
2. Root `Control` or `CanvasLayer`; Full Rect on the outer shell.
3. Nest containers; set `separation` on `VBox`/`HBox` instead of margin hacks.
4. Mark script references with `%UniqueName`.
5. Player strings via `tr(LocaleKeys.*)` ([`i18n.md`](i18n.md)).
6. No economy/combat rules in UI scripts ([`presentation/AGENTS.md`](../../presentation/AGENTS.md)).
7. Overlay: test with **Embed Game disabled** ([`overlay-desktop.md`](../architecture/overlay-desktop.md)).

## When absolute layout is allowed

| Case | Reason |
|------|--------|
| `worlds_panel` stage map | Nodes placed on a circle in code |
| `skill_tree_map` | Graph node positions |
| `forge_panel` gem grid centering | Runtime alignment inside a fixed slot |
| Context popups (e.g. filter menu) | Floating above a control |
| `WindowManager` | OS window position, click-through polygon |
| `SectionVisualOffset` | Small visual nudge; parent still owns layout space |

Do **not** use absolute layout for the main inventory hub panel, headers, or nav — use containers.

## Anti-patterns

- Hardcoding `WINDOW_HEIGHT` offsets on menu bands (use `OverlayVBox` spacers + `UiConstants`).
- `layout_mode = 0` on children of `VBoxContainer` / `HBoxContainer` (editor fights runtime).
- Scaling `Control` nodes instead of `custom_minimum_size` on slots.
- Duplicating slot scenes in a loop at runtime when a baked prefab grid exists.
- Fixing hub width or inventory row size in `inventory_menu.tscn` (`custom_minimum_size` on `Panel` / `MenuArea` / `LinhaInventario`) — use `InventoryLayout` + `_apply_panel_layout()` instead.

## CI / local audit

```powershell
powershell -ExecutionPolicy Bypass -File tools/run_ui_layout_check.ps1
```

`tools/check_ui_layout.py` scans `presentation/**/*.tscn` and fails on `layout_mode = 0` unless the node is in the allowlist (`worlds_panel` stage map, `hero_section` visual offset wrapper). It also rejects `custom_minimum_size.x` above `WINDOW_WIDTH` on inventory hub nodes. Extend `ALLOWLIST` in that script when a new documented exception is added.

Inventory menu geometry (ten screens): `tools/run_inventory_menu_layout_audit.ps1`.

Menu **visual** review for Cursor agents (`/capture-menu-screens`, ten PNG captures):

```powershell
powershell -ExecutionPolicy Bypass -File tools/run_inventory_menu_visual_capture.ps1
```

See [`workflows/ui-screens.md`](../workflows/ui-screens.md) and [`workflows/testing.md`](../workflows/testing.md#menu-screens-visual-review-cursor).

## References

- [Godot: Using Containers](https://docs.godotengine.org/en/stable/tutorials/ui/gui_containers.html)
- [Godot: UI main menu tutorial](https://docs.godotengine.org/en/stable/getting_started/step_by_step/ui_main_menu.html)
