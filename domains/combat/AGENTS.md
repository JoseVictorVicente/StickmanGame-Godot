# Combat domain

- `combat_controller.gd` — meta-combat: death/defeat, stage advance, economy signals
- `combat_session.gd` — wires encounter + simulator + presentation bridge
- `sim/combat_encounter.gd` — encounter state (spawn, horde, runner phase)
- `sim/combat_simulator.gd` — tick loop (0.25s), swarm cadence, hero hits
- `sim/combat_event.gd` — domain events emitted by the simulator
- `sim/damage_pipeline.gd` — single-pass damage application
- `sim/combat_actor_group.gd` — horde / queue squad lanes
- `sim/combat_tuning.gd` — shared scroll, spawn runway, runner duration
- `sim/combat_lane.gd` — lane coordinate helpers (maps to pixel X via bridge)
- `party_service.gd` — 3 hero slots, timers, DPS, stickman visuals
- `party_stats_service.gd` — pure HP/target helpers (extracted stats; visuals stay in `PartyService`)
- `enemy.gd` — HP, damage, rewards (runtime instance)
- `data/enemy_catalog.gd` — resolves `EnemyData` by world/stage/wave/role; `resolve_horde()` for squads
- `drop_manager.gd` — gold variance and item drops
- `skill_runtime.gd` — passive bonuses from `HeroEquipment` + `SkillResource.stat_value`
- `active_skill_runtime.gd` — active cooldowns and cast priority
- `combat_resolver.gd` — resolves `SkillResource.effects` into hits/buffs
- `buff_container.gd` — timed combat buffs per party slot (ticks in `PartyService` until full sim port)

Presentation: `presentation/combat/combat_presentation_bridge.gd` maps `CombatEvent` → visuals only (including runner scroll and `sync_solo_lane` / `sync_horde_lanes`).

## Phase authority

| Phase | Source of truth | Presentation |
|-------|-----------------|--------------|
| `RUNNING` | `CombatEncounter.phase` + `solo_lane_x` | Bridge: scroll BG, `begin_formation_march`, sim-controlled enemy X |
| `BATTLE_APPROACH` | `PartyFieldState` + `battle_approach_active` | Per-slot advance/attack; scroll stops when any hero is in range |
| `ENGAGED` | `CombatEncounter.engaged` | Bridge: stop scroll; sim ticks enemy attacks |
| Meta (gold/XP/stage) | `CombatController` | HUD signals only |

Do not duplicate runner state in `CombatController` — use `CombatSession.is_running_phase()` / `is_engaged()`. Per-slot attack gates: `can_hero_attack_slot(slot)` wired to `PartyService.can_attack_target`.

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

- Simulation (`sim/`, `CombatSession`) must NOT reference UI nodes or read sprite `global_position` for rules
- `CombatPresentationBridge` must NOT call `take_damage` or mutate economy
- `PartyService` may spawn stickman sprites — combat presentation nodes only
- Must NOT reference inventory UI (`InventoryMenu`, `ItemSlot`)
- Gold/XP rewards emit signals; `main` / `GameState` apply economy
- Must NOT call `GameLog` directly — assisted logging listens to the signals above via `core/event_log_bridge.gd` (wired in `scenes/main.gd`). New skills need no logging code if they use this pipeline.

## Assisted logging

Signals listed here are the **observability contract**. `EventLogBridge` maps them to structured events (`combat.skill_cast`, `combat.enemy_hit`, etc.). Internal `CombatEvent` kinds are translated back into these signals at the controller boundary. See `docs/workflows/assisted-logging.md`.
