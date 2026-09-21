---
name: edit-ui-screens
description: >-
  Creates or edits Stickman Idle UI screens doc-first with TSCN ownership; runs
  scoped PNG validation via capture-menu-screens after layout edits. Use for
  /edit-ui-screens, presentation/inventory/worlds UI, nova tela, editar UI,
  layout do inventário, painel de portais, warehouse, worlds ou menu hub.
---
# Edit UI Screens (Stickman Idle)

**Start here:** [`references/project-ui-patterns.md`](references/project-ui-patterns.md) (operational index).

**Wiring:** [`presentation/AGENTS.md`](../../presentation/AGENTS.md). **Visual loop:** [`capture-menu-screens`](../capture-menu-screens/SKILL.md) scoped workflow.

## Boundaries

- UI in `presentation/` only — no gold/combat rules, no domain `Control` imports.
- Player strings: `tr(LocaleKeys.*)` + `locales/*.po`.
- Do not bulk-edit `sprites/` without explicit user request.
- **Do not** clone existing panels as visual templates — design from doc + judgment.

## TSCN ownership

**The `.tscn` file is the single source of truth for each panel.** Full rule: [`references/tscn-ownership.md`](references/tscn-ownership.md).

| Put in `.tscn` | Never put in `.gd` |
|----------------|---------------------|
| Node tree, separation, min sizes, size flags | `custom_minimum_size`, `size_flags_*` |
| `sub_resource` StyleBoxes | `StyleBoxFlat.new()` / `ExtResource` to `shared/styles/` |
| Default fonts/colors | `add_theme_constant_override("separation", …)` |

Enforced by `tools/check_tscn_ownership.py` (inside `run_ui_layout_check.ps1`).

## Agent workflow

```text
Phase 0  Classify pattern → read project-ui-patterns + ui-layout + style-recipes → note Scope PNG
Phase 1  Preflight (new panels): run_new_screen_preflight.ps1 -PanelPath …
Phase 2  Design + edit .tscn (structure, StyleBoxes, %UniqueName)
Phase 3  Script audit — grep .gd for layout anti-patterns
Phase 4  Wire configure(menu) + signals; instance in menu/router
Phase 5  run_edit_ui_validation.ps1 -ScopePng <id> → capture-menu-screens scoped read
Phase 6  If issue: fix .tscn → repeat Phase 5 (max 3 iterations)
```

**Never in UI scripts:** `position =`, `offset_* =`, `reparent()` for layout, runtime `custom_minimum_size`/`size` for structure, `StyleBoxFlat.new()` for chrome.

---

## Phase 0 — Doc-first (not clone / not scaffold)

1. Classify: sidecar | overlay | hub block | worlds | settings.
2. Open [`project-ui-patterns.md`](references/project-ui-patterns.md) — pattern row + validation PNG id.
3. Read [`docs/conventions/ui-layout.md`](../../docs/conventions/ui-layout.md) — layout pattern table.
4. Read [`style-recipes.md`](references/style-recipes.md) — bake tokens in `.tscn`.
5. **Design** shell + body for the request (containers per [`containers-cheatsheet.md`](references/containers-cheatsheet.md)).
6. **Wiring only:** `presentation/AGENTS.md` + `inventory_menu.gd` / `InventoryPanelRouter`.

PNG map: [`capture-menu-screens`](../capture-menu-screens/SKILL.md#png-map).

**Router:** `inventory_menu.gd` + `InventoryPanelRouter` — do not add UIFlow.

---

## Phase 5–6 — Visual validation

```powershell
powershell -ExecutionPolicy Bypass -File tools/run_edit_ui_validation.ps1 -ScopePng <scope>
```

Follow [`capture-menu-screens` scoped workflow](../capture-menu-screens/SKILL.md#scoped-workflow-from-edit-ui-screens). Read **only** scoped PNG(s). Full twelve-PNG audit: `/capture-menu-screens`.

Task is **not done** without `EDIT_UI_VALIDATION_OK` + scoped checklist pass.

---

## File map

| Area | Files |
|------|--------|
| Hub shell | `inventory_menu.tscn`, `inventory_menu.gd`, `inventory_layout_default.tres` |
| Hub blocks | `hero_equip_*`, `hero_character_panel`, `inventory_panel`, `bottom_nav` |
| Overlays | `formation_panel.*`, `skills_panel.*`, `attributes_panel.*`, `skill_tree_panel.*` |
| Side panels | `warehouse_panel.*`, `forge_panel.*`, `worlds_panel.*` |
| Settings | `settings_panel.tscn` in `%OverlayStack` |
| Shared | `ui_constants.gd`, `panel_layout.gd`, `presentation/shared/styles/` |

---

## Preflight (new panels)

```powershell
powershell -ExecutionPolicy Bypass -File tools/run_new_screen_preflight.ps1 -PanelPath presentation/inventory/my_panel.gd
```

## New capture state

1. `tests/inventory_menu_layout_states.gd`
2. `tools/run_inventory_menu_visual_capture.ps1`
3. `tests/inventory_menu_layout_audit.gd` (optional)
4. Update `capture-menu-screens/SKILL.md` + `docs/workflows/ui-screens.md`

## Human editors (Godot)

**ui_builder** addon — [`editor-plugins.md`](references/editor-plugins.md). Parallel to agent workflow; run validation after IDE edits.

**Never run** `tools/fix_inventory_menu_encoding.py` after edits — it `git restore`s `inventory_menu.gd`.

---

## Reference index

| File | When |
|------|------|
| [**project-ui-patterns.md**](references/project-ui-patterns.md) | **Start here — doc-first index** |
| [`capture-menu-screens/SKILL.md`](../capture-menu-screens/SKILL.md) | PNG map, checklist, visual loop |
| [`tscn-ownership.md`](references/tscn-ownership.md) | TSCN vs `.gd` rules |
| [`containers-cheatsheet.md`](references/containers-cheatsheet.md) | Container pick |
| [`screen-cookbook.md`](references/screen-cookbook.md) | Shell diagrams (not clone list) |
| [`style-recipes.md`](references/style-recipes.md) | Visual tokens |
| [`stylebox-gotchas.md`](references/stylebox-gotchas.md) | Frame texture issues |
| [`troubleshooting.md`](references/troubleshooting.md) | PNG symptoms |
| [`editor-plugins.md`](references/editor-plugins.md) | ui_builder in IDE |

---

## Output format

```markdown
## UI screen edit — [screen name]

### Changes
- ...

### Visual validation
- [ ] capture-menu-screens scoped workflow
- [ ] Scope: `<png_id>`
- [ ] EDIT_UI_VALIDATION_OK

### Findings
(capture-menu-screens scoped table)

### Recommended follow-ups
1. ...
```

## Quick reference

| Command / skill | Purpose |
|-----------------|---------|
| `run_new_screen_preflight.ps1 -PanelPath` | Anti-pattern grep + ownership |
| `run_edit_ui_validation.ps1 -ScopePng <id>` | Guards + capture |
| `/capture-menu-screens` | Scoped (default) or full (12 PNGs) |
| `run_ui_layout_check.ps1` | Layout scan + ownership |
| `tools/regen/*.py` | Manual grid regen only — not agent workflow |
