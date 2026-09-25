# Idle Combat

Combat is **fully automatic**: three hero slots attack on independent timers; the enemy counter-attacks the rightmost living hero. There is no attack input — the player influences outcomes via party composition, equipment, skill tree, and selected stage.

**Code:** rules in `domains/combat/` (simulation + orchestration); visuals in `presentation/combat/`.

## Tick-based simulation (`domains/combat/sim/`)

Combat rules run in a **discrete tick loop** (0.25s, aligned with `PartyService` minimum attack interval). Presentation mirrors simulation state; it never applies damage.

| Class / file | Role |
|--------------|------|
| `CombatEncounter` | Serializable encounter state (party targets, horde squad, runner phase) |
| `CombatSimulator` | Tick advance, horde lane movement, swarm cadence, hero-hit resolution |
| `CombatEvent` | Domain events (`HERO_HIT_ENEMY`, `SWARM_ATTACK`, `ENEMY_WAVE_CLEARED`, …) |
| `CombatActorGroup` | Horde / queue squad with abstract lane positions |
| `DamagePipeline` | Single-pass hero/enemy damage (uses `CombatMath`) |
| `CombatActionQueue` | Per-tick action drain (enemy attacks; skills queued incrementally) |
| `CombatSession` | Wires encounter + simulator + `CombatPresentationBridge` |
| `CombatPresentationBridge` | Maps `CombatEvent` → sprites, VFX, audio (no combat rules) |

`CombatController` keeps **meta-combat** only: stage advance, gold/XP signals, save hooks. It delegates spawn, hero hits, and enemy cadence to `CombatSession`.

### Horde spawn (unified catalog)

`EnemyData.horde_count` + `horde_attack_mode` (`SWARM` | `QUEUE`) replace the legacy horde wave catalog. `EnemyCatalog.resolve_horde()` is the single spawn entry for multi-enemy waves.

### Observable events (assisted logging)

Structured logging still listens to **controller/party signals** (`hero_attacked`, `enemy_hit`, `enemy_died`, …). The simulator emits `CombatEvent` internally; the controller translates them into the existing signal contract for `EventLogBridge`.

## Core components

| Class / file | Role |
|--------------|------|
| `PartyService` | Party of up to 3 heroes, timers, DPS, HP, serialization |
| `CombatController` | Meta-combat: death/defeat, stage advance, economy signals |
| `CombatSession` | Simulation orchestration for the active encounter |
| `DropManager` | Gold variance and item drop chance |
| `Enemy` | HP, damage, rewards |
| `HeroProgress` | XP/level per class (used after death) |

## PartyService

`PartyService` is the party service. Responsibilities:

- **3 slots** (`SLOTS = 3`), each with `ClassData` or empty.
- **Per-hero timer** — interval `INTERVALO_BASE / attack_speed` (min. 0.25s).
- **Damage calculation** — class base + equipment + level + skill-tree bonuses (`ataque`, `ataque_pct`).
- **HP** — base HP + equipment + level + tree bonuses; rightmost hero is the enemy target.
- **Injected callables** (from `main`):
  - `obter_dano_equip(slot) -> int`
  - `obter_vida_equip(slot) -> int`
  - `obter_nivel(slot) -> int`
  - `obter_bonus_arvore(slot) -> Dictionary`

Default party uses English class IDs: `warrior`, `mage`, `archer`.

### Signals

| Signal | When |
|--------|------|
| `equipe_alterada` | Class swapped or removed |
| `heroi_atacou(slot, dano)` | Slot timer fired |
| `dps_alterado(dps, dano_grupo)` | Total DPS recalculated |

### Relevant API

```gdscript
func escalar_personagem(slot_index: int, nova_classe: ClassData = null) -> void
func incluir_classe(classe: ClassData) -> int
func remover_do_slot(slot_index: int) -> bool
func dano_do_heroi(slot_index: int) -> int
func aplicar_dano_no_heroi(slot_index: int, quantidade: int) -> bool
func curar_equipe() -> void
func recalcular_status() -> void
func serializar() -> Dictionary  # {"classes": [...], "desbloqueadas": [...]}
```

`combate_pausado` blocks timers during death/defeat resolution.

## Combat loop (`CombatController` + `CombatSession`)

```mermaid
sequenceDiagram
	participant PM as PartyService
	participant CC as CombatController
	participant CS as CombatSession
	participant SIM as CombatSimulator
	participant BR as CombatPresentationBridge

	PM->>CC: hero_attacked(slot, damage)
	CC->>CS: apply_hero_hit(damage)
	CS->>SIM: apply_hero_hit
	SIM-->>CS: CombatEvent[]
	CS->>BR: apply_events
	alt enemy wave cleared
		CC->>CC: _resolve_death
		Note over CC: gold, XP, drop, advance stage
	end

	loop each frame
		CC->>CS: advance_frame(delta)
		CS->>SIM: advance (ticks)
		SIM-->>BR: SWARM_ATTACK etc.
		BR->>BR: begin_attack animations
	end

	Note over CC: attack_impact signal
	CC->>PM: apply_damage_to_hero(right_target)
```

### Resolution states

- `_resolvendo_morte` — pauses combat, death animation, rewards, new enemy.
- `_resolvendo_derrota` — shows "Party defeated!" toast, full heal, same enemy recreated.

### Enemy generation

Base stats from `WorldProgress.enemy_stats(world, stage, difficulty)` (HP, damage, gold, XP, global `level` index). Stage 9 applies boss multipliers (`BOSS_HP_MULT`, `BOSS_DAMAGE_MULT`).

**Enemy catalog** (`data/enemy_catalog.gd`):

1. Scans `data/enemies/*.tres` (`EnemyData` resources).
2. `resolve(world, stage, stage_wave, role)` picks archetype by spawn scope.
3. `build_runtime()` applies per-enemy multipliers (`hp_mult`, `damage_mult`, …).
4. Stage 9 main enemy uses `SpawnRole.BOSS` (demon king per dimension).

Visuals: `EnemyVisualProfile` → `EnemySpritesheetBuilder` → `EnemyVisual.configure()`.

Workflow: [`docs/workflows/add-enemy.md`](../workflows/add-enemy.md). Agent skill: `/add-enemy`.

### Stage advance

After a kill, `_advance_stage()`:

1. Updates `unlocked_stages[difficulty]` via `WorldProgress.apply_stage_completion`.
2. If `repeat_stage == false`, advances with `WorldProgress.next_stage`.
3. Emits toasts: `COMBAT_REALM_SAVED` (boss), `COMBAT_PORTAL_UNLOCKED` (new dimension), `COMBAT_DIFFICULTY_UNLOCKED` (new trail). See [`portals-saga.md`](portals-saga.md).

## Drops (`DropManager`)

| Constant | Value | Effect |
|----------|-------|--------|
| `DROP_CHANCE` | 0.30 | 30% item after kill |
| `GOLD_VARIANCE` | 0.15 | ±15% on gold |

- **Gold** — `gold_with_variance(base)`; then skill-tree `bonus_ouro` in `CombatController`.
- **Item** — `ItemDatabase.gerar_item_aleatorio(enemy_level)`; ~22% gem chance.
- **XP** — applied to all active party classes; `bonus_xp` from skill tree.

Signal `item_dropado(item: ItemData)` → `main` adds to inventory.

## Skills in combat

`HeroEquipment` (autoload in `domains/combat/hero_equipment.gd`) stores up to 2 active + 2 passive skills per class.

| Component | Role |
|-----------|------|
| `skill_runtime.gd` | Passive stat bonuses from equipped passives |
| `active_skill_runtime.gd` | Active cooldowns and cast priority |
| `combat_resolver.gd` | Resolves `SkillResource.effects` into hits/buffs |
| `buff_container.gd` | Timed combat buffs per party slot |

On each hero timer tick, equipped actives (slot 0 → 1) are tried before a basic attack. See [`active-skills.md`](active-skills.md).

**Equipped skills persist in save v4** — cooldowns do not (MVP). See [`save-format.md`](save-format.md).

## UI integration

`CombatController` does **not** reference HUD nodes directly; it receives injected references:

- `inimigo_visual`, `barra_vida` — visual feedback
- `obter_destino_ouro` — coin effect origin
- Signals `hud_atualizar`, `efeito_moedas_pedido`, `aviso`

## Checklist when changing combat

1. Do DPS and HP recalculate with equipment + skill tree?
2. Do death/defeat leave no orphaned timers?
3. Is `precisa_salvar` emitted after relevant progress?
4. Playtest: idle attacks, enemy dies, defeat heals party.
