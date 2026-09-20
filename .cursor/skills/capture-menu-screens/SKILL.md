---
name: capture-menu-screens
description: >-
  Capture all inventory_menu screen states as PNGs and read them for visual review.
  Use when the user runs /capture-menu-screens, asks to grab menu layout images,
  screenshot all inventory panels, or evaluate UI layout from captures.
---
# Capture Menu Screens (Stickman Idle)

Run the automated capture, **read every PNG**, and report visual findings for **all twelve menu screens**.

**Layout rule:** if capture reveals layout issues, fix structure in `.tscn` first (see `/edit-ui-screens` → TSCN-first design) — not with `position` / `custom_minimum_size` in `.gd`.

Use this skill for full menu reviews (`/capture-menu-screens`). After a single-screen edit, follow [`edit-ui-screens`](../edit-ui-screens/SKILL.md) Step 3 and read only the PNG(s) for what you changed.

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
3. **Read all twelve PNGs** with the Read tool:
   - `artifacts/inventory_layout/hub_combat_bottom.png`
   - `artifacts/inventory_layout/hub_combat_top.png`
   - `artifacts/inventory_layout/formation_open.png`
   - `artifacts/inventory_layout/skills_open.png`
   - `artifacts/inventory_layout/attributes_open.png`
   - `artifacts/inventory_layout/skill_tree_open.png`
   - `artifacts/inventory_layout/warehouse_open.png`
   - `artifacts/inventory_layout/forge_open.png`
   - `artifacts/inventory_layout/worlds_open.png`
   - `artifacts/inventory_layout/worlds_briefing_open.png`
   - `artifacts/inventory_layout/worlds_trail_open.png`
   - `artifacts/inventory_layout/settings_open.png`
4. Summarize issues per screen using the checklist below.
5. To open the folder locally:
   ```powershell
   explorer artifacts/inventory_layout
   ```

## Visual checklist (12 screens)

| PNG | Expect |
|-----|--------|
| `hub_combat_bottom` | Hub in lower half; top ~320px clear; **Formation inside lower band** above grid; grid does not cross the horizontal divider; nav at bottom of lower band |
| `hub_combat_top` | Hub below top combat band; no overlap into reserved zone |
| `formation_open` | Formation overlay full-bleed on hub panel |
| `skills_open` | Skills overlay full-bleed on hub panel |
| `attributes_open` | Attributes overlay full-bleed; stat rows readable |
| `skill_tree_open` | Skill tree replaces hub; map and gold label visible |
| `warehouse_open` | Warehouse side panel visible; tabs and grid readable |
| `forge_open` | Forge side panel visible; slots aligned |
| `worlds_open` | **Portal hall** side panel: 5 cards stacked; progress **inside** active card; locks centered; `Trilha Segura` footer **centered** — compare [`portals_mockup_1_hall.png`](../../artifacts/design/portals_mockup_1_hall.png) |
| `worlds_briefing_open` | Briefing view: banner ~35–45% panel (not black); lore → boss → CTA without overlap — compare [`portals_mockup_2_briefing.png`](../../artifacts/design/portals_mockup_2_briefing.png) |
| `worlds_trail_open` | Trail map: placeholder map visible; stage header + **difficulty in header row**; 9 nodes inside 300px panel — compare [`portals_mockup_3_trail.png`](../../artifacts/design/portals_mockup_3_trail.png) |
| `settings_open` | Settings panel top-right; volume and locale controls visible |

Flag: grid overlapping hero/divider, Formation straddling the band line, hub too narrow, collapsed overlays, clipped side panels, settings off-screen, skill tree black screen.

## After layout fixes

Scope: `presentation/inventory/`, `presentation/worlds/`, `inventory_layout_default.tres`. Layout edits → `.tscn` first (`/edit-ui-screens`).

- Re-run this skill to verify PNGs.
- **Do not** run `tools/fix_inventory_menu_encoding.py` after layout edits — it `git restore`s `inventory_menu.gd` and drops your changes.
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
