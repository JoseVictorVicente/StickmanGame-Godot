$ErrorActionPreference = "Stop"
$root = Split-Path -Parent $PSScriptRoot
$out = Join-Path $root "dados\habilidades"
$activeCooldowns = @(5.0, 16.0, 6.0, 10.0, 12.0)

function Slugify([string]$text) {
    $normalized = $text.Normalize([Text.NormalizationForm]::FormD)
    $sb = New-Object System.Text.StringBuilder
    foreach ($ch in $normalized.ToCharArray()) {
        if ([Globalization.CharUnicodeInfo]::GetUnicodeCategory($ch) -ne [Globalization.UnicodeCategory]::NonSpacingMark) {
            [void]$sb.Append($ch)
        }
    }
    $ascii = $sb.ToString()
    $ascii = $ascii -replace '[^a-zA-Z0-9]+', '_'
    return $ascii.Trim('_').ToLower()
}

function Write-SkillTres($path, $skillId, $name, $desc, $type, $cooldown, $sortOrder, $classe) {
    $iconPath = "res://sprites/ui/skills/$classe/$skillId.png"
    $desc = $desc -replace '"', "'"
    $name = $name -replace '"', "'"
    $content = @"
[gd_resource type="Resource" script_class="SkillResource" load_steps=2 format=3]

[ext_resource type="Script" path="res://dados/skill_resource.gd" id="1_skill"]

[resource]
script = ExtResource("1_skill")
skill_id = "$skillId"
skill_name = "$name"
description = "$desc"
type = $type
cooldown = $cooldown
icon_path = "$iconPath"
sort_order = $sortOrder
stat_value = 0.0
"@
    $dir = Split-Path -Parent $path
    if (-not (Test-Path $dir)) { New-Item -ItemType Directory -Path $dir -Force | Out-Null }
    Set-Content -Path $path -Value $content -Encoding UTF8
}

# Import catalog from companion data file generated inline below
$catalogPath = Join-Path $PSScriptRoot "skills_data.ps1"
. $catalogPath

foreach ($classe in $Catalog.Keys) {
    $pasta = Join-Path $out $classe
    if (Test-Path $pasta) { Get-ChildItem $pasta -Filter "*.tres" | Remove-Item -Force }
    $ativas = $Catalog[$classe].active
    for ($i = 0; $i -lt $ativas.Count; $i++) {
        $nome = $ativas[$i][0]
        $desc = $ativas[$i][1]
        $id = Slugify $nome
        $ordem = $i + 1
        $arquivo = Join-Path $pasta ("{0:D2}_{1}.tres" -f $ordem, $id)
        Write-SkillTres $arquivo $id $nome $desc 0 $activeCooldowns[$i] $ordem $classe
    }
    $passivas = $Catalog[$classe].passive
    for ($i = 0; $i -lt $passivas.Count; $i++) {
        $nome = $passivas[$i][0]
        $desc = $passivas[$i][1]
        $id = Slugify $nome
        $ordem = $i + 1
        $arquivo = Join-Path $pasta ("p{0:D2}_{1}.tres" -f $ordem, $id)
        Write-SkillTres $arquivo $id $nome $desc 1 0.0 $ordem $classe
    }
}

Write-Host "Gerados recursos de habilidades para $($Catalog.Keys.Count) classes."
