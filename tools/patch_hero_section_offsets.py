#!/usr/bin/env python3
"""Add SectionVisualOffset wrappers to hero_section.tscn."""
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
HERO = ROOT / "presentation" / "inventory" / "hero_section.tscn"

OFFSET_SCRIPT = '[ext_resource type="Script" path="res://presentation/inventory/section_visual_offset.gd" id="7_offset"]'


def main() -> None:
    text = HERO.read_text(encoding="utf-8")
    if "section_visual_offset.gd" not in text:
        insert_at = text.find("[sub_resource type=")
        text = text[:insert_at] + OFFSET_SCRIPT + "\n\n" + text[insert_at:]
        text = text.replace("format=3 uid", "load_steps=2 format=3 uid", 1)
        if "load_steps=" not in text.split("\n")[0]:
            header = text.split("\n", 1)
            text = header[0].replace("[gd_scene format=3", "[gd_scene load_steps=8 format=3") + "\n" + header[1]
        else:
            load_steps = int(text.split("load_steps=")[1].split()[0])
            text = text.replace(f"load_steps={load_steps}", f"load_steps={load_steps + 1}", 1)

    old_hero = (
        '[node name="HeroVisualSection" type="VBoxContainer" parent="ColunaPersonagem" unique_id=1520038868]\n'
        "unique_name_in_owner = true\n"
        "layout_mode = 2\n"
        "size_flags_horizontal = 3\n"
        "theme_override_constants/separation = 0\n"
    )
    new_hero = (
        '[node name="HeroVisualSection" type="Control" parent="ColunaPersonagem" unique_id=1520038868]\n'
        "unique_name_in_owner = true\n"
        "layout_mode = 2\n"
        "size_flags_horizontal = 3\n"
        "mouse_filter = 2\n"
        'script = ExtResource("7_offset")\n'
        '\n[node name="Conteudo" type="VBoxContainer" parent="ColunaPersonagem/HeroVisualSection"]\n'
        "unique_name_in_owner = true\n"
        "layout_mode = 0\n"
        "theme_override_constants/separation = 0\n"
    )
    if old_hero not in text:
        if "HeroVisualSection/Conteudo" in text:
            print("hero_section offsets already patched")
        else:
            raise SystemExit("HeroVisualSection block not found")
    else:
        text = text.replace(old_hero, new_hero)
        conteudo_marker = '[node name="Conteudo" type="VBoxContainer" parent="ColunaPersonagem/HeroVisualSection"]'
        lines = text.splitlines(keepends=True)
        out: list[str] = []
        for line in lines:
            if line.startswith(conteudo_marker):
                out.append(line)
                continue
            if 'parent="ColunaPersonagem/HeroVisualSection"' in line:
                line = line.replace(
                    'parent="ColunaPersonagem/HeroVisualSection"',
                    'parent="ColunaPersonagem/HeroVisualSection/Conteudo"',
                )
            out.append(line)
        text = "".join(out)

    old_formation = (
        '[node name="FormationButton" type="Button" parent="ColunaPersonagem/TeamArea" unique_id=500364364]\n'
        "unique_name_in_owner = true\n"
    )
    new_formation = (
        '[node name="FormationButtonHost" type="Control" parent="ColunaPersonagem/TeamArea"]\n'
        "unique_name_in_owner = true\n"
        "layout_mode = 2\n"
        "mouse_filter = 2\n"
        'script = ExtResource("7_offset")\n'
        '\n[node name="FormationButton" type="Button" parent="ColunaPersonagem/TeamArea/FormationButtonHost" unique_id=500364364]\n'
        "unique_name_in_owner = true\n"
    )
    if old_formation in text:
        text = text.replace(old_formation, new_formation)

    HERO.write_text(text, encoding="utf-8")
    print(f"Patched {HERO}")


if __name__ == "__main__":
    main()
