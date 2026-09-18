# Phase 2: rename sprite/skill asset files and update res:// references.
$root = "C:\Users\Aleander\Desktop\stickmangame"
$git = "C:\Program Files\Git\cmd\git.exe"

$fileRenames = [ordered]@{
  "sprites/ui/capacete.png" = "sprites/ui/helmet.png"
  "sprites/ui/peitoral.png" = "sprites/ui/chest.png"
  "sprites/ui/arma.png" = "sprites/ui/weapon.png"
  "sprites/ui/secundaria.png" = "sprites/ui/offhand.png"
  "sprites/ui/luva.png" = "sprites/ui/gloves.png"
  "sprites/ui/calca.png" = "sprites/ui/pants.png"
  "sprites/ui/bota.png" = "sprites/ui/boots.png"
  "sprites/ui/cinto.png" = "sprites/ui/belt.png"
  "sprites/ui/pingente.png" = "sprites/ui/pendant.png"
  "sprites/ui/anel.png" = "sprites/ui/ring.png"
  "sprites/ui/bracelete.png" = "sprites/ui/bracelet.png"
  "sprites/ui/gema.png" = "sprites/ui/gem.png"
  "sprites/ui/fundo_painel.png" = "sprites/ui/panel_bg.png"
  "sprites/ui/fundo_inventario.png" = "sprites/ui/inventory_bg.png"
  "sprites/ui/fundo_mundos.png" = "sprites/ui/worlds_bg.png"
  "sprites/ui/fundo_forja.png" = "sprites/ui/forge_bg.png"
  "sprites/ui/nav_inventario.png" = "sprites/ui/nav_inventory.png"
  "sprites/ui/nav_ferraria.png" = "sprites/ui/nav_forge.png"
  "sprites/ui/nav_mundo.png" = "sprites/ui/nav_world.png"
  "sprites/ui/nav_atributos.png" = "sprites/ui/nav_attributes.png"
  "sprites/ui/nav_conquistas.png" = "sprites/ui/nav_achievements.png"
  "sprites/ui/nav_loja.png" = "sprites/ui/nav_shop.png"
  "sprites/heroes/px_arqueiro2.jpg" = "sprites/heroes/px_archer2.jpg"
  "sprites/heroes/px_guerreiro2.jpg" = "sprites/heroes/px_warrior2.jpg"
  "sprites/heroes/px_mago2.jpg" = "sprites/heroes/px_mage2.jpg"
  "sprites/heroes/px_sacerdote2.jpg" = "sprites/heroes/px_priest2.jpg"
  "sprites/heroes/px_tanque2.jpg" = "sprites/heroes/px_tank2.jpg"
  "sprites/heroes/px_assassino2.jpg" = "sprites/heroes/px_assassin2.jpg"
  "sprites/ui/skills/archer/tiro_duplo_instantaneo.png" = "sprites/ui/skills/archer/instant_double_shot.png"
  "sprites/ui/skills/archer/voleio_sombrio.png" = "sprites/ui/skills/archer/dark_volley.png"
  "sprites/ui/skills/archer/tiro_de_precisao.png" = "sprites/ui/skills/archer/precision_shot.png"
  "sprites/ui/skills/archer/postura_do_cacador.png" = "sprites/ui/skills/archer/hunter_stance.png"
  "sprites/ui/skills/archer/visao_neon.png" = "sprites/ui/skills/archer/neon_vision.png"
}

$skillFileRenames = [ordered]@{
  "01_tiro_duplo_instantaneo.tres" = "01_instant_double_shot.tres"
  "02_voleio_sombrio.tres" = "02_dark_volley.tres"
  "03_tiro_de_precisao.tres" = "03_precision_shot.tres"
  "04_postura_do_cacador.tres" = "04_hunter_stance.tres"
  "05_visao_neon.tres" = "05_neon_vision.tres"
}

function Rename-Asset($fromRel, $toRel) {
  $from = Join-Path $root $fromRel
  $to = Join-Path $root $toRel
  if (-not (Test-Path $from)) { return }
  $toDir = Split-Path $to -Parent
  if (-not (Test-Path $toDir)) { New-Item -ItemType Directory -Path $toDir -Force | Out-Null }
  if (Test-Path $git) {
    & $git mv $from $to 2>$null
    if (-not (Test-Path $to)) { Move-Item -Force $from $to }
  } else {
    Move-Item -Force $from $to
  }
  $fromImport = "$from.import"
  $toImport = "$to.import"
  if (Test-Path $fromImport) {
    if (Test-Path $git) { & $git mv $fromImport $toImport 2>$null } else { Move-Item -Force $fromImport $toImport }
    (Get-Content $toImport -Raw) -replace [regex]::Escape($fromRel.Replace('\','/')), $toRel.Replace('\','/') | Set-Content $toImport -NoNewline
  }
  Write-Host "RENAMED $fromRel -> $toRel"
}

foreach ($entry in $fileRenames.GetEnumerator()) {
  Rename-Asset $entry.Key $entry.Value
}

Get-ChildItem (Join-Path $root "data/skills/archer") -Filter "*.tres" | ForEach-Object {
  $base = $_.Name
  if ($skillFileRenames.Contains($base)) {
    $dest = Join-Path $_.DirectoryName $skillFileRenames[$base]
    if (Test-Path $git) { & $git mv $_.FullName $dest 2>$null } else { Move-Item -Force $_.FullName $dest }
    Write-Host "SKILL $($_.Name) -> $($skillFileRenames[$base])"
  }
}

$pathReplacements = @{}
foreach ($entry in $fileRenames.GetEnumerator()) {
  $pathReplacements["res://$($entry.Key.Replace('\','/'))"] = "res://$($entry.Value.Replace('\','/'))"
}
foreach ($entry in $skillFileRenames.GetEnumerator()) {
  $oldSlug = $entry.Key.Replace(".tres", "").Substring(3)
  $newSlug = $entry.Value.Replace(".tres", "").Substring(3)
  $pathReplacements["skills/archer/$oldSlug"] = "skills/archer/$newSlug"
  $pathReplacements[$oldSlug] = $newSlug
}

$scanDirs = @('presentation','domains','data','scenes','platform','core','tests','docs')
foreach ($dir in $scanDirs) {
  $base = Join-Path $root $dir
  if (-not (Test-Path $base)) { continue }
  Get-ChildItem $base -Recurse -Include '*.gd','*.tscn','*.tres','*.md' | ForEach-Object {
    $text = [IO.File]::ReadAllText($_.FullName)
    $orig = $text
    foreach ($old in ($pathReplacements.Keys | Sort-Object { $_.Length } -Descending)) {
      $text = $text.Replace($old, $pathReplacements[$old])
    }
    if ($text -ne $orig) {
      [IO.File]::WriteAllText($_.FullName, $text)
      Write-Host "UPDATED $($_.FullName.Replace($root + '\',''))"
    }
  }
}

# interface icon filenames
$iconFile = Join-Path $root "presentation/shared/interface_icons.gd"
$iconText = Get-Content $iconFile -Raw
$iconText = $iconText.Replace('capacete.png', 'helmet.png')
  .Replace('peitoral.png', 'chest.png')
  .Replace('arma.png', 'weapon.png')
  .Replace('secundaria.png', 'offhand.png')
  .Replace('luva.png', 'gloves.png')
  .Replace('calca.png', 'pants.png')
  .Replace('bota.png', 'boots.png')
  .Replace('cinto.png', 'belt.png')
  .Replace('pingente.png', 'pendant.png')
  .Replace('anel.png', 'ring.png')
  .Replace('bracelete.png', 'bracelet.png')
  .Replace('gema.png', 'gem.png')
Set-Content $iconFile $iconText -NoNewline

# bottom bar keys
$menuFile = Join-Path $root "presentation/inventory/inventory_menu.gd"
$menuText = Get-Content $menuFile -Raw
$menuText = $menuText.Replace('_setup_bar_button(botao_inventario, "inventario")', '_setup_bar_button(botao_inventario, "inventory")')
  .Replace('_setup_bar_button(botao_ferraria, "ferraria")', '_setup_bar_button(botao_ferraria, "forge")')
Set-Content $menuFile $menuText -NoNewline

Write-Host 'Phase 2 asset rename complete.'
