# Workflow: Add an Item

Guide for adding new equipment types or gems to the drop catalog.

## Architecture

- **Definition:** `ItemData` (`data/item_data.gd`)
- **Catalog:** `ItemDatabase` autoload (`platform/item_database.gd`)
- **Drops:** `DropManager` → `ItemDatabase.gerar_item_aleatorio(level)`
- **UI:** `ItemSlot`, inventory, forge

## Item types

| Category | `ItemData.Tipo` | Drops? |
|----------|-----------------|--------|
| Armor pieces | `CAPACETE`…`BOTA` | Yes |
| Weapons | `ARMA`, `SECUNDARIA` | Yes |
| Accessories | `CINTO`…`PET` | Yes |
| Gem | `GEMA` | ~22% of drops |

## Add template to catalog

Edit `ItemDatabase._popular_catalogo()`:

```gdscript
func _popular_catalogo() -> void:
    itens.append(_criar(
        "long_sword",              # base model id
        "Long Sword",              # name (migrate to name_key)
        ItemData.Tipo.ARMA,
        ItemData.RequiredClass.WARRIOR,
        base_damage := 8,
        base_hp := 0,
    ))
```

Or append to the existing array following the same pattern.

### Important fields

| Field | Notes |
|-------|-------|
| `id` | Unique in catalog; instances get `_ticks` suffix on drop |
| `tipo` | Defines equip slot |
| `classe_requerida` | `TODAS` or specific class (`WARRIOR`, `MAGE`, `ARCHER`, …) |
| `dano_bonus` / `vida_bonus` | Base before rarity/level |
| `raridade` | Rolled on drop |
| `nivel_item` | Rolled via `ItemData.sortear_nivel_item(enemy_level)` |

## Icon

Items use procedural icons by default:

```gdscript
item.icone = item.gerar_icone()
```

`gerar_icone()` draws by type/rarity. For custom art:

1. Create PNG in `sprites/ui/` (do not overwrite hero sprites).
2. Assign `item.icone = preload("res://...")` on the template.

## Rarity and balance

Multipliers in `ItemData.multiplicador_stats(rarity)` and `multiplicador_nivel_item(level)`.

Test drops at high stage:

```gdscript
# Temporary debug
print(ItemDatabase.gerar_item_aleatorio(30).descricao())
```

## Gems

```gdscript
ItemData.criar_gema(ItemData.AtributoGema.ATAQUE_PCT, ItemData.Raridade.RARO)
```

Valid attributes: see `AtributoGema` enum in `item_data.gd`.

## Imbuing (forge)

Legendary+ gear accepts gems via `ItemData.imbuir_gema()`. Persists in `gema_imbuida` in save.

## Serialization

Every inventory item uses `para_dicionario()` / `de_dicionario()`. For new `@export` fields:

1. Add to `para_dicionario()`.
2. Read in `de_dicionario()` with safe default.
3. Document in [`save-format.md`](../architecture/save-format.md) if it affects save.

## UI / slots

`InventoryMenu.TIPOS_EQUIP` maps label → `ItemData.Tipo`. For a new slot type:

1. Add enum in `ItemData.Tipo` (caution: int values are in save).
2. Update `TIPOS_EQUIP` and scene layout.
3. `serializar_equipamentos` updates automatically if slots exist.

## Playtest checklist

1. Drop in combat (kill ~10 enemies).
2. Equip in correct slot; wrong class rejected.
3. Stats reflect in DPS/HP (`recalcular_atributos`).
4. Save, restart — item preserved.
5. Dismantle in forge; synthesize 9→1 if applicable.

## Target

During migration, templates may become `.tres` in `data/items/templates/` loaded at boot — keep `gerar_item_aleatorio` API stable.
