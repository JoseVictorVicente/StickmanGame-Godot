#!/usr/bin/env python3
"""Ensure panel UI structure lives in .tscn, not .gd or external StyleBox .tres.

See .cursor/skills/edit-ui-screens/references/tscn-ownership.md
"""
from __future__ import annotations

import re
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
PRESENTATION = ROOT / "presentation"

# Panel scripts allowed to set layout at runtime (legacy hub/shell — do not extend).
GD_LAYOUT_ALLOWLIST: frozenset[str] = frozenset(
    {
        "presentation/inventory/inventory_menu.gd",
        "presentation/inventory/inventory_layout.gd",
        "presentation/inventory/inventory_panel_router.gd",
        "presentation/inventory/panel_layout.gd",
        "presentation/shared/window_manager.gd",
        "presentation/inventory/hero_equip_left_panel.gd",
        "presentation/inventory/hero_equip_right_panel.gd",
        "presentation/inventory/hero_character_panel.gd",
        "presentation/inventory/inventory_panel.gd",
        "presentation/inventory/bottom_nav.gd",
        "presentation/inventory/item_slot.gd",
        "presentation/inventory/skill_tree_map.gd",
        "presentation/inventory/section_visual_offset.gd",
        "presentation/inventory/formation_hero_grid.gd",
        "presentation/inventory/equipment_grid.gd",
        "presentation/inventory/inventory_slots_grid.gd",
        "presentation/inventory/warehouse_slots_grid.gd",
        "presentation/inventory/skills_active_grid.gd",
        "presentation/inventory/skills_passive_grid.gd",
        "presentation/inventory/skill_tooltip.gd",
        "presentation/inventory/team_selection_ui.gd",
        "presentation/worlds/trail_map_view.gd",
        # Legacy overlays — migrate layout into .tscn (do not extend).
        "presentation/inventory/attributes_panel.gd",
        "presentation/inventory/formation_panel.gd",
        "presentation/inventory/skills_panel.gd",
        "presentation/worlds/worlds_panel.gd",
        "presentation/worlds/portal_hall_view.gd",
        "presentation/worlds/realm_briefing_view.gd",
    }
)

GD_PANEL_GLOB = ("*_panel.gd", "*_view.gd")

GD_FORBIDDEN_PATTERNS: tuple[tuple[str, re.Pattern[str]], ...] = (
    ("position assignment", re.compile(r"\bposition\s*=")),
    ("offset_* assignment", re.compile(r"\boffset_(left|right|top|bottom)\s*=")),
    ("custom_minimum_size in script", re.compile(r"\bcustom_minimum_size\s*=")),
    (".size assignment", re.compile(r"\bsize\s*=")),
    ("size_flags assignment", re.compile(r"\bsize_flags_(horizontal|vertical)\s*=")),
    ("separation override in script", re.compile(r'add_theme_constant_override\s*\(\s*["\']separation')),
    ("reparent()", re.compile(r"\.reparent\s*\(")),
    ("StyleBoxFlat.new()", re.compile(r"StyleBoxFlat\.new\s*\(")),
    ("StyleBoxTexture.new()", re.compile(r"StyleBoxTexture\.new\s*\(")),
)

TSCN_STYLE_EXT_RE = re.compile(
    r'^\[ext_resource\s+type="StyleBox(?:Flat|Texture)"\s+path="([^"]+)"',
    re.MULTILINE,
)

COMMENT_RE = re.compile(r"^\s*#")


def _is_comment_line(line: str) -> bool:
    return bool(COMMENT_RE.match(line))


def scan_panel_gd(path: Path) -> list[str]:
    rel = path.relative_to(ROOT).as_posix()
    if rel in GD_LAYOUT_ALLOWLIST:
        return []
    issues: list[str] = []
    for index, line in enumerate(path.read_text(encoding="utf-8").splitlines(), start=1):
        if _is_comment_line(line):
            continue
        for label, pattern in GD_FORBIDDEN_PATTERNS:
            if pattern.search(line):
                issues.append(f"{rel}:{index}: {label} — move to .tscn")
    return issues


def scan_panel_tscn(path: Path) -> list[str]:
    rel = path.relative_to(ROOT).as_posix()
    text = path.read_text(encoding="utf-8")
    issues: list[str] = []
    for match in TSCN_STYLE_EXT_RE.finditer(text):
        style_path = match.group(1)
        if style_path.startswith("res://presentation/shared/styles/"):
            issues.append(
                f"{rel}: external StyleBox ExtResource '{style_path}' — "
                "bake as [sub_resource] inside this .tscn (copy from shared/styles if needed)"
            )
    return issues


def iter_panel_scripts() -> list[Path]:
    paths: list[Path] = []
    for pattern in GD_PANEL_GLOB:
        paths.extend(PRESENTATION.rglob(pattern))
    return sorted(set(paths))


def iter_panel_scenes() -> list[Path]:
    return sorted(PRESENTATION.rglob("*_panel.tscn")) + sorted(PRESENTATION.rglob("*_view.tscn"))


def main() -> int:
    issues: list[str] = []
    for gd in iter_panel_scripts():
        issues.extend(scan_panel_gd(gd))
    for tscn in iter_panel_scenes():
        issues.extend(scan_panel_tscn(tscn))

    if issues:
        print("TSCN ownership check FAILED:\n")
        for issue in issues:
            print(f"  - {issue}")
        print("\nGuide: .cursor/skills/edit-ui-screens/references/tscn-ownership.md")
        return 1

    gd_count = len(iter_panel_scripts())
    tscn_count = len(iter_panel_scenes())
    print(f"[PASS] TSCN ownership ({tscn_count} panel scenes, {gd_count} panel scripts scanned)")
    return 0


if __name__ == "__main__":
    sys.exit(main())
