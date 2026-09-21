# Align inventory_menu.tscn node names with @onready % references in inventory_menu.gd
$ErrorActionPreference = 'Stop'
$path = Join-Path (Split-Path -Parent (Split-Path -Parent $MyInvocation.MyCommand.Path)) 'presentation\inventory\inventory_menu.tscn'
$text = Get-Content -Raw -Encoding UTF8 $path
$map = [ordered]@{
    'name="Painel"' = 'name="Panel"'
    'name="BotaoSkills"' = 'name="SkillsButton"'
    'name="BotaoInventario"' = 'name="InventoryButton"'
    'name="BotaoForgePanel"' = 'name="ForgePanelButton"'
    'name="PainelForgePanel"' = 'name="PanelForgePanel"'
}
foreach ($k in $map.Keys) { $text = $text.Replace($k, $map[$k]) }
$utf8NoBom = New-Object System.Text.UTF8Encoding $false
[System.IO.File]::WriteAllText($path, $text, $utf8NoBom)
Write-Host 'Fixed inventory_menu.tscn node names'
