# Naming Conventions

## Language

| Context | Language | Example |
|---------|----------|---------|
| Code (functions, variables, signals, `.gd` files) | **English** | `apply_damage`, `gold_changed` |
| `class_name` declarations | English | `PartyService`, `ItemData` |
| Target module folders | English | `domains/combat/`, `data/skills/` |
| Player-facing UI | i18n `tr("KEY")` | `tr("INVENTORY_TITLE")` |
| Documentation (`docs/`, `README.md`, `AGENTS.md`) | **English** | this file |
| Skill `.tres` filenames | English slug preferred | `01_frenzied_sequence.tres` |

Legacy Portuguese API (`coletar_save`, `aplicar_save`) remains until refactored; **new code in English**.

## Files and folders

```
snake_case.gd          # scripts
snake_case.tscn        # scenes
snake_case.tres        # resources
PascalCase for class_name only
```

### Legacy → target map

| Legacy | Target |
|--------|--------|
| `cenas/main.gd` | `scenes/main.gd` |
| `combate/party_manager.gd` | `domains/combat/party_service.gd` |
| `dados/item_data.gd` | `data/item_data.gd` |
| `inventario/menu.gd` | `presentation/inventory/inventory_menu.gd` |
| `autoload/save_system.gd` | `core/save_service.gd` |

## GDScript identifiers

| Type | Pattern | Example |
|------|---------|---------|
| Constant | `UPPER_SNAKE` | `MAX_ACTIVE`, `SAVE_VERSION` |
| Private variable | `_snake_case` | `_resolvendo_morte` |
| Public function | `snake_case` | `apply_save`, `get_gold` |
| Internal function | `_snake_case` | `_emitir_dps` |
| Signal | `snake_case` | `hero_attacked`, `gold_changed` |
| Enum | `PascalCase` type, `UPPER` members | `Tipo.ARMA` |
| `@export` | `snake_case` | `skill_id`, `cooldown` |

## Domain IDs

| Entity | Format | Example |
|--------|--------|---------|
| Hero class | English slug (canonical) | `warrior`, `mage`, `archer` |
| Legacy class ID | PT slug (save migration) | `guerreiro` → `warrior` |
| Skill | `NN_slug` or `pNN_slug` | `01_meteoro_abissal`, `p01_amplificacao_arcana` |
| Item instance | `{model_id}_{ticks}` | `espada_1703123456789` |
| Skill tree node | sequential `int` in catalog | `0`, `42` |

All six playable classes: `warrior`, `mage`, `archer`, `assassin`, `tank`, `priest`.

## Signals — preferred vocabulary

| Concept | Verb |
|---------|------|
| Value changed | `*_changed` |
| Action completed | `*_completed` |
| Async request | `*_requested` |
| UI toggle | `visibility_changed` |

Legacy `alterada` / `pedido` accepted in existing code; new signals in English.

## Scenes and nodes

- Scene nodes: `PascalCase` in English when possible (`PartyService`, `InventoryGrid`).
- Unique names with `%` for binds: `%LabelGold`, `%InventoryGrid`.
- Groups: `snake_case` (`combat_units`).

## Save and JSON

v4 uses English keys (`gold`, `inventory`). Legacy PT aliases supported:

```gdscript
const KEY_GOLD := "gold"           # canonical
const KEY_GOLD_LEGACY := "ouro"    # compat
```

See [`../architecture/save-format.md`](../architecture/save-format.md).

## i18n keys

`SCREAMING_SNAKE` with module prefix:

```
COMBAT_ENEMY_DEFEATED
INV_SORT_INVENTORY
TREE_NODE_MAX_LEVEL
```

See [`i18n.md`](i18n.md).

## Do not bulk-rename

- `sprites/` — paths referenced in `.tres` and `.import`
- `user://save.cfg` — no planned path migration
- `project.godot` public autoload names without version bump
