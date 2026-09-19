# Workflow: Add Active Skill (Combat)

Add one active skill by creating a **Godot resource** in the class folder. No build scripts required.

## Pipeline

```text
data/skills/<class>/XX_<skill_id>.tres
sprites/ui/skills/<class>/<skill_id>.png
locales/en.po + locales/pt_BR.po
        ↓ (auto)
HeroEquipment catalog scan → equip in UI → ActiveSkillRuntime → CombatResolver
```

Architecture: [`docs/architecture/active-skills.md`](../architecture/active-skills.md).

## Checklist

1. **Design** — `skill_id` (slug), cooldown, effects, `vfx_id`.
2. **Duplicate** the closest existing `.tres` in `data/skills/<class>/`.
3. **Edit** fields: `skill_id`, `cooldown`, `sort_order`, `effects`, `vfx_id`, `icon_path`.
4. **Icon** — `sprites/ui/skills/<class>/<skill_id>.png` (64×64).
5. **Locales** — add `SKILL_<id>` and `SKILL_<id>_DESC` to `en.po` and `pt_BR.po`.
6. **Playtest** — equip on correct class, idle combat.

## Templates in repo

| Pattern | File |
|---------|------|
| Multi-hit | `archer/01_instant_double_shot.tres` |
| Multi-buff | `archer/04_hunter_stance.tres` |
| Heal party | `mage/06_arcane_heal.tres` |

## Effect types (MVP)

| Type | Resource |
|------|----------|
| `damage_burst` / `damage_multi` | `damage_effect.gd` |
| `buff_self` | `buff_effect.gd` |
| `heal_party` / `heal_self` / `heal_lowest` | `heal_effect.gd` |

New mechanics (poison, mark, shield) → extend `data/effects/` + `combat_resolver.gd` first.

## Playtest notes

- Max **2** equipped actives; slot **0** has priority.
- Heal shows `+HP` only when below max HP.
- `effects = []` → basic attack fallback.

## Cursor

Use `/add-active-skill` — skill file: `.cursor/skills/add-active-skill/SKILL.md`.

## Bulk tools (optional, not for single skills)

`tools/skill_catalog_data.py` + `tools/generate_skills.py` regenerate **all** skills from a central catalog. Use only for mass updates, not day-to-day authoring.
