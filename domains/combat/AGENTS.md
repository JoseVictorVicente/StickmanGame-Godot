# Combat domain

- `combat_controller.gd` — idle loop, phase advance, enemy death/defeat
- `party_service.gd` — 3 hero slots, timers, DPS, optional `StatCalculator`
- `enemy.gd` — HP, damage, rewards
- `drop_manager.gd` — gold variance and item drops
- `skill_runtime.gd` — passive bonuses from `HeroEquipment` + `SkillResource.stat_value`

## Signals (CombatController)

| Signal | When |
|--------|------|
| `enemy_hp_changed(current, max_hp)` | Enemy HP updated |
| `enemy_hit(damage, current, max_hp)` | Hero hit landed |
| `enemy_died` | Enemy killed (before loot resolution) |

## Boundaries

- `PartyService` may spawn stickman sprites — combat presentation nodes only
- Must NOT reference inventory UI (`InventoryMenu`, `ItemSlot`)
- Gold/XP rewards emit signals; `main` / `GameState` apply economy
