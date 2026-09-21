#!/usr/bin/env python3
"""Patch skills_panel.tscn: bake hero slots + instance skill grids."""
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
PANEL = ROOT / "presentation" / "inventory" / "skills_panel.tscn"

ACTIVE_GRID_PATH = "Conteudo/SkillsPanelCorpo/RolagemSkills/ConteudoSkills/ActiveSkillsSection/CentralAtivas/ActiveGrid"
PASSIVE_GRID_PATH = "Conteudo/SkillsPanelCorpo/RolagemSkills/ConteudoSkills/PassiveSkillsSection/CentralPassivas/PassiveGrid"
HERO_SLOTS_PATH = "Conteudo/HeroSkillSlots"

EXT_LINES = [
    '[ext_resource type="PackedScene" path="res://presentation/inventory/skills_active_grid.tscn" id="20_active_grid"]',
    '[ext_resource type="PackedScene" path="res://presentation/inventory/skills_passive_grid.tscn" id="21_passive_grid"]',
    '[ext_resource type="PackedScene" uid="uid://c8partybtn01" path="res://presentation/inventory/party_hero_slot_button.tscn" id="22_hero_btn"]',
]


def replace_node_block(text: str, node_name: str, parent_suffix: str, new_block: str) -> str:
    marker = f'[node name="{node_name}" type="GridContainer" parent="{parent_suffix}"'
    start = text.find(marker)
    if start == -1:
        raise SystemExit(f"Node not found: {node_name}")
    end = text.find("\n\n[node name=", start + 1)
    if end == -1:
        end = len(text)
    return text[:start] + new_block + text[end:]


def main() -> None:
    text = PANEL.read_text(encoding="utf-8")
    if "skills_active_grid.tscn" not in text:
        insert_at = text.find("[sub_resource type=")
        text = text[:insert_at] + "\n".join(EXT_LINES) + "\n\n" + text[insert_at:]
        text = text.replace("load_steps=2", "load_steps=5", 1)

    active_block = (
        f'[node name="ActiveGrid" parent="{ACTIVE_GRID_PATH.rsplit("/", 1)[0]}" instance=ExtResource("20_active_grid")]\n'
        "unique_name_in_owner = true\n"
        "layout_mode = 2\n"
    )
    text = replace_node_block(
        text,
        "ActiveGrid",
        "Conteudo/SkillsPanelCorpo/RolagemSkills/ConteudoSkills/ActiveSkillsSection/CentralAtivas",
        active_block,
    )

    passive_block = (
        f'[node name="PassiveGrid" parent="{PASSIVE_GRID_PATH.rsplit("/", 1)[0]}" instance=ExtResource("21_passive_grid")]\n'
        "unique_name_in_owner = true\n"
        "layout_mode = 2\n"
    )
    text = replace_node_block(
        text,
        "PassiveGrid",
        "Conteudo/SkillsPanelCorpo/RolagemSkills/ConteudoSkills/PassiveSkillsSection/CentralPassivas",
        passive_block,
    )

    hero_marker = f'[node name="HeroSkillSlots" type="HBoxContainer" parent="Conteudo"]'
    hero_start = text.find(hero_marker)
    hero_end = text.find("\n\n[node name=", hero_start + 1)
    hero_children = ""
    for i in range(3):
        hero_children += (
            f'\n[node name="HeroSkillSlot{i}" parent="{HERO_SLOTS_PATH}" instance=ExtResource("22_hero_btn")]\n'
            f"unique_name_in_owner = true\n"
            f"layout_mode = 2\n"
            f"custom_minimum_size = Vector2(72, 82)\n"
            f"visible = false\n"
        )
    hero_block = (
        '[node name="HeroSkillSlots" type="HBoxContainer" parent="Conteudo"]\n'
        "unique_name_in_owner = true\n"
        "layout_mode = 2\n"
        "theme_override_constants/separation = 8\n"
        "alignment = 1"
        + hero_children
        + "\n"
    )
    text = text[:hero_start] + hero_block + text[hero_end:]

    PANEL.write_text(text, encoding="utf-8")
    print(f"Patched {PANEL}")


if __name__ == "__main__":
    main()
