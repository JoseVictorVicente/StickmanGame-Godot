# TSCN ownership — keep the screen in the scene file

**Rule:** a panel's visual definition must be readable by opening **one** `.tscn` in the Godot editor. Scripts wire data; they do not define structure.

## What belongs in `.tscn` (always)

| Item | Example |
|------|---------|
| Node tree | `VBox` / `HBox` / `Grid`, `%UniqueName` |
| `custom_minimum_size`, size flags | On each control node |
| `theme_override_constants/separation` | On containers |
| `theme_override_styles/*` | `StyleBoxFlat` / `StyleBoxTexture` as **`[sub_resource]`** |
| Margins, anchors (shell only) | `Margem`, root Full Rect |
| Default fonts/colors on labels | `theme_override_colors`, `font_size` |

## What belongs in `.gd` (only)

| OK | Not OK |
|----|--------|
| `text = tr(...)` / `label.text = ...` | `custom_minimum_size =` |
| `visible`, `disabled` | `size_flags_* =` |
| `pressed.connect(...)` | `add_theme_constant_override("separation", ...)` |
| `configure(menu)` | `StyleBoxFlat.new()` for chrome |
| State tints (`modulate`, `font_color`) | `reparent()` for layout |
| `duplicate()` on **exported** StyleBoxes from the same `.tscn` for tab/selection state | New StyleBoxes built in code |

## External files — strict rules

| File type | Allowed? |
|-----------|----------|
| `sub_resource` inside panel `.tscn` | **Yes — default** |
| `presentation/shared/styles/*.tres` linked via `ExtResource` in panel `.tscn` | **No** — copy values into `sub_resource` instead |
| `inventory_layout_default.tres` | **Shell only** — hub `apply_layout()` on legacy `@tool` prefabs (do not add new runtime sizing) |
| `PackedScene` prefabs (`item_slot`, grids) | **Yes** — reuse grids, not one-off layout |

`shared/styles/` is a **clipboard**: copy hex/margins into the panel's `sub_resource` blocks when creating a screen. Do not `ExtResource` link unless three+ panels share one style **and** the team explicitly extracts it (rare).

## Agent checklist (before marking done)

1. Open the panel `.tscn` — tree + StyleBoxes visible without opening `.gd`
2. Run `tools/check_tscn_ownership.py` — must pass for new/edited panels
3. Grep panel `.gd` — no `custom_minimum_size`, `StyleBoxFlat.new`, `size_flags`
4. If layout changed → `run_edit_ui_validation.ps1 -ScopePng <id>` + capture-menu-screens scoped workflow

## New panel vs existing hub prefab

| Context | Rule |
|---------|------|
| **New sidecar / overlay / settings** | Bake sizes and StyleBoxes in `.tscn`. No runtime `apply_layout()` for structure. |
| **Editing existing hub prefabs** (`hero_*_panel`, `inventory_panel`, `bottom_nav`) | May call `apply_layout()` from `InventoryLayout` — legacy `@tool` preview. Change layout in `.tscn` first; `apply_layout()` only scales baked nodes. |
| **Menu shell** | `inventory_menu.gd` orchestrates `InventoryLayout` via `_apply_panel_layout()`. |

**Do not copy `apply_layout()` into brand-new panels** — bake sizes in `.tscn` and use `InventoryLayout` only at the menu shell.

## Legacy exceptions

Allowlist: `tools/check_tscn_ownership.py` → `GD_LAYOUT_ALLOWLIST`.

## Tab / dynamic states

Bake three StyleBoxes as `sub_resource` in the panel `.tscn`, assign to `@export` on the root script, use `.duplicate()` only when toggling state — never `StyleBoxFlat.new()`.

```text
[sub_resource type="StyleBoxFlat" id="StyleBoxFlat_tab_active"]
...

[node name="MyPanel" type="Control"]
style_tab_active = SubResource("StyleBoxFlat_tab_active")
```

```gdscript
@export var style_tab_active: StyleBoxFlat

func _style_tab(button: Button, active: bool) -> void:
    var style := style_tab_active.duplicate() as StyleBoxFlat
    button.add_theme_stylebox_override("normal", style)
```

## Enforcement

```powershell
python tools/check_tscn_ownership.py
powershell -ExecutionPolicy Bypass -File tools/run_ui_layout_check.ps1   # includes ownership
```

Fails when:

- Panel `.tscn` uses `ExtResource` to `presentation/shared/styles/`
- Panel `.gd` (not allowlisted) sets layout or creates StyleBoxes
