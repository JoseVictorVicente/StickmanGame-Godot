# StyleBoxTexture gotchas (panel frames)

Critical for sidecars using `sprites/ui/worlds_bg.png` and hub overlays using `panel_bg.png`.

## Correct stack

```text
Control (root)
├─ FundoPainel (PanelContainer)
│  └─ theme_override_styles/panel = panel_frame_worlds.tres (StyleBoxTexture)
└─ Margem (MarginContainer)          ← siblings, both Full Rect
   └─ Conteudo (VBox)
```

`FundoPainel` draws the frame; `Margem` insets **content** to the inner safe area. Do not rely on texture margins alone to pad children.

## texture_margin vs content_margin

| Property | Role |
|----------|------|
| `texture_margin_*` | 9-patch border width in **texture pixels** (21/19/19/20 for `worlds_bg`) |
| `content_margin_*` | Padding **inside** the stylebox for child controls |

When `content_margin_*` is **-1** (default), Godot falls back to `texture_margin_*` for minimum content inset — children get pushed by the border size ([StyleBoxTexture docs](https://docs.godotengine.org/en/stable/classes/class_styleboxtexture.html)).

**Stickman rule:** set `content_margin_* = 0` on shared `panel_frame_worlds.tres`; use `Margem` for inner padding.

## Failure modes

| Symptom | Cause | Fix |
|---------|-------|-----|
| Border overlaps text | `content_margin` < `texture_margin` | Set content margins to 0; pad with `MarginContainer` |
| Panel taller than expected | content_margin -1 + label min height | Explicit content_margin 0 on frame StyleBox |
| Double padding | Margem **and** large content_margin | One source of inset only (Margem) |
| Frame looks wrong at small size | texture_margin does not shrink below native border | Art must match margins; see [godot#73468](https://github.com/godotengine/godot/issues/73468) |

## Canonical values (`worlds_bg.png`)

```text
texture_margin_left   = 21
texture_margin_top    = 19
texture_margin_right  = 19
texture_margin_bottom = 20
content_margin_*      = 0   (all four)
```

`Margem` theme overrides should mirror texture margins so content aligns with the inner frame.

## PanelContainer vs NinePatchRect

Community shortcut ([Reddit 1j5aho8](https://www.reddit.com/r/godot/comments/1j5aho8/)): use **one** `PanelContainer` + `StyleBoxTexture`, not a chain of Margin + NinePatch + VBox for simple dialogs.

## Hub `panel_bg.png`

`formation_panel.tscn` may set both `content_margin` and `texture_margin` on the same values — intentional for full-bleed overlays. Sidecars use the split frame + Margem pattern above.

## Further reading

- [GitHub #110186](https://github.com/godotengine/godot/issues/110186) — texture margin affecting button min height
- [`style-recipes.md`](style-recipes.md) — shared `.tres` paths
