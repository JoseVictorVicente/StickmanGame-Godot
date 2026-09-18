#!/usr/bin/env python3
"""Scan project files for res:// paths that do not exist on disk."""
from __future__ import annotations

import re
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
SCAN_DIRS = ("scenes", "presentation", "domains", "core", "platform", "data", "tests")
SKIP_PARTS = {".godot", "tools"}
RES_PATTERN = re.compile(r'res://[^\s"\')]+')


def res_to_path(res_url: str) -> Path:
    rel = res_url.removeprefix("res://").split("#")[0]
    return ROOT / rel.replace("/", "\\")


def iter_source_files() -> list[Path]:
    files: list[Path] = []
    for name in SCAN_DIRS:
        base = ROOT / name
        if not base.is_dir():
            continue
        for path in base.rglob("*"):
            if path.suffix in {".gd", ".tscn", ".tres"}:
                files.append(path)
    for path in (ROOT / "project.godot",):
        if path.is_file():
            files.append(path)
    return files


def main() -> int:
    missing: list[tuple[str, int, str]] = []
    for file_path in iter_source_files():
        try:
            text = file_path.read_text(encoding="utf-8")
        except OSError as err:
            print(f"WARN: cannot read {file_path}: {err}", file=sys.stderr)
            continue
        for match in RES_PATTERN.finditer(text):
            res_url = match.group(0).rstrip("\\")
            disk = res_to_path(res_url)
            if not disk.exists():
                line = text.count("\n", 0, match.start()) + 1
                missing.append((str(file_path.relative_to(ROOT)), line, res_url))

    if not missing:
        print("[OK] No missing res:// paths in active modules.")
        return 0

    print(f"[FAIL] {len(missing)} missing res:// path(s):")
    for file_name, line, res_url in sorted(missing):
        print(f"  {file_name}:{line} -> {res_url}")
    return 1


if __name__ == "__main__":
    raise SystemExit(main())
