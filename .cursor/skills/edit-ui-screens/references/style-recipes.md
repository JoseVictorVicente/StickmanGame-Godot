# Style recipes — visual tokens (copy into `.tscn`)

**Do not link** `presentation/shared/styles/*.tres` from panel scenes. Copy values into `[sub_resource]` blocks in the panel `.tscn`. See [`tscn-ownership.md`](tscn-ownership.md).

The `.tres` files are a **palette** for copy-paste when authoring in Godot or in the ui_builder editor.

## Palette files (reference only)

| Resource | Type | Use |
|----------|------|-----|
| `panel_frame_worlds.tres` | StyleBoxTexture | Sidecar frame (`worlds_bg.png`) |
| `banner_title.tres` | StyleBoxFlat | Red/gold title banner |
| `button_normal.tres` | StyleBoxFlat | Default button |
| `button_hover.tres` | StyleBoxFlat | Button hover |
| `button_pressed.tres` | StyleBoxFlat | Button pressed |
| `button_active.tres` | StyleBoxFlat | Selected tab / toggle on |

## Correct usage in `.tscn`

```text
[sub_resource type="StyleBoxFlat" id="StyleBoxFlat_botao"]
bg_color = Color(0.18, 0.14, 0.11, 1)
...

theme_override_styles/normal = SubResource("StyleBoxFlat_botao")
```

Bake tokens as inline `sub_resource` in each panel `.tscn` (see `warehouse_panel.tscn` for an example).

## Color tokens

| Token | Value | Use |
|-------|-------|-----|
| Banner bg | `Color(0.42, 0.14, 0.13, 1)` | Title strip |
| Banner border | `Color(0.78, 0.58, 0.28, 1)` | Banner + active button border |
| Title text | `Color(1, 0.86, 0.45, 1)` | Banner labels |
| Button bg | `Color(0.18, 0.14, 0.11, 1)` | Normal |
| Button hover bg | `Color(0.32, 0.24, 0.16, 1)` | Hover |
| Button pressed bg | `Color(0.1, 0.08, 0.07, 1)` | Pressed |
| Muted label | `Color(0.72, 0.66, 0.52, 1)` | Footer status |

## Spacing tokens

| Context | Value | Where |
|---------|-------|-------|
| Panel content stack | 8px | `Conteudo` VBox `separation` |
| Worlds title → meta | 20px | `WorldsHeader.separation` |
| Trail meta inner | 8px | `TrailHeaderDetails.separation` |
| Header row | 6px | Sidecar header HBox |
| Grid slot gap | 4px | `h_separation` / `v_separation` on grids |

## Margin tokens (`UiConstants`)

| Constant | Value | Use |
|----------|-------|-----|
| `PANEL_TEXTURE_MARGIN_LEFT` | 10 | Doc reference (inner logic) |
| `PANEL_TEXTURE_MARGIN_TOP` | 19 | |
| `PANEL_TEXTURE_MARGIN_RIGHT` | 10 | |
| `PANEL_TEXTURE_MARGIN_BOTTOM` | 6 | |

Sidecar `Margem` node uses texture margins **21 / 19 / 19 / 20** to match `panel_frame_worlds.tres` — keep in sync when art changes.

## Hub layout tokens

Use `inventory_layout_default.tres` + `InventoryLayout.sync_from_base_unit()` — never hardcode hub width on `HubBody` / `MenuArea`.

## Migration status

| Panel | Style location |
|-------|----------------|
| `warehouse_panel.tscn` | Inline `sub_resource` (canonical) |
| `forge_panel.tscn` | Inline (legacy) — do not ExtResource link |
| `worlds_panel.tscn` | Inline (legacy) |

New panels: design from [`project-ui-patterns.md`](project-ui-patterns.md); bake tokens here; run `check_tscn_ownership.py`. Older panels may diverge — follow doc for new work.
