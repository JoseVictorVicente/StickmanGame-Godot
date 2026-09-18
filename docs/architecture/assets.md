# Assets (`sprites/`)

Art lives at the **repository root** in `sprites/`. It is not inside `data/` or `presentation/` because textures are shared across combat, UI, and world panels.

## Layout

```
sprites/
├── environment/          # backgrounds, floor tiles, world map previews
├── heroes/               # portraits, body sprites, spritesheets
├── projectiles/          # combat VFX (arrows, etc.)
└── ui/
    ├── skill_tree/       # skill-tree node icons (attack, health, gold, …)
    └── skills/           # per-class skill icons (<class_id>/)
        ├── warrior/
        ├── mage/
        ├── archer/
        ├── assassin/
        ├── tank/
        └── priest/
```

Folder and file names use **English**. Individual PNG filenames may still use legacy Portuguese slugs until art is renamed; paths in code always point to the English folder structure.

## Module boundaries

| Consumer | Usage |
|----------|--------|
| `data/class_data.gd` | Hero portrait paths |
| `data/skills/**/*.tres` | `icon_path` per skill |
| `presentation/shared/tree_icons.gd` | Skill-tree stat icons |
| `presentation/shared/skill_icons.gd` | Skill button icons |
| `presentation/worlds/` | World map textures |
| `presentation/combat/` | Spritesheets, projectiles |
| `scenes/main.tscn` | Combat floor texture |

Domain code (`domains/`) must **not** hardcode sprite paths; pass `Texture2D` or resource paths from `data/` / `presentation/`.

## Protected path

See `.cursor/rules/protected-paths.mdc`:

- Do not bulk-regenerate or delete art.
- Renaming folders is OK when all `res://` references are updated.
- New skill icons: `sprites/ui/skills/<class_id>/<skill_slug>.png`

## i18n

Sprites are **not** translated. Player-visible text uses `locales/*.po` and `tr(LocaleKeys.*)` — never embed locale-specific text in PNGs.
