# New screen workflow

**Moved to:** [`project-ui-patterns.md`](project-ui-patterns.md) — single doc-first index for agents.

Humans: see also [`docs/workflows/ui-screens.md`](../../../../docs/workflows/ui-screens.md).

Quick checklist:

- [ ] Classify pattern (sidecar / overlay / hub / worlds / settings)
- [ ] Read `project-ui-patterns.md` + `ui-layout.md` + `style-recipes.md`
- [ ] Design `.tscn` (shell + body) — do not clone existing panels as visual templates
- [ ] Script: `configure(menu)`, signals, `tr()` only
- [ ] Wire in `inventory_menu` / `InventoryPanelRouter`
- [ ] New capture state if menu-visible (`inventory_menu_layout_states.gd`, capture script)
- [ ] `run_edit_ui_validation.ps1 -ScopePng <id>` + capture-menu-screens scoped PNG review
