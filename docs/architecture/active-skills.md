# Active Skills (GAS-lite)

Equipped **active** skills (`HeroEquipment`, 2 slots per class) are resolved in combat by domain code. Data describes effects; runtime interprets them; presentation only displays cues.

## Principles

| Layer | Responsibility |
|-------|----------------|
| `data/effects/` | `CombatEffectResource` subtypes (`DamageEffect`, `BuffEffect`) |
| `data/skill_resource.gd` | `effects[]`, `vfx_id`, `cooldown` |
| `domains/combat/` | `ActiveSkillRuntime`, `CombatResolver`, `BuffContainer` |
| `presentation/combat/` | `CombatCueAdapter` — maps `vfx_id` to existing VFX |

Domain code must **not** reference UI nodes. Presentation must **not** implement damage or cooldown rules.

## Combat tick rule

On each hero attack timer (`PartyService._on_hero_timer`):

1. `play_attack()` on stickman (same lunge as basic attack).
2. `ActiveSkillRuntime.try_cast(slot)` — checks equipped actives **slot 0 → slot 1**.
3. If a skill is off cooldown and has `effects` → `CombatResolver.resolve()` → emit `hero_skill_used`.
4. Otherwise → basic attack via `hero_attacked`.

## Effect types (MVP)

| `effect_type` | Resource | Behavior |
|---------------|----------|----------|
| `damage_burst` | `DamageEffect` | Single hit: `base_damage * multiplier` |
| `damage_multi` | `DamageEffect` | `hits` strikes at `multiplier` each |
| `buff_self` | `BuffEffect` | Timed stat bonus merged into `hero_stats()` |
| `heal_party` / `heal_self` / `heal_lowest` | `HealEffect` | Restores % max HP (party, caster, or lowest ally) |
| `noop` | — | No combat effect (fallback to basic attack) |

`DamageEffect` also supports `force_crit` and `armor_pen_pct` (MVP: bonus damage %, not enemy armor stat).

## Cooldowns

- Stored in memory per `skill_id` (`ready_at` timestamp).
- **Not persisted** in save (MVP).
- Reduced by 15% when passive `nimble_hands` is equipped.

## Buffs

- `BuffContainer` holds timed instances per party slot.
- Expired buffs trigger `recalculate_stats()` so attack timers pick up new `attack_speed`.
- Buffs do not pause during death resolution (acceptable for MVP).

## Signals

| Signal | Emitter | Payload |
|--------|---------|---------|
| `hero_skill_used` | `PartyService` | `slot_index`, `SkillResource`, `hits: Array`, `heals: Array` |
| `hero_attacked` | `PartyService` | `slot_index`, `damage`, `is_crit` |

Each hit: `{damage: int, is_crit: bool, delay_sec: float}`.

Each heal: `{heal_pct_max_hp: float, target_scope: String, delay_sec: float}` — applied in `CombatController`; green `+HP` via `DamageNumber.spawn_heal`.

## VFX (`vfx_id`)

| ID | Presentation |
|----|--------------|
| `arrow_single` | `ArrowProjectile.fire` from hero to enemy |
| `arrow_burst` | Multiple arrow projectiles (staggered) |
| `buff_glow` | Stickman `self_modulate` tween |

## Adding a new active skill

1. Create `data/skills/<class>/<NN>_<skill_id>.tres` (duplicate an existing active in that folder).
2. Add icon `sprites/ui/skills/<class>/<skill_id>.png`.
3. Add `SKILL_<id>` / `SKILL_<id>_DESC` to `locales/en.po` and `locales/pt_BR.po`.
4. Playtest equip + idle combat.

`HeroEquipment` auto-loads every `.tres` in the class folder — no registration step.

Workflow: [`docs/workflows/add-active-skill.md`](../workflows/add-active-skill.md). Cursor: `/add-active-skill`.

Complex mechanics (poison, marks, channeling) → Sprint 3b+ or `effect_registry` exception table.

## Archer pilot (Sprint 3)

| skill_id | MVP mapping |
|----------|-------------|
| `instant_double_shot` | 2 hits, force crit |
| `dark_volley` | 5 hits @ 40% damage |
| `precision_shot` | 1.5× burst, force crit, 30% armor pen |
| `hunter_stance` | +30% attack speed, +10% attack % for 3.5s |
| `neon_vision` | +30% crit chance for 4s |
