---
name: capture-inventory-layout
description: >-
  Capture inventory_menu hub layout screenshots and read them for visual review.
  Use when the user runs /capture-inventory-layout, asks to grab layout images,
  re-run visual capture, or evaluate inventory UI layout from PNGs.
---
# Capture Inventory Layout (Stickman Idle)

Run the automated capture, **read every PNG**, and report visual findings. Do not rely on geometry audit alone for layout quality.

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
3. **Read all six PNGs** with the Read tool (images, not just paths):
   - `artifacts/inventory_layout/hub_combat_bottom.png`
   - `artifacts/inventory_layout/hub_combat_top.png`
   - `artifacts/inventory_layout/formation_open.png`
   - `artifacts/inventory_layout/skills_open.png`
   - `artifacts/inventory_layout/warehouse_open.png`
   - `artifacts/inventory_layout/forge_open.png`
4. Summarize issues per state using the checklist below.
5. If the user wants to see files locally, open the folder:
   ```powershell
   explorer artifacts/inventory_layout
   ```

## Visual checklist

| PNG | Expect |
|-----|--------|
| `hub_combat_bottom` | Hub in lower half; top ~320px clear; 10×5 grid readable; nav proportional |
| `hub_combat_top` | Hub below top combat band; no overlap into reserved zone |
| `formation_open` | Formation overlay full-bleed on hub panel |
| `skills_open` | Skills overlay full-bleed on hub panel |
| `warehouse_open` | Warehouse panel visible; frame margins ok; hub grid hidden or not overlapping |
| `forge_open` | Forge panel visible; slots aligned |

Flag: grid overlapping hero/formation area, hub too narrow, checkerboard bleeding into panel, collapsed overlays, side panels clipped.

## After layout fixes

Scope: `presentation/inventory/inventory_menu.tscn`, `inventory_layout_default.tres`, `inventory_menu.gd`, `panel_layout.gd`.

- Re-run this skill to verify PNGs.
- If editing `inventory_menu.gd` and encoding breaks, patch via `tools/fix_inventory_menu_encoding.py` (do not use StrReplace on that file).
- Docs: `docs/workflows/testing.md`, `docs/conventions/ui-layout.md`.

## Output format

```markdown
## Layout capture — [pass / issues found]

### hub_combat_bottom
- ...

### hub_combat_top
- ...

(repeat for all six states)

### Recommended fixes
1. ...
```

## References

- Capture script: `tests/inventory_menu_visual_capture.gd`
- Shared states: `tests/inventory_menu_layout_states.gd`
- Manifest: `artifacts/inventory_layout/manifest.json` (paths + timestamp)
