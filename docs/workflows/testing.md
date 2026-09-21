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

Runs [`tests/inventory_menu_layout_audit.gd`](../tests/inventory_menu_layout_audit.gd): twelve menu states with rect invariants. On failure prints one JSON line per issue (`state`, `node`, `rect`, `expected`).

Full create/edit workflow: [`ui-screens.md`](ui-screens.md). Cursor skill: `/edit-ui-screens`.

### Menu screens visual review (Cursor)

Captures **twelve** PNG screenshots (all `inventory_menu` screens) at 960×860 for AI visual review. **Requires display** — do not pass `--headless` (rendering is disabled headless). Set `GODOT` env if Godot is not on PATH.

Cursor skills: `/edit-ui-screens` then `/capture-menu-screens` scoped (`.cursor/skills/capture-menu-screens/SKILL.md`).

```powershell
powershell -ExecutionPolicy Bypass -File tools/run_edit_ui_validation.ps1 -ScopePng worlds_open
```

Output: `artifacts/inventory_layout/<state_id>.png` plus `manifest.json`.

Full review (geometry + visual + all twelve PNGs):

```powershell
powershell -ExecutionPolicy Bypass -File tools/run_edit_ui_validation.ps1
```

**Agent loop** after edits under `presentation/inventory/` or `presentation/worlds/`:

1. Run `tools/run_edit_ui_validation.ps1 -ScopePng <id>` (see PNG map in [`capture-menu-screens`](../../.cursor/skills/capture-menu-screens/SKILL.md#png-map))
2. Read scoped PNG(s) + apply checklist in capture-menu-screens skill (full mode: all twelve)
3. Fix `.tscn` first. For UTF-16 corruption only, use `tools/fix_inventory_menu_encoding.py` on a **clean** file — it runs `git restore` and drops uncommitted edits.
4. Repeat until acceptable

| PNG | Visual expectations |
|-----|---------------------|
| `hub_combat_bottom` | Hub in lower half; top ~320px clear; 5×10 grid readable; nav proportional |
| `hub_combat_top` | Hub below top combat band; no overlap into reserved zone |
| `formation_open` | Formation overlay full-bleed on hub panel |
| `skills_open` | Skills overlay full-bleed on hub panel |
| `attributes_open` | Attributes overlay full-bleed; stat rows readable |
| `skill_tree_open` | Skill tree replaces hub; map visible |
| `warehouse_open` | Warehouse side panel visible; tabs and grid readable |
| `forge_open` | Forge side panel visible; slots aligned |
| `worlds_open` | Portal hall: five cards; header + footer readable |
| `worlds_briefing_open` | Dimension briefing before trail |
| `worlds_trail_open` | Trail map + header meta; stage nodes inside panel |
| `settings_open` | Settings panel top-right; volume and locale controls |

Shared state setup: [`tests/inventory_menu_layout_states.gd`](../tests/inventory_menu_layout_states.gd).

## What not to test (initially)

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
