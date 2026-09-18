# AI-Assisted Development

Guide for agents (Cursor, Copilot, etc.) working on Stickman Idle with correct context and safe diffs.

## Entry point

1. [`AGENTS.md`](../../AGENTS.md) — stack, module boundaries, minimum playtest
2. [`docs/KNOWLEDGE_GRAPH.md`](../KNOWLEDGE_GRAPH.md) — document map
3. [`docs/architecture/overview.md`](../architecture/overview.md) — module flow
4. Area-specific doc for the task (combat, inventory, save, …)

## Before editing

| Question | Where to answer |
|----------|-----------------|
| Which domain? | `domains/*` vs `presentation/*` |
| Affects save? | [`save-format.md`](../architecture/save-format.md), bump `SAVE_VERSION`? |
| New or legacy code? | New → English, target paths |
| Touches sprites? | Only with explicit user request |

## Hard limits (do not violate)

- `sprites/` — do not bulk-regenerate or replace
- `user://` — never commit saves
- `project.godot` autoload order — only with documented reason
- Domain must not reference UI nodes
- `presentation/` must not implement gold/combat rules

## Legacy → target migration

The repo may have **both** paths during migration:

```
combate/party_manager.gd      # legacy
domains/combat/party_service.gd  # target
```

**Rule for agents:** prefer editing where code **already lives** unless the task is explicitly migration. When creating new files, use target path and English.

## Diff size

- One feature = one domain per PR when possible
- Do not mass-rename + change logic in the same commit
- Grep old `res://` paths before merge

## Effective prompts

### Good

> "Add evasion bonus from skill tree to damage received calculation. Read combat.md and party_service.gd. Do not touch UI."

> "Document save v3→v4 migration for hero_equipment. Docs only plus migrate stub in save_service."

### Avoid

> "Refactor the entire project to clean architecture"

> "Generate all skill sprites"

## Post-edit checklist (agent)

1. Do edited files belong to the correct module?
2. Is save backward-compatible or version bumped?
3. Do new strings in `presentation/` use `tr()`?
4. Is [`playtest-checklist.md`](playtest-checklist.md) applicable?
5. Docs updated if public contract changed?

## Cursor rules

`.cursor/rules/*.mdc` reinforce:

- `project-core.mdc` — required reading, boundaries
- `godot-gdscript.mdc` — GDScript style
- `*-domain.mdc` — scope per folder
- `protected-paths.mdc` — sprites, user://, project.godot
- `english-code.mdc` — English identifiers
- `idle-game-patterns.mdc` — timer/save patterns (opt-in)

## Automated tests

Phase 7 (optional): see [`testing.md`](testing.md). Until then, manual playtest is the quality gate.

## Communication

- Docs (`docs/`), `README.md`, `AGENTS.md`: **English**
- New code: **English**
- Player-facing UI: **i18n** (`tr()` + `locales/*.po`)
- Commits: only when the user asks

## Quick decision tree

```text
Combat bug?
  → combat.md → domains/combat/ + presentation/combat/
  → If progress lost: save-format.md

New UI?
  → presentation/AGENTS.md (when present)
  → i18n.md

Item not dropping?
  → item_database.gd + drop_manager.gd

Save broken?
  → save_service.gd + collect_save in main.gd
```
