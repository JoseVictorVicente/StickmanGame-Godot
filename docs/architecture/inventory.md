# Inventory and Meta-Progression

The inventory groups equipment per class, item grid, forge (craft), warehouse (extra storage), and panel navigation — all inside `InventoryMenu`.

**Code:** rules in `domains/inventory/`; UI in `presentation/inventory/`.

## InventoryMenu — central hub

`InventoryMenu` is the floating panel opened by the 4-square button. Responsibilities:

| Area | Component | Function |
|------|-----------|----------|
| Main grid | `InventorySlotsGrid` | 5×10 display (49 usable slots + expand) |
| Equipment | `hero_equip_left_panel` / `hero_equip_right_panel` | 12 slots per class |
| Characters | hidden `CharacterRow` in hero section | legacy selector (party UI primary) |
| Party | `TeamSelectionUI` | Up to 3 active classes (`PartyService`) |
| Forge | `ForgePanel` | Synthesis, dismantle, gems |
| Warehouse | `WarehousePanel` | Paginated storage |
| Worlds | `WorldsPanel` | Portal saga: hall → briefing → trail map |
| Skill tree | `SkillTreePanel` | Gold upgrades |
| Skills | `SkillsPanel` | Skill view/equip |
| Navigation | `BottomNav` | Storage, skills, tree, formation, forge, world |

### Gold

Gold lives in `GameState` (synced from `main`). The menu queries via `consultar_ouro: Callable` and emits:

- `ouro_obtido(quantidade)` — sell, dismantle, etc.
- `ouro_gasto(quantidade)` — skill tree, forge

**Domain code must not mutate gold directly** — always via signals/callbacks through `GameState`.

## Equipment

### Slots per class

Each `ClassData.id` (e.g. `warrior`, `mage`, `archer`) has a list of `ItemSlot` with `tipo_aceitavel` (`ItemData.Tipo`):

- Left: Primary, Secondary, Helmet, Chest, Gloves, Pants, Boots
- Right: Belt, Pendant, Ring, Bracelet, Pet

### Rules

- `ItemData.classe_requerida` must match the class.
- Imbued gems (`gema_imbuida`) persist in `para_dicionario()`.
- `equipamentos_alterados` → `main.recalcular_atributos()`.

### Query API (combat)

```gdscript
obter_dano_equipado(slot_index: int) -> int
obter_vida_equipada(slot_index: int) -> int
```

Sums `dano_bonus` / `vida_bonus` from items equipped for the party slot's class.

### Serialization

```json
{
  "warrior": [
    {"tipo": 2, "item": { /* ItemData dict */ }},
    ...
  ],
  "mage": [...],
  ...
}
```

Legacy `Array` format (3 fixed entries) still supported in `aplicar_equipamentos`. Save v4 migrates legacy Portuguese class keys (`guerreiro`, `mago`, `arqueiro`) to English IDs.

## Inventory (grid)

- **5×10 display (50 slots, 49 usable)** in UI; last slot is a non-functional "+" expand placeholder.
- **Baked in scene:** `inventory_slots_grid.tscn` holds 50 `item_slot.tscn` instances. Runtime updates slots in place via `ItemSlot.set_item()` — no per-frame rebuild.
- Proportions driven by `InventoryLayout` (`base_unit`, `inventory_layout_default.tres`); hub panel `apply_layout()` methods and menu `_apply_panel_layout()` apply sizes at runtime.
- Serialization: one entry per usable slot; empty = `{}`. `apply_inventory` clears trailing slots and ignores empty dicts.
- Combat drops: `try_add_inventory_item` → `first_empty_inventory_slot()` on **`inventory_slots_grid.usable_slots()` only**; never equipment slots. **Silent discard** when full (no auto-warehouse).
- Warehouse storage is manual (drag to `WarehousePanel` or player action).
- Drag-and-drop via `ItemSlot` signals.
- `fill_initial_item_if_empty()` — tutorial item on new save.
- Sort compacts items to the front of the fixed grid (`sort_slots`).

### Slot wiring (presentation)

| List / API | Scope |
|------------|--------|
| `inventory_slot_list` | Grid slots only — set by `InventoryPanel.configure()` |
| `_all_equipment_slots()` | Left/right hub panels — wired in `_setup_equipment()` |
| `first_empty_inventory_slot()` | Usable grid slots only |
| `is_equipment_slot()` | Equip slots via `HeroEquipLeftPanel` + `HeroEquipRightPanel` |

## Inventory hub (presentation)

`inventory_menu.tscn` is split into editable prefabs:

| Prefab | Role |
|--------|------|
| `hero_equip_left_panel.tscn` | Baked equip grid (7 slots) + active skill slots |
| `hero_character_panel.tscn` | Portrait, XP, ultimate, attributes, party row |
| `hero_equip_right_panel.tscn` | Passive skills, jewelry, pet, sort button |
| `inventory_panel.tscn` | Scroll + 5×10 `inventory_slots_grid.tscn` |
| `bottom_nav.tscn` | Storage, skills, tree, formation, forge, **Portais** |
| `settings_panel.tscn` | Volume and locale overlay |

`inventory_menu.gd` is a thin shell; drag/panel/persistence logic lives in `InventoryDragController`, `InventoryPanelRouter`, and `InventoryPersistenceBridge`.

Equipment slots are baked in `hero_equip_left_panel.tscn` / `hero_equip_right_panel.tscn`. Per-class loadouts live in `EquipmentLoadoutRegistry`; switching hero/class refreshes the visible slots without duplicating grids in the scene tree.

## Warehouse (`WarehousePanel`)

- **Baked UI:** 8 tab buttons + 8 `warehouse_slots_grid.tscn` instances (40 slots each) in `warehouse_panel.tscn`; `warehouse_panel.gd` wires tabs and refreshes slot state only.
- Multiple tabs; first always unlocked.
- Extra tabs via `ARMAZEM` nodes in the skill tree.
- Serialization:

```json
{
  "desbloqueadas": [true, false, ...],
  "abas": [[{item}, ...], ...]
}
```

Legacy format: flat `Array` = tab 0 only.

## ForgePanel

Three tabs:

| Tab | Mechanic |
|-----|----------|
| **Synthesis** | 9 items same rarity/family → 1 higher rarity |
| **Dismantle** | Item → gold (emits `ouro_obtido`) |
| **Gems** | Imbue gem into legendary+ gear (`ItemData.imbuir_gema`) |

**Baked UI:** synthesis/dismantle use `forge_slots_grid.tscn`; gems tab has three `item_slot.tscn` children in `GemsArea` (`SlotJoiaAlvo`, `SlotJoiaGema`, arrow host). Runtime updates icons/state only.

## AttributesPanel

- **Baked UI:** 12 `attribute_row.tscn` instances in `attributes_panel.tscn`; `attributes_panel.gd` calls `AttributeRow.set_values()` on refresh.

## WorldsPanel (Portals)

- **Baked UI:** portal hall (5 cards + progress), briefing panel, trail map (9 stage anchors) in `worlds_panel.tscn`; `worlds_panel.gd` drives three views and labels from `WorldCatalog`.
- **Narrative canon:** [`portals-saga.md`](portals-saga.md)

Optional toggle to consume warehouse items in synthesis.

## ItemData

Central resource (`data/item_data.gd`):

- Types: equipment, accessory, gem.
- Rarities: Common → Transcendental (11 tiers).
- Discrete levels: `[5, 10, 15, …, 80]`.
- Persistence: `para_dicionario()` / `de_dicionario()` with rarity migration.

Catalog and drops: `ItemDatabase` autoload.

## Skills (view/equip)

`SkillsPanel` + `HeroEquipment` autoload:

- 2 active + 2 passive slots per class.
- Resources in `data/skills/<class>/*.tres`.
- Equipped loadouts **persist in save v4** via `hero_equipment`.
- **WYSIWYG:** `skills_active_grid.tscn` (pool 6 ativas) + `skills_passive_grid.tscn` (pool 10 passivas) bakeados; 3× `party_hero_slot_button` no seletor de herói; runtime só atualiza `visible` / ícones / meta — sem rebuild de grades.

## Formation

`FormationPanel` monta a party em campo:

- 3× `formation_party_slot.tscn` (party row) — bakeados.
- 6× `party_hero_slot_button` em `%FormationHeroGrid` (uma por classe do catálogo) — bakeados com `metadata/class_id`.
- Runtime: `_refresh_hero_grid()` atualiza visibilidade/estado; sem `queue_free`.

## Layout and window

- `largura_para_janela()` — expands overlay when sub-panels open.
- `obter_retangulos_clicaveis()` — hit-test for click-through (`WindowManager`).
- Menu can open upward/downward based on screen position (`janela_solta`).

## Module boundaries

`domains/inventory/` must **not**:

- Create `Label`/`Button` directly (that is `presentation/`).
- Call `PartyService` without an interface (prefer signals or injected service).

It may:

- Validate equip, serialize, compute item stats, forge rules.
