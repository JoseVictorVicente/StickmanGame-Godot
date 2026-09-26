# Progression

Progression covers **worlds/stages**, **per-hero level**, **global skill tree**, and derived bonuses that feed combat and economy.

**Code:** `domains/progression/world_progress.gd`, `hero_progress.gd`, `skill_tree_progress.gd`, `skill_tree_definition.gd`; UI in `presentation/worlds/worlds_panel.gd`.

## Worlds and stages (`WorldProgress`)

Player-facing **portals / dimensions** use names from `WorldCatalog` (`data/world_catalog.gd`). Narrative: [`portals-saga.md`](portals-saga.md).

| Constant | Value |
|----------|-------|
| `TOTAL_MUNDOS` | 5 |
| `FASES_POR_MUNDO` | 9 |
| `TOTAL_FASES` | 45 |
| Difficulties | Easy, Hard, Hell |

### Global index

`indice(world, stage) = (world - 1) * 9 + stage` — used as **enemy level** and curve base.

### Challenge and reward curves

- **HP** — S-curve: `HP_BASE * pow(1 + n/HP_ESCALA, HP_EXPONENTE) * difficulty_mult * world_mult * boss`.
- **Enemy damage** — scales with level and `sqrt(world_mult)`.
- **Gold/XP** — `curva_recompensa(level)` with difficulty and world multipliers.

### Unlocks

- `fases_liberadas: Array[int]` — one int per difficulty = highest **unlocked** stage (index of next playable).
- Difficulty N+1 requires full completion (`PROGRESSO_COMPLETO`) of the previous one.
- Selection UI: `presentation/worlds/worlds_panel.gd` emits `stage_started(world, stage, difficulty)` → `CombatController.start_stage`.

### Repeat stage

`repetir_fase: bool` — on enemy kill, does not advance world/stage, but still updates `fases_liberadas` to record progress.

## XP and level (`HeroProgress`)

Progress is **per class** (`ClassData.id`), not per slot. Canonical IDs: `warrior`, `mage`, `archer`, plus `barbarian`, `tank`, `priest`.

| Field | Description |
|-------|-------------|
| `nivel` | Starts at 1 |
| `xp` | XP accumulated in current level |
| `xp_proximo` | `300 * 1.43^(level-1)` |

`apply_xp(amount, active_party)` distributes XP equally to each class occupying a slot. Level-up loops until `xp < xp_proximo`.

**Serialization:** `Dictionary { "warrior": {"nivel": 5, "xp": 120}, ... }`. Old saves as `Array` are still migrated in `apply()`.

### Combat effect

- `atk_per_level` / `hp_per_level` from `ClassData` summed in `PartyService.dano_do_heroi` and `vida_maxima_do_heroi`.
- HUD shows level of the character selected in inventory.

## Skill tree (`SkillTreeDefinition` + `SkillTreeProgress`)

Account-wide tree — bonuses apply to the whole party.

### Structure

- 3 sections: Attack, Defense, Utility.
- 23 nodes per section, diamond 2-1-2 pattern across 15 rows.
- Levels per node: up to 5 (warehouse nodes: 1).

### Bonus types (`TipoBonus`)

`ataque`, `ataque_pct`, `vida`, `bonus_xp`, `bonus_ouro`, `vel_ataque`, `crit_*`, `res_*`, `armazem`.

Caps in `SkillTreeProgress._aplicar_caps_bonus` (e.g. `bonus_ouro` max 30%).

### Purchase

- Cost: `CUSTO_BASE + CUSTO_CRESCIMENTO * node_level + CUSTO_POR_NIVEL * (node_level - 1)` with premium on special nodes.
- Prerequisite: parents at level ≥ 1.
- Paid in **gold** via `SkillTreePanel` → `ouro_gasto` / `arvore_alterada` signals.

### Integration

- `SkillTreeProgress.bonus_global()` → `InventoryMenu.bonus_arvore_global()` → combat (gold, XP, stats).
- `ARMAZEM` nodes unlock extra warehouse tabs (`indices_armazem_desbloqueados`).

**Serialization:** `Dictionary { node_id: level }`.

## Attribute recalculation flow

```text
Equipment changed / Tree changed / Level up
	→ main.recalcular_atributos()
		→ party.recalcular_status()
		→ menu refreshes panels
```

Target in `domains/progression/`:

- `WorldProgress`
- `HeroProgress`
- `SkillTreeProgress`
- `StatCalculator` — aggregate equip + tree + level (today split across `PartyService` and `ItemData`)

## Save

Related fields in `collect_save()`:

- `world`, `stage`, `difficulty`, `unlocked_stages`, `repeat_stage`, `wave`
- `progress` — levels per class
- `skill_tree` — levels per node
- `hero_equipment` — equipped skills per class (v4)

See [`save-format.md`](save-format.md).
