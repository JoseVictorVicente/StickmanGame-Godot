#!/usr/bin/env python3
"""Extract hero_section, inventory_row, bottom_nav from inventory_menu.tscn."""
from __future__ import annotations

import re
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
MENU = ROOT / "presentation/inventory/inventory_menu.tscn"
INV = ROOT / "presentation/inventory"

# Sub-resources needed by hub prefabs (ids from menu file)
SHARED_SUBS = [
    "StyleBoxFlat_botao_sair_jogo",
    "StyleBoxFlat_botao_pressed",
    "StyleBoxFlat_botao_hover",
    "StyleBoxFlat_botao",
    "StyleBoxFlat_ouro",
    "StyleBoxFlat_slot_skill",
    "StyleBoxFlat_foto",
    "StyleBoxFlat_xp_bg",
    "StyleBoxFlat_xp_fill",
    "StyleBoxFlat_character_tab",
]

EXT_FOR_HERO = [
    ('type="Texture2D" uid="uid://c74n55kpxkj17" path="res://sprites/heroes/px_warrior2.jpg"', "5_ao6jx"),
    ('type="PackedScene" uid="uid://c8equipleft1" path="res://presentation/inventory/equipment_grid_left.tscn"', "14_equip_left"),
    ('type="PackedScene" uid="uid://c8equipright1" path="res://presentation/inventory/equipment_grid_right.tscn"', "14_equip_right"),
    ('type="PackedScene" uid="uid://c8partybtn01" path="res://presentation/inventory/party_hero_slot_button.tscn"', "15_partybtn"),
    ('type="Script" uid="uid://u7nsljsgk78f" path="res://presentation/inventory/team_selection_ui.gd"', "2_equipe"),
    ('type="Script" path="res://presentation/inventory/hero_section.gd"', "1_hero"),
]

EXT_FOR_ROW = [
    ('type="PackedScene" uid="uid://c8invslots01" path="res://presentation/inventory/inventory_slots_grid.tscn"', "13_invslots"),
    ('type="Texture2D" uid="uid://c5o34g0lmphl5" path="res://sprites/ui/chest.png"', "9_x8cif"),
    ('type="Script" path="res://presentation/inventory/inventory_row.gd"', "1_row"),
]

EXT_FOR_NAV = [
    ('type="Texture2D" uid="uid://bnc8n5u3bvfvp" path="res://sprites/ui/nav_skills.png"', "10_8b33j"),
    ('type="Texture2D" uid="uid://dpbh05jiuntra" path="res://sprites/ui/nav_inventory.png"', "11_oay6y"),
    ('type="Texture2D" uid="uid://bsehtefuj1pxn" path="res://sprites/ui/nav_forge.png"', "12_p1355"),
    ('type="Texture2D" uid="uid://dw0jgemm34bg" path="res://sprites/ui/nav_world.png"', "13_ss3w7"),
    ('type="Script" path="res://presentation/inventory/bottom_nav.gd"', "1_nav"),
]


def load_menu() -> str:
    return MENU.read_text(encoding="utf-8")


def extract_sub_resources(text: str, names: list[str]) -> str:
    blocks: list[str] = []
    for name in names:
        pattern = rf"(\[sub_resource type=\"[^\]]+\" id=\"{name}\"\][\s\S]*?)(?=\n\n\[)"
        m = re.search(pattern, text)
        if m:
            blocks.append(m.group(1).rstrip())
    return "\n\n".join(blocks)


def extract_node_block(text: str, node_name: str) -> str:
    """Extract node and all descendants by matching parent paths."""
    base = f'[node name="{node_name}"'
    start = text.find(base)
    if start < 0:
        raise SystemExit(f"Node {node_name} not found")
    # Find next sibling at same parent level under Conteudo (Header, AreaHeroi, Linha..., MenuInferior)
    rest = text[start:]
    # End at next [node under Conteudo that's not a descendant
    parent_prefix = None
    lines = rest.splitlines()
    out = [lines[0]]
    i = 1
    root_parent = ""
    m = re.search(r'parent="([^"]*)"', lines[0])
    if m:
        root_parent = m.group(1)
    while i < len(lines):
        line = lines[i]
        if line.startswith("[node ") and not line.startswith(f'[node name="{node_name}"'):
            m2 = re.search(r'parent="([^"]*)"', line)
            if m2:
                p = m2.group(1)
                if not p.startswith(root_parent + "/" + node_name) and p != root_parent + "/" + node_name:
                    if p == root_parent or (root_parent and p.count("/") <= root_parent.count("/") + 0 and node_name not in p):
                        break
        out.append(line)
        i += 1
    return "\n".join(out)


def rewrite_parents(block: str, old_prefix: str, new_prefix: str) -> str:
    block = block.replace(f'parent="{old_prefix}"', f'parent="{new_prefix}"')
    block = block.replace(f'parent="{old_prefix}/', f'parent="{new_prefix}/')
    return block


def build_scene(
    path: Path,
    root_name: str,
    root_type: str,
    script_id: str,
    ext_lines: list[tuple[str, str]],
    subs: str,
    node_block: str,
    old_root: str,
) -> None:
    ext_count = len(ext_lines) + 1
    load_steps = ext_count + (1 if subs else 0)
    parts = [f'[gd_scene load_steps={load_steps} format=3 uid="uid://{root_name.lower()}01"]', ""]
    parts.append(f'[ext_resource type="Script" path="res://presentation/inventory/{root_name.lower()}.gd" id="{script_id}"]')
    for spec, eid in ext_lines:
        parts.append(f"[ext_resource {spec} id=\"{eid}\"]")
    if subs:
        parts.append("")
        parts.append(subs)
    parts.append("")
    root_line = (
        f'[node name="{root_name}" type="{root_type}"]\n'
        "unique_name_in_owner = true\n"
        "layout_mode = 2\n"
        f'script = ExtResource("{script_id}")'
    )
    if root_name == "HeroSection":
        root_line += "\nsize_flags_vertical = 0\ntheme_override_constants/separation = 6\nalignment = 1"
    elif root_name == "InventoryRow":
        root_line += (
            "\ncustom_minimum_size = Vector2(486, 202)\n"
            "size_flags_horizontal = 4\nsize_flags_vertical = 0\n"
            "theme_override_constants/separation = 6\nalignment = 1"
        )
    elif root_name == "BottomNav":
        root_line += (
            "\ncustom_minimum_size = Vector2(0, 34)\n"
            "size_flags_horizontal = 3\nsize_flags_vertical = 0\n"
            "theme_override_constants/separation = 4"
        )
    parts.append(root_line)
    inner = rewrite_parents(node_block, old_root, ".")
    # Drop first line (old root) — children only
    inner_lines = inner.splitlines()
    child_lines = []
    skip_root = True
    for line in inner_lines:
        if skip_root and line.startswith(f'[node name="{old_root.split("/")[-1]}"'):
            skip_root = False
            continue
        if not skip_root:
            child_lines.append(line)
    parts.append("\n".join(child_lines))
    path.write_text("\n".join(parts) + "\n", encoding="utf-8")
    print(f"Wrote {path}")


def patch_menu(text: str) -> str:
    text = re.sub(
        r'\[ext_resource type="Script" uid="uid://daiy8cb6blmv"[^\n]+\n',
        "",
        text,
    )
    text = re.sub(
        r'\[ext_resource type="PackedScene" uid="uid://c8equipgrid1"[^\n]+\n',
        "",
        text,
    )
    text = re.sub(
        r'\n\[node name="EditorPreviewHost"[^\]]*\][\s\S]*?script = ExtResource\("16_preview_host"\)\n',
        "\n",
        text,
    )
    # Add new ext resources after party btn
    insert = (
        '[ext_resource type="PackedScene" path="res://presentation/inventory/hero_section.tscn" id="18_hero"]\n'
        '[ext_resource type="PackedScene" path="res://presentation/inventory/inventory_row.tscn" id="19_row"]\n'
        '[ext_resource type="PackedScene" path="res://presentation/inventory/bottom_nav.tscn" id="20_nav"]\n'
    )
    text = text.replace(
        '[ext_resource type="PackedScene" uid="uid://c8partybtn01"',
        insert + '[ext_resource type="PackedScene" uid="uid://c8partybtn01"',
        1,
    )
    # Remove old hero/row/nav blocks - replace with instances
    for section, inst_id, uname in [
        ("AreaHeroi", "18_hero", "HeroSection"),
        ("LinhaInventario", "19_row", "InventoryRow"),
        ("MenuInferior", "20_nav", "BottomNav"),
    ]:
        block = extract_node_block(text, section)
        replacement = (
            f'\n[node name="{uname}" parent="CenterAnchor/MenuArea/Panel/Conteudo" instance=ExtResource("{inst_id}")]\n'
            "unique_name_in_owner = true\n"
            "layout_mode = 2\n"
        )
        text = text.replace(block, replacement, 1)
    # Remove unused ext resources from menu (invslots, chest nav icons if only in row)
    return text


def main() -> None:
    text = load_menu()
    subs = extract_sub_resources(text, SHARED_SUBS)

    hero_block = extract_node_block(text, "AreaHeroi")
    hero_block = hero_block.replace("EquipLeft_warrior", "EquipLeftWarrior")
    hero_block = hero_block.replace("EquipRight_warrior", "EquipRightWarrior")
    hero_block = hero_block.replace('instance=ExtResource("14_equipgrid")', 'instance=ExtResource("14_equip_left")', 1)
    hero_block = hero_block.replace('instance=ExtResource("14_equipgrid")', 'instance=ExtResource("14_equip_right")', 1)

    row_block = extract_node_block(text, "LinhaInventario")
    nav_block = extract_node_block(text, "MenuInferior")

    build_scene(
        INV / "hero_section.tscn",
        "HeroSection",
        "HBoxContainer",
        "1_hero",
        EXT_FOR_HERO[1:],
        subs,
        hero_block,
        "CenterAnchor/MenuArea/Panel/Conteudo/AreaHeroi",
    )
    # Fix hero ext - script is separate
    hero_text = (INV / "hero_section.tscn").read_text(encoding="utf-8")
    hero_text = hero_text.replace("load_steps=6", "load_steps=7")
    (INV / "hero_section.tscn").write_text(hero_text, encoding="utf-8")

    row_subs = extract_sub_resources(text, ["StyleBoxFlat_botao"])
    build_scene(
        INV / "inventory_row.tscn",
        "InventoryRow",
        "HBoxContainer",
        "1_row",
        EXT_FOR_ROW[1:],
        row_subs,
        row_block,
        "CenterAnchor/MenuArea/Panel/Conteudo/LinhaInventario",
    )
    build_scene(
        INV / "bottom_nav.tscn",
        "BottomNav",
        "HBoxContainer",
        "1_nav",
        EXT_FOR_NAV[1:],
        extract_sub_resources(text, ["StyleBoxFlat_botao"]),
        nav_block,
        "CenterAnchor/MenuArea/Panel/Conteudo/MenuInferior",
    )

    MENU.write_text(patch_menu(text), encoding="utf-8")
    print(f"Patched {MENU}")


if __name__ == "__main__":
    main()
