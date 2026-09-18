$root = "C:\Users\Aleander\Desktop\stickmangame"
$dirs = @('presentation', 'domains', 'data', 'platform', 'core', 'scenes', 'tests')
$fixes = [ordered]@{
  'Ihas_classData' = 'ItemData'
  'Ihas_classSlot' = 'ItemSlot'
  'CanvasIhas_class' = 'CanvasItem'
  'ihas_class_type' = 'item_type'
  'ihas_class_level' = 'item_level'
  'ihas_class_clicked' = 'item_clicked'
  'ihas_class_double_clicked' = 'item_double_clicked'
  'ihas_class_right_clicked' = 'item_right_clicked'
  'ihas_class_dropped' = 'item_dropped'
  'set_ihas_class' = 'set_item'
  'get_equipped_ihas_classs' = 'get_equipped_items'
  'p_ihas_class' = 'p_item'
  'novo_ihas_class' = 'new_item'
  'candidato_ihas_class' = 'candidate_item'
  'origem_ihas_class' = 'source_item'
  'destino_ihas_class' = 'dest_item'
  'slot_ihas_class' = 'slot_item'
  'reservado_ihas_class' = 'reserved_item'
  'tipo_ihas_class' = 'item_kind'
  'filtro_ihas_class' = 'item_filter'
  'lista_ihas_class' = 'item_list'
  'grade_ihas_class' = 'item_grid'
  'valor_ihas_class' = 'item_value'
  'nome_ihas_class' = 'item_name'
  'sigla_ihas_class' = 'item_abbr'
  'CamadaLegendaIhas_class' = 'TooltipLayer'
  'ihas_class:' = 'item:'
  'ihas_class ' = 'item '
  'ihas_class)' = 'item)'
  'ihas_class,' = 'item,'
  'ihas_class.' = 'item.'
  'ihas_class=' = 'item='
  'ihas_class\n' = 'item\n'
  '(ihas_class' = '(item'
  '[ihas_class' = '[item'
  '"ihas_class"' = '"item"'
  "'ihas_class'" = "'item'"
}

$ordered = $fixes.Keys | Sort-Object { $_.Length } -Descending
foreach ($dir in $dirs) {
  $base = Join-Path $root $dir
  if (-not (Test-Path $base)) { continue }
  Get-ChildItem $base -Recurse -Include '*.gd','*.tscn' | ForEach-Object {
    $text = [IO.File]::ReadAllText($_.FullName)
    $orig = $text
    foreach ($old in $ordered) {
      $text = $text.Replace($old, $fixes[$old])
    }
    if ($text -ne $orig) {
      [IO.File]::WriteAllText($_.FullName, $text)
      Write-Host $_.Name
    }
  }
}
