# Workflow: Add a Skill

Guide for adding a new active or passive skill for a hero class.

## Prerequisites

- Target class exists in `ClassData.catalog()` (e.g. `warrior`, `mage`, `archer`).
- PNG icon in `sprites/ui/skills/<class>/`.
- Read: [`docs/conventions/scenes-and-resources.md`](../conventions/scenes-and-resources.md).

## Step by step

### 1. Define design

| Field | Decision |
|-------|----------|
| `skill_id` | Unique slug, e.g. `06_new_ability` |
| `type` | `ACTIVE` (0) or `PASSIVE` (1) |
| `cooldown` | Seconds; 0 if passive |
| `sort_order` | Order in skills panel |
| `stat_value` | Numeric bonus if passive applies a stat |

### 2. Create icon

```
sprites/ui/skills/<class>/<skill_id>.png
```

Match existing skill size (~64×64). Godot imports automatically.

### 3. Create `.tres` resource

**Recommended** — duplicate an existing skill in `data/skills/<class>/` and edit fields (see [`add-active-skill.md`](add-active-skill.md)).

Example content:

```ini
[resource]
skill_id = "06_new_ability"
skill_name = "New Ability"
description = "Tooltip description."
type = 0
cooldown = 8.0
icon_path = "res://sprites/ui/skills/warrior/06_new_ability.png"
sort_order = 6
```

### 4. Register in catalog

`HeroEquipment` loads automatically from `SKILLS_FOLDER = res://data/skills/` on first access (`_ensure_catalog`). Verify the class folder path is correct.

### 5. Combat runtime (if active)

Active skills use the GAS-lite pipeline — see [`docs/architecture/active-skills.md`](../architecture/active-skills.md) and [`add-active-skill.md`](add-active-skill.md).

1. Add `effects[]` and `vfx_id` directly in the `.tres` (see `archer/01_instant_double_shot.tres`, `mage/06_arcane_heal.tres`).
2. `PartyService` + `CombatResolver` handle cooldown, damage, heals, and buffs automatically.

Passives that only alter stats integrate via `stat_bonus_key` + `stat_value` + `StatCalculator`.

### 6. UI

`SkillsPanel` and slots in `InventoryMenu` read from `HeroEquipment`:

- `equip_skill(class_id, resource, slot_index)`
- Tooltip via `SkillResource.texto_tooltip()` (migrate to i18n later).

### 7. Save (v4)

Equipped skills persist in save v4:

- Serialized as `skill_id` per slot in `hero_equipment`.
- Loaded with `HeroEquipment.deserialize()` after `apply_save()`.

### 8. Playtest

1. Open Skills panel in inventory.
2. Equip in active/passive slot.
3. Verify icon and tooltip.
4. If active: trigger in combat and observe cooldown.
5. Restart game — loadout should persist (v4 save).

## Per-class limits

| Type | Maximum |
|------|---------|
| Active | 2 (`HeroEquipment.MAX_ACTIVE`) |
| Passive | 2 (`HeroEquipment.MAX_PASSIVE`) |

## Naming

- File: `06_name_slug.tres`
- Premium passives: prefix `p01_`, `p02_`, …
- `skill_id` == filename without extension

## Common errors

| Problem | Fix |
|---------|-----|
| Skill not listed | Path outside `data/skills/<class>/` |
| Pink icon | Wrong `icon_path` or missing PNG |
| Cannot equip | Slots full; call `unequip_skill` first |
| Cooldown ignored | Missing `ACTIVE_EFFECTS` entry or empty `effects[]` in `.tres` |
| Need logging for new skill | **No extra step** — `hero_skill_used` → `combat.skill_cast` is automatic. See [assisted-logging.md](assisted-logging.md) |
