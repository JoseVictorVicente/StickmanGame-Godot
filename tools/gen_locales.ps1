# Generate locales/en.po, locales/pt_BR.po, locales/messages.pot
$ErrorActionPreference = 'Stop'
$Root = Split-Path -Parent (Split-Path -Parent $MyInvocation.MyCommand.Path)

$lkText = Get-Content -Raw -Encoding UTF8 (Join-Path $Root 'presentation\shared\locale_keys.gd')
$localeKeys = [regex]::Matches($lkText, 'const [A-Z_]+ := "([^"]+)"') | ForEach-Object { $_.Groups[1].Value }

$idbText = Get-Content -Raw -Encoding UTF8 (Join-Path $Root 'platform\item_database.gd')
. (Join-Path $Root 'tools\item_id_map.ps1')
$items = [regex]::Matches($idbText, '_create\("([^"]+)",\s*ItemData') | ForEach-Object {
    $id = $_.Groups[1].Value
    $pt = if ($itemNamePt.ContainsKey($id)) { $itemNamePt[$id] } else { $id }
    @{ id = $id; pt = $pt }
}

$skillLocalesPath = Join-Path $Root 'tools\skill_locales.ps1'
if (-not (Test-Path $skillLocalesPath)) {
    throw "Missing tools/skill_locales.ps1 - run tools/generate_skills.ps1 first"
}
. $skillLocalesPath
$skills = $skillLocales

$itemEn = $itemNameEn

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
