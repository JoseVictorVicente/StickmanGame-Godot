#!/usr/bin/env python3
"""Extract hub prefabs from inventory_menu.tscn and patch menu to use instances."""
from __future__ import annotations

import re
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
MENU = ROOT / "presentation/inventory/inventory_menu.tscn"
INV = ROOT / "presentation/inventory"

OLD_HERO = "CenterAnchor/MenuArea/Panel/Conteudo/AreaHeroi"
OLD_ROW = "CenterAnchor/MenuArea/Panel/Conteudo/LinhaInventario"
OLD_NAV = "CenterAnchor/MenuArea/Panel/Conteudo/MenuInferior"


def extract_section(text: str, section_name: str, stop_names: list[str]) -> str:
    marker = f'[node name="{section_name}" type='
    start = text.find(marker)
    if start < 0:
        raise SystemExit(f"Missing section {section_name}")
    chunk = text[start:]
    lines = chunk.splitlines()
    out = [lines[0]]
    for line in lines[1:]:
        if line.startswith("[node ") and line.startswith('[node name="') and not line.startswith(f'[node name="{section_name}"'):
            nm = re.search(r'\[node name="([^"]+)"', line)
            parent = re.search(r'parent="([^"]*)"', line)
            if nm and parent:
                pname = parent.group(1)
                if pname == OLD_HERO.replace(f"/{section_name}", "").replace(section_name, OLD_HERO.split("/")[-2] + "/" + section_name):
                    pass
                # stop at sibling under Conteudo
                if parent.group(1) == "CenterAnchor/MenuArea/Panel/Conteudo":
                    if nm.group(1) in stop_names:
                        break
        out.append(line)
    return "\n".join(out)


def collect_subs(text: str, ids: list[str]) -> str:
    parts = []
    for sid in ids:
        m = re.search(
            rf'(\[sub_resource type="[^"]+" id="{sid}"\][\s\S]*?)(?=\n\n\[)',
            text,
        )
        if m:
            parts.append(m.group(1).strip())
    return "\n\n".join(parts)


def remap_block(block: str, old_base: str, new_base: str) -> str:
    block = block.replace(f'parent="{old_base}"', f'parent="{new_base}"')
    block = block.replace(f'parent="{old_base}/', f'parent="{new_base}/')
    return block


def child_nodes_only(block: str, root_name: str) -> str:
    lines = block.splitlines()
    out: list[str] = []
    past_root = False
    for line in lines:
        if line.startswith(f'[node name="{root_name}"'):
            past_root = True
            continue
        if past_root:
            out.append(line)
    return "\n".join(out)


def write_prefab(
    path: Path,
    uid: str,
    root_name: str,
    root_type: str,
    script: str,
    ext_resources: list[str],
    sub_resources: str,
    root_props: str,
    inner_block: str,
) -> None:
    load_steps = 1 + len(ext_resources) + (1 if sub_resources else 0)
    lines = [f'[gd_scene load_steps={load_steps} format=3 uid="{uid}"]', ""]
    lines.append(f'[ext_resource type="Script" path="res://presentation/inventory/{script}" id="1_script"]')
    for i, ext in enumerate(ext_resources, start=2):
        lines.append(f"[ext_resource {ext} id=\"{i}_ext\"]")
    if sub_resources:
        lines.append("")
        lines.append(sub_resources)
    lines.append("")
    lines.append(f'[node name="{root_name}" type="{root_type}"]')
    lines.append("unique_name_in_owner = true")
    lines.append(root_props)
    lines.append('script = ExtResource("1_script")')
    lines.append(inner_block)
    path.write_text("\n".join(lines) + "\n", encoding="utf-8")
    print("Wrote", path)


def main() -> None:
    text = MENU.read_text(encoding="utf-8")
    subs = collect_subs(
        text,
        [
            "StyleBoxFlat_botao",
            "StyleBoxFlat_botao_pressed",
            "StyleBoxFlat_botao_hover",
            "StyleBoxFlat_ouro",
            "StyleBoxFlat_slot_skill",
            "StyleBoxFlat_foto",
            "StyleBoxFlat_xp_bg",
            "StyleBoxFlat_xp_fill",
            "StyleBoxFlat_character_tab",
        ],
    )

    hero_block = extract_section(text, "AreaHeroi", ["LinhaInventario", "MenuInferior"])
    hero_block = remap_block(hero_block, OLD_HERO, "HeroSection")
    hero_block = hero_block.replace("AreaHeroi", "HeroSection", 1)
    hero_block = hero_block.replace("EquipLeft_warrior", "EquipLeftWarrior")
    hero_block = hero_block.replace("EquipRight_warrior", "EquipRightWarrior")
    hero_block = hero_block.replace(
        'instance=ExtResource("14_equipgrid")',
        'instance=ExtResource("2_ext")',
        1,
    )
    hero_block = hero_block.replace(
        'instance=ExtResource("14_equipgrid")',
        'instance=ExtResource("3_ext")',
        1,
    )
    hero_inner = child_nodes_only(hero_block, "HeroSection")
    hero_inner = hero_inner.replace('parent="HeroSection"', 'parent="."')
    hero_inner = hero_inner.replace('parent="HeroSection/', 'parent="')

    write_prefab(
        INV / "hero_section.tscn",
        "uid://c8herosect01",
        "HeroSection",
        "HBoxContainer",
        "hero_section.gd",
        [
            'type="Texture2D" uid="uid://c74n55kpxkj17" path="res://sprites/heroes/px_warrior2.jpg"',
            'type="PackedScene" path="res://presentation/inventory/equipment_grid_left.tscn"',
            'type="PackedScene" path="res://presentation/inventory/equipment_grid_right.tscn"',
            'type="PackedScene" uid="uid://c8partybtn01" path="res://presentation/inventory/party_hero_slot_button.tscn"',
            'type="Script" uid="uid://u7nsljsgk78f" path="res://presentation/inventory/team_selection_ui.gd"',
        ],
        subs,
        "layout_mode = 2\nsize_flags_vertical = 0\ntheme_override_constants/separation = 6\nalignment = 1",
        hero_inner,
    )

    row_block = extract_section(text, "LinhaInventario", ["MenuInferior"])
    row_block = remap_block(row_block, OLD_ROW, "InventoryRow")
    row_inner = child_nodes_only(row_block, "LinhaInventario").replace('parent="InventoryRow"', 'parent="."')
    row_inner = row_inner.replace('parent="InventoryRow/', 'parent="')
    write_prefab(
        INV / "inventory_row.tscn",
        "uid://c8invrow001",
        "InventoryRow",
        "HBoxContainer",
        "inventory_row.gd",
        [
            'type="PackedScene" uid="uid://c8invslots01" path="res://presentation/inventory/inventory_slots_grid.tscn"',
            'type="Texture2D" uid="uid://c5o34g0lmphl5" path="res://sprites/ui/chest.png"',
        ],
        collect_subs(text, ["StyleBoxFlat_botao", "StyleBoxFlat_botao_pressed", "StyleBoxFlat_botao_hover"]),
        (
            "custom_minimum_size = Vector2(486, 202)\n"
            "size_flags_horizontal = 4\nsize_flags_vertical = 0\n"
            "theme_override_constants/separation = 6\nalignment = 1"
        ),
        row_inner,
    )

    nav_block = extract_section(text, "MenuInferior", ["WarehousePanel"])
    nav_block = remap_block(nav_block, OLD_NAV, "BottomNav")
    nav_inner = child_nodes_only(nav_block, "MenuInferior").replace('parent="BottomNav"', 'parent="."')
    nav_inner = nav_inner.replace('parent="BottomNav/', 'parent="')
    write_prefab(
        INV / "bottom_nav.tscn",
        "uid://c8bottomnav1",
        "BottomNav",
        "HBoxContainer",
        "bottom_nav.gd",
        [
            'type="Texture2D" uid="uid://bnc8n5u3bvfvp" path="res://sprites/ui/nav_skills.png"',
            'type="Texture2D" uid="uid://dpbh05jiuntra" path="res://sprites/ui/nav_inventory.png"',
            'type="Texture2D" uid="uid://bsehtefuj1pxn" path="res://sprites/ui/nav_forge.png"',
            'type="Texture2D" uid="uid://dw0jgemm34bg" path="res://sprites/ui/nav_world.png"',
        ],
        collect_subs(text, ["StyleBoxFlat_botao", "StyleBoxFlat_botao_pressed", "StyleBoxFlat_botao_hover"]),
        (
            "custom_minimum_size = Vector2(0, 34)\n"
            "size_flags_horizontal = 3\nsize_flags_vertical = 0\n"
            "theme_override_constants/separation = 4"
        ),
        nav_inner,
    )

    # Patch menu
    text = re.sub(
        r'\[ext_resource type="Script" uid="uid://daiy8cb6blmv"[^\n]+\n',
        "",
        text,
    )
    text = re.sub(
        r'\n\[node name="EditorPreviewHost"[^\]]*\]\nscript = ExtResource\("16_preview_host"\)\n',
        "\n",
        text,
    )
    insert = (
        '[ext_resource type="PackedScene" path="res://presentation/inventory/hero_section.tscn" id="18_hero"]\n'
        '[ext_resource type="PackedScene" path="res://presentation/inventory/inventory_row.tscn" id="19_row"]\n'
        '[ext_resource type="PackedScene" path="res://presentation/inventory/bottom_nav.tscn" id="20_nav"]\n'
    )
    if "id=\"18_hero\"" not in text:
        text = text.replace(
            '[ext_resource type="Resource" uid="uid://layoutinv001"',
            insert + '[ext_resource type="Resource" uid="uid://layoutinv001"',
            1,
        )

    for old_name, new_name, ext in [
        ("AreaHeroi", "HeroSection", "18_hero"),
        ("LinhaInventario", "InventoryRow", "19_row"),
        ("MenuInferior", "BottomNav", "20_nav"),
    ]:
        block = extract_section(text, old_name, ["MenuInferior", "WarehousePanel", "LinhaInventario", "MenuInferior"])
        if old_name == "AreaHeroi":
            block = extract_section(text, "AreaHeroi", ["LinhaInventario"])
        elif old_name == "LinhaInventario":
            block = extract_section(text, "LinhaInventario", ["MenuInferior"])
        else:
            block = extract_section(text, "MenuInferior", ["WarehousePanel"])
        repl = (
            f'\n[node name="{new_name}" parent="CenterAnchor/MenuArea/Panel/Conteudo" '
            f'instance=ExtResource("{ext}")]\n'
            "unique_name_in_owner = true\n"
            "layout_mode = 2\n"
        )
        text = text.replace(block, repl, 1)

    # Remove unused ext from menu
    for rem in [
        '[ext_resource type="PackedScene" uid="uid://c8invslots01"',
        '[ext_resource type="Texture2D" uid="uid://c5o34g0lmphl5"',
        '[ext_resource type="PackedScene" uid="uid://c8equipgrid1"',
        '[ext_resource type="Texture2D" uid="uid://bnc8n5u3bvfvp"',
        '[ext_resource type="Texture2D" uid="uid://dpbh05jiuntra"',
        '[ext_resource type="Texture2D" uid="uid://bsehtefuj1pxn"',
        '[ext_resource type="Texture2D" uid="uid://dw0jgemm34bg"',
        '[ext_resource type="Texture2D" uid="uid://c74n55kpxkj17"',
        '[ext_resource type="PackedScene" uid="uid://c8partybtn01"',
        '[ext_resource type="Script" uid="uid://u7nsljsgk78f"',
    ]:
        text = re.sub(rem + r"[^\n]+\n", "", text)

    MENU.write_text(text, encoding="utf-8")
    print("Patched menu")


if __name__ == "__main__":
    main()
