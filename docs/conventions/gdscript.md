# GDScript Conventions

Patterns for Godot 4.7 code in Stickman Idle. Complements [`naming.md`](naming.md) and rules in `.cursor/rules/`.

## Version and style

- Godot **4.7**, typed GDScript where it improves readability.
- `class_name` on reusable services and resources (`PartyService`, `ItemData`).
- Prefer `extends RefCounted` for pure logic without a node tree.

## File structure

```gdscript
class_name MyService
extends Node
## One line: class responsibility.

signal something_changed(value: int)

const MAX_SLOTS := 3

var public_state: int = 0
var _private: Dictionary = {}


func _ready() -> void:
	pass


func public_method() -> void:
	pass


func _internal_method() -> void:
	pass
```

Suggested order: `class_name` → `extends` → `##` doc → signals → enums → const → `@export` → public vars → `_` private vars → `@onready` → lifecycle → public API → internals.

## Typing

```gdscript
# Good
func apply_damage(amount: int) -> bool:
	...

# Avoid implicit Variant in domain APIs
func get_bonus() -> Dictionary:
	return SkillTreeDefinition.bonus_vazio()
```

Use `Variant` only at save/JSON boundaries. Validate with `is Dictionary`, `is Array` before use.

## Signals vs callables

| Situation | Use |
|-----------|-----|
| 1 emitter, N unknown listeners | `signal` |
| Explicit 1:1 injection in `main` | `Callable` (`consultar_ouro`) |
| UI reacts to domain | `signal` at domain boundary |

## Nodes and responsibility

- Domain (`domains/`) **must not** use `get_node` for UI.
- `presentation/` may `@onready` reference children of its own scene.
- Autoloads (`platform/`) expose stable API; avoid screen state.

## Async

Combat pattern:

```gdscript
_resolvendo_morte = true
party.combate_pausado = true
await get_tree().create_timer(0.4).timeout
# ...
_resolvendo_morte = false
party.combate_pausado = false
```

Always guard with a boolean flag against reentrancy.

## Resources

- Static data → `@export` on `Resource` (`SkillResource`, `ItemData`).
- Duplicate before mutating drop instances: `model.duplicate()`.

## Errors and warnings

```gdscript
push_warning("Failed to save: %s" % err)  # recoverable
assert(slot_index >= 0)  # dev invariants only
```

Do not silence save or JSON parse errors.

## Performance (idle game)

- Per-hero/enemy timers — avoid heavy `_process`.
- Recalculate stats only on events (equip, skill tree, level-up).
- `DamageNumber.spawn` — lightweight objects, no per-frame mass allocation.

## Comments

- `##` at class top: what, not how.
- Inline comments only for non-obvious business rules (bonus caps, save migration).
- Do not comment self-explanatory code.

## Legacy → new migration

When adding a file under `domains/combat/`:

1. Keep `class_name` if already used globally.
2. Update `res://` paths.
3. Grep old references before merge.
