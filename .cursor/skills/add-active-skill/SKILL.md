---
name: add-active-skill
description: >-
  Adds or updates an active combat skill in Stickman Idle (.tres, locales, icon)
  following GAS-lite architecture. Use for /add-active-skill, skill ativa,
  habilidade ativa, nova skill do mago/arqueiro/guerreiro, ou adicionar
  habilidade de combate.
---
# Add Active Skill (Stickman Idle)

When the user runs **`/add-active-skill`**, implement the skill **directly in the repo** following this architecture. Do **not** use `tools/generate_skills.py`, `tools/generate_skills.ps1`, or `tools/skill_catalog_data.py` unless the user explicitly asks for a bulk regen of all 91 skills.

## Architecture (do not reinvent)

```text
data/skills/<class>/XX_<skill_id>.tres   ← you create/edit this
        ↓ auto-discovered by HeroEquipment (scans folder)
ActiveSkillRuntime → CombatResolver → hero_skill_used
        ↓
CombatCueAdapter (vfx_id)
```

Read: [`docs/architecture/active-skills.md`](docs/architecture/active-skills.md).

**Never** create per-class `*_skills.gd`. **Never** put combat rules in `stickman.gd` or UI.

## What to create (checklist)

For each new active skill, create or update **all** of:

| # | File | Action |
|---|------|--------|
| 1 | `data/skills/<class>/<NN>_<skill_id>.tres` | Skill resource with `effects[]` |
| 2 | `sprites/ui/skills/<class>/<skill_id>.png` | 64×64 icon (or note if placeholder needed) |
| 3 | `locales/en.po` | `SKILL_<id>` + `SKILL_<id>_DESC` |
| 4 | `locales/pt_BR.po` | Same keys, Portuguese text |

`NN` = next `sort_order` (see existing files in class folder). `skill_id` = English slug (`snake_case`).

`HeroEquipment` loads every `.tres` under `res://data/skills/<class>/` — **no catalog registration step**.

## Pick a template (duplicate closest match)

| Pattern | Copy from |
|---------|-----------|
| Multi-hit damage | `data/skills/archer/01_instant_double_shot.tres` |
| Single burst + armor pen | `data/skills/archer/03_precision_shot.tres` |
| Multiple buffs | `data/skills/archer/04_hunter_stance.tres` |
| Party heal | `data/skills/mage/06_arcane_heal.tres` |
| No combat yet (placeholder) | Copy any active, set `effects = []`, `vfx_id = ""` |

## `.tres` field reference

```ini
skill_id = "<slug>"                    # unique, English snake_case
name_key = "SKILL_<slug>"
description_key = "SKILL_<slug>_DESC"
type = 0                               # ACTIVE
cooldown = <seconds>
icon_path = "res://sprites/ui/skills/<class>/<slug>.png"
sort_order = <int>                     # matches file prefix NN
vfx_id = "<vfx_id>"                    # see table below
effects = [SubResource("Effect_0"), ...]
```

Optional: `icon_inner_only = true` when the PNG is art-only (frame composed in UI).

### Effect scripts (`ext_resource`)

| effect_type | Script path |
|-------------|-------------|
| `damage_burst`, `damage_multi` | `res://data/effects/damage_effect.gd` |
| `buff_self` | `res://data/effects/buff_effect.gd` |
| `heal_party`, `heal_self`, `heal_lowest` | `res://data/effects/heal_effect.gd` |

Update `load_steps`: `2 + (effects.Count * 2)` — e.g. 1 effect → `load_steps=4`, 2 effects → `load_steps=6`.

### DamageEffect sub_resource

```ini
effect_type = "damage_multi"   # or damage_burst
multiplier = 1.0
hits = 2
force_crit = false             # true / false
armor_pen_pct = 0.0
```

### BuffEffect sub_resource

```ini
effect_type = "buff_self"
stat_key = "attack_speed"      # keys from SkillTreeDefinition.empty_bonus()
stat_value = 30.0
duration_sec = 3.5
```

Valid `stat_key`: `attack`, `attack_pct`, `hp`, `hp_pct`, `attack_speed`, `crit_chance`, `crit_damage`, `evasion`, `phys_res`, `arcane_res`, `elemental_res`, `xp_bonus`, `gold_bonus`.

### HealEffect sub_resource

```ini
effect_type = "heal_party"     # or heal_self / heal_lowest
heal_pct_max_hp = 20.0
target_scope = "party"         # party | self | lowest_hp
```

### VFX ids

| vfx_id | Use |
|--------|-----|
| `arrow_single` | One projectile |
| `arrow_burst` | Multiple projectiles |
| `buff_glow` | Buff or heal flash on caster |
| `""` | No VFX cue |

New vfx → add case in `presentation/combat/combat_cue_adapter.gd` first.

## Locales

Append to **both** `locales/en.po` and `locales/pt_BR.po` (keep alphabetical or class grouping consistent with neighbors):

```po
msgid "SKILL_<skill_id>"
msgstr "<English name>"

msgid "SKILL_<skill_id>_DESC"
msgstr "<English description>"
```

Portuguese file: same `msgid`, Portuguese `msgstr`.

## Decision tree

| User wants | You do |
|------------|--------|
| Damage / buff / heal with existing types | **Data only** — `.tres` + locales + icon |
| Poison, mark, shield, channel | Extend `data/effects/*.gd` + `combat_resolver.gd` + test first |
| New VFX | `combat_cue_adapter.gd` + `vfx_id` in `.tres` |
| Passive stat only | Use `type = 1`, `stat_bonus_key` / `stat_value` — see `p01_*.tres` |

## Playtest

1. Boot game — no console errors.
2. Equip skill on the **correct class** (max 2 actives; slot 0 fires before slot 1).
3. Idle combat — skill casts off cooldown when `effects` is non-empty.
4. Heals: heroes must be **below max HP** to show green `+HP` numbers.
5. Empty `effects` → falls back to basic attack (cooldown still ticks).

## Tests

If you changed `combat_resolver.gd` or effect types:

```powershell
& "<godot-console>" --headless --path . -s res://tests/combat_resolver_test.gd
```

## Classes

`archer`, `assassin`, `priest`, `warrior`, `mage`, `tank` — folder under `data/skills/<class>/`.

## Common mistakes

| Mistake | Fix |
|---------|-----|
| Skill not in UI | Wrong folder or filename not `*.tres` |
| Pink icon | Missing PNG at `icon_path` |
| Skill does nothing | `effects = []` — add effect sub_resources |
| Heal shows nothing | Party at full HP |
| Wrong `load_steps` | Recount ext_resource + sub_resource entries |
| Used generate scripts | Not needed — edit `.tres` directly |

## Optional (out of scope for /add-active-skill)

`tools/skill_catalog_data.py` and `tools/generate_skills.py` exist only for **bulk** regeneration of all skills. Do not use for a single new skill.
