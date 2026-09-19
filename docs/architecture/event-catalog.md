# Event Catalog (schema v1)

Structured logging contract for assisted testing and AI-readable diagnostics.

## Record shape

```json
{
  "v": 1,
  "ts": 1734567890.123,
  "run_id": "a1b2c3d4",
  "trace_id": "enemy_kill-0001",
  "level": "INFO",
  "kind": "domain",
  "cat": "combat",
  "event": "combat.enemy_died",
  "data": {}
}
```

| Field | Required | Notes |
|-------|----------|-------|
| `v` | yes | Schema version (currently `1`) |
| `ts` | yes | Unix timestamp |
| `run_id` | yes | One process execution |
| `level` | yes | TRACE … FATAL |
| `kind` | yes | `debug`, `domain`, `invariant` |
| `cat` | yes | Module category |
| `event` | yes | Stable name from `EventCatalog` |
| `data` | yes | Payload; IDs only, no `tr()` strings |
| `trace_id` | no | Causal chain (attack → death → gold → save) |

## Activation

- Environment: `GAMELOG=1`
- CLI: `--game-log`
- Auto-enabled in `--headless`

## Events

### System

| Event | Level | Data |
|-------|-------|------|
| `system.boot` | INFO | `godot_version`, `headless`, `save_version`, `run_id`, `rng_seed` |
| `system.trace_start` | DEBUG | `action`, `trace_id` |
| `system.trace_end` | DEBUG | `trace_id`, `duration_ms` |
| `engine.error` | ERROR | `message` |
| `engine.warning` | WARN | `message` |

### Combat

| Event | Level | Data |
|-------|-------|------|
| `combat.hero_attack` | DEBUG/INFO | `slot`, `damage`, `is_crit` |
| `combat.skill_cast` | INFO | `slot`, `skill_id`, `hit_count` |
| `combat.enemy_hit` | DEBUG | `damage`, `hp`, `max_hp` |
| `combat.enemy_died` | INFO | `world`, `stage`, `wave` |

### Party

| Event | Level | Data | Throttle |
|-------|-------|------|----------|
| `party.dps_changed` | TRACE | `dps`, `group_damage` | 1× / 5s |

### Progression

| Event | Level | Data |
|-------|-------|------|
| `progression.gold_gained` | INFO | `amount`, `source` |
| `progression.gold_spent` | INFO | `amount`, `reason` |
| `progression.level_up` | INFO | `slot`, `level` |
| `progression.stage_changed` | INFO | `world`, `stage`, `difficulty` |
| `progression.stage_started` | INFO | `world`, `stage`, `difficulty` |
| `progression.skill_tree_changed` | INFO | (optional `node_id`) |

### Inventory

| Event | Level | Data |
|-------|-------|------|
| `inventory.item_dropped` | INFO | `item_id` |
| `inventory.equip_changed` | INFO | `slot`, `class_id` |
| `inventory.character_changed` | INFO | `index` |
| `inventory.hero_equip_changed` | INFO | `class_id` |

### Save

| Event | Level | Data |
|-------|-------|------|
| `save.written` | INFO | `version`, `gold`, `stage`, `payload_keys` |
| `save.write_failed` | WARN | `error_code` |
| `save.loaded` | INFO | `version`, `gold`, `migrated_from` |
| `save.load_failed` | WARN | `reason` |
| `save.autosave` | DEBUG | `interval` |

### Test

| Event | Level | Data |
|-------|-------|------|
| `test.state_dump` | INFO | snapshot fields + `label` |
| `test.scenario_start` | INFO | `suite`, … |
| `test.scenario_end` | INFO | `suite`, `passed`, `counters` |
| `test.assertion` | ERROR | `name`, `ok` |
| `test.suite_complete` | INFO | `suite`, `passed` |
| `invariant.*` | DEBUG/ERROR | `rule`, `ok`, … |

## Naming rules

1. Event names are defined in `data/event_catalog.gd` — never inline strings in domain code.
2. Breaking payload changes require schema version bump (`v: 2`).
3. Do not log per-frame ticks, timer ticks, or translated UI strings.

## Output

- Stdout: `[EVENT] ` + JSON per line
- File: `user://logs/{run_id}.jsonl` (last 5 files kept)
