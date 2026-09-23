# Data layer

- Resources only — no `Control` nodes
- Schemas: `item_data.gd`, `class_data.gd`, `skill_resource.gd`, `enemy_data.gd`, `enemy_visual_profile.gd`
- Portal narrative catalog: `world_catalog.gd` (dimension names, milestones, map paths)
- Skills: `data/skills/{class}/` — `01_` active, `p01_` passive
- Enemies: `data/enemies/*.tres` — auto-loaded by `EnemyCatalog`; profiles in `data/enemy_visual_profiles/`
