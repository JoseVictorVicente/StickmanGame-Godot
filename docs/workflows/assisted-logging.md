# Assisted Logging

Structured JSONL events for Cursor/CI to verify game behavior without manual playtesting every change.

## Core idea (read this first)

**Developers do not add logs to each skill, damage calc, or validation step.**

Logging is attached to **flow boundaries** — Godot signals and service entry points. When combat runs through the normal pipeline, events are emitted automatically:

```
Skill .tres → CombatResolver → PartyService → signal → EventLogBridge → GameLog
```

| Do | Don't |
|----|-------|
| Emit/use existing domain signals (`hero_skill_used`, `enemy_hit`, …) | `GameLog.event()` inside `combat_resolver.gd` or skill resources |
| Add a new signal + one bridge handler for a **new flow** | `print()` / `GameLog` in every function along the path |
| Add constants to `EventCatalog` when introducing a **new event type** | Log per-frame, per-timer-tick, or translated UI strings |

**Adding a new active skill?** Create the `.tres` and effects — `combat.skill_cast` and `combat.enemy_hit` are logged with `skill_id`, `hit_count`, and damage without extra code.

## Quick start

```powershell
# Enable logging during local play
$env:GAMELOG = "1"
& "C:\Users\Aleander\Downloads\Godot_v4.7.2-stable_win64.exe" --path .

# Full assisted check (unit tests + 30s smoke)
powershell -ExecutionPolicy Bypass -File tools/run_assisted_check.ps1
```

Set `GODOT` env var if Godot is not at the default path above.

Parser output (last line, when Python is installed):

```json
{"passed": true, "events_total": 342, "errors": 0, "warnings": 0, "failures": [], "run_id": "a1b2c3d4"}
```

## Architecture

```
┌─────────────────────────────────────────────────────────┐
│  Domain (no GameLog here)                               │
│  PartyService · CombatController · SaveService          │
│       │ signals              │ save/load                │
└───────┼──────────────────────┼──────────────────────────┘
        ▼                      ▼
┌──────────────────┐   ┌──────────────────┐
│ EventLogBridge   │   │ SaveService      │
│ (main.gd wiring) │   │ (save.* events)  │
└────────┬─────────┘   └────────┬─────────┘
         │                      │
         ▼                      ▼
┌─────────────────────────────────────────┐
│ GameLog autoload                        │
│ stdout: [EVENT] {json}                  │
│ file:   user://logs/{run_id}.jsonl      │
└─────────────────────────────────────────┘
         │
         ▼
┌─────────────────────────────────────────┐
│ tools/parse_game_log.py (optional)      │
│ tools/run_assisted_check.ps1            │
└─────────────────────────────────────────┘
```

| Component | Path | Role |
|-----------|------|------|
| `GameLog` | `platform/game_log.gd` | Autoload: emit JSONL to stdout + file |
| `GodotLogCapture` | `platform/godot_log_capture.gd` | Captures `push_error` / `push_warning` |
| `EventCatalog` | `data/event_catalog.gd` | Stable event name constants |
| `EventLogBridge` | `core/event_log_bridge.gd` | **Single wiring point:** domain signals → `GameLog` |
| Parser | `tools/parse_game_log.py` | Validates invariants and sequences |

See [event-catalog.md](../architecture/event-catalog.md) for the full event list.

## What gets logged automatically

| Player action | Signal | Event |
|---------------|--------|-------|
| Basic attack | `PartyService.hero_attacked` | `combat.hero_attack` |
| Any active skill | `PartyService.hero_skill_used` | `combat.skill_cast` (`skill_id`, `hit_count`) |
| Damage applied | `CombatController.enemy_hit` | `combat.enemy_hit` |
| Enemy dies | `CombatController.enemy_died` | `combat.enemy_died` → trace ends |
| Gold / XP / drop | `CombatController` signals | `progression.*` / `inventory.*` |
| Save / load | `SaveService` | `save.written` / `save.loaded` |
| Equip / inventory | `InventoryMenu` signals | `inventory.*` |

Causal chains use `trace_id` (e.g. attack → hits → death → gold → save).

## Cursor workflow

After editing combat, save, event bridge, or main wiring:

1. Run `powershell -ExecutionPolicy Bypass -File tools/run_assisted_check.ps1`
2. Confirm `[TEST PASS]` for all three suites
3. If parser runs: check `"passed": true` in the final JSON line
4. If `engine.error` events appear, fix before merging

The Cursor rule `.cursor/rules/assisted-logging.mdc` applies when editing files under `domains/combat/`, save, or tests.

## When you need to change logging

| Situation | Action |
|-----------|--------|
| New skill using existing pipeline | **Nothing** — already logged |
| New combat signal (new flow) | Add signal in domain → handler in `event_log_bridge.gd` → constant in `event_catalog.gd` → row in `event-catalog.md` |
| New non-combat system | Same pattern: boundary signal → bridge → catalog |
| Debugging one function temporarily | Use `GAMELOG=1` and read existing events; avoid permanent logs in domain code |

## Parser usage

```powershell
# Parse a saved log file
python tools/parse_game_log.py --file "$env:APPDATA/Godot/app_userdata/Stickman Idle/logs/<run_id>.jsonl"

# Pipe from smoke test (requires --path)
godot --headless --path . -s res://tests/scenario_idle_smoke.gd 2>&1 | python tools/parse_game_log.py --stdin --expect-combat --expect-boot
```

Exit codes: `0` ok | `1` invariant failed | `2` parse error | `3` timeout / no input

## Built-in invariants

| Rule | Check |
|------|-------|
| `boot_happened` | At least one `system.boot` |
| `hp_non_negative` | `combat.enemy_hit.data.hp >= 0` |
| `gold_consistency` | `progression.gold_gained.amount >= 0` |
| `no_engine_errors` | Zero `engine.error` events |
| `combat_loop_ran` | With `--expect-combat`: attack → hit → death → gold |

## Smoke test

```powershell
godot --headless --path . -s res://tests/scenario_idle_smoke.gd
```

Runs `main.tscn` idle combat for 30s headless; expects ≥1 attack, ≥1 death, ≥1 gold event.

## Performance

Logging is **off** by default in normal play. When enabled:

- `party.dps_changed` throttled to 1× / 5s
- Max 10,000 events per run (then WARN+ only)
- Log file capped at 2 MB per run

Do not add per-frame or per-timer-tick events.

## Related docs

- [event-catalog.md](../architecture/event-catalog.md) — schema and event table
- [ai-development.md](ai-development.md) — agent entry point
- [testing.md](testing.md) — test strategy
- [add-skill.md](add-skill.md) — new skills (no logging step required)
