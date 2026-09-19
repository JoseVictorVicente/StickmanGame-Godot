# Generate English-named SkillResource .tres files from skill_catalog_data.py
$ErrorActionPreference = 'Stop'
$Root = Split-Path -Parent (Split-Path -Parent $MyInvocation.MyCommand.Path)
$Out = Join-Path $Root 'data\skills'
$CatalogPath = Join-Path $Root 'tools\skill_catalog_data.py'
$CatalogExportPath = Join-Path $Root 'tools\skill_catalog_export.json'
$ExportScriptPath = Join-Path $Root 'tools\export_skill_catalog.py'
$FullText = Get-Content -Raw -Encoding UTF8 $CatalogPath
$catalogStart = $FullText.IndexOf('CATALOG:')
if ($catalogStart -lt 0) { throw 'CATALOG block not found in skill_catalog_data.py' }
$Text = $FullText.Substring($catalogStart)

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

function Get-PythonLaunchers {
    $launchers = New-Object System.Collections.Generic.List[string]
    $candidates = @(
        (Join-Path $env:LOCALAPPDATA 'Programs\Python\Python312\python.exe'),
        (Join-Path $env:LOCALAPPDATA 'Programs\Python\Python313\python.exe'),
        (Join-Path $env:LOCALAPPDATA 'Programs\Python\Python311\python.exe')
    )
    foreach ($path in $candidates) {
        if (Test-Path $path) { $launchers.Add($path) }
    }
    foreach ($name in @('py', 'python3', 'python')) {
        $cmd = Get-Command $name -ErrorAction SilentlyContinue
        if ($null -eq $cmd) { continue }
        if ($cmd.Source -like '*WindowsApps*') { continue }
        if (-not $launchers.Contains($cmd.Source)) { $launchers.Add($cmd.Source) }
    }
    return $launchers.ToArray()
}

function Refresh-SkillCatalogExport {
    foreach ($launcher in (Get-PythonLaunchers)) {
        try {
            & $launcher $ExportScriptPath 2>$null
            if ($LASTEXITCODE -eq 0 -and (Test-Path $CatalogExportPath)) {
                return
            }
        } catch {
            continue
        }
    }
}

function Read-JsonFile([string]$path) {
    $json = Get-Content -Raw -Encoding UTF8 $path
    if ($PSVersionTable.PSVersion.Major -ge 6) {
        return ($json | ConvertFrom-Json -Depth 50)
    }
    Add-Type -AssemblyName System.Web.Extensions
    $serializer = New-Object System.Web.Script.Serialization.JavaScriptSerializer
    $serializer.MaxJsonLength = 67108864
    $serializer.RecursionLimit = 128
    return $serializer.DeserializeObject($json)
}

function Import-SkillCatalogExport {
    Refresh-SkillCatalogExport
    if (-not (Test-Path $CatalogExportPath)) {
        throw "Missing $CatalogExportPath. Install Python and run: python tools/export_skill_catalog.py"
    }
    return Read-JsonFile $CatalogExportPath
}

function ConvertTo-Hashtable([object]$InputObject) {
    if ($null -eq $InputObject) { return $null }
    if ($InputObject -is [System.Collections.IDictionary]) {
        $table = @{}
        foreach ($key in $InputObject.Keys) {
            $table[$key] = ConvertTo-Hashtable $InputObject[$key]
        }
        return $table
    }
    if ($InputObject -is [System.Collections.IEnumerable] -and $InputObject -isnot [string]) {
        $list = New-Object System.Collections.Generic.List[object]
        foreach ($item in $InputObject) {
            $list.Add((ConvertTo-Hashtable $item))
        }
        return $list.ToArray()
    }
    if ($InputObject -is [pscustomobject]) {
        $table = @{}
        foreach ($prop in $InputObject.PSObject.Properties) {
            $table[$prop.Name] = ConvertTo-Hashtable $prop.Value
        }
        return $table
    }
    return $InputObject
}

function Get-ExportMapValue([object]$map, [string]$key) {
    if ($null -eq $map) { return $null }
    if ($map -is [System.Collections.IDictionary]) {
        if ($map.Contains($key)) { return $map[$key] }
        return $null
    }
    return $map.$key
}

function Get-ExportMapEntries([object]$map) {
    if ($null -eq $map) { return @() }
    if ($map -is [System.Collections.IDictionary]) {
        return $map.Keys
    }
    return $map.PSObject.Properties.Name
}

function Ensure-Array([object]$value) {
    if ($null -eq $value) { return @() }
    if ($value -isnot [System.Collections.IEnumerable] -or $value -is [string]) {
        return @($value)
    }
    $list = New-Object System.Collections.Generic.List[object]
    foreach ($item in $value) {
        $list.Add($item)
    }
    return $list.ToArray()
}

function Get-EffectValue([object]$effect, [string]$name, $default = $null) {
    if ($null -eq $effect) { return $default }
    if ($effect -is [System.Collections.IDictionary]) {
        if ($effect.Contains($name)) { return $effect[$name] }
        return $default
    }
    if ($effect.PSObject.Properties.Name -contains $name) {
        return $effect.$name
    }
    return $default
}

function Format-EffectSubresource([object]$effect, [int]$index) {
    $subId = "Effect_$index"
    $effectType = [string](Get-EffectValue $effect 'effect_type' '')
    if ($effectType -eq 'buff_self') {
        $body = @"
[sub_resource type="Resource" id="$subId"]
script = ExtResource("effect_$index")
effect_type = "$effectType"
stat_key = "$(Get-EffectValue $effect 'stat_key' '')"
stat_value = $(Get-EffectValue $effect 'stat_value' 0.0)
duration_sec = $(Get-EffectValue $effect 'duration_sec' 0.0)

"@
    } elseif ($effectType -in @('heal_party', 'heal_self', 'heal_lowest')) {
        $body = @"
[sub_resource type="Resource" id="$subId"]
script = ExtResource("effect_$index")
effect_type = "$effectType"
heal_pct_max_hp = $(Get-EffectValue $effect 'heal_pct_max_hp' 15.0)
target_scope = "$(Get-EffectValue $effect 'target_scope' 'party')"

"@
    } else {
        $forceCrit = if ([bool](Get-EffectValue $effect 'force_crit' $false)) { 'true' } else { 'false' }
        $body = @"
[sub_resource type="Resource" id="$subId"]
script = ExtResource("effect_$index")
effect_type = "$effectType"
multiplier = $(Get-EffectValue $effect 'multiplier' 1.0)
hits = $(Get-EffectValue $effect 'hits' 1)
force_crit = $forceCrit
armor_pen_pct = $(Get-EffectValue $effect 'armor_pen_pct' 0.0)

"@
    }
    return @{ Id = $subId; Body = $body }
}

function Format-ActiveEffectsBlock([array]$effects) {
    if ($null -eq $effects -or $effects.Count -eq 0) {
        return @{ LoadSteps = 2; Ext = ''; Sub = ''; Line = 'effects = []' + "`n" }
    }
    $extLines = New-Object System.Collections.Generic.List[string]
    $subLines = New-Object System.Collections.Generic.List[string]
    $refs = New-Object System.Collections.Generic.List[string]
    for ($i = 0; $i -lt $effects.Count; $i++) {
        $effect = $effects[$i]
        $effectType = [string](Get-EffectValue $effect 'effect_type' '')
        $scriptPath = if ($effectType -eq 'buff_self') {
            'res://data/effects/buff_effect.gd'
        } elseif ($effectType -in @('heal_party', 'heal_self', 'heal_lowest')) {
            'res://data/effects/heal_effect.gd'
        } else {
            'res://data/effects/damage_effect.gd'
        }
        $extLines.Add("[ext_resource type=`"Script`" path=`"$scriptPath`" id=`"effect_$i`"]")
        $formatted = Format-EffectSubresource $effect $i
        $subLines.Add($formatted.Body)
        $refs.Add("SubResource(`"$($formatted.Id)`")")
    }
    $loadSteps = 2 + ($effects.Count * 2)
    return @{
        LoadSteps = $loadSteps
        Ext = ($extLines -join "`n")
        Sub = ($subLines -join "`n")
        Line = "effects = [$($refs -join ', ')]`n"
    }
}

function Parse-PassiveStats([string]$sourceText) {
    $stats = @{}
    $blockMatch = [regex]::Match($sourceText, '(?ms)PASSIVE_STATS:\s*dict\[.*?\]\s*=\s*\{(.*?)\n\}')
    if (-not $blockMatch.Success) { throw 'PASSIVE_STATS block not found in skill_catalog_data.py' }
    $block = $blockMatch.Groups[1].Value
    foreach ($classMatch in [regex]::Matches($block, '(?ms)"([a-z]+)":\s*\[(.*?)\]')) {
        $classId = $classMatch.Groups[1].Value
        $entries = [regex]::Matches($classMatch.Groups[2].Value, '\("([^"]+)",\s*([0-9.]+)\)')
        $list = New-Object System.Collections.Generic.List[object]
        foreach ($entry in $entries) {
            $list.Add([pscustomobject]@{
                Key = $entry.Groups[1].Value
                Value = [double]$entry.Groups[2].Value
            })
        }
        $stats[$classId] = $list
    }
    return $stats
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

function Assert-ActiveCatalogLengths([string]$classId, [int]$activeCount, $catalogExport) {
    $effects = Get-ExportMapValue (Get-ExportMapValue $catalogExport 'active_effects') $classId
    $vfx = Get-ExportMapValue (Get-ExportMapValue $catalogExport 'active_vfx') $classId
    if ($null -ne $effects -and $effects.Count -gt 0 -and $effects.Count -ne $activeCount) {
        throw "ACTIVE_EFFECTS['$classId'] has $($effects.Count) entries, expected $activeCount"
    }
    if ($null -ne $vfx -and $vfx.Count -gt 0 -and $vfx.Count -ne $activeCount) {
        throw "ACTIVE_VFX['$classId'] has $($vfx.Count) entries, expected $activeCount"
    }
}

$catalogExport = ConvertTo-Hashtable (Import-SkillCatalogExport)
$ActiveCooldowns = Ensure-Array $catalogExport['active_cooldowns']
$ActiveOverrides = @{}
foreach ($classKey in (Get-ExportMapEntries $catalogExport['active_id_overrides'])) {
    $ActiveOverrides[$classKey] = Ensure-Array $catalogExport['active_id_overrides'][$classKey]
}
$ActiveEffects = @{}
foreach ($classKey in (Get-ExportMapEntries $catalogExport['active_effects'])) {
    $classEffects = New-Object System.Collections.Generic.List[object]
    foreach ($skillEffects in (Ensure-Array $catalogExport['active_effects'][$classKey])) {
        $effectList = New-Object System.Collections.Generic.List[object]
        if ($null -ne $skillEffects) {
            foreach ($effect in (Ensure-Array $skillEffects)) {
                $effectList.Add((ConvertTo-Hashtable $effect))
            }
        }
        $classEffects.Add($effectList.ToArray())
    }
    $ActiveEffects[$classKey] = Ensure-Array $classEffects
}
$ActiveVfx = @{}
foreach ($classKey in (Get-ExportMapEntries $catalogExport['active_vfx'])) {
    $ActiveVfx[$classKey] = Ensure-Array $catalogExport['active_vfx'][$classKey]
}
$IconInnerOnly = @{}
foreach ($classKey in (Get-ExportMapEntries $catalogExport['icon_inner_only'])) {
    $IconInnerOnly[$classKey] = Ensure-Array $catalogExport['icon_inner_only'][$classKey]
}

$classIds = @('archer', 'assassin', 'priest', 'warrior', 'mage', 'tank')
$PassiveStats = Parse-PassiveStats $FullText
$skillLocales = [ordered]@{}
$skillIdMigration = @{}
$count = 0

foreach ($classId in $classIds) {
    $classPattern = "(?ms)`"$classId`":\s*\{\s*`"active`":\s*\[(.*?)\],\s*`"passive`":\s*\[(.*?)\]\s*,?\s*\}"
    $classMatch = [regex]::Match($Text, $classPattern)
    if (-not $classMatch.Success) { throw "Failed to parse class $classId from skill_catalog_data.py" }
    $active = Parse-Tuples $classMatch.Groups[1].Value
    $passive = Parse-Tuples $classMatch.Groups[2].Value
    Assert-ActiveCatalogLengths $classId $active.Count $catalogExport
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
        $classEffects = @()
        if ($ActiveEffects.ContainsKey($classId) -and $i -lt $ActiveEffects[$classId].Count) {
            $classEffects = Ensure-Array $ActiveEffects[$classId][$i]
        }
        $vfxId = ''
        if ($ActiveVfx.ContainsKey($classId) -and $i -lt $ActiveVfx[$classId].Count) {
            $vfxId = $ActiveVfx[$classId][$i]
        }
        $fx = Format-ActiveEffectsBlock $classEffects
        $extraExt = if ($fx.Ext) { "`n$($fx.Ext)" } else { '' }
        $extraSub = if ($fx.Sub) { "`n$($fx.Sub)" } else { '' }
        $content = @"
[gd_resource type="Resource" script_class="SkillResource" load_steps=$($fx.LoadSteps) format=3]

[ext_resource type="Script" path="res://data/skill_resource.gd" id="1_skill"]$extraExt
$extraSub
[resource]
script = ExtResource("1_skill")
skill_id = "$skillId"
name_key = "SKILL_$skillId"
description_key = "SKILL_${skillId}_DESC"
type = 0
cooldown = $(if ($i -lt $ActiveCooldowns.Count) { $ActiveCooldowns[$i] } else { 8.0 })
icon_path = "res://sprites/ui/skills/$classId/$skillId.png"
${inner}sort_order = $sort
stat_bonus_key = ""
stat_value = 0.0
vfx_id = "$vfxId"
$($fx.Line)
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
        $statKey = ''
        $statValue = 0.0
        if ($PassiveStats.ContainsKey($classId) -and $i -lt $PassiveStats[$classId].Count) {
            $statKey = $PassiveStats[$classId][$i].Key
            $statValue = $PassiveStats[$classId][$i].Value
        }
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
stat_bonus_key = "$statKey"
stat_value = $statValue
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
