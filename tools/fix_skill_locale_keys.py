#!/usr/bin/env python3
"""Fix skill .tres name_key/description_key to canonical EN locale keys."""
from __future__ import annotations

import re
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]

SKILL_IDS = {
    "absorcao_no_impacto": "impact_absorption",
    "adrenalina": "adrenaline",
    "afiacao_extrema": "extreme_sharpening",
    "amplificacao_arcana": "arcane_amplification",
    "armadura_de_ferro": "iron_armor",
    "ataque_furtivo": "stealth_strike",
    "aura_de_inviolabilidade": "inviolability_aura",
    "barreira_de_runas": "rune_barrier",
    "barreira_reativa": "reactive_barrier",
    "bola_de_fogo_negra": "black_fireball",
    "caca_aos_fracos": "weak_prey",
    "casca_de_titanio": "titanium_shell",
    "casca_dura": "hard_shell",
    "cordeiro_esticado": "drawstring_tension",
    "corte_duplo_executor": "twin_execution_cut",
    "corte_duplo_rapido": "quick_twin_cut",
    "corte_profundo": "deep_cut",
    "corte_rapido": "quick_slash",
    "cura_critica": "critical_heal",
    "decaptacao_celerada": "swift_decapitation",
    "devocao_inabalavel": "unshakable_devotion",
    "dreno_de_alma": "soul_drain",
    "escudo_solar": "solar_shield",
    "esmagamento_vital": "vital_crush",
    "espinhos_da_superficie": "surface_thorns",
    "execucao_acelerada": "swift_execution",
    "execucao_precisa": "precise_execution",
    "fervor_sagrado": "sacred_fervor",
    "fluxo_de_mana": "mana_flow",
    "foco_critico": "critical_focus",
    "forca_bruta": "brute_force",
    "grito_de_guerra": "war_cry",
    "impacto_acumulativo": "stacking_impact",
    "impulso_de_adrenalina": "adrenaline_surge",
    "inabalavel": "unshakable",
    "inercia_de_batalha": "battle_inertia",
    "lamina_leve": "light_blade",
    "lamina_pesada": "heavy_blade",
    "lanca_de_gelo": "ice_lance",
    "liga_magica": "magic_alloy",
    "luz_protetora": "protective_light",
    "maos_ageis": "nimble_hands",
    "mapeamento_de_pontos_frais": "weak_point_mapping",
    "marca_da_presa": "prey_mark",
    "mente_aberta": "open_mind",
    "mestre_das_laminas": "blade_master",
    "meteoro_abissal": "abyssal_meteor",
    "mira_cirurgica": "surgical_aim",
    "misericordia": "mercy",
    "moinho_esmagador": "crushing_mill",
    "musculos_de_aco": "steel_muscles",
    "nova_de_gelo": "ice_nova",
    "olho_de_aguia": "eagle_eye",
    "pacto_celestial": "celestial_pact",
    "penetracao_de_armadura": "armor_penetration",
    "penetracao_magica": "magic_penetration",
    "perfuracao_dupla": "double_thrust",
    "peso_pesado": "heavy_weight",
    "portal_de_dano": "damage_portal",
    "posicao_sagrada": "sacred_position",
    "postura_de_defesa": "defensive_stance",
    "postura_do_cacador": "hunter_stance",
    "postura_inquebravel": "unbreakable_stance",
    "postura_inviolavel": "inviolable_stance",
    "presenca_do_vazio": "void_presence",
    "presenca_iluminada": "radiant_presence",
    "provocacao_sombria": "dark_taunt",
    "punicao_divina": "divine_punishment",
    "recuo_reflexo": "reflex_recoil",
    "reflexos_sombrios": "shadow_reflexes",
    "resistencia_media": "medium_resistance",
    "ressoar_de_runas": "rune_resonance",
    "ritmo_assassino": "assassin_rhythm",
    "sequencia_desperta": "awakened_sequence",
    "sequencia_frenetica": "frenzied_sequence",
    "sinfonia_elementar": "elemental_symphony",
    "sintonizacao": "tuning",
    "supressao_total": "total_suppression",
    "tiro_de_precisao": "precision_shot",
    "tiro_duplo_instantaneo": "instant_double_shot",
    "toque_do_sol": "sun_touch",
    "toque_sagrado": "sacred_touch",
    "ultima_trincheira": "last_trench",
    "veia_venenosa": "venomous_vein",
    "veneno_desgastante": "wearing_poison",
    "vigor_divino": "divine_vigor",
    "visao_neon": "neon_vision",
    "volley_sombrio": "dark_volley",
    "vontade_de_ferro": "iron_will",
    "execucao_letal": "lethal_execution",
}


def canonical(skill_id: str) -> str:
    return SKILL_IDS.get(skill_id, skill_id)


def main() -> None:
    for path in (ROOT / "data" / "skills").rglob("*.tres"):
        text = path.read_text(encoding="utf-8")
        match = re.search(r'skill_id = "([^"]+)"', text)
        if not match:
            continue
        skill_id = match.group(1)
        canon = canonical(skill_id)
        text = re.sub(r'name_key = "[^"]*"', f'name_key = "SKILL_{canon}"', text)
        text = re.sub(r'description_key = "[^"]*"', f'description_key = "SKILL_{canon}_DESC"', text)
        path.write_text(text, encoding="utf-8")
        if canon != skill_id:
            print(f"Locale keys {path.name}: {skill_id} -> {canon}")


if __name__ == "__main__":
    main()
