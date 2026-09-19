# Rename runtime dict keys and public API identifiers from PT to EN
$ErrorActionPreference = 'Stop'
$Root = Split-Path -Parent (Split-Path -Parent $MyInvocation.MyCommand.Path)
$files = Get-ChildItem -Path $Root -Recurse -Include *.gd,*.tscn | Where-Object {
    $_.FullName -notmatch '\\\.godot\\' -and $_.FullName -notmatch '\\tools\\'
}

$replacements = [ordered]@{
    '"xp_proximo"' = '"xp_next"'
    "'xp_proximo'" = "'xp_next'"
    'xp_proximo' = 'xp_next'
    '"desbloqueadas"' = '"unlocked"'
    "'desbloqueadas'" = "'unlocked'"
    'desbloqueadas' = 'unlocked'
    '"vel_ataque"' = '"attack_speed"'
    "'vel_ataque'" = "'attack_speed'"
    'vel_ataque' = 'attack_speed'
    '"bonus_ouro"' = '"gold_bonus"'
    "'bonus_ouro'" = "'gold_bonus'"
    'bonus_ouro' = 'gold_bonus'
    '"bonus_xp"' = '"xp_bonus"'
    'bonus_xp' = 'xp_bonus'
    '"crit_dano"' = '"crit_damage"'
    'crit_dano' = 'crit_damage'
    '"res_fisica"' = '"phys_res"'
    'res_fisica' = 'phys_res'
    '"res_arcana"' = '"arcane_res"'
    'res_arcana' = 'arcane_res'
    '"res_elemental"' = '"elemental_res"'
    'res_elemental' = 'elemental_res'
    '"crit_chance"' = '"crit_chance"'
    'STAT_KEY_ATTACK := "ataque"' = 'STAT_KEY_ATTACK := "attack"'
    'STAT_KEY_HP := "vida"' = 'STAT_KEY_HP := "hp"'
    'STAT_KEY_ATTACK_SPEED := "vel_ataque"' = 'STAT_KEY_ATTACK_SPEED := "attack_speed"'
    '"ataque"' = '"attack"'
    "'ataque'" = "'attack'"
    '.ataque' = '.attack'
    '"vida"' = '"hp"'
    "'vida'" = "'hp'"
    '.vida' = '.hp'
    '"nivel"' = '"level"'
    "'nivel'" = "'level'"
    '.nivel' = '.level'
    'get("nivel"' = 'get("level"'
    '["nivel"]' = '["level"]'
    'var dano:' = 'var damage:'
    '.dano' = '.damage'
    'p_dano:' = 'p_damage:'
    ' dano:' = ' damage:'
    '(dano:' = '(damage:'
    ', dano:' = ', damage:'
    'func comparar_ordenacao' = 'func compare_sort'
    'comparar_ordenacao(' = 'compare_sort('
    'var reservado_ferraria' = 'var forge_reserved'
    'reservado_ferraria' = 'forge_reserved'
    'var nome_slot' = 'var slot_label'
    'nome_slot' = 'slot_label'
    'func descricao_bonus' = 'func bonus_description'
    'descricao_bonus(' = 'bonus_description('
    'PERSONAGENS' = 'HERO_SLOTS'
    '"nome"' = '"name"'
    '["nome"]' = '["name"]'
    'dados["nome"]' = 'dados["name"]'
    '"classe"' = '"hero_class"'
    '["classe"]' = '["hero_class"]'
    'func apply_save' = 'func apply_from_save'
    'apply_save(' = 'apply_from_save('
    'var itens:' = 'var items:'
    'generate_random_item(nivel_inimigo' = 'generate_random_item(enemy_level'
    'push_warning("Habilidade não encontrada' = 'push_warning("Skill not found'
    'push_warning("Skill não encontrada' = 'push_warning("Skill not found'
    '@export_group("Coluna do personagem")' = '@export_group("Character column")'
    '@export_group("Seções do painel")' = '@export_group("Panel sections")'
    'offset_regiao_retrato' = 'portrait_region_offset'
    'offset_botao_formacao' = 'formation_button_offset'
    'espaco_retrato_controles' = 'portrait_controls_spacing'
    'config/name="TESTE JOGO STICKMAN IDDLE"' = 'config/name="Stickman Idle"'
}

foreach ($file in $files) {
    $text = Get-Content -Raw -Encoding UTF8 $file.FullName
    $original = $text
    foreach ($k in $replacements.Keys) {
        $text = $text.Replace($k, $replacements[$k])
    }
    if ($text -ne $original) {
        Set-Content -Path $file.FullName -Value $text -Encoding UTF8 -NoNewline
        Write-Host "Updated $($file.FullName.Substring($Root.Length + 1))"
    }
}
Write-Host 'phase_b_runtime_en complete'
