---
name: capture-menu-screens
description: >-
  Captures inventory_menu screen states as PNGs and analyzes them visually.
  Scoped mode (1–2 PNGs) after UI edits; full mode (12 PNGs) for complete audit.
  Use for /capture-menu-screens, captura de tela, revisão visual, PNG do menu,
  validar layout, verificar se a tela ficou legível ou auditoria das 12 telas.
---
# Capture Menu Screens (Stickman Idle)

**Single owner** of: capture command, PNG checklist, visual feedback loop, and findings format.

**Layout fixes:** structure in `.tscn` first ([`/edit-ui-screens`](../edit-ui-screens/SKILL.md) → TSCN ownership) — not `position` / `custom_minimum_size` in `.gd`.

---

## Two modes

| Mode | When | PNGs to read |
|------|------|--------------|
| **Scoped** | After `/edit-ui-screens` (default) | Only row(s) from [PNG map](#png-map) for files you edited |
| **Full** | User runs `/capture-menu-screens` or asks for all screens | All **12** PNGs |

The capture script **always writes 12 files** to `artifacts/inventory_layout/`. Scope controls **which files you open and analyze** — not which files are generated.

---

## Commands

**Validation chain** (preferred after UI edits — includes layout guards + capture):

```powershell
powershell -ExecutionPolicy Bypass -File tools/run_edit_ui_validation.ps1 -ScopePng worlds_open
```

`-ScopePng` accepts one or more state ids (comma-separated or repeat the flag). It echoes which PNG(s) to read after capture.

**Capture only** (when guards already passed):

```powershell
powershell -ExecutionPolicy Bypass -File tools/run_inventory_menu_visual_capture.ps1
```

Optional headless geometry pre-check:

```powershell
powershell -ExecutionPolicy Bypass -File tools/run_inventory_menu_layout_audit.ps1
```

Requires **display** for capture (no `--headless`). Set `GODOT` env var if Godot is not in default paths.

---

## Scoped workflow (from `/edit-ui-screens`)

Use after every layout edit. This is the **visual feedback loop**.

```text
1. Note validation PNG(s) from PNG map (edit-ui-screens Phase 0)
2. Run run_edit_ui_validation.ps1 -ScopePng <id>[,<id2>]
3. Confirm EDIT_UI_VALIDATION_OK and INVENTORY_MENU_VISUAL_CAPTURE_OK
4. Read ONLY the scoped PNG(s) with the Read tool
5. Check against checklist row(s) below (+ mockup if worlds)
6. If issue → fix .tscn → go to step 2 (max 3 iterations, then ask user)
7. Report findings table (scoped rows only)
```

**Do not** open the other eleven PNGs unless you also edited shared code (`panel_layout`, `InventoryLayout`, router) and suspect regression — then add the extra row(s) to `-ScopePng`.

---

## Full workflow (`/capture-menu-screens`)

1. Run `run_edit_ui_validation.ps1` (no `-ScopePng`) or capture-only command.
2. Confirm `INVENTORY_MENU_VISUAL_CAPTURE_OK`.
3. **Read all twelve PNGs:**
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
4. Summarize every screen using the checklist below.
5. Optional: `explorer artifacts/inventory_layout`

---

## PNG map

| You edited | Scope PNG (`-ScopePng`) |
|------------|-------------------------|
| Hub shell, layout tres, hub prefabs, `ui_constants`, `panel_layout` | `hub_combat_bottom` |
| Spacers / `set_below_combat` only | `hub_combat_top` (add to scope) |
| `formation_panel.*` | `formation_open` |
| `skills_panel.*` | `skills_open` |
| `attributes_panel.*` | `attributes_open` |
| `skill_tree_panel.*` | `skill_tree_open` |
| `warehouse_panel.*` | `warehouse_open` |
| `forge_panel.*` | `forge_open` |
| `worlds_panel.*`, `portal_hall_view.*`, `portal_card.*` (hall) | `worlds_open` |
| `realm_briefing_view.*` | `worlds_briefing_open` |
| `trail_map_view.*`, `stage_map.*` | `worlds_trail_open` |
| `settings_panel.*` | `settings_open` |

Paths: `artifacts/inventory_layout/<state_id>.png`.

---

## Visual checklist

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
| `worlds_open` | **Portal hall**: 5 cards; progress **inside** active card; locks centered; `Trilha Segura` footer **centered**; header `←` + banner + `X` — compare [`portals_mockup_1_hall.png`](../../artifacts/design/portals_mockup_1_hall.png) |
| `worlds_briefing_open` | Briefing: banner ~35–45% panel (not black); lore → boss → CTA without overlap — compare [`portals_mockup_2_briefing.png`](../../artifacts/design/portals_mockup_2_briefing.png) |
| `worlds_trail_open` | Trail map: placeholder visible; stage header + **difficulty in header row**; 9 nodes inside panel — compare [`portals_mockup_3_trail.png`](../../artifacts/design/portals_mockup_3_trail.png) |
| `settings_open` | Settings panel top-right; volume and locale controls visible |

**Flag everywhere:** grid overlapping hero/divider, Formation straddling the band line, hub too narrow, collapsed overlays, clipped side panels, settings off-screen, skill tree black screen.

Symptom → fix: [`edit-ui-screens/references/troubleshooting.md`](../edit-ui-screens/references/troubleshooting.md).

---

## After layout fixes

- Re-run scoped or full workflow above.
- **Do not** run `tools/fix_inventory_menu_encoding.py` after layout edits — it `git restore`s `inventory_menu.gd`.
- Docs: `docs/workflows/testing.md`, `docs/conventions/ui-layout.md`.

---

## Output format

### Scoped (default)

```markdown
## Visual capture — scoped

### Scope
- PNG(s): worlds_open

### Findings
| PNG | Status | Notes |
|-----|--------|-------|
| worlds_open | ok / issue | ... |

### Loop
- Iterations: 1
- Next: done | fix X in portal_card.tscn
```

### Full (`/capture-menu-screens`)

```markdown
## Menu screens — [pass / issues found]

### hub_combat_bottom
- ...

(repeat for all twelve)

### Recommended fixes
1. ...
```

---

## References

- Edit workflow: [`edit-ui-screens`](../edit-ui-screens/SKILL.md) (`/edit-ui-screens`)
- Doc: [`docs/workflows/ui-screens.md`](../../docs/workflows/ui-screens.md)
- States: `tests/inventory_menu_layout_states.gd` (`STATE_IDS`)
- Capture: `tests/inventory_menu_visual_capture.gd`
- Manifest: `artifacts/inventory_layout/manifest.json`
