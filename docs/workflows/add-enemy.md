# Workflow: Add an Enemy

Guide for adding idle combat enemy archetypes (minion, elite, boss).

## Architecture

- **Definition:** `EnemyData` (`data/enemy_data.gd`)
- **Visual tuning:** `EnemyVisualProfile` (`data/enemy_visual_profile.gd`)
- **Catalog:** `EnemyCatalog` (`data/enemy_catalog.gd`) — scans `data/enemies/*.tres`
- **Base stats:** `WorldProgress.enemy_stats(world, stage, difficulty)` × multipliers
- **Presentation:** `EnemyVisual.configure(profile)` + `EnemySpritesheetBuilder`

Agent shortcut: **`.cursor/skills/add-enemy/SKILL.md`** (`/add-enemy`).

## Spawn model

Each stage has **4 waves** (`stage_wave` 1–4). The catalog matches:

| Axis | Range |
|------|-------|
| `world_id` | 0 (any) or 1–5 |
| `stage_min` / `stage_max` | 1–9 |
| `wave_min` / `wave_max` | 1–4 |
| `spawn_role` | MINION, ELITE, BOSS |

On **stage 9**, the main enemy resolves as **BOSS** (demon king per dimension).

## Step by step

### 1. Define design

| Field | Decision |
|-------|----------|
| `enemy_id` | Unique slug, e.g. `forest_wisp` |
| `spawn_role` | Minion, elite companion, or boss |
| `world_id` | Target dimension or 0 |
| `stage_*` / `wave_*` | Spawn window |
| `*_mult` | Multipliers on global curve (not fixed HP) |

### 2. Create or reuse visual profile

Duplicate `data/enemy_visual_profiles/imp_red.tres` when sprites differ.

Set `base_dir` to `res://sprites/enemies/<folder>/` with subfolders:

```
idle/frame_000.png
run/frame_000.png
attack/frame_000.png
death/frame_000.png
```

### 3. Create enemy `.tres`

Place under `data/enemies/<enemy_id>.tres`. Reference the visual profile.

**Minion example** (world 1, stages 1–8, all waves):

```ini
enemy_id = "forest_wisp"
name_key = "ENEMY_forest_wisp"
spawn_role = 0
world_id = 1
stage_min = 1
stage_max = 8
wave_min = 1
wave_max = 4
```

**Boss example** (world 1, stage 9):

```ini
enemy_id = "boss_world_1"
name_key = "DIMENSION_1_DEMON_KING"
spawn_role = 2
world_id = 1
stage_min = 9
stage_max = 9
use_demon_king_name = true
```

### 4. Locales

Add to `locales/en.po` and `locales/pt_BR.po`:

```po
msgid "ENEMY_forest_wisp"
msgstr "Forest Wisp"
```

Bosses can reuse existing `DIMENSION_N_DEMON_KING` keys.

### 5. Validate

```powershell
powershell -ExecutionPolicy Bypass -File tools/run_assisted_check.ps1
```

Headless catalog tests:

```powershell
& "<godot>" --headless --path . -s res://tests/enemy_catalog_test.gd
```

## Balance notes

- Global HP/damage/gold/XP come from `WorldProgress` curves (difficulty + boss multipliers on stage 9).
- Per-enemy tuning uses `hp_mult`, `damage_mult`, `gold_mult`, `xp_mult` on `EnemyData`.
- Elite companions often set `gold_mult = 0`, `xp_mult = 0` (rewards on minion only).

## Related docs

- [`docs/architecture/combat.md`](../architecture/combat.md)
- [`docs/architecture/progression.md`](../architecture/progression.md)
- [`docs/architecture/portals-saga.md`](../architecture/portals-saga.md)
