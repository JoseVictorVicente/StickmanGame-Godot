# Screen cookbook — shell diagrams

**Doc-first:** design from [`project-ui-patterns.md`](project-ui-patterns.md) and [`ui-layout.md`](../../../../docs/conventions/ui-layout.md). Diagrams below describe **structure constraints**, not scenes to clone.

## Inventory menu shell

```text
inventory_menu.tscn
└─ OverlayVBox
   ├─ TopSpacer
   ├─ MenuArea (HBox, separation=8)
   │  ├─ WarehousePanel
   │  ├─ HubColumn (VBox)
   │  │  ├─ HubChromeBar → gold, quit, settings
   │  │  └─ HubBody
   │  │     ├─ HubContent (VBox)
   │  │     │  ├─ HubUpperRow → hero_equip_left + hero_character + hero_equip_right
   │  │     │  ├─ InventoryPanel (scroll + 5×10 grid)
   │  │     │  └─ BottomNav
   │  │     └─ OverlayStack → formation, skills, attributes, skill tree, settings
   │  ├─ ForgePanel
   │  └─ WorldsPanel
   └─ BottomSpacer
```

Heights: `InventoryLayout.hub_upper_row_size()` / `inventory_panel_size()` via `_apply_hub_content_heights()`.

`inventory_bg.png` has two bands — upper (hero) and lower (grid + nav). Formation lives in lower band via `inventory_row.tscn` / `bottom_nav.tscn`.

## Sidecar panel (warehouse, forge, worlds)

**Pattern:** Panel inset + header row + variable body.

```text
Control (root, size_flags_vertical=EXPAND_FILL)
├─ FundoPainel (PanelContainer, Full Rect, StyleBoxTexture frame)
└─ Margem (MarginContainer, margins = texture margins 21/19/19/20)
   └─ Conteudo (VBox, separation=8)
      ├─ Header (HBox) → BannerTitulo + close Button
      ├─ body (tabs, grid, scroll, … — design per feature)
      └─ footer (HBox, optional)
```

Wire: `configure(menu: InventoryMenu)`, `panel_open_changed` signal, `InventoryPanelRouter`.

Worlds: same shell; inner views swap (`portal_hall_view`, `realm_briefing_view`, `trail_map_view`).

## Full-bleed overlay (formation, skills, attributes)

```text
Control (root, visible=false, Full Rect on OverlayStack)
└─ FundoPainel (PanelContainer, panel_bg StyleBoxTexture)
   └─ Margem → Conteudo (VBox)
      ├─ header row (banner + close)
      └─ body
```

Alignment: `panel_layout.gd` `align_overlays` on hub `Panel`. Hide hub via router — not `painel.visible = false` on the whole hub.

## Skill tree overlay

Replaces hub content; graph positions baked in `.tscn` (allowed exception).

## Worlds / Portais header stacks

```text
WorldsHeader (VBox, separation = 20)
├─ HeaderRow (HBox) — back, title banner, close
└─ TrailHeaderDetails (VBox, separation = 8) — trail only
   ├─ TrailProgressLabel
   └─ TrailDifficultyRow → TrailDifficultyButton
RodapeDificuldade — hall only (%DifficultyButton)
```

Difficulty menus: **two** baked stacks in `worlds_panel.tscn` (hall footer + trail header). Menu panel **above** button in a `VBox`. No `reparent()` in script.

## Trail map

- `AspectRatioContainer` + `TextureRect` for map art
- Stage UV anchors baked on `MapLayer`
- `StageColumn` VBox (circle + label) inside each anchor

## Hub block prefabs

| Block | Scene |
|-------|--------|
| Equip left | `hero_equip_left_panel.tscn` |
| Character | `hero_character_panel.tscn` |
| Equip right + sort | `hero_equip_right_panel.tscn` |
| Inventory grid | `inventory_panel.tscn` |
| Bottom nav | `bottom_nav.tscn` |

Edit prefab in isolation; wire via `configure(menu)` + signals.

## Settings popup

Anchored top-right under `%OverlayStack` — not sidecar.

## Mockups

Portals visual target: `artifacts/design/portals_mockup_1_hall.png`, `_2_briefing.png`, `_3_trail.png`.
