---
name: edit-ui-screens
description: >-
  Create or edit Stickman Idle UI screens using container layout conventions.
  After editing any inventory_menu screen, run visual PNG capture and read images
  before finishing. Use for /edit-ui-screens, new panels, layout changes, or
  editing presentation/inventory or presentation/worlds UI.
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
6. **Mandatory:** run visual capture and read PNGs before declaring done.

## Editing an existing screen

**Always run capture after layout edits** — geometry audit alone is not enough.

### Step 1 — Edit

| Area | Files |
|------|--------|
| Hub shell | `inventory_menu.tscn`, `inventory_menu.gd`, `inventory_layout_default.tres` |
| Hub blocks | `hero_section.tscn`, `inventory_row.tscn`, `bottom_nav.tscn` |
| Overlays | `formation_panel.*`, `skills_panel.*`, `attributes_panel.*`, `skill_tree_panel.*` |
| Side panels | `warehouse_panel.*`, `forge_panel.*`, `worlds_panel.*` |
| Settings | `SettingsPanel` in `inventory_menu.tscn` |
| Shared | `ui_constants.gd`, `panel_layout.gd`, `window_manager.gd` |

Rules:
- Containers own child positions — no `layout_mode = 0` inside `VBox`/`HBox` (unless allowlisted).
- Hub widths/slot sizes via `InventoryLayout` + `_apply_panel_layout()`, not hardcoded on `Panel`/`MenuArea`.
- **`inventory_menu.gd`:** patch with `python tools/fix_inventory_menu_encoding.py` — do not use editor StrReplace (UTF-16 corruption).

### Step 2 — Capture (required)

```powershell
powershell -ExecutionPolicy Bypass -File tools/run_inventory_menu_visual_capture.ps1
```

Optional headless pre-check:

```powershell
powershell -ExecutionPolicy Bypass -File tools/run_inventory_menu_layout_audit.ps1
```

Full details: skill [`capture-menu-screens`](../capture-menu-screens/SKILL.md) (`/capture-menu-screens`).

### Step 3 — Read every PNG

Read **all ten** files in `artifacts/inventory_layout/` (not just the screen you changed — side effects are common):

- `hub_combat_bottom.png`, `hub_combat_top.png`
- `formation_open.png`, `skills_open.png`, `attributes_open.png`, `skill_tree_open.png`
- `warehouse_open.png`, `forge_open.png`, `worlds_open.png`, `settings_open.png`

### Step 4 — Fix and repeat

Iterate edit → capture → read until layout is acceptable. Report findings per screen.

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
- [ ] Read all 10 PNGs

### Findings
| Screen | Status | Notes |
|--------|--------|-------|
| hub_combat_bottom | ok / issue | ... |

### Recommended follow-ups
1. ...
```

## Quick reference

| Command | Purpose |
|---------|---------|
| `tools/run_inventory_menu_visual_capture.ps1` | 10 PNGs for AI visual review (display required) |
| `tools/run_inventory_menu_layout_audit.ps1` | Headless geometry check |
| `tools/run_ui_layout_check.ps1` | Forbidden `layout_mode = 0` scan |
| `explorer artifacts/inventory_layout` | Open captures folder (Windows) |
