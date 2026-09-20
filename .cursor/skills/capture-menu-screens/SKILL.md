---
name: capture-menu-screens
description: >-
  Capture all inventory_menu screen states as PNGs and read them for visual review.
  Use when the user runs /capture-menu-screens, asks to grab menu layout images,
  screenshot all inventory panels, or evaluate UI layout from captures.
---
# Capture Menu Screens (Stickman Idle)

Run the automated capture, **read every PNG**, and report visual findings for **all ten menu screens**.

## Command

```powershell
powershell -ExecutionPolicy Bypass -File tools/run_inventory_menu_visual_capture.ps1
```

Requires **display** (no `--headless`). Set `GODOT` env var if Godot is not in default paths.

Optional fast pre-check (headless):

```powershell
powershell -ExecutionPolicy Bypass -File tools/run_inventory_menu_layout_audit.ps1
```

## Workflow

1. Run the visual capture command above.
2. Confirm `INVENTORY_MENU_VISUAL_CAPTURE_OK` in output.
3. **Read all ten PNGs** with the Read tool:
   - `artifacts/inventory_layout/hub_combat_bottom.png`
   - `artifacts/inventory_layout/hub_combat_top.png`
   - `artifacts/inventory_layout/formation_open.png`
   - `artifacts/inventory_layout/skills_open.png`
   - `artifacts/inventory_layout/attributes_open.png`
   - `artifacts/inventory_layout/skill_tree_open.png`
   - `artifacts/inventory_layout/warehouse_open.png`
   - `artifacts/inventory_layout/forge_open.png`
   - `artifacts/inventory_layout/worlds_open.png`
   - `artifacts/inventory_layout/settings_open.png`
4. Summarize issues per screen using the checklist below.
5. To open the folder locally:
   ```powershell
   explorer artifacts/inventory_layout
   ```

## Visual checklist (10 screens)

| PNG | Expect |
|-----|--------|
| `hub_combat_bottom` | Hub in lower half; top ~320px clear; 10×5 grid readable; nav proportional |
| `hub_combat_top` | Hub below top combat band; no overlap into reserved zone |
| `formation_open` | Formation overlay full-bleed on hub panel |
| `skills_open` | Skills overlay full-bleed on hub panel |
| `attributes_open` | Attributes overlay full-bleed; stat rows readable |
| `skill_tree_open` | Skill tree replaces hub; map and gold label visible |
| `warehouse_open` | Warehouse side panel visible; tabs and grid readable |
| `forge_open` | Forge side panel visible; slots aligned |
| `worlds_open` | Worlds side panel visible; stage map readable |
| `settings_open` | Settings panel top-right; volume and locale controls visible |

Flag: grid overlapping hero area, hub too narrow, collapsed overlays, clipped side panels, settings off-screen.

## After layout fixes

Scope: `presentation/inventory/`, `presentation/worlds/worlds_panel.*`, `inventory_layout_default.tres`.

- Re-run this skill to verify PNGs.
- `inventory_menu.gd` patches: use `tools/fix_inventory_menu_encoding.py` only.
- Docs: `docs/workflows/testing.md`, `docs/conventions/ui-layout.md`.

## Output format

```markdown
## Menu screens — [pass / issues found]

### hub_combat_bottom
- ...

(repeat for all ten screens)

### Recommended fixes
1. ...
```

## References

- Create/edit workflow: [`edit-ui-screens`](../edit-ui-screens/SKILL.md) (`/edit-ui-screens`)
- Doc: [`docs/workflows/ui-screens.md`](../../docs/workflows/ui-screens.md)
- States: `tests/inventory_menu_layout_states.gd` (`STATE_IDS`)
- Capture: `tests/inventory_menu_visual_capture.gd`
- Manifest: `artifacts/inventory_layout/manifest.json`
