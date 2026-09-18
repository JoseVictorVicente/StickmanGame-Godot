# Rename Portuguese signals, variables, and remaining methods in active folders.
$root = "C:\Users\Aleander\Desktop\stickmangame"
$dirs = @('presentation','domains','data','platform','core','scenes','tests')

$renames = [ordered]@{
  'consultar_progresso_slot' = 'query_slot_progress'
  'equipamento_alterado' = 'equipment_changed'
  'classe_heroi_alterada' = 'hero_class_changed'
  'largura_menus_alterada' = 'menu_width_changed'
  'visibilidade_alterada' = 'visibility_changed'
  'equipamentos_alterados' = 'equipment_changed'
  'efeito_moedas_pedido' = 'coin_effect_requested'
  'nivel_heroi_alterado' = 'hero_level_changed'
  'progressao_alterada' = 'progression_changed'
  'consultar_ouro' = 'query_gold'
  'personagem_alterado' = 'character_changed'
  'obter_indice_personagem' = 'get_character_index'
  'obter_destino_ouro' = 'get_gold_destination'
  'classes_desbloqueadas' = 'unlocked_classes'
  'fases_liberadas' = 'unlocked_stages'
  'obter_bonus_arvore' = 'get_skill_tree_bonus'
  'obter_dano_equip' = 'get_equipped_damage'
  'obter_vida_equip' = 'get_equipped_hp'
  'obter_rects_menu' = 'get_menu_rects'
  'menu_esta_visivel' = 'is_menu_visible'
  'ao_soltar_arraste' = 'on_drag_released'
  'item_duplo_clique' = 'item_double_clicked'
  'item_botao_direito' = 'item_right_clicked'
  'formacao_pedida' = 'formation_requested'
  'slot_selecionado' = 'slot_selected'
  'slot_escolhido' = 'slot_selected'
  'classe_atribuida' = 'class_assigned'
  'no_selecionado' = 'node_selected'
  'precisa_salvar' = 'save_needed'
  'hud_atualizar' = 'hud_refresh'
  'equipe_alterada' = 'party_changed'
  'heroi_atacou' = 'hero_attacked'
  'dps_alterado' = 'dps_changed'
  'item_dropado' = 'item_dropped'
  'ouro_ganho' = 'gold_gained'
  'arvore_alterada' = 'skill_tree_changed'
  'fase_iniciada' = 'stage_started'
  'janela_solta' = 'window_released'
  'combate_pausado' = 'combat_paused'
  'equipe_ativa' = 'active_party'
  'repetir_fase' = 'repeat_stage'
  'inimigo_atual' = 'current_enemy'
  'inimigo_visual' = 'enemy_visual'
  'barra_vida' = 'enemy_health_bar'
  'menu_inventario' = 'inventory_menu'
  'painel_batalha' = 'battle_panel'
  'botao_abrir_inventario' = 'open_inventory_button'
  'botao_repetir_fase' = 'repeat_stage_button'
  'efeito_moedas' = 'coin_effect_layer'
  'label_aviso' = 'notice_label'
  'label_inimigo' = 'enemy_label'
  'label_nivel' = 'level_label'
  'dano_total' = 'total_damage'
  '_tween_aviso' = '_notice_tween'
  '_progresso_arvore' = '_skill_tree_progress'
  '_equip_esquerdo_por_classe' = '_left_equipment_by_class'
  '_equip_direito_por_classe' = '_right_equipment_by_class'
  '_indice_personagem' = '_character_index'
  '_botoes_personagem' = '_character_buttons'
  '_slots_inventario' = '_inventory_slot_list'
  '_estilos_botao_ferraria' = '_forge_button_styles'
  '_estilos_botao_armazem' = '_warehouse_button_styles'
  '_estilos_botao_mundo' = '_world_button_styles'
  '_equipamentos' = '_equipment'
  'combate_no_topo' = 'combat_at_top'
  '_offset_arraste' = '_drag_offset'
  '_arrastando' = '_dragging'
  'obter_nivel' = 'get_level'
  'dificuldade' = 'difficulty'
  'progresso' = 'hero_progress'
  'fechado' = 'closed'
  'ouro_obtido' = 'gold_gained'
  'ouro_gasto' = 'gold_spent'
  'item_clicado' = 'item_clicked'
  'item_solto' = 'item_dropped'
  'mundo' = 'world'
  'fase' = 'stage'
  'onda' = 'wave'
  'aviso' = 'notice'
  'palco' = 'stage_panel'
  'combate' = 'combat_root'
  'chao' = 'floor'
  '_janela' = '_window_manager'
  '_luta' = '_combat'
  '_progresso' = '_hero_progress'
  '_on_equipe_alterada' = '_on_party_changed'
  '_devolver_itens' = '_return_items'
  '_guardar_resultado_central' = '_store_central_result'
  '_atributo_resultado_sintese_gema' = '_synthesis_gem_result_attribute'
  '_estilizar_toggle_armazem' = '_style_warehouse_toggle'
  '_on_visibilidade_legenda_info' = '_on_info_tooltip_visibility'
  '_garantir_caixa_legenda_info' = '_ensure_info_tooltip_box'
  '_tipo_resultado_sintese' = '_synthesis_result_type'
  '_nome_resultado_sintese' = '_synthesis_result_name'
  '_nome_padrao_tipo' = '_default_name_for_type'
  '_on_itens_alterados' = '_on_items_changed'
  '_passa_filtro' = '_passes_filter'
  '_itens_origem_filtrados' = '_filtered_source_items'
  '_on_filtro_escolhido' = '_on_filter_selected'
  '_nome_origem_itens' = '_source_items_name'
  '_nome_filtro_atual' = '_current_filter_name'
  '_mensagem_sem_itens_desmonte' = '_no_dismantle_items_message'
  '_garantir_sigla' = '_ensure_abbreviation'
  '_rotulo_tooltip' = '_tooltip_label'
  '_on_formacao_pressed' = '_on_formation_pressed'
  '_on_heroi_pressionado' = '_on_hero_pressed'
  'piscar_hit' = 'flash_hit'
  'aparecer' = 'show_up'
  '_botoes_heroi' = '_hero_buttons'
  '_indices_heroi' = '_hero_indices'
  '_desbloqueadas' = '_unlocked_tabs'
}

$ordered = $renames.Keys | Sort-Object { $_.Length } -Descending
$extensions = @('*.gd')

foreach ($dir in $dirs) {
  $base = Join-Path $root $dir
  if (-not (Test-Path $base)) { continue }
  Get-ChildItem $base -Recurse -Include $extensions | ForEach-Object {
    $text = [IO.File]::ReadAllText($_.FullName)
    $orig = $text
    foreach ($old in $ordered) {
      $new = $renames[$old]
      if ($old -eq $new) { continue }
      $text = [regex]::Replace($text, "(?<![A-Za-z0-9_])$old(?![A-Za-z0-9_])", $new)
    }
    if ($text -ne $orig) {
      [IO.File]::WriteAllText($_.FullName, $text)
      Write-Host $_.FullName.Replace($root + '\', '')
    }
  }
}
Write-Host "Identifier rename complete."
