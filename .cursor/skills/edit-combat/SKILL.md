---
name: edit-combat
description: >-
  Edits idle combat systems in Stickman Idle (runner, sim, spawn lanes, enemy
  cadence) following the CombatSession architecture. Use for /edit-combat,
  refatorar combate, runner entre waves, spawn de inimigo, fase RUNNING/ENGAGED,
  ou corrigir desync sim/visual.
---
# Edit Combat (Stickman Idle)

When the user runs **`/edit-combat`**, follow this architecture. Read first:

1. `docs/architecture/combat.md`
2. `domains/combat/AGENTS.md`
3. `.cursor/skills/edit-combat/references/combat-boundaries.md`

## Layer routing

| Change | Edit |
|--------|------|
| Spawn distance, scroll speed, runner duration | `domains/combat/sim/combat_tuning.gd` |
| Lane movement, engage, enemy attack ticks | `domains/combat/sim/combat_simulator.gd`, `combat_encounter.gd` |
| Sprite position, run anim, scroll on/off | `presentation/combat/combat_presentation_bridge.gd` |
| Gold/XP, stage advance, defeat flow | `domains/combat/combat_controller.gd` |
| Hero slot X, spawn anchor, formation march | `domains/combat/party_service.gd` (`engage_lane_slot`, `formation_slot_x`, `PartyFieldState`) |
| Per-slot attack range / archer fix | `combat_controller.gd` (`can_hero_attack_slot`), `party_service.gd` (`is_hero_in_engage_range`) |
| New enemy archetype | `/add-enemy` skill instead |
| New active skill | `/add-active-skill` skill instead |

## Rules

- **Sim owns rules** — damage via `DamagePipeline` + `CombatEvent`; never apply HP changes in `EnemyVisual`.
- **One phase source** — `CombatEncounter.Phase`; do not add parallel `RunPhase` enums in the controller.
- **Contact lane** — `engage_lane_slot()` for approach/spawn; `right_target_index()` for who receives enemy damage.
- **Constants** — add to `CombatTuning`, not duplicated magic numbers in party or visuals.
- **Logging** — no `GameLog` in sim/resolver; use existing controller/party signals for `EventLogBridge`.
- **Save** — do not bump `SAVE_VERSION` for combat-only edits.

## Validation checklist

```powershell
& "D:\Desktop\Tudo\Godot\Godot_v4.7.2-stable_win64.exe\Godot_v4.7.2-stable_win64_console.exe" --headless --path "<repo>" -s res://tests/combat_simulator_test.gd
powershell -ExecutionPolicy Bypass -File tools/run_assisted_check.ps1
```

Manual playtest:

1. Boot — no console errors
2. Wave 1 — immediate engage, heroes + minion fight
3. Kill wave 1 — regroup to formation, heroes march, BG scrolls, wave 2 spawns off-screen; scroll stops when enemy enters hero range; archer attacks; melee advances until engage
4. Horde stage 2 — swarm contact + attacks
5. Save/load unchanged

See `.cursor/skills/edit-combat/references/combat-validation.md` for full steps.
