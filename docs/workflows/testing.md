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

## UI layout audit (available now)

```powershell
powershell -ExecutionPolicy Bypass -File tools/run_ui_layout_check.ps1
```

Catches forbidden `layout_mode = 0` in `presentation/` scenes. See [`conventions/ui-layout.md`](../conventions/ui-layout.md).

### Inventory hub geometry audit

```powershell
powershell -ExecutionPolicy Bypass -File tools/run_inventory_menu_layout_audit.ps1
```

Runs [`tests/inventory_menu_layout_audit.gd`](../tests/inventory_menu_layout_audit.gd): six menu states (hub top/bottom, formation, skills, warehouse, forge) with rect invariants. On failure prints one JSON line per issue (`state`, `node`, `rect`, `expected`).

### Inventory hub visual layout review (Cursor)

Captures six PNG screenshots at 960×860 for AI visual review. **Requires display** — do not pass `--headless` (rendering is disabled headless).

```powershell
powershell -ExecutionPolicy Bypass -File tools/run_inventory_menu_visual_capture.ps1
```

Output: `artifacts/inventory_layout/<state_id>.png` plus `manifest.json`.

Full review (geometry + visual):

```powershell
powershell -ExecutionPolicy Bypass -File tools/run_inventory_menu_layout_review.ps1
```

**Agent loop** after edits under `presentation/inventory/`:

1. Run `tools/run_inventory_menu_visual_capture.ps1`
2. Read the six PNGs in `artifacts/inventory_layout/`
3. Evaluate layout visually (checklist below)
4. Fix [`inventory_menu.tscn`](../presentation/inventory/inventory_menu.tscn), [`inventory_layout_default.tres`](../presentation/inventory/inventory_layout_default.tres), or [`inventory_menu.gd`](../presentation/inventory/inventory_menu.gd) — if `inventory_menu.gd` encoding breaks, apply patches via `tools/fix_inventory_menu_encoding.py`
5. Repeat until acceptable; optionally run `tools/run_inventory_menu_layout_audit.ps1`

| PNG | Visual expectations |
|-----|---------------------|
| `hub_combat_bottom` | Hub in lower half; top ~320px clear; 10×5 grid readable; nav proportional |
| `hub_combat_top` | Hub below top combat band; no overlap into reserved zone |
| `formation_open` | Formation overlay full-bleed on hub panel |
| `skills_open` | Skills overlay full-bleed on hub panel |
| `warehouse_open` | Warehouse panel visible; frame margins ok |
| `forge_open` | Forge panel visible; slots aligned |

Shared state setup: [`tests/inventory_menu_layout_states.gd`](../tests/inventory_menu_layout_states.gd).

## What not to test (initially)

- Visual combat timers (flaky)
- Visual combat timers (flaky)
- Procedural icon generation

## Assisted logging (available now)

Structured JSONL events for Cursor/CI validation. See [`assisted-logging.md`](assisted-logging.md).

```powershell
pwsh tools/run_assisted_check.ps1
```

Runs unit tests + 30s idle smoke test and validates invariants via `tools/parse_game_log.py`.

## Quality gate today

Until Phase 7 is active:

1. [`playtest-checklist.md`](playtest-checklist.md) manual
2. No console errors on boot
3. Save review in PRs touching persistence
4. Optional: `pwsh tools/run_assisted_check.ps1` after combat/save changes

## Adding a new test

1. Confirm logic lives in `RefCounted` / testable domain (no mandatory `get_tree`).
2. Create minimal fixture in `tests/fixtures/`.
3. Document run command here when GUT is installed.
