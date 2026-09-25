# Combat module boundaries

## Must not

| Layer | Forbidden |
|-------|-----------|
| `sim/` | `Control` nodes, `global_position`, gold/XP mutations |
| `CombatPresentationBridge` | `take_damage` on `Enemy`, economy, save |
| `CombatController` | Per-frame enemy movement, duplicate runner state |
| `EnemyVisual` | Damage rules, spawn catalog lookups |

## May

| Layer | Allowed |
|-------|---------|
| `PartyService` | Stickman sprites, timer windups, `can_attack_target` gate |
| `CombatController` | Death/defeat coroutines, `enemy_attack_context` callable for sim |
| `CombatPresentationBridge` | Apply hero damage from `ENEMY_HIT_HERO` payload (presentation boundary) |

## Wiring (`scenes/main.gd`)

- `attack_impact` → `CombatController.on_attack_impact` (VFX timing; solo minion damage from sim)
- `party.hero_attacked` → controller applies hero hit to session
