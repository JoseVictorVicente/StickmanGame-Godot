#!/usr/bin/env python3
"""Fail when presentation scenes use forbidden manual layout (layout_mode = 0).

See docs/conventions/ui-layout.md for allowed exceptions.
"""
from __future__ import annotations

import re
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
PRESENTATION = ROOT / "presentation"

LAYOUT_ZERO_RE = re.compile(r"^\s*layout_mode\s*=\s*0\s*$")

# (file glob fragment, parent path substring that must appear above the node in the block)
ALLOWLIST: tuple[tuple[str, str], ...] = (
    ("trail_map_view.tscn", "MapLayer"),
    ("trail_map_view.tscn", "StageMap"),
    ("stage_node.tscn", "StageNumber"),
    ("hero_section.tscn", "HeroVisualSection"),
)


def _node_header_at(lines: list[str], line_index: int) -> str:
    for index in range(line_index, -1, -1):
        if lines[index].startswith("[node "):
            return lines[index]
    return ""


def _parent_from_header(header: str) -> str:
    parent_match = re.search(r'parent="([^"]+)"', header)
    return parent_match.group(1) if parent_match else ""


def _is_allowed(file_name: str, parent: str, node_name: str) -> bool:
    for fragment, needle in ALLOWLIST:
        if fragment not in file_name:
            continue
        if needle in parent or needle == node_name:
            return True
    return False


def scan_file(path: Path) -> list[str]:
    text = path.read_text(encoding="utf-8")
    rel = path.relative_to(ROOT).as_posix()
    issues: list[str] = []
    for index, line in enumerate(text.splitlines()):
        if not LAYOUT_ZERO_RE.match(line):
            continue
        lines = text.splitlines()
        header = _node_header_at(lines, index)
        parent = _parent_from_header(header)
        node_match = re.search(r'\[node name="([^"]+)"', header)
        node_name = node_match.group(1) if node_match else "?"
        if _is_allowed(path.name, parent, node_name):
            continue
        issues.append(f"{rel}:{index + 1}: {node_name} (parent={parent}) uses layout_mode=0")
    return issues


WINDOW_WIDTH = 960
HUB_NODES = ("MenuArea", "Panel", "LinhaInventario")
MIN_SIZE_RE = re.compile(
    r'^\s*custom_minimum_size\s*=\s*Vector2\((\d+(?:\.\d+)?),\s*(\d+(?:\.\d+)?)\)\s*$'
)


def scan_inventory_hub_sizes(path: Path) -> list[str]:
    if path.name != "inventory_menu.tscn":
        return []
    rel = path.relative_to(ROOT).as_posix()
    issues: list[str] = []
    lines = path.read_text(encoding="utf-8").splitlines()
    current_node = ""
    for index, line in enumerate(lines):
        node_match = re.search(r'\[node name="([^"]+)"', line)
        if node_match:
            current_node = node_match.group(1)
            continue
        size_match = MIN_SIZE_RE.match(line)
        if not size_match or current_node not in HUB_NODES:
            continue
        width = float(size_match.group(1))
        if width > WINDOW_WIDTH:
            issues.append(
                f"{rel}:{index + 1}: {current_node} custom_minimum_size.x={width} "
                f"exceeds WINDOW_WIDTH ({WINDOW_WIDTH}); use InventoryLayout at runtime"
            )
    return issues


def main() -> int:
    all_issues: list[str] = []
    for tscn in sorted(PRESENTATION.rglob("*.tscn")):
        all_issues.extend(scan_file(tscn))
        all_issues.extend(scan_inventory_hub_sizes(tscn))
    if all_issues:
        print("UI layout check FAILED — forbidden layout_mode = 0:\n")
        for issue in all_issues:
            print(f"  - {issue}")
        print("\nAllowed exceptions: tools/check_ui_layout.py ALLOWLIST")
        print("Guide: docs/conventions/ui-layout.md")
        return 1
    print(f"[PASS] UI layout check ({len(list(PRESENTATION.rglob('*.tscn')))} scenes)")
    return 0


if __name__ == "__main__":
    sys.exit(main())
