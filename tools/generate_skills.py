#!/usr/bin/env python3
"""Generate English-named SkillResource .tres files for all classes."""

from __future__ import annotations

import re
import unicodedata
from pathlib import Path

from skill_catalog_data import (
    ACTIVE_COOLDOWNS,
    ACTIVE_EFFECTS,
    ACTIVE_ID_OVERRIDES,
    ACTIVE_VFX,
    CATALOG,
    ICON_INNER_ONLY,
    PASSIVE_ID_OVERRIDES,
    PASSIVE_STATS,
)

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
        active_effects = ACTIVE_EFFECTS.get(class_id, [])
        active_vfx = ACTIVE_VFX.get(class_id, [])
        for index, entry in enumerate(groups["active"], start=1):
            pt_name, pt_desc, en_name, en_desc = entry
            skill_id = overrides[index - 1] if index - 1 < len(overrides) else slugify(pt_name)
            effects = active_effects[index - 1] if index - 1 < len(active_effects) else []
            vfx_id = active_vfx[index - 1] if index - 1 < len(active_vfx) else ""
            yield (
                class_id,
                skill_id,
                pt_name,
                pt_desc,
                en_name,
                en_desc,
                0,
                ACTIVE_COOLDOWNS[index - 1]
                if index - 1 < len(ACTIVE_COOLDOWNS)
                else 8.0,
                index,
                "",
                0.0,
                vfx_id,
                effects,
            )
        passive_overrides = PASSIVE_ID_OVERRIDES.get(class_id, [])
        passive_stats = PASSIVE_STATS.get(class_id, [])
        for index, entry in enumerate(groups["passive"], start=1):
            pt_name, pt_desc, en_name, en_desc = entry
            skill_id = passive_overrides[index - 1] if index - 1 < len(passive_overrides) else slugify(pt_name)
            stat_key = ""
            stat_value = 0.0
            if index - 1 < len(passive_stats):
                stat_key, stat_value = passive_stats[index - 1]
            yield class_id, skill_id, pt_name, pt_desc, en_name, en_desc, 1, 0.0, index, stat_key, stat_value, "", []


def build_skill_locale_entries() -> dict[str, tuple[str, str]]:
    entries: dict[str, tuple[str, str]] = {}
    for _class_id, skill_id, pt_name, pt_desc, en_name, en_desc, *_rest in iter_skills():  # noqa: PERF203
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
        passive_overrides = PASSIVE_ID_OVERRIDES.get(class_id, [])
        for index, entry in enumerate(groups["passive"], start=1):
            pt_name = entry[0]
            legacy = slugify(pt_name)
            new_id = passive_overrides[index - 1] if index - 1 < len(passive_overrides) else legacy
            if legacy != new_id:
                mapping[legacy] = new_id
            mapping.setdefault(legacy, legacy)
    return mapping


def _effect_script_path(effect: dict) -> str:
    effect_type = effect.get("effect_type", "")
    if effect_type == "buff_self":
        return "res://data/effects/buff_effect.gd"
    if effect_type in ("heal_party", "heal_self", "heal_lowest"):
        return "res://data/effects/heal_effect.gd"
    return "res://data/effects/damage_effect.gd"


def _format_effect_subresource(effect: dict, index: int, script_id: str) -> tuple[str, str]:
    sub_id = f"Effect_{index}"
    effect_type = effect.get("effect_type", "")
    if effect_type == "buff_self":
        body = f"""[sub_resource type="Resource" id="{sub_id}"]
script = ExtResource("{script_id}")
effect_type = "{effect_type}"
stat_key = "{effect.get('stat_key', '')}"
stat_value = {float(effect.get('stat_value', 0.0))}
duration_sec = {float(effect.get('duration_sec', 0.0))}
"""
    elif effect_type in ("heal_party", "heal_self", "heal_lowest"):
        body = f"""[sub_resource type="Resource" id="{sub_id}"]
script = ExtResource("{script_id}")
effect_type = "{effect_type}"
heal_pct_max_hp = {float(effect.get('heal_pct_max_hp', 15.0))}
target_scope = "{effect.get('target_scope', 'party')}"
"""
    else:
        body = f"""[sub_resource type="Resource" id="{sub_id}"]
script = ExtResource("{script_id}")
effect_type = "{effect_type}"
multiplier = {float(effect.get('multiplier', 1.0))}
hits = {int(effect.get('hits', 1))}
force_crit = {"true" if effect.get("force_crit") else "false"}
armor_pen_pct = {float(effect.get('armor_pen_pct', 0.0))}
"""
    return sub_id, body


def _format_effects_block(effects: list[dict]) -> tuple[str, str, int, str]:
    if not effects:
        return "", "", 2, "effects = []\n"
    ext_lines: list[str] = []
    sub_lines: list[str] = []
    sub_refs: list[str] = []
    load_steps = 2 + len(effects) * 2
    for index, effect in enumerate(effects):
        script_path = _effect_script_path(effect)
        script_id = f"effect_{index}"
        ext_lines.append(
            f'[ext_resource type="Script" path="{script_path}" id="{script_id}"]'
        )
        sub_id, sub_body = _format_effect_subresource(effect, index, script_id)
        sub_lines.append(sub_body)
        sub_refs.append(f'SubResource("{sub_id}")')
    effects_line = f"effects = [{', '.join(sub_refs)}]\n"
    return "\n".join(ext_lines), "\n".join(sub_lines), load_steps, effects_line


def write_tres(
    path: Path,
    skill_id: str,
    class_id: str,
    tipo: int,
    cooldown: float,
    sort_order: int,
    stat_bonus_key: str = "",
    stat_value: float = 0.0,
    vfx_id: str = "",
    effects: list[dict] | None = None,
) -> None:
    icon_path = f"res://sprites/ui/skills/{class_id}/{skill_id}.png"
    inner_only = skill_id in ICON_INNER_ONLY.get(class_id, set())
    inner_line = "icon_inner_only = true\n" if inner_only else ""
    effect_list = effects or []
    ext_effects, sub_effects, load_steps, effects_line = _format_effects_block(effect_list)
    vfx_line = f'vfx_id = "{vfx_id}"\n' if vfx_id else 'vfx_id = ""\n'
    ext_skill_line = '[ext_resource type="Script" path="res://data/skill_resource.gd" id="1_skill"]'
    extra_ext = f"\n{ext_effects}" if ext_effects else ""
    extra_sub = f"\n{sub_effects}" if sub_effects else ""
    content = f"""[gd_resource type="Resource" script_class="SkillResource" load_steps={load_steps} format=3]

{ext_skill_line}{extra_ext}
{extra_sub}
[resource]
script = ExtResource("1_skill")
skill_id = "{skill_id}"
name_key = "SKILL_{skill_id}"
description_key = "SKILL_{skill_id}_DESC"
type = {tipo}
cooldown = {cooldown}
icon_path = "{icon_path}"
{inner_line}sort_order = {sort_order}
stat_bonus_key = "{stat_bonus_key}"
stat_value = {stat_value}
{vfx_line}{effects_line}"""
    path.parent.mkdir(parents=True, exist_ok=True)
    path.write_text(content, encoding="utf-8")


def _validate_active_catalog_lengths() -> None:
    for class_id, groups in CATALOG.items():
        active_count = len(groups["active"])
        effects = ACTIVE_EFFECTS.get(class_id, [])
        vfx = ACTIVE_VFX.get(class_id, [])
        if effects and len(effects) != active_count:
            raise ValueError(
                f"ACTIVE_EFFECTS['{class_id}'] has {len(effects)} entries, expected {active_count}"
            )
        if vfx and len(vfx) != active_count:
            raise ValueError(
                f"ACTIVE_VFX['{class_id}'] has {len(vfx)} entries, expected {active_count}"
            )


def main() -> None:
    _validate_active_catalog_lengths()
    for class_id in CATALOG:
        folder = OUT / class_id
        if folder.exists():
            for arquivo in folder.glob("*.tres"):
                arquivo.unlink()
    count = 0
    for (
        class_id,
        skill_id,
        _pt_name,
        _pt_desc,
        _en_name,
        _en_desc,
        tipo,
        cooldown,
        sort_order,
        stat_bonus_key,
        stat_value,
        vfx_id,
        effects,
    ) in iter_skills():
        prefix = f"{sort_order:02d}_" if tipo == 0 else f"p{sort_order:02d}_"
        filename = f"{prefix}{skill_id}.tres"
        write_tres(
            OUT / class_id / filename,
            skill_id,
            class_id,
            tipo,
            cooldown,
            sort_order,
            stat_bonus_key,
            stat_value,
            vfx_id,
            effects,
        )
        count += 1
    print(f"Generated {count} skill resources in {OUT}")


if __name__ == "__main__":
    main()
