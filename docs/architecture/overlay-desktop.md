# Desktop Overlay

Stickman Idle runs as a **transparent floating window** over the desktop: borderless, always-on-top, alpha background, with click-through on empty areas.

## Configuration in `project.godot`

```ini
[display]
window/size/viewport_width=960
window/size/viewport_height=860
window/size/borderless=true
window/size/always_on_top=true
window/size/transparent=true
window/stretch/mode="canvas_items"
window/stretch/aspect="expand"
window/per_pixel_transparency/allowed=true

[rendering]
renderer/rendering_method="gl_compatibility"
viewport/transparent_background=true
```

| Setting | Value | Reason |
|---------|-------|--------|
| `borderless` | true | No OS chrome |
| `always_on_top` | true | Persistent overlay |
| `transparent` | true | Empty areas do not block desktop |
| `gl_compatibility` | — | Stable transparency on Windows |
| `viewport_width/height` | 960×860 | Logical UI size |

## WindowManager

**Code:** `presentation/shared/window_manager.gd` (`WindowManager`).

Instantiated by `main` in `_ready()`. Responsibilities:

### Window flags (`configurar_flags`)

```gdscript
DisplayServer.window_set_flag(WINDOW_FLAG_BORDERLESS, true)
DisplayServer.window_set_flag(WINDOW_FLAG_ALWAYS_ON_TOP, true)
DisplayServer.window_set_flag(WINDOW_FLAG_TRANSPARENT, true)
DisplayServer.window_set_flag(WINDOW_FLAG_MOUSE_PASSTHROUGH, false)  # toggled dynamically
```

Also forces `transparent_bg` on viewport and root.

### Drag

- Drag areas: `palco`, `painel_batalha` (`gui_input` → `on_area_arraste`).
- Moves window via `DisplayServer.window_set_position`.
- On release with menu open: `ao_soltar_arraste` → repositions combat (top/bottom).

### Click-through (`atualizar_click_through`)

Runs in `_process`:

1. If menu visible: disable passthrough (capture clicks on inventory).
2. If menu closed: enable passthrough except on interactive controls (menu button, combat stage).

Uses `obter_rects_menu()` for inventory clickable rectangles.

### Dynamic layout

| Method | Function |
|--------|----------|
| `alinhar_combate()` | Anchors `combate` to floor center |
| `ajustar_largura(expandido, largura_menu)` | Window width with/without side panel |
| `ancorar_combate_no_topo(no_topo)` | Menu opens downward vs upward |
| `aplicar_direcao_do_menu()` | Chooses direction based on screen position |

Main constants: [`ui_constants.gd`](../../presentation/shared/ui_constants.gd) (`WINDOW_WIDTH=960`, `WINDOW_HEIGHT=860`, `COMBAT_RESERVED_SPACE=320`). `WindowManager` also uses `PALCO_ALTURA=124` for combat anchors.

### Inventory menu band

`InventoryMenu` uses a vertical container shell (not fixed `offset_bottom` on a top band):

```text
OverlayVBox
├─ TopSpacer      (Expand, or fixed combat reserve when combat is on top)
├─ MenuArea       (HBox: warehouse | Panel hub | forge/worlds)
└─ BottomSpacer   (fixed combat reserve when combat is at bottom, else Expand)
```

`set_below_combat()` flips which spacer expands vs reserves `COMBAT_RESERVED_SPACE`. Window width follows `MenuArea.get_combined_minimum_size()`.

## Main scene

Relevant hierarchy in `scenes/main.tscn`:

```text
Main
├── HudBotao (open inventory button)
├── HudBatalha
│   ├── PainelBatalha (drag)
│   ├── Palco (drag + combat)
│   └── Combate / PartyService / InimigoVisual
└── HudInventario / InventoryMenu
```

`menu_inventario.hide()` on boot — overlay starts with combat HUD only.

## Testing in Godot editor

1. **Disable "Embed Game"** in the run panel — embed ignores OS window flags.
2. Run F5 — window should appear without opaque background.
3. Click outside stage/combat — click passes to apps below (menu closed).
4. Open inventory — clicks captured on panel.
5. Drag stage — window moves; when opening menu near bottom edge, combat anchors to top.

## Common issues

| Symptom | Likely cause |
|---------|--------------|
| Black background | `transparent_bg` off or incompatible renderer |
| Window not on top | `always_on_top` flag or OS blocking |
| Clicks do not pass | `MOUSE_PASSTHROUGH` false or large rect covering screen |
| Embed in editor | Use separate window mode |

## Platform

Primary development: **Windows 10+**. `rendering_device/driver.windows=d3d12` in project; transparency validated with GL Compatibility.

Do not change `project.godot` display/rendering without updating this doc and testing the full overlay.
