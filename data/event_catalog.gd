class_name EventCatalog
extends RefCounted
## Stable event name constants for structured logging (schema v1).

# System
const SYSTEM_BOOT := "system.boot"
const SYSTEM_TRACE_START := "system.trace_start"
const SYSTEM_TRACE_END := "system.trace_end"

# Engine (captured passively)
const ENGINE_ERROR := "engine.error"
const ENGINE_WARNING := "engine.warning"

# Combat
const COMBAT_HERO_ATTACK := "combat.hero_attack"
const COMBAT_SKILL_CAST := "combat.skill_cast"
const COMBAT_ENEMY_HIT := "combat.enemy_hit"
const COMBAT_ENEMY_DIED := "combat.enemy_died"

# Party
const PARTY_DPS_CHANGED := "party.dps_changed"

# Progression
const PROGRESSION_GOLD_GAINED := "progression.gold_gained"
const PROGRESSION_GOLD_SPENT := "progression.gold_spent"
const PROGRESSION_LEVEL_UP := "progression.level_up"
const PROGRESSION_STAGE_CHANGED := "progression.stage_changed"
const PROGRESSION_STAGE_STARTED := "progression.stage_started"
const PROGRESSION_SKILL_TREE_CHANGED := "progression.skill_tree_changed"

# Inventory
const INVENTORY_ITEM_DROPPED := "inventory.item_dropped"
const INVENTORY_EQUIP_CHANGED := "inventory.equip_changed"
const INVENTORY_CHARACTER_CHANGED := "inventory.character_changed"
const INVENTORY_HERO_EQUIP_CHANGED := "inventory.hero_equip_changed"

# Save
const SAVE_WRITTEN := "save.written"
const SAVE_WRITE_FAILED := "save.write_failed"
const SAVE_LOADED := "save.loaded"
const SAVE_LOAD_FAILED := "save.load_failed"
const SAVE_AUTOSAVE := "save.autosave"

# Test
const TEST_STATE_DUMP := "test.state_dump"
const TEST_SCENARIO_START := "test.scenario_start"
const TEST_SCENARIO_END := "test.scenario_end"
const TEST_ASSERTION := "test.assertion"
const TEST_SUITE_COMPLETE := "test.suite_complete"
