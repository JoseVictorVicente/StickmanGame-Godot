# Portals Saga (narrative + UI)

**Code:** `data/world_catalog.gd`, `presentation/worlds/worlds_panel.gd`  
**Visual spec:** `artifacts/design/portals_mockup_*.png`

## Premise

In the **Sanctuary of Lumen** (home world), divinity **Aurion** chose three adventurers as **Bearers of the Flame**. Stable portals lead to **fallen dimensions** each ruled by a regional **Demon King**. The party crosses a portal, clears nine trail stages, and defeats the demon king to restore hope.

| Layer | Player-facing | Save / code |
|-------|---------------|-------------|
| Home world | Sanctuary hub (inventory menu) | — |
| Portal | Named dimension card | `world` 1..5 |
| Trail stage | Named milestone | `stage` 1..9 |
| Difficulty | Safe / Marked / Cursed trail | `difficulty` 0..2 |

Save keys unchanged (`world`, `stage`, `difficulty`, `unlocked_stages`). `world` is a catalog ID, not the display name.

## UI flow (WorldsPanel)

1. **Portal hall** — five dimension cards, subtitle, difficulty selector  
2. **Briefing** — biome banner, decay lore, demon king name, *Cross portal*  
3. **Trail map** — nine named nodes; stage 9 = Demon King  

Signals unchanged: `stage_started(world, stage, difficulty)`.

## Dimensions

| `world` | Name (PT) | Demon King | Map texture |
|---------|-----------|------------|-------------|
| 1 | Bosque Esmeralda | Morgrath, Senhor das Raízes Podres | `forest_map_clean.png` |
| 2 | Bosque Corrompido | Vex'hal, Sombra dos Ecos | `forest_map_dark.jpg` |
| 3 | Areias Perdidas | Khar-Ra, Faraó das Tempestades | `desert_map.jpg` |
| 4 | Picos Gelados | Ymiron, Coração de Gelo | `snow_map.jpg` |
| 5 | Forja do Abismo | Azrak, Senhor da Forja Profana | `volcanic_map.jpg` |

Stage milestone keys: `DIMENSION_{n}_STAGE_{1..9}` in locales. Boss label: `STAGE_DEMON_KING`.

## Combat notices

| Event | Locale key |
|-------|------------|
| Boss defeated (stage 9) | `COMBAT_REALM_SAVED` |
| Next portal unlocked | `COMBAT_PORTAL_UNLOCKED` |
| Next difficulty trail | `COMBAT_DIFFICULTY_UNLOCKED` |

## Related docs

- [`progression.md`](progression.md) — `WorldProgress` curves and unlock rules  
- [`inventory.md`](inventory.md) — WorldsPanel in menu shell  
- [`combat.md`](combat.md) — enemy stats from `WorldProgress.enemy_stats`
