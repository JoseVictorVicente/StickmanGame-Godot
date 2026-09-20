# Scenes and Resources

Patterns for `.tscn`, `.tres`, and data asset organization.

## Scene vs data separation

| Type | Contains | Must not contain |
|------|----------|------------------|
| `.tscn` | Node hierarchy, layout, skins | Economy/combat rules |
| `.tres` | Exported data (`@export`) | Runtime node references |
| Domain `.gd` | Pure logic / services | `@onready` to foreign UI |

## Folder structure (target)

```
data/
├── item_data.gd          # Resource scripts
├── skill_resource.gd
├── class_data.gd
├── skills/
│   ├── warrior/
│   ├── mage/
│   └── archer/
└── schemas/              # Curves, design constants

presentation/
├── hud/
├── inventory/
│   ├── inventory_menu.tscn
│   └── forge_panel.tscn
└── shared/
	└── window_manager.gd

scenes/
└── main.tscn             # Single composition root
```

Scenes: `presentation/inventory/*.tscn`, skills in `data/skills/`, entry point `scenes/main.tscn`.

## Scenes (`.tscn`)

### Main

- Single entry point: `scenes/main.tscn`.
- Script orchestrates wiring; feature logic lives in children or instantiated services.

### UI panels

- Root `Control` with anchors for overlay.
- Internal layout via containers — see [`ui-layout.md`](ui-layout.md).
- Sub-panels (ForgePanel, Warehouse) as hidden children (`hide()` by default).
- Unique names (`%NodeName`) for script binds.

### Combat visuals

- `PartyService` as `Node2D` with `Marker2D` for positions.
- Sprites created in code (`stickman.gd`) — do not duplicate 3× in the scene.

## Resources (`.tres`)

### SkillResource

Path: `data/skills/<class>/<id>.tres`

```ini
[resource]
script = ExtResource("skill_resource.gd")
skill_id = "01_meteoro_abissal"
skill_name = "Meteoro Abissal"
description = "..."
type = 0          # ACTIVE
cooldown = 5.0
icon_path = "res://sprites/ui/skills/mage/01_meteoro_abissal.png"
sort_order = 1
```

Generator: `tools/gerar_skills.ps1`.

### ItemData

Catalog items generated at runtime by `ItemDatabase._popular_catalogo()` — not one `.tres` per drop. Templates may become resources later.

### Layout resources

`layout_inventario_padrao.tres` — reusable theme/spacing; OK in `presentation/`.

## `res://` references

- **New code:** target paths (`res://data/`, `res://domains/`).
- When moving files, grep old `res://` in the repo.
- Do not reference `user://` in committed resources.

## Instantiation

```gdscript
# Service without dedicated scene
var combat := CombatController.new()
add_child(combat)

# UI with complex layout
var menu := preload("res://presentation/inventory/inventory_menu.tscn").instantiate()
```

Prefer scenes for visual layout; `new()` for pure services.

## UID files

Godot 4 generates `*.uid` — commit with the asset. Do not edit manually.

## Sprites

- Art in `sprites/` — **do not bulk-regenerate or replace**.
- `.import` sidecars committed.
- Skill icons: `sprites/ui/skills/<class>/<skill_id>.png`.

## New resource checklist

1. Script with `class_name` in `data/`.
2. `@export` fields documented with `##`.
3. Path follows `<type>/<category>/<id>.tres`.
4. Referenced icon exists in `sprites/`.
5. Registered in catalog if needed (`HeroEquipment`, `ItemDatabase`).

## New UI scene checklist

1. Pick a layout pattern from [`ui-layout.md`](ui-layout.md).
2. Script in `presentation/<area>/`.
3. Text via `tr()` (see [`i18n.md`](i18n.md)).
4. Signals to domain — no gold/combat logic in UI beyond emitting signals.
5. Test with menu open/closed and click-through.
