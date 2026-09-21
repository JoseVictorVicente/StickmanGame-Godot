# Fix incomplete PT->EN replacements from phase_b_runtime_en.ps1
$ErrorActionPreference = 'Stop'
$Root = Split-Path -Parent (Split-Path -Parent $MyInvocation.MyCommand.Path)
$files = Get-ChildItem -Path $Root -Recurse -Include *.gd | Where-Object {
    $_.FullName -notmatch '\\\.godot\\' -and $_.FullName -notmatch '\\tools\\'
}

$replacements = [ordered]@{
    'var itens: Array[ItemData]' = 'var items: Array[ItemData]'
    'var itens: Array =' = 'var items: Array ='
    'itens.append' = 'items.append'
    'return itens' = 'return items'
    'itens.sort_custom' = 'items.sort_custom'
    'itens[i]' = 'items[i]'
    'itens.size()' = 'items.size()'
    'current_enemy.take_damage(dano)' = 'current_enemy.take_damage(damage)'
    'enemy_hit.emit(dano,' = 'enemy_hit.emit(damage,'
    'enemy_visual.global_position, dano)' = 'enemy_visual.global_position, damage)'
    'stats.get("dano"' = 'stats.get("damage"'
    '"dano":' = '"damage":'
    'dano = max(1, p_dano)' = 'damage = max(1, p_damage)'
    'if pai == null or dano <= 0:' = 'if pai == null or damage <= 0:'
    'numero.show_damage(dano, cor)' = 'numero.show_damage(damage, cor)'
    'text = str(dano)' = 'text = str(damage)'
}

foreach ($file in $files) {
    $text = Get-Content -Raw -Encoding UTF8 $file.FullName
    $original = $text
    foreach ($k in $replacements.Keys) { $text = $text.Replace($k, $replacements[$k]) }
    if ($text -ne $original) {
        $utf8NoBom = New-Object System.Text.UTF8Encoding $false
        [System.IO.File]::WriteAllText($file.FullName, $text, $utf8NoBom)
        Write-Host "Fixed $($file.FullName.Substring($Root.Length + 1))"
    }
}
Write-Host 'phase_b_fixup complete'
