# ItemData enum/export migration (word-boundary safe)
$root = "C:\Users\Aleander\Desktop\stickmangame"
$dirs = @('presentation', 'domains', 'data', 'platform', 'core', 'scenes', 'tests')

$renames = [ordered]@{
  # export fields
  '@export var nome:' = '@export var display_name:'
  '@export var tipo:' = '@export var item_type:'
  '@export var raridade:' = '@export var rarity:'
  '@export var nivel_item:' = '@export var item_level:'
  '@export var dano_bonus:' = '@export var damage_bonus:'
  '@export var vida_bonus:' = '@export var hp_bonus:'
  '@export var atributo_gema:' = '@export var gem_attribute:'
  '@export var valor_gema:' = '@export var gem_value:'
  'var gema_imbuida:' = 'var embedded_gem:'

  # Type enum values
  'Type.CAPACETE' = 'Type.HELMET'
  'Type.PEITORAL' = 'Type.CHEST'
  'Type.ARMA' = 'Type.WEAPON'
  'Type.SECUNDARIA' = 'Type.OFFHAND'
  'Type.LUVA' = 'Type.GLOVES'
  'Type.CALCA' = 'Type.PANTS'
  'Type.BOTA' = 'Type.BOOTS'
  'Type.CINTO' = 'Type.BELT'
  'Type.PINGENTE' = 'Type.PENDANT'
  'Type.ANEL' = 'Type.RING'
  'Type.BRACELETE' = 'Type.BRACELET'
  'Type.GEMA' = 'Type.GEM'

  # GemAttribute values
  'GemAttribute.ATAQUE' = 'GemAttribute.ATTACK'
  'GemAttribute.ATAQUE_PCT' = 'GemAttribute.ATTACK_PCT'
  'GemAttribute.VIDA' = 'GemAttribute.HP'
  'GemAttribute.VIDA_PCT' = 'GemAttribute.HP_PCT'
  'GemAttribute.VEL_ATAQUE' = 'GemAttribute.ATTACK_SPEED'
  'GemAttribute.CRIT_DANO' = 'GemAttribute.CRIT_DAMAGE'
  'GemAttribute.EVASAO' = 'GemAttribute.EVASION'
  'GemAttribute.RES_FISICA' = 'GemAttribute.PHYS_RES'
  'GemAttribute.RES_ARCANA' = 'GemAttribute.ARCANE_RES'
  'GemAttribute.RES_ELEMENTAL' = 'GemAttribute.ELEMENTAL_RES'

  # Rarity values
  'Rarity.COMUM' = 'Rarity.COMMON'
  'Rarity.INCOMUM' = 'Rarity.UNCOMMON'
  'Rarity.RARO' = 'Rarity.RARE'
  'Rarity.EPICO' = 'Rarity.EPIC'
  'Rarity.LENDARIO' = 'Rarity.LEGENDARY'
  'Rarity.MITICO' = 'Rarity.MYTHIC'

  # Category values
  'Category.EQUIPAMENTO' = 'Category.EQUIPMENT'
  'Category.ACESSORIO' = 'Category.ACCESSORY'
  'Category.GEMA' = 'Category.GEM'

  # broken type annotations
  ': Tipo' = ': Type'
  ': Raridade' = ': Rarity'
  'as Tipo' = 'as Type'
  'as Raridade' = 'as Rarity'
  'Raridade.' = 'Rarity.'
  'Raridade)' = 'Rarity)'
  'Raridade,' = 'Rarity,'
  'Raridade ' = 'Rarity '
  'Raridade:' = 'Rarity:'
  'Raridade]' = 'Rarity]'
  'Raridade>' = 'Rarity>'
  '(Raridade' = '(Rarity'

  # property access (word boundary via regex below)
  '.nome' = '.display_name'
  '.tipo' = '.item_type'
  '.raridade' = '.rarity'
  '.nivel_item' = '.item_level'
  '.dano_bonus' = '.damage_bonus'
  '.vida_bonus' = '.hp_bonus'
  '.atributo_gema' = '.gem_attribute'
  '.valor_gema' = '.gem_value'
  '.gema_imbuida' = '.embedded_gem'

  # local identifiers in item_data
  'nome_de_raridade' = 'rarity_display_name'
  'p_raridade' = 'p_rarity'
  'raridade_item' = 'item_rarity'
  'eh_raridade_maxima' = 'is_max_rarity'
  'proxima_raridade' = 'next_rarity'
  'migrar_raridade_salva' = 'migrate_saved_rarity'
  'chance_forja_sucesso' = 'forge_success_chance'
  'chance_forja_sucesso_pct' = 'forge_success_chance_pct'
  'raridade_maxima' = 'max_rarity'
}

$fieldLocals = [ordered]@{
  '\bnome\b' = 'display_name'
  '\btipo\b' = 'item_type'
  '\braridade\b' = 'rarity'
  '\bnivel_item\b' = 'item_level'
  '\bdano_bonus\b' = 'damage_bonus'
  '\bvida_bonus\b' = 'hp_bonus'
  '\batributo_gema\b' = 'gem_attribute'
  '\bvalor_gema\b' = 'gem_value'
  '\bgema_imbuida\b' = 'embedded_gem'
}

$ordered = $renames.Keys | Sort-Object { $_.Length } -Descending
foreach ($dir in $dirs) {
  $base = Join-Path $root $dir
  if (-not (Test-Path $base)) { continue }
  Get-ChildItem $base -Recurse -Include '*.gd' | ForEach-Object {
    $text = [IO.File]::ReadAllText($_.FullName)
    $orig = $text
    foreach ($old in $ordered) {
      $text = $text.Replace($old, $renames[$old])
    }
    if ($_.Name -eq 'item_data.gd') {
      foreach ($pat in $fieldLocals.Keys) {
        $text = [regex]::Replace($text, $pat, $fieldLocals[$pat])
      }
    }
    if ($text -ne $orig) {
      [IO.File]::WriteAllText($_.FullName, $text)
      Write-Host $_.FullName.Replace($root + '\', '')
    }
  }
}
