# Containers cheatsheet (Godot 4.7)

Stickman Idle UI uses built-in containers only. No GameGUI / runtime layout libs.

## Two layout modes (read this first)

| Parent type | Child layout |
|-------------|--------------|
| **Not** a Container (`Control`, root shell) | Anchors + offsets (Layout presets) |
| **Is** a Container (`VBox`, `HBox`, `Grid`, …) | `size_flags` + `custom_minimum_size` only — **anchors ignored** |

Before editing a node: check the parent. Fighting a Container with manual anchors causes “random” runtime jumps.

## Three-level nesting (default recipe)

```text
Control (Full Rect)              ← screen / panel root
└─ MarginContainer or PanelContainer   ← outer padding or frame (StyleBox)
   └─ VBox / HBox                ← rows and columns
      └─ content widgets
```

Sidecar panels in this project:

```text
Control (WarehousePanel)
├─ FundoPainel (PanelContainer + StyleBoxTexture)
└─ Margem (MarginContainer, mirrors texture margins)
   └─ Conteudo (VBox)
```

## Size flags recipes

### Toolbar: label left, button right

```text
HBox
├─ Label          size_flags_horizontal = SHRINK_BEGIN
├─ Control        size_flags_horizontal = EXPAND_FILL   (spacer)
└─ Button         size_flags_horizontal = SHRINK_END
```

### Equal-width buttons in a row

Each button: `size_flags_horizontal = EXPAND_FILL`, same `custom_minimum_size.y`.

### Proportional columns 25% / 50% / 25%

Use `stretch_ratio` **1 : 2 : 1** (not 0.25 : 1 : 0.25). All three children: `EXPAND_FILL`.

### Child height 0 in VBox

Set `custom_minimum_size.y` **or** `size_flags_vertical = EXPAND_FILL`. Default min height is often 0.

### Button exact size in a container

`custom_minimum_size` + `SIZE_SHRINK_CENTER` (or `SHRINK_BEGIN` / `SHRINK_END`). Container owns final size.

## Which container when

| Container | Use in Stickman Idle |
|-----------|----------------------|
| `VBoxContainer` / `HBoxContainer` | Headers, nav rows, meta stacks (20px / 8px separation) |
| `GridContainer` | Slot grids, tab rows |
| `MarginContainer` | Inner inset inside framed panels (`Margem`) |
| `PanelContainer` | `FundoPainel` with `StyleBoxTexture` / `StyleBoxFlat` |
| `ScrollContainer` | `inventory_panel` grid overflow |
| `AspectRatioContainer` | Trail map art (`trail_map_view.tscn`) |
| `CenterContainer` | Center icon inside slot / stage node |
| `TabContainer` | Avoid unless product asks for tabs |

## %UniqueName rules

- Scope is **the scene** that owns the node.
- Scripts on the panel root use `%CloseButton`; cross-scene refs go through `configure(menu)` or `@export`.
- Prefer monolithic panel scenes + `%` over many tiny web-style components (GDQuest).

## CanvasLayer

One `CanvasLayer` on the game main scene — not on every UI prefab. UI scene roots stay `Control` so anchors work when instanced.

## TSCN-first reminders

- `theme_override_constants/separation` on VBox/HBox — not negative `position`.
- `layout_mode = 0` forbidden inside containers (see `tools/check_ui_layout.py` ALLOWLIST).
- Popups: stack menu **above** button in a `VBox` (`worlds_panel.tscn`).

## External links

- [Godot — Using Containers](https://docs.godotengine.org/en/stable/tutorials/ui/gui_containers.html)
- [Godot — Size and anchors](https://docs.godotengine.org/en/stable/tutorials/ui/size_and_anchors.html)
- [GDQuest — All containers](https://school.gdquest.com/courses/learn_2d_gamedev_godot_4/start_a_dialogue/all_the_containers)
