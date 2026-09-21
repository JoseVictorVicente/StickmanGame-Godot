# Troubleshooting — symptoms and fixes

## PNG / hub layout

| Issue | Often caused by | Fix |
|-------|-----------------|-----|
| Grid crosses `inventory_bg` divider | Widget in wrong band | Move to `HubUpperRow` vs `InventoryPanel`; see [`screen-cookbook.md`](screen-cookbook.md) |
| Formation on band line | Formation not in lower band | `inventory_row.tscn` + `bottom_nav.tscn` |
| Grid overlaps hero | `SectionVisualOffset` or manual `position` | Containers + `clip_contents` on hub zones |
| Hub too narrow | `custom_minimum_size` on `Panel` / wrong `base_unit` | `InventoryLayout` + `_apply_panel_layout()` |
| Overlay not full-bleed | Missing Full Rect on overlay | `panel_layout.gd` `align_overlays` |
| Skill tree black / settings bleed | Wrong visibility target | `set_hub_visible(false)` / router, not hide whole `Panel` |
| Side panel clipped / zero height | Missing `EXPAND_FILL` | `_sync_side_panel_heights()` on sidecars |
| Panel taller than combat band | Zone heights not updated | `inventory_panel_size()` + `fit_panel_to_viewport()` |
| Top of `inventory_bg` clipped | Panel min height > max hub height | `sync_from_base_unit()` after token edits |
| Checkerboard in capture | Transparent window test host | Capture-only; ignore if in-game OK |

## Community / container symptoms

| Symptom | Cause | Fix |
|---------|-------|-----|
| Child height 0 in VBox | No min size / expand | `custom_minimum_size` or `SIZE_EXPAND_FILL` |
| Button won't resize in script | Container owns size | `custom_minimum_size` + `SIZE_SHRINK_*` |
| Layout changes on F5 only | Mixed anchors inside Container | Remove anchors; use size flags |
| 25/50/25 layout wrong | `stretch_ratio` decimals | Use **1:2:1** |
| Prefab invisible in grid | Root min size 0 | `custom_minimum_size` + shrink flags on instance root |
| Dropdown in wrong place | Runtime position math | Bake menu above button in `VBox` (`worlds_panel`) |

## StyleBox / frame symptoms

| Symptom | Cause | Fix |
|---------|-------|-----|
| Text under frame border | content_margin fallback | [`stylebox-gotchas.md`](stylebox-gotchas.md) |
| Inconsistent buttons across panels | Inline duplicate StyleBoxes | `presentation/shared/styles/*.tres` |

## Script / workflow

| Symptom | Cause | Fix |
|---------|-------|-----|
| `inventory_menu.gd` corrupted encoding | Editor saved UTF-16 | Edit UTF-8; **do not** run `fix_inventory_menu_encoding.py` on dirty tree |
| Capture missing state | State not registered | Add to `inventory_menu_layout_states.gd` + capture script |
| layout check fails | `layout_mode = 0` in container child | Move to container layout or ALLOWLIST with doc |

## Validation commands

```powershell
powershell -ExecutionPolicy Bypass -File tools/run_new_screen_preflight.ps1 -PanelPath presentation/inventory/my_panel.gd
powershell -ExecutionPolicy Bypass -File tools/run_ui_layout_check.ps1
powershell -ExecutionPolicy Bypass -File tools/run_inventory_menu_layout_audit.ps1
powershell -ExecutionPolicy Bypass -File tools/run_edit_ui_validation.ps1 -ScopePng <png_id>
# Full audit: see capture-menu-screens/SKILL.md
```

## Worlds visual regression

Compare captures to `artifacts/design/portals_mockup_*.png` for hall, briefing, trail.
