#!/usr/bin/env python3
"""One-time helper: align passive skill stats with class fantasy."""
from __future__ import annotations

import re
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]

# skill_id -> (stat_bonus_key, stat_value)
PASSIVE_STATS = {
    # Archer
    "armor_penetration": ("attack_pct", 8.0),
    "reflex_recoil": ("evasion", 5.0),
    "swift_execution": ("attack_pct", 6.0),
    "nimble_hands": ("cooldown_reduction", 15.0),
    "eagle_eye": ("crit_chance", 6.0),
    "drawstring_tension": ("attack_speed", 12.0),
    "wearing_poison": ("attack", 4.0),
    "weak_prey": ("attack_pct", 5.0),
    "stacking_impact": ("attack_pct", 7.0),
    "surgical_aim": ("crit_chance", 8.0),
    # Warrior
    "blade_master": ("attack", 8.0),
    "extreme_sharpening": ("crit_chance", 6.0),
    "iron_armor": ("phys_res", 10.0),
    "unbreakable_stance": ("phys_res", 8.0),
    "precise_execution": ("attack_pct", 8.0),
    "iron_will": ("attack_speed", 10.0),
    "defensive_stance": ("phys_res", 8.0),
    "brute_force": ("attack_pct", 7.0),
    "medium_resistance": ("phys_res", 8.0),
    "steel_muscles": ("hp_pct", 10.0),
    # Assassin
    "shadow_reflexes": ("crit_chance", 5.0),
    "adrenaline_surge": ("attack_speed", 8.0),
    "venomous_vein": ("crit_damage", 12.0),
    "stealth_strike": ("crit_damage", 10.0),
    "lethal_execution": ("attack_pct", 8.0),
    "deep_cut": ("attack", 4.0),
    "weak_point_mapping": ("attack_pct", 8.0),
    "adrenaline": ("attack_speed", 5.0),
    "assassin_rhythm": ("attack_speed", 10.0),
    "light_blade": ("attack_pct", 10.0),
    # Priest
    "sun_touch": ("hp", 35.0),
    "reactive_barrier": ("hp", 40.0),
    "radiant_presence": ("elemental_res", 8.0),
    "unshakable_devotion": ("cooldown_reduction", 10.0),
    "divine_vigor": ("hp", 25.0),
    "sacred_touch": ("hp", 25.0),
    "critical_heal": ("crit_chance", 5.0),
    "celestial_pact": ("hp", 50.0),
    "protective_light": ("phys_res", 10.0),
    "mercy": ("hp", 35.0),
    # Tank
    "titanium_shell": ("evasion", 5.0),
    "surface_thorns": ("attack", 5.0),
    "unshakable": ("phys_res", 6.0),
    "impact_absorption": ("hp", 35.0),
    "magic_alloy": ("elemental_res", 8.0),
    "last_trench": ("hp", 45.0),
    "heavy_weight": ("attack", 5.0),
    "battle_inertia": ("phys_res", 6.0),
    "hard_shell": ("phys_res", 10.0),
    "vital_crush": ("attack_pct", 7.0),
    # Mage
    "arcane_amplification": ("attack", 6.0),
    "rune_resonance": ("cooldown_reduction", 8.0),
    "magic_penetration": ("attack_pct", 8.0),
    "critical_focus": ("crit_chance", 8.0),
    "soul_drain": ("hp", 30.0),
    "mana_flow": ("attack_pct", 7.0),
    "tuning": ("attack_speed", 5.0),
    "void_presence": ("attack_pct", 6.0),
    "open_mind": ("crit_chance", 7.0),
    "elemental_symphony": ("attack_pct", 8.0),
}

# English descriptions aligned with stats
DESC_EN = {
    "armor_penetration": "Arrows ignore part of enemy armor, increasing damage by 8%.",
    "reflex_recoil": "Quick reflexes grant 5% Evasion.",
    "swift_execution": "Swift strikes deal 6% more damage.",
    "nimble_hands": "Reduces cooldown of all active skills by 15%.",
    "eagle_eye": "Eagle vision grants 6% Critical Chance.",
    "drawstring_tension": "Tensed bowstring increases Attack Speed by 12%.",
    "wearing_poison": "Poisoned arrows add 4 flat damage.",
    "weak_prey": "Hunter instinct adds 5% damage.",
    "stacking_impact": "Each impact lands harder, adding 7% damage.",
    "surgical_aim": "Precise aim grants 8% Critical Chance.",
    "blade_master": "Master of the blade adds 8 flat Physical Damage.",
    "extreme_sharpening": "Razor edge grants 6% Critical Chance.",
    "iron_armor": "Iron plating reduces physical damage taken by 10%.",
    "unbreakable_stance": "Unbreakable stance grants 8% Physical Resistance.",
    "precise_execution": "Precise strikes deal 8% more damage.",
    "iron_will": "Iron will increases Attack Speed by 10%.",
    "defensive_stance": "Defensive stance grants 8% Physical Resistance.",
    "brute_force": "Brute strength adds 7% damage.",
    "medium_resistance": "Medium armor reduces physical damage taken by 8%.",
    "steel_muscles": "Steel muscles increase max HP by 10%.",
    "shadow_reflexes": "Shadow reflexes grant 5% Critical Chance.",
    "adrenaline_surge": "Adrenaline surge increases Attack Speed by 8%. Killing an enemy resets 0.5s of skill cooldown.",
    "venomous_vein": "Venomous strikes add 12% Critical Damage.",
    "stealth_strike": "Stealth strikes add 10% Critical Damage.",
    "lethal_execution": "Lethal execution adds 8% damage.",
    "deep_cut": "Deep cuts add 4 flat damage.",
    "weak_point_mapping": "Weak point knowledge adds 8% damage.",
    "adrenaline": "Adrenaline rush increases Attack Speed by 5%. Killing an enemy resets 1s of skill cooldown.",
    "assassin_rhythm": "Assassin rhythm increases Attack Speed by 10%.",
    "light_blade": "Light blade adds 10% damage.",
    "sun_touch": "Solar vitality increases max HP by 35.",
    "reactive_barrier": "Reactive barrier increases max HP by 40.",
    "radiant_presence": "Radiant presence grants 8% Elemental Resistance.",
    "unshakable_devotion": "Unshakable devotion reduces skill cooldowns by 10%.",
    "divine_vigor": "Divine vigor increases max HP by 25.",
    "sacred_touch": "Sacred touch increases max HP by 25.",
    "critical_heal": "Critical prayer grants 5% Critical Chance.",
    "celestial_pact": "Celestial pact increases max HP by 50.",
    "protective_light": "Protective light grants 10% Physical Resistance.",
    "mercy": "Mercy increases max HP by 35.",
    "titanium_shell": "Titanium shell grants 5% Evasion.",
    "surface_thorns": "Thorned plating adds 5 flat damage.",
    "unshakable": "Unshakable body grants 6% Physical Resistance.",
    "impact_absorption": "Impact absorption increases max HP by 35.",
    "magic_alloy": "Magic alloy grants 8% Elemental Resistance.",
    "last_trench": "Last trench resolve increases max HP by 45.",
    "heavy_weight": "Heavy mace adds 5 flat damage.",
    "battle_inertia": "Battle inertia grants 6% Physical Resistance.",
    "hard_shell": "Hard shell grants 10% Physical Resistance.",
    "vital_crush": "Vital crush adds 7% mace skill damage.",
    "arcane_amplification": "Arcane amplification adds 6 Magic Damage.",
    "rune_resonance": "Each active skill cast grants 5% cooldown reduction for 3s (stacks up to 4 times).",
    "magic_penetration": "Magic penetration adds 8% spell damage.",
    "critical_focus": "Critical focus grants 8% magic Critical Chance.",
    "soul_drain": "Soul drain increases max HP by 30.",
    "mana_flow": "Mana flow adds 7% spell damage.",
    "tuning": "Arcane tuning increases cast speed by 5%.",
    "void_presence": "Void presence adds 6% spell damage.",
    "open_mind": "Open mind grants 7% Critical Chance.",
    "elemental_symphony": "Elemental symphony adds 8% spell damage.",
}

DESC_PT = {
    "armor_penetration": "Flechas ignoram parte da armadura inimiga, aumentando o dano em 8%.",
    "reflex_recoil": "Reflexos rapidos concedem 5% de Evasao.",
    "swift_execution": "Golpes rapidos causam 6% a mais de dano.",
    "nimble_hands": "Reduz o cooldown de todas as skills ativas em 15%.",
    "eagle_eye": "Visao de aguia concede 6% de Chance Critica.",
    "drawstring_tension": "Corda tensa aumenta a Velocidade de Ataque em 12%.",
    "wearing_poison": "Flechas envenenadas adicionam 4 de dano fixo.",
    "weak_prey": "Instinto de cacador adiciona 5% de dano.",
    "stacking_impact": "Cada impacto fica mais forte, adicionando 7% de dano.",
    "surgical_aim": "Mira precisa concede 8% de Chance Critica.",
    "blade_master": "Mestre da lamina adiciona 8 de Dano Fisico fixo.",
    "extreme_sharpening": "Fio afiado concede 6% de Chance Critica.",
    "iron_armor": "Placas de ferro reduzem dano fisico recebido em 10%.",
    "unbreakable_stance": "Postura inquebravel concede 8% de Resistencia Fisica.",
    "precise_execution": "Golpes precisos causam 8% a mais de dano.",
    "iron_will": "Vontade de ferro aumenta a Velocidade de Ataque em 10%.",
    "defensive_stance": "Postura defensiva concede 8% de Resistencia Fisica.",
    "brute_force": "Forca bruta adiciona 7% de dano.",
    "medium_resistance": "Armadura media reduz dano fisico recebido em 8%.",
    "steel_muscles": "Musculos de aco aumentam o HP maximo em 10%.",
    "shadow_reflexes": "Reflexos sombrios concedem 5% de Chance Critica.",
    "adrenaline_surge": "Surto de adrenalina aumenta a Velocidade de Ataque em 8%. Matar inimigo reduz 0,5s de cooldown.",
    "venomous_vein": "Golpes venenosos adicionam 12% de Dano Critico.",
    "stealth_strike": "Golpes furtivos adicionam 10% de Dano Critico.",
    "lethal_execution": "Execucao letal adiciona 8% de dano.",
    "deep_cut": "Cortes profundos adicionam 4 de dano fixo.",
    "weak_point_mapping": "Conhecimento de pontos fracos adiciona 8% de dano.",
    "adrenaline": "Adrenalina aumenta a Velocidade de Ataque em 5%. Matar inimigo reduz 1s de cooldown.",
    "assassin_rhythm": "Ritmo do assassino aumenta a Velocidade de Ataque em 10%.",
    "light_blade": "Lamina leve adiciona 10% de dano.",
    "sun_touch": "Vitalidade solar aumenta o HP maximo em 35.",
    "reactive_barrier": "Barreira reativa aumenta o HP maximo em 40.",
    "radiant_presence": "Presenca radiante concede 8% de Resistencia Elemental.",
    "unshakable_devotion": "Devocao inabalavel reduz cooldowns de skills em 10%.",
    "divine_vigor": "Vigor divino aumenta o HP maximo em 25.",
    "sacred_touch": "Toque sagrado aumenta o HP maximo em 25.",
    "critical_heal": "Oracao critica concede 5% de Chance Critica.",
    "celestial_pact": "Pacto celestial aumenta o HP maximo em 50.",
    "protective_light": "Luz protetora concede 10% de Resistencia Fisica.",
    "mercy": "Misericordia aumenta o HP maximo em 35.",
    "titanium_shell": "Casco de titanio concede 5% de Evasao.",
    "surface_thorns": "Placas espinhosas adicionam 5 de dano fixo.",
    "unshakable": "Corpo inabalavel concede 6% de Resistencia Fisica.",
    "impact_absorption": "Absorcao de impacto aumenta o HP maximo em 35.",
    "magic_alloy": "Liga magica concede 8% de Resistencia Elemental.",
    "last_trench": "Trincheira final aumenta o HP maximo em 45.",
    "heavy_weight": "Maça pesada adiciona 5 de dano fixo.",
    "battle_inertia": "Inercia de batalha concede 6% de Resistencia Fisica.",
    "hard_shell": "Casco duro concede 10% de Resistencia Fisica.",
    "vital_crush": "Esmagamento vital adiciona 7% de dano de maça.",
    "arcane_amplification": "Amplificacao arcana adiciona 6 de Dano Magico fixo.",
    "rune_resonance": "Cada skill ativa lancada concede 5% de reducao de cooldown por 3s (ate 4 stacks).",
    "magic_penetration": "Penetracao magica adiciona 8% de dano de feitico.",
    "critical_focus": "Foco critico concede 8% de Chance Critica magica.",
    "soul_drain": "Dreno de alma aumenta o HP maximo em 30.",
    "mana_flow": "Fluxo de mana adiciona 7% de dano de feitico.",
    "tuning": "Sintonia arcana aumenta a velocidade de conjuracao em 5%.",
    "void_presence": "Presenca do vazio adiciona 6% de dano de feitico.",
    "open_mind": "Mente aberta concede 7% de Chance Critica.",
    "elemental_symphony": "Sinfonia elemental adiciona 8% de dano de feitico.",
}


def update_tres(path: Path, stat_key: str, stat_value: float) -> None:
    text = path.read_text(encoding="utf-8")
    text = re.sub(r'stat_bonus_key = "[^"]*"', f'stat_bonus_key = "{stat_key}"', text)
    text = re.sub(r"stat_value = [\d.]+", f"stat_value = {stat_value}", text)
    path.write_text(text, encoding="utf-8")


def update_po(path: Path, descriptions: dict[str, str]) -> None:
    text = path.read_text(encoding="utf-8")
    for skill_id, desc in descriptions.items():
        msgid = f"SKILL_{skill_id}_DESC"
        pattern = rf'(msgid "{re.escape(msgid)}"\nmsgstr ")([^"]*)(")'
        replacement = rf'\1{desc}\3'
        new_text, count = re.subn(pattern, replacement, text)
        if count:
            text = new_text
        else:
            print(f"WARN missing {msgid} in {path.name}")
    path.write_text(text, encoding="utf-8")


def main() -> None:
    for class_dir in (ROOT / "data" / "skills").iterdir():
        if not class_dir.is_dir():
            continue
        for path in class_dir.glob("p*.tres"):
            skill_id_match = re.search(r'skill_id = "([^"]+)"', path.read_text(encoding="utf-8"))
            if not skill_id_match:
                continue
            skill_id = skill_id_match.group(1)
            if skill_id not in PASSIVE_STATS:
                print(f"SKIP {path}")
                continue
            stat_key, stat_value = PASSIVE_STATS[skill_id]
            update_tres(path, stat_key, stat_value)
            print(f"Updated passive {path.relative_to(ROOT)}")

    update_po(ROOT / "locales" / "en.po", DESC_EN)
    update_po(ROOT / "locales" / "pt_BR.po", DESC_PT)
    print("Updated locale descriptions")


if __name__ == "__main__":
    main()
