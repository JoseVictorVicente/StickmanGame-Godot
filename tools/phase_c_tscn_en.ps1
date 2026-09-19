# Rename Portuguese scene node names and unique name references
$ErrorActionPreference = 'Stop'
$Root = Split-Path -Parent (Split-Path -Parent $MyInvocation.MyCommand.Path)
$files = Get-ChildItem -Path $Root -Recurse -Include *.gd,*.tscn | Where-Object {
    $_.FullName -notmatch '\\\.godot\\' -and $_.FullName -notmatch '\\tools\\'
}

$nodeMap = [ordered]@{
    '%Painel' = '%Panel'
    '%BotaoSkills' = '%SkillsButton'
    '%BotaoInventario' = '%InventoryButton'
    '%BotaoForgePanel' = '%ForgePanelButton'
    '%PainelForgePanel' = '%ForgePanelHost'
    '%BotaoFecharForgePanel' = '%CloseForgeButton'
    '%ToggleArmazem' = '%WarehouseToggle'
    '%BotaoSintetizar' = '%SynthesizeButton'
    '%BotaoDesmontar' = '%DismantleButton'
    '%BotaoImbuir' = '%ImbueButton'
    '%PainelStageMap' = '%StageMapPanel'
    'name = "Painel"' = 'name = "Panel"'
    'name = "BotaoSkills"' = 'name = "SkillsButton"'
    'name = "BotaoInventario"' = 'name = "InventoryButton"'
    'name = "BotaoForgePanel"' = 'name = "ForgePanelButton"'
    'name = "PainelForgePanel"' = 'name = "ForgePanelHost"'
    'name = "Combate"' = 'name = "Combat"'
    'name = "InfoBatalha"' = 'name = "BattleInfo"'
    'name = "Conteudo"' = 'name = "Content"'
    'name = "Cabecalho"' = 'name = "Header"'
    'name = "TituloConfig"' = 'name = "SettingsTitle"'
    'name = "ConteudoConfig"' = 'name = "SettingsContent"'
    'name = "CabecalhoConfig"' = 'name = "SettingsHeader"'
    'name = "LabelVolumeTitulo"' = 'name = "VolumeTitleLabel"'
    'name = "LabelVolumeValor"' = 'name = "VolumeValueLabel"'
    'name = "SliderVolume"' = 'name = "VolumeSlider"'
    'name = "BannerTitulo"' = 'name = "TitleBanner"'
    'name = "Titulo"' = 'name = "Title"'
    'name = "TituloHeroi"' = 'name = "HeroTitle"'
    'name = "TituloAtivas"' = 'name = "ActiveTitle"'
    'name = "TituloPassivas"' = 'name = "PassiveTitle"'
    'name = "TituloEquipAtivas"' = 'name = "EquippedActiveTitle"'
    'name = "TituloEquipPassivas"' = 'name = "EquippedPassiveTitle"'
    'name = "TituloDisponiveis"' = 'name = "AvailableTitle"'
    'name = "GradeAtivas"' = 'name = "ActiveGrid"'
    'name = "GradePassivas"' = 'name = "PassiveGrid"'
    'name = "GradeEquipAtivas"' = 'name = "EquippedActiveGrid"'
    'name = "GradeEquipPassivas"' = 'name = "EquippedPassiveGrid"'
    'name = "RolagemSkills"' = 'name = "SkillsScroll"'
    'name = "RolagemAtributos"' = 'name = "AttributesScroll"'
    'name = "ConteudoSkills"' = 'name = "SkillsContent"'
    'name = "MenuInferior"' = 'name = "BottomMenu"'
    'name = "LinhaInventario"' = 'name = "InventoryRow"'
    'name = "AreaHeroi"' = 'name = "HeroArea"'
    'name = "Personagem_' = 'name = "Character_'
    'name = "BotaoMundo_' = 'name = "WorldButton_'
    'name == "Painel"' = 'name == "Panel"'
    'name == "Menu"' = 'name == "Menu"'
    'parent="CenterAnchor/MenuArea/Painel"' = 'parent="CenterAnchor/MenuArea/Panel"'
    'parent="CenterAnchor/MenuArea/Painel/' = 'parent="CenterAnchor/MenuArea/Panel/'
    '/Painel/' = '/Panel/'
    '/Painel"' = '/Panel"'
    '/BotaoSkills' = '/SkillsButton'
    '/BotaoInventario' = '/InventoryButton'
    '/BotaoForgePanel' = '/ForgePanelButton'
    '/PainelForgePanel' = '/ForgePanelHost'
    'res://sprites/ui/bau.png' = 'res://sprites/ui/chest.png'
}

foreach ($file in $files) {
    $text = Get-Content -Raw -Encoding UTF8 $file.FullName
    $original = $text
    foreach ($k in $nodeMap.Keys) { $text = $text.Replace($k, $nodeMap[$k]) }
    if ($text -ne $original) {
        Set-Content -Path $file.FullName -Value $text -Encoding UTF8 -NoNewline
        Write-Host "Updated $($file.FullName.Substring($Root.Length + 1))"
    }
}
Write-Host 'phase_c_tscn_en complete'
