#!/usr/bin/env python3
"""Update active skill MVP descriptions in locale files."""
from __future__ import annotations

import re
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]

ACTIVE_DESC_EN = {
    "frenzied_sequence": "Three rapid sword strikes dealing full damage each.",
    "quick_slash": "A fast horizontal slash dealing standard damage.",
    "double_thrust": "Two ultra-fast thrusts, each dealing full damage.",
    "heavy_blade": "A slow heavy strike dealing double damage.",
    "war_cry": "War cry boosts Physical Damage by 20% for 5 seconds.",
    "twin_execution_cut": "Cross slash hitting twice for full damage.",
    "prey_mark": "Marked prey takes 30% bonus burst damage.",
    "quick_twin_cut": "Two ultra-fast cross strikes.",
    "awakened_sequence": "Awakened rhythm grants 60% Attack Speed for 3 seconds.",
    "swift_decapitation": "Neck strike dealing 50% bonus damage.",
    "sacred_position": "Restores 15% max HP to the lowest-HP ally.",
    "solar_shield": "Solar light restores 12% max HP to the lowest-HP ally.",
    "divine_punishment": "Divine beam dealing 50% bonus damage.",
    "inviolability_aura": "Heals party for 8% max HP and grants 15% Physical Resistance for 1.5s.",
    "sacred_fervor": "Sacred fervor grants all allies 15% damage for 4 seconds.",
    "rune_barrier": "Rune barrier increases max HP by 25% for 4 seconds.",
    "dark_taunt": "Dark taunt sustains the tank, restoring 15% max HP.",
    "inviolable_stance": "Inviolable stance grants 100% Physical Resistance for 2.5 seconds.",
    "total_suppression": "Shield slam dealing 30% bonus area damage.",
    "crushing_mill": "Three fast mace strikes at 90% damage each.",
    "abyssal_meteor": "Abyssal meteor deals double damage.",
    "damage_portal": "Damage portal fires 5 magical hits at 40% damage each.",
    "black_fireball": "Black fireball deals 50% bonus area damage.",
    "ice_nova": "Ice nova wave deals 20% bonus damage.",
    "ice_lance": "Ice lance pierces twice for full damage each.",
    "instant_double_shot": "Two instant shots, both guaranteed critical hits.",
    "dark_volley": "Dark volley fires 5 arrows at 40% damage each.",
    "precision_shot": "Precision shot: 50% bonus damage, guaranteed crit, 30% armor pen.",
    "hunter_stance": "Hunter stance: +30% Attack Speed and +10% damage for 3.5 seconds.",
    "neon_vision": "Neon vision grants 30% Critical Chance for 4 seconds.",
    "arcane_heal": "Arcane heal restores 20% max HP to the entire party.",
}

ACTIVE_DESC_PT = {
    "frenzied_sequence": "Tres golpes rapidos de espada causando dano total cada.",
    "quick_slash": "Corte horizontal rapido causando dano padrao.",
    "double_thrust": "Dois thrusts ultra-rapidos, cada um com dano total.",
    "heavy_blade": "Golpe pesado lento causando dano dobrado.",
    "war_cry": "Grito de guerra aumenta Dano Fisico em 20% por 5 segundos.",
    "twin_execution_cut": "Corte em cruz atingindo duas vezes com dano total.",
    "prey_mark": "Presa marcada recebe 30% de dano burst bonus.",
    "quick_twin_cut": "Dois golpes cruzados ultra-rapidos.",
    "awakened_sequence": "Ritmo despertado concede 60% de Velocidade de Ataque por 3 segundos.",
    "swift_decapitation": "Golpe no pescoco causando 50% de dano bonus.",
    "sacred_position": "Restaura 15% do HP maximo do aliado com menos vida.",
    "solar_shield": "Luz solar restaura 12% do HP maximo do aliado com menos vida.",
    "divine_punishment": "Feixe divino causando 50% de dano bonus.",
    "inviolability_aura": "Cura grupo em 8% HP max e concede 15% Resistencia Fisica por 1,5s.",
    "sacred_fervor": "Fervor sagrado concede 15% de dano a todos os aliados por 4 segundos.",
    "rune_barrier": "Barreira de runas aumenta HP maximo em 25% por 4 segundos.",
    "dark_taunt": "Provocacao sombria sustenta o tank, restaurando 15% do HP maximo.",
    "inviolable_stance": "Postura inviolavel concede 100% de Resistencia Fisica por 2,5 segundos.",
    "total_suppression": "Golpe de escudo causando 30% de dano bonus em area.",
    "crushing_mill": "Tres golpes rapidos de maca a 90% de dano cada.",
    "abyssal_meteor": "Meteoro abissal causa dano dobrado.",
    "damage_portal": "Portal de dano dispara 5 hits magicos a 40% de dano cada.",
    "black_fireball": "Bola de fogo negra causa 50% de dano bonus em area.",
    "ice_nova": "Onda de gelo causa 20% de dano bonus.",
    "ice_lance": "Lanca de gelo perfura duas vezes com dano total cada.",
    "instant_double_shot": "Dois tiros instantaneos, ambos criticos garantidos.",
    "dark_volley": "Volley sombrio dispara 5 flechas a 40% de dano cada.",
    "precision_shot": "Tiro de precisao: 50% dano bonus, critico garantido, 30% pen de armadura.",
    "hunter_stance": "Postura do cacador: +30% Velocidade de Ataque e +10% dano por 3,5 segundos.",
    "neon_vision": "Visao neon concede 30% de Chance Critica por 4 segundos.",
    "arcane_heal": "Cura arcana restaura 20% do HP maximo de todo o grupo.",
}


def update_po(path: Path, descriptions: dict[str, str]) -> None:
    text = path.read_text(encoding="utf-8")
    for canon, desc in descriptions.items():
        msgid = f"SKILL_{canon}_DESC"
        pattern = rf'(msgid "{re.escape(msgid)}"\nmsgstr ")([^"]*)(")'
        new_text, count = re.subn(pattern, rf"\1{desc}\3", text)
        if count:
            text = new_text
        else:
            insert = f'\nmsgid "{msgid}"\nmsgstr "{desc}"\n'
            text += insert
            print(f"Added {msgid} to {path.name}")
    path.write_text(text, encoding="utf-8")


def main() -> None:
    update_po(ROOT / "locales" / "en.po", ACTIVE_DESC_EN)
    update_po(ROOT / "locales" / "pt_BR.po", ACTIVE_DESC_PT)
    print("Active skill locale descriptions updated")


if __name__ == "__main__":
    main()
