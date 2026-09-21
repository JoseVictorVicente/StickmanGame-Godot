#!/usr/bin/env python3
"""Replace inline hub sections in inventory_menu.tscn with prefab instances."""
from pathlib import Path

MENU = Path(__file__).resolve().parents[1] / "presentation/inventory/inventory_menu.tscn"


def replace_section(lines: list[str], start_name: str, stop_name: str, replacement_lines: list[str]) -> list[str]:
    out: list[str] = []
    i = 0
    while i < len(lines):
        line = lines[i]
        if line.startswith(f'[node name="{start_name}"'):
            out.extend(replacement_lines)
            i += 1
            while i < len(lines):
                nxt = lines[i]
                if nxt.startswith(f'[node name="{stop_name}"'):
                    break
                i += 1
            continue
        out.append(line)
        i += 1
    return out


def main() -> None:
    text = MENU.read_text(encoding="utf-8")
    if 'id="18_hero"' not in text:
        text = text.replace(
            '[ext_resource type="Resource" uid="uid://layoutinv001"',
            '[ext_resource type="PackedScene" path="res://presentation/inventory/hero_section.tscn" id="18_hero"]\n'
            '[ext_resource type="PackedScene" path="res://presentation/inventory/inventory_row.tscn" id="19_row"]\n'
            '[ext_resource type="PackedScene" path="res://presentation/inventory/bottom_nav.tscn" id="20_nav"]\n'
            '[ext_resource type="Resource" uid="uid://layoutinv001"',
            1,
        )
    lines = text.splitlines(keepends=True)
    hero = [
        '[node name="AreaHeroi" parent="CenterAnchor/MenuArea/Panel/Conteudo" instance=ExtResource("18_hero")]\n',
        "unique_name_in_owner = true\n",
        "layout_mode = 2\n",
        "\n",
    ]
    row = [
        '[node name="LinhaInventario" parent="CenterAnchor/MenuArea/Panel/Conteudo" instance=ExtResource("19_row")]\n',
        "unique_name_in_owner = true\n",
        "layout_mode = 2\n",
        "\n",
    ]
    nav = [
        '[node name="MenuInferior" parent="CenterAnchor/MenuArea/Panel/Conteudo" instance=ExtResource("20_nav")]\n',
        "unique_name_in_owner = true\n",
        "layout_mode = 2\n",
        "\n",
    ]
    lines = replace_section(lines, "AreaHeroi", "LinhaInventario", hero)
    lines = replace_section(lines, "LinhaInventario", "MenuInferior", row)
    lines = replace_section(lines, "MenuInferior", "WarehousePanel", nav)
    MENU.write_text("".join(lines), encoding="utf-8")
    print(f"Patched {MENU} ({sum(1 for _ in open(MENU, encoding='utf-8'))} lines)")


if __name__ == "__main__":
    main()
