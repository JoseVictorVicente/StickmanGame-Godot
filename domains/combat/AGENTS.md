# Combat domain

- `combat_controller.gd` — idle loop, phase advance, enemy death/defeat
- `party_service.gd` — 3 hero slots, timers, DPS, optional `StatCalculator`
- `enemy.gd` — HP, damage, rewards (runtime instance)
- `data/enemy_catalog.gd` — resolves `EnemyData` by world/stage/wave/role
- `drop_manager.gd` — gold variance and item drops
- `skill_runtime.gd` — passive bonuses from `HeroEquipment` + `SkillResource.stat_value`
- `active_skill_runtime.gd` — active cooldowns and cast priority
- `combat_resolver.gd` — resolves `SkillResource.effects` into hits/buffs
- `buff_container.gd` — timed combat buffs per party slot

## Signals (PartyService)

| Signal | When |
|--------|------|
| `hero_attacked(slot, damage, is_crit)` | Basic attack timer fired |
| `hero_skill_used(slot, skill, hits, heals)` | Active skill cast resolved |

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
- Must NOT call `GameLog` directly — assisted logging listens to the signals above via `core/event_log_bridge.gd` (wired in `scenes/main.gd`). New skills need no logging code if they use this pipeline.

## Assisted logging

Signals listed here are the **observability contract**. `EventLogBridge` maps them to structured events (`combat.skill_cast`, `combat.enemy_hit`, etc.). See `docs/workflows/assisted-logging.md`.
