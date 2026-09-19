# Phase D: remaining PT identifiers in runtime code (not save migration maps)
$ErrorActionPreference = 'Stop'
$Root = Split-Path -Parent (Split-Path -Parent $MyInvocation.MyCommand.Path)
$utf8NoBom = New-Object System.Text.UTF8Encoding $false
$files = Get-ChildItem -Path $Root -Recurse -Include *.gd | Where-Object {
    $_.FullName -notmatch '\\\.godot\\' -and $_.FullName -notmatch '\\tools\\'
}

$replacements = [ordered]@{
    '"ataque_pct"' = '"attack_pct"'
    "'ataque_pct'" = "'attack_pct'"
    '["ataque_pct"]' = '["attack_pct"]'
    '.get("ataque_pct"' = '.get("attack_pct"'
    'chave == "ataque_pct"' = 'chave == "attack_pct"'
    '"vida_pct"' = '"hp_pct"'
    '.get("vida_pct"' = '.get("hp_pct"'
    '"evasao"' = '"evasion"'
    '.get("evasao"' = '.get("evasion"'
    'stats.get("evasao"' = 'stats.get("evasion"'
    '_add_row("evasao"' = '_add_row("evasion"'
    '_set_row("evasao"' = '_set_row("evasion"'
    'return "ataque_pct"' = 'return "attack_pct"'
    'return "evasao"' = 'return "evasion"'
    'stats["ouro"]' = 'stats["gold"]'
    '"ouro": maxi' = '"gold": maxi'
    'var ouro :=' = 'var gold :='
    'round(ouro))' = 'round(gold))'
    'de_dicionario(' = 'from_dictionary('
    'func de_dicionario(' = 'func from_dictionary('
    'tipo_aceitavel' = 'accepted_type'
    'aceita_qualquer' = 'accepts_any'
    'item_type_aceitavel' = 'accepted_type'
    '"tipo": int(' = '"type": int('
    '.get("tipo"' = '.get("type"'
    'entrada.get("tipo"' = 'entrada.get("type"'
    'por_tipo[' = 'by_type['
    'por_tipo.get' = 'by_type.get'
    'var por_tipo' = 'var by_type'
    '"abas": abas' = '"tabs": tabs'
    'var abas: Variant = dados.get("abas"' = 'var tabs: Variant = data.get("tabs"'
    'var abas: Variant = data.get("abas"' = 'var tabs: Variant = data.get("tabs"'
    'dados.get("abas"' = 'data.get("tabs"'
    'data.get("abas"' = 'data.get("tabs"'
    'for lista in abas' = 'for tab_list in tabs'
    'if abas is Array' = 'if tabs is Array'
    'var abas: Array = []' = 'var tabs: Array = []'
    'abas.append(' = 'tabs.append('
    'EquipEsq_' = 'EquipLeft_'
    'EquipDir_' = 'EquipRight_'
    'ColunaEquipAtivas' = 'EquippedActiveColumn'
    'ColunaEquipPassivas' = 'EquippedPassiveColumn'
    'hero_level_changed(stage_index: int, nivel: int)' = 'hero_level_changed(stage_index: int, level: int)'
    '_on_hero_level_changed(stage_index: int, nivel: int)' = '_on_hero_level_changed(stage_index: int, level: int)'
    'push_warning("Habilidade não encontrada' = 'push_warning("Skill not found'
    'botao.text = "Herói %d"' = 'botao.text = tr(LocaleKeys.UI_HERO_N) %'
    'espada.display_name = "Espada de Madeira"' = 'espada.display_name = ""'
    'espada.name_key = ""' = 'espada.name_key = "ITEM_wooden_sword"'
    '{"name": "Guerreiro"' = '{"name": "Warrior"'
    '{"name": "Mago"' = '{"name": "Mage"'
    '{"name": "Arqueiro"' = '{"name": "Archer"'
    '"name": "Monstro %d-%d"' = '"name": "Enemy %d-%d"'
    '"rotulo":' = '"label":'
}

foreach ($file in $files) {
    if ($file.FullName -match 'save_service\.gd$' -or $file.FullName -match 'id_migration\.gd$') { continue }
    $text = [System.IO.File]::ReadAllText($file.FullName)
    $original = $text
    foreach ($k in $replacements.Keys) { $text = $text.Replace($k, $replacements[$k]) }
    if ($text -ne $original) {
        [System.IO.File]::WriteAllText($file.FullName, $text, $utf8NoBom)
        Write-Host "Updated $($file.FullName.Substring($Root.Length + 1))"
    }
}
Write-Host 'phase_d_residual_en complete'
