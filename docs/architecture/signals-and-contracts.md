# Signals and API Contracts

Contracts between modules avoid direct coupling to scene nodes. Orchestration lives in `main.gd`; the target is **`GameState`** in `core/game_state.gd` as the central bus.

## GameState (current + target)

`GameState` exposes observable session state and delegates mutations to services.

### Implemented signals

| Signal | Payload | Emitted when |
|--------|---------|--------------|
| `gold_changed` | `new_amount: int` | Gold changed |
| `phase_changed` | `world, stage, difficulty` | World/stage/difficulty changed |
| `save_requested` | — | Persist requested (e.g. after spend) |

### Planned signals

| Signal | Payload | Emitted when |
|--------|---------|--------------|
| `combat_state_changed` | — | Wave/enemy state changed |
| `party_changed` | — | Party or stats recalculated |
| `inventory_changed` | — | Grid or equipment changed |
| `skill_tree_changed` | — | Skill tree node purchased |
| `hero_level_changed` | `slot: int, level: int` | Level-up |
| `toast_requested` | `message: String` | Player notification |

### API

```gdscript
# core/game_state.gd
func get_gold() -> int
func add_gold(amount: int) -> void
func try_spend_gold(amount: int) -> bool
func set_gold(amount: int) -> void
func sync_from_combat(combat_state: Dictionary) -> void
```

**Rule:** `presentation/` listens to `GameState`; `domains/*` must not reference UI nodes.

---

## Current signals (legacy names)

### `CombatController`

| Signal | Connected in `main` |
|--------|---------------------|
| `aviso(texto)` | `_mostrar_aviso` |
| `efeito_moedas_pedido(origem, destino, qtd)` | `_on_efeito_moedas` |
| `ouro_ganho(quantidade)` | `_on_ouro_combate` |
| `item_dropado(item)` | `_on_item_dropado` |
| `progressao_alterada` | `_on_progressao_alterada` |
| `hud_atualizar` | `_atualizar_hud` |
| `precisa_salvar` | `SaveSystem.salvar` |
| `nivel_heroi_alterado(indice, nivel)` | `_on_nivel_heroi_alterado` |

### `PartyService`

| Signal | Use |
|--------|-----|
| `equipe_alterada` | Formation UI |
| `heroi_atacou(slot, dano)` | → `CombatController.on_heroi_atacou` |
| `dps_alterado(dps, dano_grupo)` | DPS labels on HUD |

### `InventoryMenu`

| Signal | Use |
|--------|-----|
| `fechado` | Close + save |
| `personagem_alterado(indice)` | Refresh panels |
| `equipamentos_alterados` | `recalcular_atributos` |
| `classe_heroi_alterada(indice, classe)` | Sync party |
| `ouro_obtido` / `ouro_gasto` | Mutate `GameState` gold |
| `arvore_alterada` | `recalcular_atributos` |
| `fase_iniciada(mundo, fase, dificuldade)` | `CombatController.iniciar_fase` |
| `largura_menus_alterada` | Resize window |

### `HeroEquipment`

| Signal | Use |
|--------|-----|
| `equipamento_alterado(classe_id)` | Refresh skills UI |

### Sub-panels

Common pattern: `visibilidade_alterada(aberta: bool)` on ForgePanel, Warehouse, Worlds, Skills, Skill Tree, Formation, Attributes.

---

## Injected callables (implicit contracts)

### `PartyService` ← `main`

| Callable | Return | Source |
|----------|--------|--------|
| `obter_dano_equip(slot)` | `int` | `InventoryMenu.obter_dano_equipado` |
| `obter_vida_equip(slot)` | `int` | `InventoryMenu.obter_vida_equipada` |
| `obter_nivel(slot)` | `int` | `HeroProgress.get_level_at_slot` |
| `obter_bonus_arvore(slot)` | `Dictionary` | `InventoryMenu.bonus_arvore_global` (global today) |

### `CombatController` ← `main`

| Callable | Return |
|----------|--------|
| `obter_indice_personagem()` | `int` |
| `obter_destino_ouro()` | `Vector2` |
| `obter_bonus_arvore()` | `Dictionary` |

### `InventoryMenu` ← `main`

| Callable | Return |
|----------|--------|
| `consultar_ouro()` | `int` |
| `consultar_progresso_slot(slot)` | `Dictionary` |

### `WindowManager` ← `main`

| Callable | Return |
|----------|--------|
| `obter_rects_menu()` | `Array[Rect2]` |
| `menu_esta_visivel()` | `bool` |

---

## Service contracts (domain)

### PartyService

- Maximum 3 active heroes; minimum 1 to remove.
- `serializar()` / `aplicar_save()` stable for save v4.
- Pause combat via `combate_pausado`, not by stopping timers outside the class.

### CombatController

- `iniciar_fase` validates difficulty and unlocked stage before mutating state.
- Enemy death is async (`await`); `_resolvendo_*` flags prevent reentrancy.

### Inventory

- `serializar_*` / `aplicar_*` symmetric.
- Invalid equip rejected before emitting `equipamentos_alterados`.

### SaveService / SaveSystem

- `SaveSystem.registrar(jogo: Node)` before `carregar()`.
- Game must implement `collect_save()` / `apply_save()` (or legacy `coletar_save` / `aplicar_save`).

---

## Anti-patterns

| Avoid | Prefer |
|-------|--------|
| `get_node("/root/.../Label")` in domain | Signal + binding in `presentation/` |
| Mutate gold from inside `ForgePanel` | `ouro_obtido.emit()` |
| Drop logic in UI | `DropManager` + `ItemDatabase` |
| Ad-hoc save in each panel | `precisa_salvar` / `SaveSystem.salvar` central |

---

## GameState migration map

```text
main.ouro                         → GameState.gold
CombatController.precisa_salvar   → GameState.save_requested
InventoryMenu.ouro_*              → GameState.add_gold / try_spend_gold
recalcular_atributos()            → GameState.party_changed (planned)
```

When extracting more into `GameState`, keep legacy signals as temporary forwards to avoid breaking UI.
