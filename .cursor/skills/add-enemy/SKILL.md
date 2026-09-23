---
name: add-enemy
description: >-
  Adds or updates an idle combat enemy in Stickman Idle (.tres, visual profile,
  sprites, locales) following the EnemyCatalog architecture. Use for /add-enemy,
  novo inimigo, arquétipo de combate, boss de dimensão, ou elite por wave.
---
# Add Enemy (Stickman Idle)

When the user runs **`/add-enemy`**, implement the enemy **directly in the repo** following this architecture. Do **not** bulk-regenerate sprites unless the user explicitly asks.

## Architecture (do not reinvent)

```text
data/enemies/<enemy_id>.tres          ← spawn scope + stat multipliers
data/enemy_visual_profiles/*.tres     ← sprite paths + movement/attack tuning
        ↓ auto-discovered by EnemyCatalog
WorldProgress.enemy_stats × multipliers → Enemy runtime instance
        ↓
EnemyVisual.configure(profile) + CombatController.spawn_enemy
```

Read: [`docs/architecture/combat.md`](docs/architecture/combat.md), [`docs/workflows/add-enemy.md`](docs/workflows/add-enemy.md).

**Never** hardcode HP/gold in `CombatController`. **Never** add combat rules in `EnemyVisual`.

## What to create (checklist)

For each new enemy archetype, create or update **all** of:

| # | File | Action |
|---|------|--------|
| 1 | `data/enemy_visual_profiles/<profile_id>.tres` | Visual tuning (duplicate `imp_red.tres` if new sprites) |
| 2 | `sprites/enemies/<folder>/{idle,run,attack,death}/frame_NNN.png` | Sprite frames (`frame_000.png`…) |
| 3 | `data/enemies/<enemy_id>.tres` | Spawn scope + multipliers + profile ref |
| 4 | `locales/en.po` + `locales/pt_BR.po` | `ENEMY_<enemy_id>` (bosses may reuse `DIMENSION_N_DEMON_KING`) |

`EnemyCatalog` loads every `.tres` under `res://data/enemies/` — **no catalog registration step**.

## Spawn coordinates

Combat resolves enemies by **(world, stage, stage_wave, role)**:

| Field | Meaning |
|-------|---------|
| `world_id` | `0` = any dimension; `1..5` = specific portal |
| `stage_min` / `stage_max` | Stage range within dimension (1–9) |
| `wave_min` / `wave_max` | Wave within stage (1–4) |
| `spawn_role` | `MINION` (0), `ELITE` (1), `BOSS` (2) |

Stage 9 main enemy uses **`BOSS`** role (auto-mapped from minion on boss stages).

## Pick a template (duplicate closest match)

| Pattern | Copy from |
|---------|-----------|
| Default minion | `data/enemies/imp_red.tres` + `data/enemy_visual_profiles/imp_red.tres` |
| Elite companion (wave 4) | `data/enemies/dark_elite.tres` + `dark_elite.tres` profile |
| Dimension boss (stage 9) | `data/enemies/boss_world_1.tres` |

## `.tres` field reference (`EnemyData`)

```ini
enemy_id = "<slug>"                    # unique English snake_case
name_key = "ENEMY_<slug>"              # or DIMENSION_N_DEMON_KING for bosses
visual_profile = ExtResource("...")    # EnemyVisualProfile
hp_mult = 1.0
damage_mult = 1.0
gold_mult = 1.0
xp_mult = 1.0
attack_interval = -1.0                 # -1 = use profile default
spawn_role = 0                         # 0 MINION, 1 ELITE, 2 BOSS
world_id = 0                           # 0 any, 1..5 dimension
stage_min = 1
stage_max = 8
wave_min = 1
wave_max = 4
sort_order = 0                         # higher wins on overlapping spawns
use_demon_king_name = false            # true for dimension bosses
```

### Visual profile (`EnemyVisualProfile`)

Key fields: `base_dir`, `scale`, `spawn_offset`, `attack_interval`, `attack_impact_frames`, `escort_spawn_offset` (elite escort), `idle_frame_indices` (empty = all idle frames).

## Decision tree

| User wants | You do |
|------------|--------|
| New look + stats on global curve | Profile + enemy `.tres` + sprites + locales |
| Elite on wave 4 | `spawn_role=ELITE`, `wave_min=wave_max=4`, escort offsets in profile |
| Boss on stage 9 | `spawn_role=BOSS`, `stage_min=stage_max=9`, `world_id` fixed, `use_demon_king_name=true` |
| Poison, shields, new AI | Out of scope — extend domain + tests first |

## Playtest

1. Boot game — no console errors.
2. Start the target dimension/stage — correct enemy visual and translated name.
3. Wave 4 (non-boss stage) — elite companion if configured.
4. Stage 9 — demon king name from saga locales.
5. Death/defeat/run phase unchanged.
6. Run assisted check:

```powershell
powershell -ExecutionPolicy Bypass -File tools/run_assisted_check.ps1
```

## Tests

After changing `enemy_catalog.gd` or spawn rules:

```powershell
& "<godot-console>" --headless --path . -s res://tests/enemy_catalog_test.gd
```

## Common mistakes

| Mistake | Fix |
|---------|-----|
| Wrong enemy spawns | `world_id` / `stage_*` / `wave_*` do not cover current spawn |
| Pink sprite | Wrong `base_dir` in profile or missing PNG frames |
| Broken animation | Missing `idle/run/attack/death` subfolders |
| Stats feel wrong | Tune `*_mult` on `EnemyData`, not fixed HP in code |
| Elite missing | `spawn_role=ELITE`, wave 4, non-boss stage |
| Overlapping entries | Raise `sort_order` on the more specific `.tres` |

## Out of scope for /add-enemy

- Bulk sprite regen (`tools/regen/*`)
- New combat effects on enemies (poison, shield)
- Save format changes (stage/wave already persist)
