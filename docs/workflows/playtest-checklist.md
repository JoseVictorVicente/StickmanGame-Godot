# Playtest Checklist

Run after changes to **combat**, **inventory**, **save**, or **overlay**.

Estimated time: 5–10 minutes.

## Environment

- [ ] Godot 4.7, GL Compatibility renderer
- [ ] **Embed Game disabled** (separate window)
- [ ] Console visible for errors (`Output`)

## 1. Boot

- [ ] F5 with no critical console errors
- [ ] Transparent window, always-on-top
- [ ] Combat HUD visible (enemy, HP bar, gold)
- [ ] Heroes appear on stage

## 2. Idle combat

- [ ] Heroes attack automatically (animation + damage numbers)
- [ ] Enemy HP bar decreases
- [ ] Enemy dies → coin effect → gold increases
- [ ] New enemy spawns
- [ ] World/stage label updates (if not repeating)
- [ ] Enemy attacks rightmost hero; hero HP bar responds

## 3. Defeat (quick optional)

- [ ] Let party die OR force in debug
- [ ] "Party defeated!" toast (or i18n key)
- [ ] Party healed; combat resumes

## 4. Inventory

- [ ] Menu button (4 squares) opens panel
- [ ] Click-through disabled with menu open
- [ ] Closing inventory (ESC or button) triggers save
- [ ] Switching character (Warrior/Mage/Archer) updates equip and level

## 5. Equip item

- [ ] Drag item from grid to equip slot
- [ ] DPS/damage on HUD changes (`recalcular_atributos`)
- [ ] Wrong class item rejected
- [ ] Unequip returns item to grid

## 6. Skill tree

- [ ] Open Skill Tree panel
- [ ] Purchase node with enough gold
- [ ] Gold decreases; bonus reflects (e.g. +attack → DPS)
- [ ] Node without prerequisite blocked

## 7. Portais

- [ ] Open **Portais** side panel (portal hall + subtitle)
- [ ] Select dimension → briefing → cross portal → trail map
- [ ] Named milestones visible; stage 9 = Demon King
- [ ] Start stage (if unlocked); enemy stats match stage
- [ ] Defeat boss → `COMBAT_REALM_SAVED` toast with dimension name

## 8. Forge / warehouse (if touched)

- [ ] Forge opens attached to inventory
- [ ] Dismantle item → gold
- [ ] Warehouse: move item between tabs

## 9. Persistence

- [ ] Close game (window X)
- [ ] Reopen F5
- [ ] Gold, stage, inventory, equipment, skill tree preserved
- [ ] Equipped skills preserved (save v4)
- [ ] `user://save.cfg` with `version = 4` in `game` section

## 10. Overlay

- [ ] Dragging stage moves window
- [ ] Menu near bottom edge → combat anchors to top
- [ ] Empty areas with menu closed: click passes through (test desktop behind)

## Known regressions to watch

| Area | Symptom |
|------|---------|
| Save v2 → v3 | Skill tree reset on first load |
| Save v3 → v4 | Legacy PT keys/class IDs should migrate |
| i18n | PT strings hardcoded in toasts |

## On failure

1. Note exact steps and world/stage.
2. Copy console error.
3. If save-related → [`save-format.md`](../architecture/save-format.md).
4. Fix in the correct domain (not UI-only).
