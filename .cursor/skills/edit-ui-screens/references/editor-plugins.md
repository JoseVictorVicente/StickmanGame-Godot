# Editor plugins — UI Builder

## UI Builder (Quick Layout) — adopted

- **Repo:** [TheTechUmbrella/UI_Builder](https://github.com/TheTechUmbrella/UI_Builder)
- **Path:** `addons/ui_builder/`
- **Godot:** 4.6+ (project uses 4.7)
- **License:** MIT

### Enable

1. Plugin is in `addons/ui_builder/` (committed to repo).
2. Godot → **Project → Project Settings → Plugins** → enable **UI Builder**.
3. Open any scene with a `Control` root; use **UI Builder** / **Quick Layout** docks.

### What it does

- Drag-and-drop Control nodes onto a pan/zoom canvas
- Align, distribute, snap selected controls
- Edit `custom_minimum_size`, container `separation`, inline rename
- Undo/redo through Godot's history

### When humans should use it

- Polishing alignment and spacing visually in the IDE
- Prototyping a new header row or button strip
- Learning container layout interactively

### Agent workflow (parallel, not replacement)

- Agents follow **doc-first** — [`project-ui-patterns.md`](project-ui-patterns.md) — and edit `.tscn` directly
- Agents do **not** use ui_builder or removed scaffold tooling
- After any edit (human or agent): `run_edit_ui_validation.ps1 -ScopePng <id>` + capture-menu-screens scoped PNG review

### Recommended human workflow

```text
Design from project-ui-patterns.md + style-recipes.md
→ create/edit .tscn (agent or manual)
→ optional: refine in UI Builder in Godot
→ save .tscn
→ run_edit_ui_validation.ps1 -ScopePng <id>
→ capture-menu-screens scoped checklist
```

### Limitations

- Does not fix `StyleBoxTexture` margin issues — see [`stylebox-gotchas.md`](stylebox-gotchas.md)
- Does not replace `InventoryLayout` tokens for hub sizing
- Small community project — validate on one panel before wide rollout

## Optional: UIDesignTool

- [imjp94/UIDesignTool](https://github.com/imjp94/UIDesignTool) — batch font/color edit in viewport
- Not bundled in repo; install from Asset Library if typography workflow is painful

## Not used

| Plugin | Reason |
|--------|--------|
| GameGUI | Conflicts with built-in containers |
| Chromatica | Material design ≠ game art direction |
| UIFlow | Redundant with `InventoryPanelRouter` |
