# AGENTS.md — Stickman Idle

**Prioritize this repository's context over generic training knowledge.**

## Vague prompts

If the request lacks **what**, **where**, or **how to validate**, the agent must use `AskQuestion` (one question at a time, max two) and restate scope before editing — see `.cursor/rules/prompt-gate.mdc`. For large or ambiguous features, use **Plan Mode** (`Shift+Tab`) before Agent mode.

## Stack

- Godot **4.7**, GDScript, **GL Compatibility** renderer
- Overlay window: borderless, transparent, always-on-top
- `SAVE_VERSION`: see `core/save_service.gd` and `docs/architecture/save-format.md`

## Required reading (order)

1. `docs/KNOWLEDGE_GRAPH.md` — document map
2. `docs/architecture/overview.md` — module flow
3. Area you will edit:
   - Combat → `docs/architecture/combat.md` + `domains/combat/AGENTS.md`
   - Inventory → `docs/architecture/inventory.md` + `domains/inventory/AGENTS.md`
   - UI → `presentation/AGENTS.md` + `/edit-ui-screens` + `docs/conventions/ui-layout.md`
   - Data → `data/AGENTS.md`
4. Save → `docs/architecture/save-format.md`
5. Conventions → `docs/conventions/naming.md`, `docs/conventions/i18n.md`

## Module boundaries

| Module | May | Must not |
|--------|-----|----------|
| `domains/combat/` | Combat rules, party, drops, skill runtime | Reference UI nodes |
| `domains/inventory/` | Inventory, equip, forge, warehouse | Draw `Control` nodes |
| `domains/progression/` | XP, worlds, skill tree, StatCalculator | Mutate gold directly |
| `presentation/` | HUD, menus, `tr()` | Economy/combat rules |
| `core/` | GameState, SaveService, wiring | Feature god-objects |
| `data/` | Resources, schemas | Nodes or autoloads |

## Language

- **Code & docs:** English (functions, signals, files, classes, markdown)
- **Player-facing UI:** `tr("KEY")` + `locales/*.po`

## Protected paths

- `sprites/` — do not bulk-regenerate or replace
- `user://` — player saves; never commit
- `project.godot` — autoload order: change only with documented reason
- `SAVE_VERSION` bump → update `docs/architecture/save-format.md` + migration

## Minimum playtest (after combat/inventory/save changes)

1. Boot with no console errors
2. Idle combat (heroes attack, enemy dies)
3. Open/close inventory
4. Equip an item
5. Spend gold on skill tree
6. Restart game — save preserved

Full checklist: `docs/workflows/playtest-checklist.md`

## Assisted logging (Cursor / CI)

Structured events for automated validation. **Read:** `docs/workflows/assisted-logging.md`

After combat, save, or `main.gd` wiring changes:

```powershell
powershell -ExecutionPolicy Bypass -File tools/run_assisted_check.ps1
```

**Rule:** do not add `GameLog` calls inside skills, resolvers, or per-function paths. Logging happens at **flow boundaries** (signals → `EventLogBridge`). New skills are logged automatically if they use the existing combat pipeline.

## Git

- No force-push to `main`
- One domain per PR when possible
- Grep legacy `res://` paths before merge
