# Testing (Phase 7 — Optional)

Automated testing strategy planned after the architectural migration stabilizes. **Not a prerequisite for current contributions** — manual playtest remains mandatory.

## Goals

| Layer | What to test |
|-------|--------------|
| Pure domain | `WorldProgress` curves, XP, skill tree bonuses, serialization |
| Integration | Save round-trip v4, migrations |
| UI | Manual smoke (no extensive GUT initially) |

## Recommended tool

**GUT** (Godot Unit Test) — addon for Godot 4.x.

```
addons/gut/
tests/
├── unit/
│   ├── test_world_progress.gd
│   ├── test_hero_progress.gd
│   └── test_skill_tree.gd
└── integration/
    ├── test_save_v4_roundtrip.gd
    └── test_save_migration_v3_to_v4.gd
```

## Coverage priority

### P0 — before/alongside save v4

1. `WorldProgress.stats_inimigo` — monotonic values by level
2. `HeroProgress.apply_xp` — multiple level-ups
3. `SkillTreeProgress.bonus_global` — bonus caps
4. `ItemData.para_dicionario` / `de_dicionario` — round-trip
5. Save v3 load → v4 save without loss

### P1 — post `domains/` migration

1. `PartyService.dano_do_heroi` with mocked callables
2. `DropManager` — gold distribution (fixed seed)
3. Migration v3→v4 `hero_equipment`

### P2 — nice to have

1. DPS snapshot with equipment fixtures
2. Regression tests for `indice(world, stage)`

## Test pattern (GUT)

```gdscript
extends GutTest

func test_xp_level_up():
    var progress := HeroProgress.new()
    var party := [ClassData.get_by_id("warrior"), null, null]
    var levels := progress.apply_xp(10000, party)
    assert_gt(progress.get_level_at_slot(0, party), 1)
```

## CI (future)

```yaml
# .github/workflows/godot-test.yml (sketch)
- name: Run GUT
  run: godot --headless -s addons/gut/gut_cmdln.gd -gdir=res://tests -gexit
```

Requires Godot on the runner or a container with GL Compatibility.

## What not to test (initially)

- Rendering, window transparency
- Visual combat timers (flaky)
- Procedural icon generation

## Quality gate today

Until Phase 7 is active:

1. [`playtest-checklist.md`](playtest-checklist.md) manual
2. No console errors on boot
3. Save review in PRs touching persistence

## Adding a new test

1. Confirm logic lives in `RefCounted` / testable domain (no mandatory `get_tree`).
2. Create minimal fixture in `tests/fixtures/`.
3. Document run command here when GUT is installed.
