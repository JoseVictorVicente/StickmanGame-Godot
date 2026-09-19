# Generate English-named SkillResource .tres files from skill_catalog_data.py
$ErrorActionPreference = 'Stop'
$Root = Split-Path -Parent (Split-Path -Parent $MyInvocation.MyCommand.Path)
$Out = Join-Path $Root 'data\skills'
$CatalogPath = Join-Path $Root 'tools\skill_catalog_data.py'
$Text = Get-Content -Raw -Encoding UTF8 $CatalogPath
$catalogStart = $Text.IndexOf('CATALOG:')
if ($catalogStart -lt 0) { throw 'CATALOG block not found in skill_catalog_data.py' }
$Text = $Text.Substring($catalogStart)

function Slugify([string]$s) {
    $n = $s.Normalize([Text.NormalizationForm]::FormD)
    $sb = New-Object System.Text.StringBuilder
    foreach ($ch in $n.ToCharArray()) {
        if ([Globalization.CharUnicodeInfo]::GetUnicodeCategory($ch) -ne 'NonSpacingMark') {
            [void]$sb.Append($ch)
        }
    }
    $ascii = $sb.ToString()
    $ascii = [regex]::Replace($ascii, '[^a-zA-Z0-9]+', '_').Trim('_').ToLower()
    return $ascii
}

$ActiveCooldowns = @(5.0, 16.0, 6.0, 10.0, 12.0)
$ActiveOverrides = @{
    archer = @('instant_double_shot', 'dark_volley', 'precision_shot', 'hunter_stance', 'neon_vision')
}
$IconInnerOnly = @{
    archer = @('precision_shot', 'hunter_stance')
}

function Parse-Tuples([string]$block) {
    $list = New-Object System.Collections.Generic.List[object]
    foreach ($m in [regex]::Matches($block, '\("([^"]*)",\s*"([^"]*)",\s*"([^"]*)",\s*"([^"]*)"\)')) {
        $list.Add([pscustomobject]@{
            PtName = $m.Groups[1].Value
            PtDesc = $m.Groups[2].Value
            EnName = $m.Groups[3].Value
            EnDesc = $m.Groups[4].Value
        })
    }
    return $list
}

$classIds = @('archer', 'assassin', 'priest', 'warrior', 'mage', 'tank')
$skillLocales = [ordered]@{}
$skillIdMigration = @{}
$count = 0

foreach ($classId in $classIds) {
    $classPattern = "(?ms)`"$classId`":\s*\{\s*`"active`":\s*\[(.*?)\],\s*`"passive`":\s*\[(.*?)\]\s*,?\s*\}"
    $classMatch = [regex]::Match($Text, $classPattern)
    if (-not $classMatch.Success) { throw "Failed to parse class $classId from skill_catalog_data.py" }
    $active = Parse-Tuples $classMatch.Groups[1].Value
    $passive = Parse-Tuples $classMatch.Groups[2].Value
    $folder = Join-Path $Out $classId
    if (Test-Path $folder) {
        Get-ChildItem $folder -Filter '*.tres' | Remove-Item -Force
    } else {
        New-Item -ItemType Directory -Path $folder -Force | Out-Null
    }

    for ($i = 0; $i -lt $active.Count; $i++) {
        $entry = $active[$i]
        $legacyId = Slugify $entry.PtName
        $skillId = if ($ActiveOverrides.ContainsKey($classId) -and $i -lt $ActiveOverrides[$classId].Count) {
            $ActiveOverrides[$classId][$i]
        } else { Slugify $entry.EnName }
        if ($legacyId -ne $skillId) { $skillIdMigration[$legacyId] = $skillId }
        $sort = $i + 1
        $filename = '{0:D2}_{1}.tres' -f $sort, $skillId
        $inner = if ($IconInnerOnly.ContainsKey($classId) -and ($IconInnerOnly[$classId] -contains $skillId)) { "icon_inner_only = true`n" } else { '' }
        $content = @"
[gd_resource type="Resource" script_class="SkillResource" load_steps=2 format=3]

[ext_resource type="Script" path="res://data/skill_resource.gd" id="1_skill"]

[resource]
script = ExtResource("1_skill")
skill_id = "$skillId"
name_key = "SKILL_$skillId"
description_key = "SKILL_${skillId}_DESC"
type = 0
cooldown = $($ActiveCooldowns[$i])
icon_path = "res://sprites/ui/skills/$classId/$skillId.png"
${inner}sort_order = $sort
stat_value = 0.0
"@
        $utf8NoBom = New-Object System.Text.UTF8Encoding $false
        [System.IO.File]::WriteAllText((Join-Path $folder $filename), $content, $utf8NoBom)
        $skillLocales["SKILL_$skillId"] = @($entry.EnName, $entry.PtName)
        $skillLocales["SKILL_${skillId}_DESC"] = @($entry.EnDesc, $entry.PtDesc)
        $count++
    }

    for ($i = 0; $i -lt $passive.Count; $i++) {
        $entry = $passive[$i]
        $legacyId = Slugify $entry.PtName
        $skillId = Slugify $entry.EnName
        if ($legacyId -ne $skillId) { $skillIdMigration[$legacyId] = $skillId }
        $sort = $i + 1
        $filename = "p{0:D2}_{1}.tres" -f $sort, $skillId
        $content = @"
[gd_resource type="Resource" script_class="SkillResource" load_steps=2 format=3]

[ext_resource type="Script" path="res://data/skill_resource.gd" id="1_skill"]

[resource]
script = ExtResource("1_skill")
skill_id = "$skillId"
name_key = "SKILL_$skillId"
description_key = "SKILL_${skillId}_DESC"
type = 1
cooldown = 0
icon_path = "res://sprites/ui/skills/$classId/$skillId.png"
sort_order = $sort
stat_value = 0.0
"@
        $utf8NoBom = New-Object System.Text.UTF8Encoding $false
        [System.IO.File]::WriteAllText((Join-Path $folder $filename), $content, $utf8NoBom)
        $skillLocales["SKILL_$skillId"] = @($entry.EnName, $entry.PtName)
        $skillLocales["SKILL_${skillId}_DESC"] = @($entry.EnDesc, $entry.PtDesc)
        $count++
    }
}

# Export skill locales for gen_locales.ps1
$localeLines = @()
foreach ($k in $skillLocales.Keys) {
    $pair = $skillLocales[$k]
    $localeLines += "    '$k' = @('$($pair[0] -replace "'", "''")', '$($pair[1] -replace "'", "''")')"
}
$localeExport = @"
# Auto-generated by tools/generate_skills.ps1 — do not edit manually
`$skillLocales = [ordered]@{
$(($localeLines | ForEach-Object { $_ }) -join "`n")
}
"@
Set-Content -Path (Join-Path $Root 'tools\skill_locales.ps1') -Value $localeExport -Encoding UTF8

$migrationLines = @()
foreach ($k in $skillIdMigration.Keys) {
    $migrationLines += "    '$k' = '$($skillIdMigration[$k])'"
}
$migrationExport = @"
# Auto-generated by tools/generate_skills.ps1
`$skillIdMigration = @{
$(($migrationLines | ForEach-Object { $_ }) -join "`n")
}
"@
Set-Content -Path (Join-Path $Root 'tools\skill_id_migration.ps1') -Value $migrationExport -Encoding UTF8

Write-Host "Generated $count skill resources in $Out"
Write-Host "Skill locale keys: $($skillLocales.Count)"
