# Align forge_panel.tscn and worlds_panel.tscn node names with GDScript % refs
$ErrorActionPreference = 'Stop'
$Root = Split-Path -Parent (Split-Path -Parent $MyInvocation.MyCommand.Path)
$utf8NoBom = New-Object System.Text.UTF8Encoding $false

$forgeMap = [ordered]@{
    'name="BotaoFecharForgePanel"' = 'name="CloseForgeButton"'
    'name="ToggleArmazem"' = 'name="WarehouseToggle"'
    'name="BotaoSintetizar"' = 'name="SynthesizeButton"'
    'name="BotaoDesmontar"' = 'name="DismantleButton"'
    'name="PainelSintese"' = 'name="PanelSintese"'
    'name="PainelDesmontar"' = 'name="PanelDesmontar"'
    'name="PainelJoias"' = 'name="PanelJoias"'
    'name="BotaoImbuir"' = 'name="ImbueButton"'
}

$forgePath = Join-Path $Root 'presentation\inventory\forge_panel.tscn'
$forgeText = Get-Content -Raw -Encoding UTF8 $forgePath
foreach ($k in $forgeMap.Keys) { $forgeText = $forgeText.Replace($k, $forgeMap[$k]) }
$forgePathMap = [ordered]@{
    '/PainelSintese' = '/PanelSintese'
    '/PainelDesmontar' = '/PanelDesmontar'
    '/PainelJoias' = '/PanelJoias'
    '/ToggleArmazem' = '/WarehouseToggle'
}
foreach ($k in $forgePathMap.Keys) { $forgeText = $forgeText.Replace($k, $forgePathMap[$k]) }
[System.IO.File]::WriteAllText($forgePath, $forgeText, $utf8NoBom)

$worldsPath = Join-Path $Root 'presentation\worlds\worlds_panel.tscn'
$worldsText = Get-Content -Raw -Encoding UTF8 $worldsPath
$worldsText = $worldsText.Replace('name="PainelStageMap"', 'name="PanelStageMap"')
$worldsText = $worldsText.Replace('/PainelStageMap/', '/PanelStageMap/')
[System.IO.File]::WriteAllText($worldsPath, $worldsText, $utf8NoBom)
Write-Host 'Fixed forge_panel.tscn and worlds_panel.tscn'
