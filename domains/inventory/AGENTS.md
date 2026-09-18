# Inventory domain

- `inventory_service.gd` — 10×5 grid, `add_item`, `to_dict` / `from_dict`
- `equipment_service.gd` — 12 equip slots × 3 character indices, `ItemData` validation
- `warehouse_service.gd` — 8 tabs × 40 slots, unlock flags, serialize
- `forge_service.gd` — stub: `can_improve`, `get_cost`, synthesis helpers

Pure `RefCounted` logic; no UI nodes. UI lives in `presentation/inventory/` (`InventoryMenu`, `ForgePanel`, `WarehousePanel`).

## Boundaries

- May use `ItemData`, `ClassData`, `SkillTreeDefinition` bonus keys
- Must NOT reference `Control` / `ItemSlot` nodes
- Gold mutations go through `GameState` / menu signals — not here

## Save

Inventory grid → `inventory` in save (legacy key `inventario`). Equipment → `equipment` dict by class id. Warehouse → `warehouse` dict.
