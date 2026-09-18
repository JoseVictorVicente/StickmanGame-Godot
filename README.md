# Stickman Idle

2D idle RPG in Godot 4.7 — a stickman party auto-battles in a transparent desktop overlay window.

## Requirements

- [Godot 4.7](https://godotengine.org/) (GL Compatibility)
- **godot-tools** extension recommended in Cursor/VS Code for GDScript LSP

## How to run

1. Clone the repository
2. Open the folder containing `project.godot` in the Godot editor
3. Press F5 to run

**Overlay:** disable *Embed Game* in the editor when testing the transparent window (see `docs/architecture/overlay-desktop.md`).

## Project structure

```
stickmangame/
├── core/                 # Global state, save, stat calculation
├── domains/              # Game rules (combat, progression, inventory)
├── data/                 # Resources (.tres) and schemas
├── presentation/         # UI (HUD, inventory, worlds, shared)
├── platform/             # Autoloads (audio, item database)
├── scenes/               # Main scene
├── locales/              # i18n translations (pt_BR, en)
├── docs/                 # Documentation and AI context
├── sprites/              # Art (do not edit without request)
└── tools/                # Helper scripts
```

Canonical English layout: `scenes/`, `core/`, `domains/`, `data/skills/`, `presentation/`, `platform/`.

## Quick playtest

See `docs/workflows/playtest-checklist.md`.

## Contributing

- Code & docs: **English**
- Player UI: **i18n** via `tr()` and `locales/*.po`
- Read `AGENTS.md` before large changes

## AI / agents

Entry point: [`AGENTS.md`](AGENTS.md) → [`docs/KNOWLEDGE_GRAPH.md`](docs/KNOWLEDGE_GRAPH.md)
