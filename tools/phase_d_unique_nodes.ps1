# Rename unique scene nodes (PT -> EN) and sync % references in GDScript
$ErrorActionPermission = 'Stop'
$ErrorActionPreference = 'Stop'
$Root = Split-Path -Parent (Split-Path -Parent $MyInvocation.MyCommand.Path)
$utf8NoBom = New-Object System.Text.UTF8Encoding $false

$nodeMap = [ordered]@{
    '%GradeSintese' = '%SynthesisGrid'
    '%GradeDesmontar' = '%DismantleGrid'
    '%BotaoPreenchimento' = '%AutofillButton'
    '%BotaoInfoNivel' = '%LevelInfoButton'
    '%ToggleTrilho' = '%ToggleTrack'
    '%BotaoAbaSintese' = '%SynthesisTabButton'
    '%BotaoAbaDesmontar' = '%DismantleTabButton'
    '%BotaoAbaJoias' = '%GemsTabButton'
    '%BotaoFiltroForja' = '%ForgeFilterButton'
    '%BotaoPreenchimentoDesmonte' = '%DismantleAutofillButton'
    '%BotaoFiltroDesmonte' = '%DismantleFilterButton'
    '%PanelSintese' = '%SynthesisPanel'
    '%PanelDesmontar' = '%DismantlePanel'
    '%PanelJoias' = '%GemsPanel'
    '%AreaJoias' = '%GemsArea'
    '%LabelExplicacaoForgePanel' = '%ForgeExplanationLabel'
    '%LabelExplicacaoDesmontar' = '%DismantleExplanationLabel'
    '%LabelExplicacaoJoias' = '%GemsExplanationLabel'
    '%LabelValorDesmonte' = '%DismantleValueLabel'
    '%CabecalhoForgePanel' = '%ForgeHeader'
    '%CorpoForgePanel' = '%ForgeBody'
    '%Cabecalho' = '%Header'
    '%TituloConfig' = '%SettingsTitle'
    '%LabelVolumeTitulo' = '%VolumeTitleLabel'
    '%LabelVolumeValor' = '%VolumeValueLabel'
    '%SliderVolume' = '%VolumeSlider'
    '%GradeEquipAtivas' = '%EquippedActiveGrid'
    '%GradeEquipPassivas' = '%EquippedPassiveGrid'
    '%GradeAtivas' = '%ActiveGrid'
    '%GradePassivas' = '%PassiveGrid'
    '%LinhaAbas' = '%TabRow'
    'name="GradeSintese"' = 'name="SynthesisGrid"'
    'name="GradeDesmontar"' = 'name="DismantleGrid"'
    'name="BotaoPreenchimento"' = 'name="AutofillButton"'
    'name="BotaoInfoNivel"' = 'name="LevelInfoButton"'
    'name="ToggleTrilho"' = 'name="ToggleTrack"'
    'name="BotaoAbaSintese"' = 'name="SynthesisTabButton"'
    'name="BotaoAbaDesmontar"' = 'name="DismantleTabButton"'
    'name="BotaoAbaJoias"' = 'name="GemsTabButton"'
    'name="BotaoFiltroForja"' = 'name="ForgeFilterButton"'
    'name="BotaoPreenchimentoDesmonte"' = 'name="DismantleAutofillButton"'
    'name="BotaoFiltroDesmonte"' = 'name="DismantleFilterButton"'
    'name="PanelSintese"' = 'name="SynthesisPanel"'
    'name="PanelDesmontar"' = 'name="DismantlePanel"'
    'name="PanelJoias"' = 'name="GemsPanel"'
    'name="AreaJoias"' = 'name="GemsArea"'
    'name="LabelExplicacaoForgePanel"' = 'name="ForgeExplanationLabel"'
    'name="LabelExplicacaoDesmontar"' = 'name="DismantleExplanationLabel"'
    'name="LabelExplicacaoJoias"' = 'name="GemsExplanationLabel"'
    'name="LabelValorDesmonte"' = 'name="DismantleValueLabel"'
    'name="CabecalhoForgePanel"' = 'name="ForgeHeader"'
    'name="CorpoForgePanel"' = 'name="ForgeBody"'
    'name="PainelForgePanel"' = 'name="ForgePanel"'
    'name="Cabecalho"' = 'name="Header"'
    'name="TituloConfig"' = 'name="SettingsTitle"'
    'name="LabelVolumeTitulo"' = 'name="VolumeTitleLabel"'
    'name="LabelVolumeValor"' = 'name="VolumeValueLabel"'
    'name="SliderVolume"' = 'name="VolumeSlider"'
    'name="GradeEquipAtivas"' = 'name="EquippedActiveGrid"'
    'name="GradeEquipPassivas"' = 'name="EquippedPassiveGrid"'
    'name="GradeAtivas"' = 'name="ActiveGrid"'
    'name="GradePassivas"' = 'name="PassiveGrid"'
    'name="LinhaAbas"' = 'name="TabRow"'
    '/GradeSintese' = '/SynthesisGrid'
    '/GradeDesmontar' = '/DismantleGrid'
    '/BotaoPreenchimento' = '/AutofillButton'
    '/BotaoInfoNivel' = '/LevelInfoButton'
    '/ToggleTrilho' = '/ToggleTrack'
    '/BotaoAbaSintese' = '/SynthesisTabButton'
    '/BotaoAbaDesmontar' = '/DismantleTabButton'
    '/BotaoAbaJoias' = '/GemsTabButton'
    '/BotaoFiltroForja' = '/ForgeFilterButton'
    '/BotaoPreenchimentoDesmonte' = '/DismantleAutofillButton'
    '/BotaoFiltroDesmonte' = '/DismantleFilterButton'
    '/PanelSintese' = '/SynthesisPanel'
    '/PanelDesmontar' = '/DismantlePanel'
    '/PanelJoias' = '/GemsPanel'
    '/AreaJoias' = '/GemsArea'
    '/LabelExplicacaoForgePanel' = '/ForgeExplanationLabel'
    '/LabelExplicacaoDesmontar' = '/DismantleExplanationLabel'
    '/LabelExplicacaoJoias' = '/GemsExplanationLabel'
    '/LabelValorDesmonte' = '/DismantleValueLabel'
    '/CabecalhoForgePanel' = '/ForgeHeader'
    '/CorpoForgePanel' = '/ForgeBody'
    '/PainelForgePanel' = '/ForgePanel'
    '/Cabecalho' = '/Header'
    '/TituloConfig' = '/SettingsTitle'
    '/LabelVolumeTitulo' = '/VolumeTitleLabel'
    '/LabelVolumeValor' = '/VolumeValueLabel'
    '/SliderVolume' = '/VolumeSlider'
    '/GradeEquipAtivas' = '/EquippedActiveGrid'
    '/GradeEquipPassivas' = '/EquippedPassiveGrid'
    '/GradeAtivas' = '/ActiveGrid'
    '/GradePassivas' = '/PassiveGrid'
    '/LinhaAbas' = '/TabRow'
}

$targets = @(
    'presentation\inventory\forge_panel.gd',
    'presentation\inventory\forge_panel.tscn',
    'presentation\inventory\inventory_menu.gd',
    'presentation\inventory\inventory_menu.tscn',
    'presentation\inventory\skills_panel.gd',
    'presentation\inventory\skills_panel.tscn',
    'presentation\inventory\warehouse_panel.gd',
    'presentation\inventory\warehouse_panel.tscn'
)

foreach ($rel in $targets) {
    $path = Join-Path $Root $rel
    if (-not (Test-Path $path)) { continue }
    $text = [System.IO.File]::ReadAllText($path)
    $original = $text
    foreach ($k in $nodeMap.Keys) { $text = $text.Replace($k, $nodeMap[$k]) }
    if ($text -ne $original) {
        [System.IO.File]::WriteAllText($path, $text, $utf8NoBom)
        Write-Host "Updated $rel"
    }
}
Write-Host 'phase_d_unique_nodes complete'
