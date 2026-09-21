#!/usr/bin/env python3
"""One-time helper: fill placeholder active skills with MVP effects."""
from __future__ import annotations

from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]

# (class, filename_prefix, skill_id, cooldown, sort_order, vfx_id, effects)
# effect: ("damage_multi"|"damage_burst"|"buff"|"heal", kwargs)
ACTIVES = [
    # Warrior
    ("warrior", "01_sequencia_frenetica", "sequencia_frenetica", 5.0, 1, "", [
        ("damage_multi", {"hits": 3, "multiplier": 1.0}),
    ]),
    ("warrior", "02_corte_rapido", "corte_rapido", 16.0, 2, "", [
        ("damage_burst", {"multiplier": 1.0}),
    ]),
    ("warrior", "03_perfuracao_dupla", "perfuracao_dupla", 6.0, 3, "", [
        ("damage_multi", {"hits": 2, "multiplier": 1.0}),
    ]),
    ("warrior", "04_lamina_pesada", "lamina_pesada", 10.0, 4, "", [
        ("damage_burst", {"multiplier": 2.0}),
    ]),
    ("warrior", "05_grito_de_guerra", "grito_de_guerra", 12.0, 5, "buff_glow", [
        ("buff", {"stat_key": "attack_pct", "stat_value": 20.0, "duration_sec": 5.0}),
    ]),
    # Assassin
    ("assassin", "01_corte_duplo_executor", "corte_duplo_executor", 5.0, 1, "", [
        ("damage_multi", {"hits": 2, "multiplier": 1.0}),
    ]),
    ("assassin", "02_marca_da_presa", "marca_da_presa", 16.0, 2, "", [
        ("damage_burst", {"multiplier": 1.3}),
    ]),
    ("assassin", "03_corte_duplo_rapido", "corte_duplo_rapido", 6.0, 3, "", [
        ("damage_multi", {"hits": 2, "multiplier": 1.0}),
    ]),
    ("assassin", "04_sequencia_desperta", "sequencia_desperta", 10.0, 4, "buff_glow", [
        ("buff", {"stat_key": "attack_speed", "stat_value": 60.0, "duration_sec": 3.0}),
    ]),
    ("assassin", "05_decaptacao_celerada", "decaptacao_celerada", 12.0, 5, "", [
        ("damage_burst", {"multiplier": 1.5}),
    ]),
    # Priest
    ("priest", "01_posicao_sagrada", "posicao_sagrada", 5.0, 1, "buff_glow", [
        ("heal", {"heal_pct_max_hp": 15.0, "target_scope": "lowest_hp", "effect_type": "heal_lowest"}),
    ]),
    ("priest", "02_escudo_solar", "escudo_solar", 16.0, 2, "buff_glow", [
        ("heal", {"heal_pct_max_hp": 12.0, "target_scope": "lowest_hp", "effect_type": "heal_lowest"}),
    ]),
    ("priest", "03_punicao_divina", "punicao_divina", 6.0, 3, "", [
        ("damage_burst", {"multiplier": 1.5}),
    ]),
    ("priest", "04_aura_de_inviolabilidade", "aura_de_inviolabilidade", 10.0, 4, "buff_glow", [
        ("heal", {"heal_pct_max_hp": 8.0, "target_scope": "party", "effect_type": "heal_party"}),
        ("buff", {"stat_key": "phys_res", "stat_value": 15.0, "duration_sec": 1.5}),
    ]),
    ("priest", "05_fervor_sagrado", "fervor_sagrado", 12.0, 5, "buff_glow", [
        ("buff", {"stat_key": "attack_pct", "stat_value": 15.0, "duration_sec": 4.0, "target_scope": "party"}),
    ]),
    # Tank
    ("tank", "01_barreira_de_runas", "barreira_de_runas", 5.0, 1, "buff_glow", [
        ("buff", {"stat_key": "hp_pct", "stat_value": 25.0, "duration_sec": 4.0}),
    ]),
    ("tank", "02_provocacao_sombria", "provocacao_sombria", 16.0, 2, "buff_glow", [
        ("heal", {"heal_pct_max_hp": 15.0, "target_scope": "self", "effect_type": "heal_self"}),
    ]),
    ("tank", "03_postura_inviolavel", "postura_inviolavel", 6.0, 3, "buff_glow", [
        ("buff", {"stat_key": "phys_res", "stat_value": 100.0, "duration_sec": 2.5}),
    ]),
    ("tank", "04_supressao_total", "supressao_total", 10.0, 4, "", [
        ("damage_burst", {"multiplier": 1.3}),
    ]),
    ("tank", "05_moinho_esmagador", "moinho_esmagador", 12.0, 5, "", [
        ("damage_multi", {"hits": 3, "multiplier": 0.9}),
    ]),
    # Mage
    ("mage", "01_abyssal_meteor", "abyssal_meteor", 5.0, 1, "", [
        ("damage_burst", {"multiplier": 2.0}),
    ]),
    ("mage", "02_damage_portal", "damage_portal", 16.0, 2, "", [
        ("damage_multi", {"hits": 5, "multiplier": 0.4}),
    ]),
    ("mage", "03_black_fireball", "black_fireball", 6.0, 3, "", [
        ("damage_burst", {"multiplier": 1.5}),
    ]),
    ("mage", "04_ice_nova", "ice_nova", 10.0, 4, "", [
        ("damage_burst", {"multiplier": 1.2}),
    ]),
    ("mage", "05_ice_lance", "ice_lance", 12.0, 5, "", [
        ("damage_multi", {"hits": 2, "multiplier": 1.0}),
    ]),
]


def effect_script(kind: str) -> str:
    if kind in ("damage_multi", "damage_burst"):
        return "res://data/effects/damage_effect.gd"
    if kind == "buff":
        return "res://data/effects/buff_effect.gd"
    return "res://data/effects/heal_effect.gd"


def render_effect_subresource(idx: int, kind: str, kwargs: dict) -> tuple[str, str]:
    ext_id = f"effect_{idx}"
    if kind == "damage_multi":
        body = f'''[sub_resource type="Resource" id="Effect_{idx}"]
script = ExtResource("{ext_id}")
effect_type = "damage_multi"
multiplier = {kwargs.get("multiplier", 1.0)}
hits = {kwargs.get("hits", 2)}
force_crit = false
armor_pen_pct = 0.0
'''
    elif kind == "damage_burst":
        body = f'''[sub_resource type="Resource" id="Effect_{idx}"]
script = ExtResource("{ext_id}")
effect_type = "damage_burst"
multiplier = {kwargs.get("multiplier", 1.0)}
hits = 1
force_crit = false
armor_pen_pct = 0.0
'''
    elif kind == "buff":
        scope = kwargs.get("target_scope", "self")
        body = f'''[sub_resource type="Resource" id="Effect_{idx}"]
script = ExtResource("{ext_id}")
effect_type = "buff_self"
stat_key = "{kwargs["stat_key"]}"
stat_value = {kwargs["stat_value"]}
duration_sec = {kwargs["duration_sec"]}
target_scope = "{scope}"
'''
    else:
        body = f'''[sub_resource type="Resource" id="Effect_{idx}"]
script = ExtResource("{ext_id}")
effect_type = "{kwargs.get("effect_type", "heal_party")}"
heal_pct_max_hp = {kwargs["heal_pct_max_hp"]}
target_scope = "{kwargs["target_scope"]}"
'''
    return ext_id, body


def build_tres(class_name: str, file_prefix: str, skill_id: str, cooldown: float, sort_order: int, vfx_id: str, effects: list) -> str:
    load_steps = 2 + len(effects) * 2
    ext_resources = ['[ext_resource type="Script" path="res://data/skill_resource.gd" id="1_skill"]']
    sub_resources = []
    effect_refs = []
    for i, (kind, kwargs) in enumerate(effects):
        ext_id, sub = render_effect_subresource(i, kind, kwargs)
        script_path = effect_script(kind)
        ext_resources.append(f'[ext_resource type="Script" path="{script_path}" id="{ext_id}"]')
        sub_resources.append(sub)
        effect_refs.append(f'SubResource("Effect_{i}")')

    lines = [
        f'[gd_resource type="Resource" script_class="SkillResource" load_steps={load_steps} format=3]',
        "",
        *ext_resources,
        "",
        *sub_resources,
        "[resource]",
        'script = ExtResource("1_skill")',
        f'skill_id = "{skill_id}"',
        f'name_key = "SKILL_{skill_id}"',
        f'description_key = "SKILL_{skill_id}_DESC"',
        "type = 0",
        f"cooldown = {cooldown}",
        f'icon_path = "res://sprites/ui/skills/{class_name}/{skill_id}.png"',
        f"sort_order = {sort_order}",
        'stat_bonus_key = ""',
        "stat_value = 0.0",
        f'vfx_id = "{vfx_id}"',
        f"effects = [{', '.join(effect_refs)}]",
        "",
    ]
    return "\n".join(lines)


def main() -> None:
    for class_name, prefix, skill_id, cooldown, sort_order, vfx_id, effects in ACTIVES:
        path = ROOT / "data" / "skills" / class_name / f"{prefix}.tres"
        content = build_tres(class_name, prefix, skill_id, cooldown, sort_order, vfx_id, effects)
        path.write_text(content, encoding="utf-8")
        print(f"Updated {path.relative_to(ROOT)}")


if __name__ == "__main__":
    main()
