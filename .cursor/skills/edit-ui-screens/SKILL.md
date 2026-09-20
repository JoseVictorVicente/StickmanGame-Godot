---
name: edit-ui-screens
description: >-
  Create or edit Stickman Idle UI screens using container layout conventions.
  After editing any inventory_menu screen, run visual PNG capture and read the
  PNG(s) for the screen(s) you changed before finishing. Use for /edit-ui-screens,
  new panels, layout changes, or editing presentation/inventory or presentation/worlds UI.
---
# Edit UI Screens (Stickman Idle)

**Read first:** [`docs/workflows/ui-screens.md`](../../docs/workflows/ui-screens.md), [`docs/conventions/ui-layout.md`](../../docs/conventions/ui-layout.md), [`presentation/AGENTS.md`](../../presentation/AGENTS.md).

## Boundaries

- UI in `presentation/` only — no gold/combat rules, no domain imports of `Control` nodes.
- Player strings: `tr(LocaleKeys.*)` + `locales/*.po`.
- Do not bulk-edit `sprites/` without explicit user request.

## Creating a new screen

1. Pick a layout pattern from [`ui-layout.md`](../../docs/conventions/ui-layout.md) (form column, sidecar, full-bleed overlay, grid prefab).
2. Prefer a **prefab** `.tscn` under `presentation/inventory/` (or `presentation/worlds/`).
3. Root `Control` / `PanelContainer`; nest `VBox`/`HBox`/`MarginContainer`; `%UniqueName` on script refs.
4. Wire from parent controller (`inventory_menu.gd`) via `configure(self)` + signals — match sibling panels.
5. If the screen is a new **menu state**, add capture support (see below).
6. **Mandatory:** run visual capture and read the PNG for the screen(s) you changed (see [Step 3](#step-3--read-the-relevant-pngs)).

## Editing an existing screen

**Always run capture after layout edits** — geometry audit alone is not enough.

### Step 1 — Edit

| Area | Files |
|------|--------|
| Hub shell | `inventory_menu.tscn`, `inventory_menu.gd`, `inventory_layout_default.tres` |
| Hub blocks | `hero_equip_left_panel.tscn`, `hero_character_panel.tscn`, `hero_equip_right_panel.tscn`, `inventory_panel.tscn`, `bottom_nav.tscn` |
| Overlays | `formation_panel.*`, `skills_panel.*`, `attributes_panel.*`, `skill_tree_panel.*` |
| Side panels | `warehouse_panel.*`, `forge_panel.*`, `worlds_panel.*` (Portals: hall → briefing → trail; mockups in `artifacts/design/`) |
| Settings | `settings_panel.tscn` in `%OverlayStack` |
| Shared | `ui_constants.gd`, `panel_layout.gd`, `window_manager.gd` |

Rules:
- Containers own child positions — no `layout_mode = 0` inside `VBox`/`HBox` (unless allowlisted).
- Hub widths/slot sizes via `InventoryLayout` + `_apply_panel_layout()`, not hardcoded on `HubBody`/`MenuArea`.
- **Do not** use `SectionVisualOffset` or negative `position` offsets in the hub — they bleed across `inventory_bg.png` bands.
- **`inventory_menu.gd`:** edit normally in UTF-8. **Never run** `python tools/fix_inventory_menu_encoding.py` after your edits — it runs `git restore` and wipes uncommitted changes. Use that script only for one-off UTF-16 recovery on a clean tree.

### Inventory hub zones (`inventory_bg.png`)

The panel art has **two horizontal bands** inside `%HubBody`. Gold / quit / settings live in `%HubChromeBar` above the panel.

```text
HubColumn (VBox)
├─ HubChromeBar (transparent) → Header: gold + quit + settings
└─ HubBody
   ├─ HubContent (VBox)
   │  ├─ HubUpperRow → hero_equip_left + hero_character + hero_equip_right
   │  ├─ InventoryPanel
   │  └─ BottomNav
   └─ OverlayStack (full bleed) → formation, skills, attributes, skill tree, settings
```

- Heights: `_apply_hub_content_heights()` + `InventoryLayout.hub_upper_row_size()` / `inventory_panel_size()`.
- **Changing `base_unit`:** edit `inventory_layout_default.tres`, then run `sync_from_base_unit()` (via `_apply_panel_layout()` at runtime). That recalculates panel size and calls `fit_panel_to_viewport()` so the hub never exceeds the overlay band — extra inventory rows scroll instead of clipping the top border. Regenerate `inventory_slots_grid.tscn` if slot pixel size changed (`tools/generate_inventory_slots_tscn.py`). Run layout audit before visual capture.
- **Formation** and **warehouse** nav live in `bottom_nav.tscn` (`%FormationButton`, `%StorageButton`).
- Sort button: `hero_equip_right_panel.tscn` (`%SortInventoryButton`).
- `inventory_panel.tscn`: scrollable **5×10** `inventory_slots_grid.tscn`.
- When moving a widget between upper/lower bands, update `inventory_panel_size()` (and related layout helpers) so the zone split stays balanced.
- Overlays that hide the hub: use `set_hub_visible(false)` / `InventoryPanelRouter.set_inventory_visible()` — hides `%HubContent`, not `%HubBody`.
- Side panels: `_sync_side_panel_heights()` + `size_flags_vertical = EXPAND_FILL` on warehouse/forge/worlds.

### Step 2 — Capture (required)

```powershell
powershell -ExecutionPolicy Bypass -File tools/run_inventory_menu_visual_capture.ps1
```

Run headless audit **before** capture (catches panel height / stack regressions):

```powershell
powershell -ExecutionPolicy Bypass -File tools/run_inventory_menu_layout_audit.ps1
```

Full details: skill [`capture-menu-screens`](../capture-menu-screens/SKILL.md) (`/capture-menu-screens`).

### Step 3 — Read the relevant PNG(s)

The capture script still writes **all ten** PNGs to `artifacts/inventory_layout/` — that is fine. **You only need to read the PNG(s) that match what you edited.**

Use this map (file area → `state_id` → PNG):

| You edited | Read this PNG |
|------------|----------------|
| Hub shell, `inventory_layout_default.tres`, `inventory_menu.gd`, `ui_constants.gd`, `panel_layout.gd`, hub prefabs (`hero_equip_*`, `hero_character_panel`, `inventory_panel`, `bottom_nav`) | `hub_combat_bottom.png` |
| `inventory_menu.gd` / spacers / `set_below_combat` only | also `hub_combat_top.png` |
| `formation_panel.*` | `formation_open.png` |
| `skills_panel.*` | `skills_open.png` |
| `attributes_panel.*` | `attributes_open.png` |
| `skill_tree_panel.*` | `skill_tree_open.png` |
| `warehouse_panel.*` | `warehouse_open.png` |
| `forge_panel.*` | `forge_open.png` |
| `worlds_panel.*` | `worlds_open.png` |
| `settings_panel.*` | `settings_open.png` |

**Rules:**

- Read **only** the row(s) for your edit. Do not open the other nine unless you changed shared layout code and see a regression, or the user asks for a full menu review (`/capture-menu-screens`).
- Hub-band edits (upper row vs inventory grid vs nav): prefer `hub_combat_bottom.png` — it shows the `inventory_bg.png` divider.
- If you touched `InventoryPanelRouter`, `InventoryLayout.sync_from_base_unit()`, or overlay alignment, add the overlay/side PNG for the panel you wired — not the whole set.

Example paths:

- `artifacts/inventory_layout/hub_combat_bottom.png`
- `artifacts/inventory_layout/formation_open.png`

### Step 4 — Fix and repeat

Iterate edit → capture → read **the same PNG(s)** until those screens look acceptable. Mention other states only if you observed a side effect.

## Adding a new capture state

When a new visible menu state is introduced:

1. Add `state_id` to `STATE_IDS` in [`tests/inventory_menu_layout_states.gd`](../../tests/inventory_menu_layout_states.gd).
2. Implement `reset_menu` cleanup + `apply_state` setup.
3. Add PNG name to [`tools/run_inventory_menu_visual_capture.ps1`](../../tools/run_inventory_menu_visual_capture.ps1) `$stateIds`.
4. Extend audit invariants in [`tests/inventory_menu_layout_audit.gd`](../../tests/inventory_menu_layout_audit.gd) if needed.
5. Update checklist in [`capture-menu-screens/SKILL.md`](../capture-menu-screens/SKILL.md) and [`docs/workflows/ui-screens.md`](../../docs/workflows/ui-screens.md).

## Output format

```markdown
## UI screen edit — [screen name]

### Changes
- ...

### Visual capture
- [ ] Ran `run_inventory_menu_visual_capture.ps1`
- [ ] Read PNG(s) for the screen(s) edited (see Step 3 map)

### Findings
| Screen (PNG) | Status | Notes |
|--------------|--------|-------|
| hub_combat_bottom | ok / issue | ... |

### Recommended follow-ups
1. ...
```

## Quick reference

| Command | Purpose |
|---------|---------|
| `tools/run_inventory_menu_visual_capture.ps1` | Writes 10 PNGs; read only the one(s) for your edit |
| `tools/run_inventory_menu_layout_audit.ps1` | Headless geometry check |
| `tools/run_ui_layout_check.ps1` | Forbidden `layout_mode = 0` scan |
| `/capture-menu-screens` | Full review — read **all** ten PNGs |
| `explorer artifacts/inventory_layout` | Open captures folder (Windows) |
