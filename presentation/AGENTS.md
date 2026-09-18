# Presentation layer

- UI emits commands; never mutates `GameState` directly
- All visible strings via `tr(LocaleKeys.*)` and `locales/*.po`
- `shared/` — window manager, icons, coin VFX
- `worlds/` — world map UI
- `inventory/` — inventory panels
