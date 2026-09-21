# Migrate item_database.gd catalog ids to English and remove hardcoded PT display names
$ErrorActionPreference = 'Stop'
$Root = Split-Path -Parent (Split-Path -Parent $MyInvocation.MyCommand.Path)
. (Join-Path $Root 'tools\item_id_map.ps1')

$path = Join-Path $Root 'platform\item_database.gd'
$text = Get-Content -Raw -Encoding UTF8 $path

foreach ($pt in $itemIdMap.Keys) {
    $en = $itemIdMap[$pt]
    $text = [regex]::Replace($text, "_create\(`"$pt`", `"[^`"]*`",", "_create(`"$en`",")
}

$text = $text -replace 'func _create\(\s*\r?\n\s*p_id: String,\s*\r?\n\s*p_nome: String,\s*\r?\n\s*p_tipo:', "`nfunc _create(`n`tp_id: String,`n`tp_tipo:"
$text = $text -replace 'item\.display_name = p_nome\r?\n', "item.display_name = `"`"`n"

$replacements = @{
    'var itens:' = 'var items:'
    'itens.clear()' = 'items.clear()'
    'itens.append' = 'items.append'
    'itens.is_empty()' = 'items.is_empty()'
    'itens.size()' = 'items.size()'
    'for item in itens' = 'for item in items'
    'generate_random_item(nivel_inimigo' = 'generate_random_item(enemy_level'
    'generate_random_equipment(nivel_inimigo' = 'generate_random_equipment(enemy_level'
    'generate_random_gem(nivel_inimigo' = 'generate_random_gem(enemy_level'
    'func _roll_rarity(nivel:' = 'func _roll_rarity(level:'
    'maxi(1, nivel_inimigo)' = 'maxi(1, enemy_level)'
    'maxi(1, nivel)' = 'maxi(1, level)'
    'float(nivel)' = 'float(level)'
    'int(floor(float(nivel)' = 'int(floor(float(level)'
    'get_by_id(id_item:' = 'get_by_id(item_id:'
    'id_item' = 'item_id'
    '# Guerreiro' = '# Warrior'
    '# Mago' = '# Mage'
    '# Arqueiro' = '# Archer'
    '# Assassino' = '# Assassin'
    '# Tanque' = '# Tank'
    '# Sacerdote' = '# Priest'
    '# Comuns (qualquer classe)' = '# Common (all classes)'
}
foreach ($k in $replacements.Keys) { $text = $text.Replace($k, $replacements[$k]) }

Set-Content -Path $path -Value $text -Encoding UTF8 -NoNewline
Write-Host "Updated item_database.gd"
