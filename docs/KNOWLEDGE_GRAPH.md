# Knowledge Graph — Stickman Idle

## Tiers

| Tier | Documents | Use |
|------|-----------|-----|
| **1 — Source of truth** | `AGENTS.md`, `docs/architecture/*`, `docs/architecture/save-format.md` | If contradicted, code should align after review |
| **2 — Implementation** | `docs/workflows/*`, `docs/conventions/*` | How to do common tasks |
| **3 — Reference** | `##` comments in `.gd` files | Local detail; link, do not duplicate |

## Conceptual clusters

### Idle combat
- `docs/architecture/combat.md`
- `docs/architecture/overview.md` (flow)
- `domains/combat/`
- `presentation/combat/`

### Progression
- `docs/architecture/progression.md`
- `docs/architecture/portals-saga.md` (narrative + WorldsPanel flow)
- `domains/progression/`
- `data/world_catalog.gd`, `WorldProgress`

### Inventory & meta
- `docs/architecture/inventory.md`
- `domains/inventory/`
- `presentation/inventory/`

### Persistence
- `docs/architecture/save-format.md`
- `core/save_service.gd`
- `core/game_state.gd`

### Desktop overlay
- `docs/architecture/overlay-desktop.md`
- `presentation/shared/window_manager.gd`

### i18n
- `docs/conventions/i18n.md`
- `locales/pt_BR.po`, `locales/en.po`

### UI layout
- `docs/conventions/ui-layout.md` — container patterns, overlay hub, allowed absolute layout
- `docs/workflows/ui-screens.md` — create/edit screens, mandatory visual capture loop
- `presentation/shared/ui_constants.gd` — window and combat band sizes
- `.cursor/skills/edit-ui-screens/` — agent skill for UI screen work (`/edit-ui-screens`)
- `.cursor/skills/capture-menu-screens/` — PNG capture + visual review (`/capture-menu-screens`)

### Assisted logging (Cursor / CI)
- `docs/workflows/assisted-logging.md` — how it works, commands, rules for devs
- `docs/architecture/event-catalog.md` — event schema and full catalog
- `platform/game_log.gd` — autoload emitter
- `core/event_log_bridge.gd` — signal → log wiring (single integration point)
- `tools/run_assisted_check.ps1` — one-command validation
- `.cursor/rules/assisted-logging.mdc` — Cursor rule when editing combat/save

## Navigation routes

| Task | Path |
|------|------|
| Onboarding | README → AGENTS → overview → naming |
| New / edit UI screen | `docs/workflows/ui-screens.md` → `ui-layout.md` → `presentation/AGENTS.md` |
| Combat bug | combat.md → domains/combat/ → save-format if progression involved |
| New skill | workflows/add-skill.md → data/skills/ |
| New item | workflows/add-item.md → platform/item_database |
| Broken save | save-format.md → save_service migrations |
| AI on project | workflows/ai-development.md |
| Logging / assisted test | workflows/assisted-logging.md → event-catalog.md |
| New skill (logging) | No per-skill logs — flows through PartyService signals automatically |
