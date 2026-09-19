# Active Skills (GAS-lite)

Equipped **active** skills (`HeroEquipment`, 2 slots per class) are resolved in combat by domain code. Data describes effects; runtime interprets them; presentation only displays cues.

## Principles

| Layer | Responsibility |
|-------|----------------|
| `data/effects/` | `CombatEffectResource` subtypes (`DamageEffect`, `BuffEffect`, `HealEffect`) |
| `data/skill_resource.gd` | `effects[]`, `vfx_id`, `cooldown` |
| `domains/combat/` | `ActiveSkillRuntime`, `CombatResolver`, `BuffContainer` |
| `presentation/combat/` | `CombatCueAdapter` — maps `vfx_id` to existing VFX |

Domain code must **not** reference UI nodes. Presentation must **not** implement damage or cooldown rules.

## Combat tick rule

On each hero attack timer (`PartyService._on_hero_timer`):

1. `play_attack()` on stickman (same lunge as basic attack).
2. `ActiveSkillRuntime.try_cast(slot, class_id, cdr_pct)` — checks equipped actives **slot 0 → slot 1**.
3. If a skill is off cooldown and has `effects` → `CombatResolver.resolve()` → emit `hero_skill_used`.
4. Otherwise → basic attack via `hero_attacked`.

## Effect types (MVP)

| `effect_type` | Resource | Behavior |
|---------------|----------|----------|
| `damage_burst` | `DamageEffect` | Single hit: `base_damage * multiplier` |
| `damage_multi` | `DamageEffect` | `hits` strikes at `multiplier` each |
| `buff_self` | `BuffEffect` | Timed stat bonus; `target_scope`: `self` or `party` |
| `heal_party` / `heal_self` / `heal_lowest` | `HealEffect` | Restores % max HP (party, caster, or lowest ally) |
| `noop` | — | No combat effect (fallback to basic attack) |

`DamageEffect` also supports `force_crit` and `armor_pen_pct` (MVP: bonus damage %, not enemy armor stat).

Valid buff/heal stats: `attack`, `attack_pct`, `hp`, `hp_pct`, `attack_speed`, `crit_chance`, `crit_damage`, `evasion`, `phys_res`, `arcane_res`, `elemental_res`, `cooldown_reduction`.

## Cooldowns

- Stored in memory per `skill_id` (`ready_at` timestamp).
- **Not persisted** in save (MVP).
- Reduced by `cooldown_reduction` stat from passives and combat buffs (`ActiveSkillRuntime.cooldown_multiplier_from_pct`).
- On-kill passives: `adrenaline` (−1s all CDs), `adrenaline_surge` (−0.5s).
- Stacking CDR buff: passive `rune_resonance` adds +5% CDR for 3s per active cast (max 4 stacks).

## Buffs

- `BuffContainer` holds timed instances per party slot.
- `target_scope = "party"` applies the same buff to all living heroes.
- Expired buffs trigger `recalculate_stats()` so attack timers pick up new `attack_speed`.
- Buffs do not pause during death resolution (acceptable for MVP).

## Damage mitigation

- `CombatMath.mitigate_damage` uses `max(phys_res, arcane_res, elemental_res)` for incoming enemy damage.
- Combat buffs overlay `arcane_res` / `elemental_res` via `PartyService._apply_buff_overlay`.

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

## Coverage

All **31 active skills** (5 per class + mage `arcane_heal`) have non-empty `effects[]`. Passives use `stat_bonus_key` / `stat_value`; special hooks for CDR and on-kill reset.

## Adding a new active skill

1. Create `data/skills/<class>/<NN>_<skill_id>.tres` (duplicate an existing active in that folder).
2. Add icon `sprites/ui/skills/<class>/<skill_id>.png`.
3. Add `SKILL_<canonical_id>` / `SKILL_<canonical_id>_DESC` to `locales/en.po` and `locales/pt_BR.po` (use English canonical id from `IdMigration.SKILL_IDS` for locale keys).
4. Playtest equip + idle combat.

`HeroEquipment` auto-loads every `.tres` in the class folder — no registration step.

Workflow: [`docs/workflows/add-active-skill.md`](../workflows/add-active-skill.md). Cursor: `/add-active-skill`.

Complex mechanics (poison, marks, channeling, taunt, shield absorb) → Sprint 3b+ or `effect_registry` exception table.

## Reference mappings

| Class | Active skills | Pattern |
|-------|---------------|---------|
| Archer | 5/5 | damage multi/burst + buffs (pilot) |
| Warrior | 5/5 | multi-hit slashes + `war_cry` attack_pct buff |
| Assassin | 5/5 | twin hits + `awakened_sequence` attack_speed |
| Priest | 5/5 | heal lowest/party + divine burst + party damage buff |
| Tank | 5/5 | phys_res / hp_pct buffs + sustain + mace damage |
| Mage | 6/6 | burst/multi spells + `arcane_heal` party heal |
