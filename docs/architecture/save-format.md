# Save Format

Persistence in `user://save.cfg` (`ConfigFile`). Current version **`SAVE_VERSION = 4`** (`core/save_service.gd`).

The game exposes state via `main.collect_save()` / `main.apply_save(data)`. `SaveService` maps to `ConfigFile` sections and serializes complex structures as JSON strings.

## Versions

| Version | Change |
|---------|--------|
| 0 | Invalid — progress cleared |
| 1 | Base format |
| 2 | Equipment per class (`Dictionary`) |
| 3 | Skill tree (`skill_tree` / legacy `arvore`) |
| **4** | Equipped hero skills (`hero_equipment`) + English keys + legacy PT aliases |

### Migration v3

In `SaveService.load_game()`, if `version < 3`: `payload["skill_tree"] = []` (tree reset).

### Migration v4

1. **Hero equipment** — persist `HeroEquipment.serialize()` per class ID:
   ```json
   "hero_equipment": {
	 "warrior": {
	   "actives": ["01_sequencia_frenetica", ""],
	   "passives": ["p01_mestre_das_laminas", ""]
	 }
   }
   ```
2. **English keys** — runtime dictionary uses English names (`gold`, `inventory`, `party`, …). `SaveService.normalize_keys()` maps legacy Portuguese keys on read; `_to_legacy_payload()` maps back for `aplicar_save()` callers.
3. **Class IDs** — `SaveService.migrate_domain_ids()` normalizes party, equipment, and `hero_equipment` keys via `ClassData.normalize_id()`. Legacy PT IDs (`guerreiro`, `mago`, `arqueiro`) should be migrated to `warrior`, `mage`, `archer`.
4. Bump `SAVE_VERSION` → update this doc + load test from v3 save.

## Key aliases (v4)

| English (canonical) | Legacy PT |
|-------------------|-----------|
| `gold` | `ouro` |
| `world` | `mundo` |
| `stage` | `fase` |
| `difficulty` | `dificuldade` |
| `unlocked_stages` | `fases_liberadas` |
| `repeat_stage` | `repetir_fase` |
| `wave` | `onda` |
| `active_character_index` | `personagem_atual` |
| `progress` | `progresso` |
| `inventory` | `inventario` |
| `warehouse` | `armazem` |
| `equipment` | `equipamentos` |
| `party` | `equipe` |
| `skill_tree` | `arvore` |

Defined in `SaveService._LEGACY_KEY_MAP`.

## Schema v4 — `collect_save()`

Dictionary returned by `scenes/main.gd`:

```gdscript
{
	"gold": int,
	"wave": int,                    # current enemy level index
	"world": int,                   # 1..5
	"stage": int,                   # 1..9
	"difficulty": int,              # 0=Easy, 1=Hard, 2=Hell
	"unlocked_stages": Array[int],  # [easy, hard, hell] — max unlocked index
	"repeat_stage": bool,
	"active_character_index": int,  # 0..2 in character menu
	"progress": Dictionary,         # see below
	"inventory": Array,             # 50 × ItemData dict or {}
	"warehouse": Dictionary,        # see below
	"equipment": Dictionary,        # per class_id
	"party": Dictionary,            # party
	"skill_tree": Dictionary,       # node_id → level
	"hero_equipment": Dictionary,   # per class_id, v4+
}
```

## ConfigFile ↔ runtime mapping (v4)

| Section | Key | Source | Type |
|---------|-----|--------|------|
| `game` | `version` | constant | int |
| `game` | `gold` | `gold` | int |
| `game` | `wave` | `_luta.onda` | int |
| `game` | `world` | `_luta.mundo` | int |
| `game` | `stage` | `_luta.fase` | int |
| `game` | `difficulty` | `_luta.dificuldade` | int |
| `game` | `unlocked_stages` | JSON array | string |
| `game` | `repeat_stage` | bool | bool |
| `game` | `active_character_index` | int | int |
| `progress` | `heroes` | JSON | string |
| `inventory` | `items` | JSON array | string |
| `inventory` | `warehouse` | JSON object | string |
| `equipment` | `data` | JSON object | string |
| `party` | `data` | JSON object | string |
| `skill_tree` | `data` | JSON object | string |
| `hero_equipment` | `data` | JSON object | string |

### Legacy v3 sections (still readable)

| Legacy section | Legacy key | Maps to |
|----------------|------------|---------|
| `jogo` | `versao` | `game.version` |
| `jogo` | `ouro` | `game.gold` |
| `progresso` | `personagens` | `progress.heroes` |
| `inventario` | `itens` | `inventory.items` |
| `equipamentos` | `dados` | `equipment.data` |
| `equipe` | `dados` | `party.data` |
| `arvore` | `dados` | `skill_tree.data` |

## Sub-schemas

### `progress` (heroes)

```json
{
  "warrior": {"nivel": 3, "xp": 45},
  "mage": {"nivel": 1, "xp": 0}
}
```

Legacy: `Array` aligned with `party.classes` — still accepted in `HeroProgress.apply()`.

### `inventory`

Array of 50 elements. Empty item = `{}`. Filled item = `ItemData.para_dicionario()`:

```json
{
  "id": "espada_123",
  "nome": "Espada",
  "tipo": 2,
  "raridade": 0,
  "nivel_item": 10,
  "dano_bonus": 5,
  "vida_bonus": 0,
  "classe_requerida": 1,
  "atributo_gema": 0,
  "valor_gema": 0.0,
  "gema_imbuida": {}
}
```

### `warehouse`

```json
{
  "desbloqueadas": [true, false, false],
  "abas": [[{}, {"id": "..."}], [], []]
}
```

### `equipment`

```json
{
  "warrior": [
	{"tipo": 2, "item": {}},
	{"tipo": 3, "item": {"id": "...", ...}}
  ]
}
```

`tipo` = `ItemData.Tipo` enum as int.

### `party`

```json
{
  "classes": ["warrior", "mage", "archer"],
  "desbloqueadas": ["warrior", "mage", "archer", "assassin", ...]
}
```

Empty slot = `""`.

### `skill_tree`

```json
{
  "0": 2,
  "5": 1,
  "42": 3
}
```

Keys = node `id` from `SkillTreeDefinition.catalogo()`.

### `hero_equipment` (v4)

```json
{
  "warrior": {
	"actives": ["01_sequencia_frenetica", "02_corte_rapido"],
	"passives": ["p01_mestre_das_laminas", ""]
  }
}
```

Empty slot = `""`. Skill IDs match `SkillResource.skill_id` filenames under `data/skills/<class>/`.

## Autosave and triggers

| Event | Action |
|-------|--------|
| 30s timer | `SaveSystem.salvar()` |
| Close inventory | `SaveSystem.salvar()` |
| `precisa_salvar` (combat) | `SaveSystem.salvar()` |
| `WM_CLOSE_REQUEST` | save + quit |

## Rules for changing save

1. Never commit files from `user://`.
2. Version bump → migration function + update this document.
3. New fields must have defaults in `apply_save` / `load_game`.
4. Test: existing v3 save loads without loss; new save writes v4 with English sections.

## Implementation (`core/save_service.gd`)

`SaveService` provides:

- `SAVE_VERSION` constant (currently `4`)
- `normalize_keys()` — PT→EN on read/write boundary
- `migrate_domain_ids()` — class ID normalization
- Legacy section detection (`jogo` vs `game`) in `_build_payload_from_config()`
- `GameState` as growing source of economy/phase serialization (via `main.collect_save()`)
