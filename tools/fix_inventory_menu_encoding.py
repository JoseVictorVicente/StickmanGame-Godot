#!/usr/bin/env python3
"""Convert inventory_menu.gd to UTF-8 and sync with OverlayVBox layout."""
from __future__ import annotations

import subprocess
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
TARGET = ROOT / "presentation" / "inventory" / "inventory_menu.gd"


def read_text(path: Path) -> str:
    raw = path.read_bytes()
    if raw.startswith(b"\xff\xfe"):
        return raw.decode("utf-16")
    if len(raw) > 1 and raw[1] == 0:
        return raw.decode("utf-16-le")
    return raw.decode("utf-8")


def main() -> None:
    subprocess.run(["git", "restore", str(TARGET)], check=True, cwd=ROOT)
    text = read_text(TARGET)

    replacements = [
        (
            "const MARGEM_TOPO_UI := 8.0\n"
            "const WINDOW_HEIGHT := 860.0\n"
            "const COMBAT_RESERVED_SPACE := 320.0",
            "const MARGEM_TOPO_UI := UiConstants.UI_TOP_MARGIN\n"
            "const COMBAT_RESERVED_SPACE := UiConstants.COMBAT_RESERVED_SPACE",
        ),
        (
            "@onready var painel: PanelContainer = %Panel\n"
            "@onready var menu_area: Control = %MenuArea\n"
            "@onready var forge_panel_node: ForgePanel = %PanelForgePanel",
            "@onready var painel: PanelContainer = %Panel\n"
            "@onready var menu_area: HBoxContainer = %MenuArea\n"
            "@onready var overlay_vbox: VBoxContainer = %OverlayVBox\n"
            "@onready var top_spacer: Control = %TopSpacer\n"
            "@onready var bottom_spacer: Control = %BottomSpacer\n"
            "@onready var forge_panel_node: ForgePanel = %PanelForgePanel",
        ),
        (
            "@onready var skill_tree_panel_node: SkillTreePanel = %SkillTreePanel\n"
            "@onready var center_anchor: Control = %CenterAnchor\n"
            "@onready var area_heroi: HeroSection = %AreaHeroi",
            "@onready var skill_tree_panel_node: SkillTreePanel = %SkillTreePanel\n"
            "@onready var area_heroi: HeroSection = %AreaHeroi",
        ),
        (
            "func _apply_panel_layout() -> void:\n"
            "\tvar layout := _layout()\n"
            "\tif menu_area:\n"
            "\t\tmenu_area.custom_minimum_size = layout.panel_min_size\n"
            "\tif center_anchor:\n"
            "\t\tcenter_anchor.custom_minimum_size = layout.panel_min_size + Vector2(20, 12)\n"
            "\tif painel:",
            "func _apply_panel_layout() -> void:\n"
            "\tvar layout := _layout()\n"
            "\tif painel:",
        ),
        (
            "func _configure_ui_anchor() -> void:\n"
            "\tcenter_anchor.set_anchors_preset(Control.PRESET_TOP_WIDE, false)\n"
            "\tcenter_anchor.grow_horizontal = Control.GROW_DIRECTION_BOTH\n"
            "\tcenter_anchor.grow_vertical = Control.GROW_DIRECTION_BEGIN\n\n\n"
            "func set_below_combat(abaixo: bool) -> void:\n"
            "\t_menus_abaixo = abaixo\n"
            "\t_configure_ui_anchor()\n"
            "\tif abaixo:\n"
            "\t\tcenter_anchor.offset_top = COMBAT_RESERVED_SPACE\n"
            "\t\tcenter_anchor.offset_bottom = WINDOW_HEIGHT - MARGEM_TOPO_UI\n"
            "\telse:\n"
            "\t\tcenter_anchor.offset_top = MARGEM_TOPO_UI\n"
            "\t\tcenter_anchor.offset_bottom = WINDOW_HEIGHT - COMBAT_RESERVED_SPACE\n"
            "\t_align_side_panels()",
            "func set_below_combat(abaixo: bool) -> void:\n"
            "\t_menus_abaixo = abaixo\n"
            "\t_apply_combat_spacers()\n"
            "\t_align_side_panels()\n\n\n"
            "func _apply_combat_spacers() -> void:\n"
            "\tif top_spacer == null or bottom_spacer == null:\n"
            "\t\treturn\n"
            "\tif _menus_abaixo:\n"
            "\t\ttop_spacer.custom_minimum_size = Vector2(0, COMBAT_RESERVED_SPACE)\n"
            "\t\ttop_spacer.size_flags_vertical = Control.SIZE_SHRINK_BEGIN\n"
            "\t\tbottom_spacer.custom_minimum_size = Vector2.ZERO\n"
            "\t\tbottom_spacer.size_flags_vertical = Control.SIZE_EXPAND_FILL\n"
            "\telse:\n"
            "\t\ttop_spacer.custom_minimum_size = Vector2.ZERO\n"
            "\t\ttop_spacer.size_flags_vertical = Control.SIZE_EXPAND_FILL\n"
            "\t\tbottom_spacer.custom_minimum_size = Vector2(0, COMBAT_RESERVED_SPACE)\n"
            "\t\tbottom_spacer.size_flags_vertical = Control.SIZE_SHRINK_END",
        ),
        (
            "func width_for_window() -> int:\n"
            "\treturn PanelLayout.window_width(painel, warehouse_panel_node, forge_panel_node, worlds_panel_node, formation_panel_node)\n\n\n"
            "func _align_side_panels() -> void:\n"
            "\t_restore_base_panel()\n"
            "\tPanelLayout.align_panel(painel, menu_area, warehouse_panel_node, forge_panel_node, worlds_panel_node, _menus_abaixo, formation_panel_node, attributes_panel_node, skills_panel_node, skill_tree_panel_node)\n"
            "\t_apply_panel_layout()",
            "func width_for_window() -> int:\n"
            "\treturn PanelLayout.window_width(menu_area)\n\n\n"
            "func _align_side_panels() -> void:\n"
            "\t_restore_base_panel()\n"
            "\tPanelLayout.align_overlays(\n"
            "\t\tpainel,\n"
            "\t\tformation_panel_node,\n"
            "\t\tattributes_panel_node,\n"
            "\t\tskills_panel_node,\n"
            "\t\tskill_tree_panel_node\n"
            "\t)\n"
            "\t_apply_panel_layout()",
        ),
        (
            "@onready var painel: PanelContainer = %Panel\n"
            "@onready var menu_area: HBoxContainer = %MenuArea",
            "@onready var painel: PanelContainer = %Panel\n"
            "@onready var conteudo: VBoxContainer = %Conteudo\n"
            "@onready var menu_area: HBoxContainer = %MenuArea",
        ),
        (
            "func _apply_panel_layout() -> void:\n"
            "\tvar layout := _layout()\n"
            "\tif painel:\n"
            "\t\tpainel.custom_minimum_size = layout.panel_min_size\n"
            "\tif not Engine.is_editor_hint():",
            "func _apply_panel_layout() -> void:\n"
            "\tvar layout := _layout()\n"
            "\tif painel:\n"
            "\t\tpainel.custom_minimum_size = layout.panel_min_size\n"
            "\tif linha_inventario:\n"
            "\t\tlinha_inventario.custom_minimum_size = layout.inventory_row_pixel_size()\n"
            "\tif menu_inferior:\n"
            "\t\tmenu_inferior.custom_minimum_size.y = layout.bottom_bar_height\n"
            "\tif not Engine.is_editor_hint():",
        ),
        (
            "func _set_inventory_visible(visivel: bool) -> void:\n"
            "\tif painel == null:\n"
            "\t\treturn\n"
            "\t_restore_base_panel()\n"
            "\tif visivel:\n"
            "\t\tpainel.visible = true\n"
            "\t\treturn\n"
            "\tvar tam := painel.size\n"
            "\tif tam.y < 1.0:\n"
            "\t\ttam = painel.get_combined_minimum_size()\n"
            "\t\ttam.x = maxf(tam.x, painel.custom_minimum_size.x)\n"
            "\tpainel.visible = false\n"
            "\tpainel.size = tam",
            "func _set_inventory_visible(visivel: bool) -> void:\n"
            "\tif conteudo == null:\n"
            "\t\treturn\n"
            "\t_restore_base_panel()\n"
            "\tconteudo.visible = visivel",
        ),
        (
            "\tcall_deferred(\"set_below_combat\", _menus_abaixo)\n"
            "\tcall_deferred(\"_align_side_panels\")",
            "\tcall_deferred(\"_align_side_panels\")",
        ),
        (
            "\tif painel:\n"
            "\t\tpainel.custom_minimum_size = layout.panel_min_size\n"
            "\tif linha_inventario:",
            "\tif painel:\n"
            "\t\tvar hub_w := maxf(layout.panel_min_size.x, layout.inventory_row_pixel_size().x + 24.0)\n"
            "\t\tpainel.custom_minimum_size = Vector2(hub_w, layout.panel_min_size.y)\n"
            "\tif linha_inventario:",
        ),
        (
            "func _set_inventory_visible(visivel: bool) -> void:\n"
            "\tif conteudo == null:\n"
            "\t\treturn\n"
            "\t_restore_base_panel()\n"
            "\tconteudo.visible = visivel",
            "func _set_inventory_visible(visivel: bool) -> void:\n"
            "\tif conteudo == null or painel == null:\n"
            "\t\treturn\n"
            "\t_restore_base_panel()\n"
            "\tif not visivel:\n"
            "\t\tvar tam := painel.get_combined_minimum_size()\n"
            "\t\ttam.x = maxf(tam.x, _layout().panel_min_size.x)\n"
            "\t\ttam.y = maxf(tam.y, painel.custom_minimum_size.y)\n"
            "\t\tpainel.custom_minimum_size = tam\n"
            "\tconteudo.visible = visivel",
        ),
    ]

    for old, new in replacements:
        if old not in text:
            raise SystemExit(f"Missing expected block in inventory_menu.gd:\n{old[:120]}...")
        text = text.replace(old, new, 1)

    TARGET.write_text(text, encoding="utf-8", newline="\n")
    raw = TARGET.read_bytes()
    print(f"[OK] {TARGET.relative_to(ROOT)} -> UTF-8 ({len(raw)} bytes, nulls={b'\\x00' in raw})")


if __name__ == "__main__":
    main()
