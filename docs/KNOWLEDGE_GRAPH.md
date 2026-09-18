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
- `domains/progression/`
- `data/` (world curves)

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

## Navigation routes

| Task | Path |
|------|------|
| Onboarding | README → AGENTS → overview → naming |
| Combat bug | combat.md → domains/combat/ → save-format if progression involved |
| New skill | workflows/add-skill.md → data/skills/ |
| New item | workflows/add-item.md → platform/item_database |
| Broken save | save-format.md → save_service migrations |
| AI on project | workflows/ai-development.md |
