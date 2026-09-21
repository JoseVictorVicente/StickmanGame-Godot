# Project UI patterns — doc-first index

**Single operational index for agents.** Design screens from documentation and judgment — do **not** clone existing panels as visual benchmarks and do **not** use removed scaffold tooling.

## Canonical docs (read these)

| Doc | Use |
|-----|-----|
| [`docs/conventions/ui-layout.md`](../../../../docs/conventions/ui-layout.md) | Layout pattern table, menu shell diagram |
| [`docs/workflows/ui-screens.md`](../../../../docs/workflows/ui-screens.md) | Human workflow, capture states |
| [`tscn-ownership.md`](tscn-ownership.md) | What lives in `.tscn` vs `.gd` |
| [`style-recipes.md`](style-recipes.md) | Colors, separation, margins — bake as `sub_resource` |
| [`containers-cheatsheet.md`](containers-cheatsheet.md) | Pick scroll vs grid vs tabs |
| [`presentation/AGENTS.md`](../../../../presentation/AGENTS.md) | **Wiring only** — router, `MenuArea`, `%OverlayStack` |

**Wiring exception:** read `inventory_menu.tscn`, `inventory_menu.gd`, `InventoryPanelRouter` only to learn where to instance panels and which signals to emit — not for visual chrome.

## Pattern checklist

Classify the screen, then apply constraints from [`ui-layout.md`](../../../../docs/conventions/ui-layout.md).

| Pattern | Shell constraints | Where to instance | Scope PNG |
|---------|-------------------|-------------------|-----------|
| **Sidecar** | `Panel inset`: frame + `MarginContainer` → `VBox` (header HBox + body) | Child of `MenuArea` | `warehouse_open`, `forge_open`, `worlds_open` (+ briefing/trail) |
| **Overlay full-bleed** | Root `Control` Full Rect on `%OverlayStack`; frame + margin + content `VBox` | `%OverlayStack` under `%HubBody` | `formation_open`, `skills_open`, `attributes_open` |
| **Hub block** | Prefab with `configure(menu)` + `apply_layout()` for existing hub zones | Instanced in `inventory_menu.tscn` hub row | `hub_combat_bottom` |
| **Hub replace** | Full content swap (skill tree) | Router hides `%HubContent` | `skill_tree_open` |
| **Settings popup** | Anchored panel, not sidecar | `%OverlayStack` | `settings_open` |
| **Worlds subview** | Same sidecar shell; inner views swap | `worlds_panel.tscn` | `worlds_open` / `worlds_briefing_open` / `worlds_trail_open` |

**Body (variable):** compose containers for the actual content — `ScrollContainer` + rows, `TabBar` + grids, `GridContainer`, map layer with baked anchors (trail). See [`screen-cookbook.md`](screen-cookbook.md) for shell diagrams only.

## Visual tokens

Copy values from [`style-recipes.md`](style-recipes.md) or `presentation/shared/styles/*.tres` into panel `sub_resource` blocks. Do not `ExtResource`-link shared styles from panel scenes.

Common tokens: content `separation` 8px; worlds header 20px; header row 6px; banner/button colors in style-recipes table.

## Integration

- Sidecars: `size_flags_vertical = EXPAND_FILL`; `configure(menu: InventoryMenu)`; emit `panel_open_changed` or router-compatible signals.
- Overlays: `visible = false` by default; router + `panel_layout.gd` `align_overlays`.
- Player strings: `tr(LocaleKeys.*)` + `locales/*.po`.
- No new `UIFlow` — use `InventoryPanelRouter`.

## Human IDE path (parallel)

Godot + **ui_builder** addon — optional visual polish in the editor. See [`editor-plugins.md`](editor-plugins.md). After IDE edits, run validation below.

## Validation gate (required before done)

```powershell
# New panel (first run)
powershell -ExecutionPolicy Bypass -File tools/run_edit_ui_validation.ps1 -PanelPath presentation/inventory/my_panel.gd -ScopePng <id>

# Existing panel layout edit
powershell -ExecutionPolicy Bypass -File tools/run_edit_ui_validation.ps1 -ScopePng <id>
```

| Step | Tool | Proves |
|------|------|--------|
| Optional | `run_new_screen_preflight.ps1` | No layout anti-patterns in `.gd` |
| 2 | `run_ui_layout_check.ps1` | `layout_mode = 0` allowlist + TSCN ownership |
| 3 | `run_inventory_menu_layout_audit.ps1` | Menu geometry invariants |
| 4 | `run_inventory_menu_visual_capture.ps1` | PNG 960×860 |
| 5 | Agent | Read scoped PNG + [`capture-menu-screens`](../../capture-menu-screens/SKILL.md) checklist |

**Requirements:** display available for capture; set `GODOT` env if Godot is not on PATH.

**Done when:** `EDIT_UI_VALIDATION_OK` + scoped PNG passes checklist. On failure: fix `.tscn`, rerun (max 3 iterations).

PNG map: [`capture-menu-screens` PNG map](../../capture-menu-screens/SKILL.md#png-map).

## Anti-patterns

- `scaffold_ui_panel.py` (removed) or any preset panel generator
- Cloning `warehouse_panel.tscn` (or any panel) as a visual template
- `position =`, runtime `custom_minimum_size`, `reparent()` for layout in `.gd`
- `StyleBoxFlat.new()` for chrome in scripts
- `tools/fix_inventory_menu_encoding.py` after normal edits (runs `git restore`)

## Architecture notes (from community practice)

- One scene per major panel; router toggles visibility (`inventory_menu.gd` + `InventoryPanelRouter`).
- Containers inside containers — two layout modes: parent is Container → size flags; shell only → anchors.
- Do not adopt external UI frameworks (UIFlow, GameGUI) — conflicts TSCN-first.
