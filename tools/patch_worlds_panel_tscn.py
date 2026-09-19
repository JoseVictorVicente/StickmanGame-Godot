#!/usr/bin/env python3
"""Bake world buttons, difficulty options, and stage anchors in worlds_panel.tscn."""
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
PANEL = ROOT / "presentation" / "worlds" / "worlds_panel.tscn"

WORLDS = 5
DIFFICULTIES = 3
STAGES = 9


def replace_block(text: str, node_marker: str, new_block: str) -> str:
    start = text.find(node_marker)
    if start == -1:
        raise SystemExit(f"Node not found: {node_marker}")
    end = text.find("\n\n[node name=", start + 1)
    if end == -1:
        end = len(text)
    return text[:start] + new_block + text[end:]


def main() -> None:
    text = PANEL.read_text(encoding="utf-8")

    world_block = (
        '[node name="WorldList" type="VBoxContainer" parent="Camada/Conteudo/WorldListPanel"]\n'
        "unique_name_in_owner = true\n"
        "layout_mode = 2\n"
        "size_flags_vertical = 3\n"
        "theme_override_constants/separation = 4\n"
    )
    for i in range(1, WORLDS + 1):
        world_block += (
            f'\n[node name="WorldButton_{i}" type="Button" parent="Camada/Conteudo/WorldListPanel/WorldList"]\n'
            "layout_mode = 2\n"
            "size_flags_vertical = 3\n"
            "custom_minimum_size = Vector2(0, 42)\n"
            "theme_override_font_sizes/font_size = 16\n"
            f'text = "World {i}"\n'
        )
    text = replace_block(
        text,
        '[node name="WorldList" type="VBoxContainer" parent="Camada/Conteudo/WorldListPanel"]',
        world_block,
    )

    diff_block = (
        '[node name="DifficultyOptions" type="VBoxContainer" parent="Camada/DifficultyMenu"]\n'
        "unique_name_in_owner = true\n"
        "layout_mode = 2\n"
        "theme_override_constants/separation = 4\n"
    )
    for i in range(DIFFICULTIES):
        diff_block += (
            f'\n[node name="DifficultyOption_{i}" type="Button" parent="Camada/DifficultyMenu/DifficultyOptions"]\n'
            "layout_mode = 2\n"
            "size_flags_horizontal = 3\n"
            "custom_minimum_size = Vector2(0, 32)\n"
            "clip_text = true\n"
            "theme_override_font_sizes/font_size = 12\n"
            f'text = "Difficulty {i}"\n'
        )
    text = replace_block(
        text,
        '[node name="DifficultyOptions" type="VBoxContainer" parent="Camada/DifficultyMenu"]',
        diff_block,
    )

    # Insert stage anchors before MapBackground inside StageMap
    map_bg_marker = '[node name="MapBackground" type="TextureRect" parent="Camada/Conteudo/PanelStageMap/StageMap"]'
    map_bg_pos = text.find(map_bg_marker)
    if map_bg_pos == -1:
        raise SystemExit("MapBackground not found")
    stage_nodes = ""
    for i in range(1, STAGES + 1):
        boss = i == STAGES
        size = 48 if boss else 34
        stage_nodes += (
            f'\n[node name="StageAnchor_{i}" type="Control" parent="Camada/Conteudo/PanelStageMap/StageMap"]\n'
            "layout_mode = 0\n"
            "mouse_filter = 2\n"
            f'\n[node name="StageButton" type="TextureButton" parent="Camada/Conteudo/PanelStageMap/StageMap/StageAnchor_{i}"]\n'
            "layout_mode = 0\n"
            f"custom_minimum_size = Vector2({size}, {size})\n"
            "focus_mode = 0\n"
            "ignore_texture_size = true\n"
            "stretch_mode = 5\n"
            f'\n[node name="StageLabel" type="Label" parent="Camada/Conteudo/PanelStageMap/StageMap/StageAnchor_{i}/StageButton"]\n'
            "layout_mode = 1\n"
            "anchors_preset = 15\n"
            "anchor_right = 1.0\n"
            "anchor_bottom = 1.0\n"
            "grow_horizontal = 2\n"
            "grow_vertical = 2\n"
            f"theme_override_font_sizes/font_size = {10 if boss else 9}\n"
            'theme_override_colors/font_color = Color(0.95, 0.88, 0.7, 1)\n'
            "mouse_filter = 2\n"
            "horizontal_alignment = 1\n"
            "vertical_alignment = 1\n"
            f'text = "{i}"\n'
        )
    text = text[:map_bg_pos] + stage_nodes + "\n" + text[map_bg_pos:]

    PANEL.write_text(text, encoding="utf-8")
    print(f"Patched {PANEL}")


if __name__ == "__main__":
    main()
