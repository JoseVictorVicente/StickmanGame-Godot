# Generate locales/en.po, locales/pt_BR.po, locales/messages.pot
$ErrorActionPreference = 'Stop'
$Root = Split-Path -Parent (Split-Path -Parent $MyInvocation.MyCommand.Path)

$lkText = Get-Content -Raw -Encoding UTF8 (Join-Path $Root 'presentation\shared\locale_keys.gd')
$localeKeys = [regex]::Matches($lkText, 'const [A-Z_]+ := "([^"]+)"') | ForEach-Object { $_.Groups[1].Value }

$idbText = Get-Content -Raw -Encoding UTF8 (Join-Path $Root 'platform\item_database.gd')
$items = [regex]::Matches($idbText, '_create\("([^"]+)", "([^"]+)"') | ForEach-Object {
    @{ id = $_.Groups[1].Value; pt = $_.Groups[2].Value }
}

$skills = [ordered]@{
    'SKILL_instant_double_shot' = @('Instant Double Shot', 'Tiro Duplo Instantâneo')
    'SKILL_instant_double_shot_DESC' = @('Fires two rapid consecutive shots with 200% critical damage.', 'Executa dois disparos rapidos consecutivos com 200% de dano critico.')
    'SKILL_dark_volley' = @('Dark Volley', 'Voleio Sombrio')
    'SKILL_dark_volley_DESC' = @('Enters focus stance for 2 seconds and fires a burst of 10 energized arrows at high speed at the strongest target.', 'Entra em postura de foco por 2 segundos e dispara uma rajada de 10 flechas energizadas em alta velocidade direto no alvo mais forte.')
    'SKILL_precision_shot' = @('Precision Shot', 'Tiro de Precisão')
    'SKILL_precision_shot_DESC' = @('A 0.4s charged shot that guarantees a critical hit and ignores 30% armor.', 'Um disparo carregado de 0.4s que garante acerto critico e ignora 30% da armadura.')
    'SKILL_hunter_stance' = @('Hunter Stance', 'Postura do Caçador')
    'SKILL_hunter_stance_DESC' = @('Plants feet lightly and gains 30% Attack Speed and 10% Physical Damage for 3.5 seconds.', 'A Arqueira finca levemente os pes no chao e ganha um surto de 30% de Velocidade de Ataque e 10% de Dano Fisico por 3.5 segundos.')
    'SKILL_neon_vision' = @('Neon Vision', 'Visão Neon')
    'SKILL_neon_vision_DESC' = @('Eyes glow intense neon green, increasing Critical Hit Rate by 30% and making all arrows pierce the first enemy for 4 seconds.', 'Seus olhos brilham em verde neon intenso, aumentando a Taxa de Acerto Critico em 30% e fazendo todas as flechas atravessarem o primeiro inimigo por 4 segundos.')
}

$itemEn = @{
    espada_ferro='Iron Sword'; espada_treino='Training Sword'; escudo_madeira='Wooden Shield'
    elmo_guerreiro='Warrior Helmet'; peitoral_guerreiro='Warrior Chestplate'; luvas_guerreiro='Warrior Gloves'
    calca_guerreiro='Warrior Pants'; botas_guerreiro='Warrior Boots'; mascote_leao='Lion Pet'
    anel_honra='Ring of Honor'; bracelete_guerreiro='Warrior Bracelet'; cajado_arcano='Arcane Staff'
    grimorio='Grimoire'; familiar='Arcane Familiar'; manto_mistico='Mystic Cloak'; tiara_arcano='Arcane Tiara'
    luvas_mago='Mage Gloves'; calca_mago='Mage Pants'; botas_mago='Mage Boots'; cinto_arcano='Arcane Belt'
    pingente_mana='Mana Pendant'; arco_curto='Short Bow'; aljava='Quiver'; capuz_couro='Leather Hood'
    peitoral_arqueiro='Archer Chestplate'; luvas_arqueiro='Archer Gloves'; calca_arqueiro='Archer Pants'
    botas_arqueiro='Archer Boots'; falcao_companheiro='Companion Falcon'; anel_precisao='Precision Ring'
    adaga_sombria='Shadow Dagger'; adaga_secundaria='Twin Dagger'; capuz_assassino='Assassin Hood'
    peitoral_sombrio='Shadow Chestplate'; luvas_assassino='Assassin Gloves'; calca_assassino='Assassin Pants'
    botas_assassino='Assassin Boots'; cinto_sombrio='Shadow Belt'; bracelete_sombrio='Shadow Bracelet'
    maca_pesada='Heavy Mace'; escudo_torre='Tower Shield'; peitoral_ferro='Iron Chestplate'
    elmo_torre='Tower Helmet'; luvas_tanque='Tank Gloves'; calca_tanque='Tank Pants'; botas_tanque='Tank Boots'
    mascote_tartaruga='Turtle Pet'; pingente_guardiao='Guardian Pendant'; cajado_sagrado='Holy Staff'
    tomo_luz='Tome of Light'; manto_clerical='Clerical Cloak'; pingente_fe='Faith Pendant'
    tiara_sagrada='Sacred Tiara'; luvas_sacerdote='Priest Gloves'; calca_sacerdote='Priest Pants'
    botas_sacerdote='Priest Boots'; anel_devocao='Devotion Ring'; luvas_tecido='Cloth Gloves'
    calca_couro='Leather Pants'; botas_viagem='Travel Boots'; cinto_simples='Simple Belt'
    anel_bruto='Rough Ring'; bracelete_ferro='Iron Bracelet'; capuz_viagem='Travel Hood'
    peitoral_couro='Leather Chestplate'; pingente_simples='Simple Pendant'; mascote_rato='Rat Pet'
}

# Load translations from embedded JSON-like hashtables via here-strings parsed manually is too heavy.
# Use the Python file's dictionaries by invoking Get-Content and regex on gen_locales.py for UI_EN/UI_PT blocks.
$py = Get-Content -Raw -Encoding UTF8 (Join-Path $Root 'tools\gen_locales.py')
function Parse-DictBlock([string]$name) {
    $pattern = "(?ms)$name = \{(.+?)\n\}"
    $m = [regex]::Match($py, $pattern)
    if (-not $m.Success) { throw "Block $name not found" }
    $block = $m.Groups[1].Value
    $dict = @{}
    foreach ($line in ($block -split "`n")) {
        $lm = [regex]::Match($line, '^\s+"([^"]+)":\s+"(.*)",\s*$')
        if ($lm.Success) {
            $val = $lm.Groups[2].Value -replace '\\"', '"' -replace '\\\\', '\'
            $dict[$lm.Groups[1].Value] = $val
        }
    }
    return $dict
}

$uiEn = Parse-DictBlock 'UI_EN'
$uiPt = Parse-DictBlock 'UI_PT'

$allKeys = New-Object System.Collections.Generic.List[string]
$seen = @{}
foreach ($k in $localeKeys) { if (-not $seen.ContainsKey($k)) { $allKeys.Add($k); $seen[$k] = $true } }
foreach ($it in $items) {
    $k = "ITEM_$($it.id)"
    if (-not $seen.ContainsKey($k)) { $allKeys.Add($k); $seen[$k] = $true }
}
foreach ($k in $skills.Keys) {
    if (-not $seen.ContainsKey($k)) { $allKeys.Add($k); $seen[$k] = $true }
}

function Escape-Po([string]$s) {
    return ($s -replace '\\', '\\' -replace '"', '\"')
}

function Write-PoFile([string]$path, [hashtable]$translations, [bool]$empty, [string]$lang) {
    $lines = New-Object System.Collections.Generic.List[string]
    if ($path -like '*.pot') {
        $lines.Add('# Translation template — Stickman Idle')
        $lines.Add('# Copy new msgid entries to locales/pt_BR.po and locales/en.po')
        $lines.Add('# Godot loads .po files listed in project.godot [internationalization]')
        $lines.Add('')
    }
    $lines.Add('msgid ""')
    $lines.Add('msgstr ""')
    $lines.Add('"Content-Type: text/plain; charset=UTF-8\n"')
    if (-not $empty) { $lines.Add('"Language: ' + $lang + '\n"') }
    $lines.Add('')
    foreach ($key in $allKeys) {
        $lines.Add('msgid "' + (Escape-Po $key) + '"')
        if ($empty) {
            $lines.Add('msgstr ""')
        } else {
            $val = $translations[$key]
            $lines.Add('msgstr "' + (Escape-Po $val) + '"')
        }
        $lines.Add('')
    }
    [System.IO.File]::WriteAllText($path, ($lines -join "`n"), [System.Text.UTF8Encoding]::new($false))
    return $allKeys.Count
}

$en = @{}; $pt = @{}
foreach ($k in $uiEn.Keys) { $en[$k] = $uiEn[$k]; $pt[$k] = $uiPt[$k] }
foreach ($it in $items) {
    $k = "ITEM_$($it.id)"
    $en[$k] = $itemEn[$it.id]
    $pt[$k] = $it.pt
}
foreach ($k in $skills.Keys) {
    $en[$k] = $skills[$k][0]
    $pt[$k] = $skills[$k][1]
}

$locales = Join-Path $Root 'locales'
$enCount = Write-PoFile (Join-Path $locales 'en.po') $en $false 'en'
$ptCount = Write-PoFile (Join-Path $locales 'pt_BR.po') $pt $false 'pt_BR'
$potCount = Write-PoFile (Join-Path $locales 'messages.pot') @{} $true ''

Write-Host "locale_keys: $($localeKeys.Count)"
Write-Host "items: $($items.Count)"
Write-Host "skills: $($skills.Count)"
Write-Host "en.po: $enCount keys"
Write-Host "pt_BR.po: $ptCount keys"
Write-Host "messages.pot: $potCount keys"
