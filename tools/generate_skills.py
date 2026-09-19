#!/usr/bin/env python3
"""Generate English-named SkillResource .tres files for all classes."""

from __future__ import annotations

import re
import unicodedata
from pathlib import Path

from skill_catalog_data import ACTIVE_COOLDOWNS, ACTIVE_ID_OVERRIDES, CATALOG, ICON_INNER_ONLY

ROOT = Path(__file__).resolve().parents[1]
OUT = ROOT / "data" / "skills"


def slugify(text: str) -> str:
    text = unicodedata.normalize("NFKD", text)
    text = text.encode("ascii", "ignore").decode("ascii")
    text = re.sub(r"[^a-zA-Z0-9]+", "_", text).strip("_").lower()
    return text


def iter_skills():
    for class_id, groups in CATALOG.items():
        overrides = ACTIVE_ID_OVERRIDES.get(class_id, [])
        for index, entry in enumerate(groups["active"], start=1):
            pt_name, pt_desc, en_name, en_desc = entry
            skill_id = overrides[index - 1] if index - 1 < len(overrides) else slugify(pt_name)
            yield class_id, skill_id, pt_name, pt_desc, en_name, en_desc, 0, ACTIVE_COOLDOWNS[index - 1], index
        for index, entry in enumerate(groups["passive"], start=1):
            pt_name, pt_desc, en_name, en_desc = entry
            skill_id = slugify(pt_name)
            yield class_id, skill_id, pt_name, pt_desc, en_name, en_desc, 1, 0.0, index


def build_skill_locale_entries() -> dict[str, tuple[str, str]]:
    entries: dict[str, tuple[str, str]] = {}
    for _class_id, skill_id, pt_name, pt_desc, en_name, en_desc, *_rest in iter_skills():
        entries[f"SKILL_{skill_id}"] = (en_name, pt_name)
        entries[f"SKILL_{skill_id}_DESC"] = (en_desc, pt_desc)
    return entries


def build_skill_id_migration() -> dict[str, str]:
    """Map legacy Portuguese skill_id slugs to English ids."""
    mapping: dict[str, str] = {}
    for class_id, groups in CATALOG.items():
        overrides = ACTIVE_ID_OVERRIDES.get(class_id, [])
        for index, entry in enumerate(groups["active"], start=1):
            pt_name = entry[0]
            legacy = slugify(pt_name)
            new_id = overrides[index - 1] if index - 1 < len(overrides) else legacy
            if legacy != new_id:
                mapping[legacy] = new_id
        for entry in groups["passive"]:
            pt_name = entry[0]
            legacy = slugify(pt_name)
            mapping.setdefault(legacy, legacy)
    return mapping


def write_tres(
    path: Path,
    skill_id: str,
    class_id: str,
    tipo: int,
    cooldown: float,
    sort_order: int,
) -> None:
    icon_path = f"res://sprites/ui/skills/{class_id}/{skill_id}.png"
    inner_only = skill_id in ICON_INNER_ONLY.get(class_id, set())
    inner_line = "icon_inner_only = true\n" if inner_only else ""
    content = f"""[gd_resource type="Resource" script_class="SkillResource" load_steps=2 format=3]

[ext_resource type="Script" path="res://data/skill_resource.gd" id="1_skill"]

[resource]
script = ExtResource("1_skill")
skill_id = "{skill_id}"
name_key = "SKILL_{skill_id}"
description_key = "SKILL_{skill_id}_DESC"
type = {tipo}
cooldown = {cooldown}
icon_path = "{icon_path}"
{inner_line}sort_order = {sort_order}
stat_value = 0.0
"""
    path.parent.mkdir(parents=True, exist_ok=True)
    path.write_text(content, encoding="utf-8")


def main() -> None:
    for class_id in CATALOG:
        folder = OUT / class_id
        if folder.exists():
            for arquivo in folder.glob("*.tres"):
                arquivo.unlink()
    count = 0
    for class_id, skill_id, pt_name, _pt_desc, _en_name, _en_desc, tipo, cooldown, sort_order in iter_skills():
        prefix = f"{sort_order:02d}_" if tipo == 0 else f"p{sort_order:02d}_"
        filename = f"{prefix}{skill_id}.tres"
        write_tres(OUT / class_id / filename, skill_id, class_id, tipo, cooldown, sort_order)
        count += 1
    print(f"Generated {count} skill resources in {OUT}")


if __name__ == "__main__":
    main()
