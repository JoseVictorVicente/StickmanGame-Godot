# Imports PixelLab hero characters (tag HERO) into sprites/heroes/<class_id>/.
# Only copies animations renamed: IDLE_ANIMATION, RUNNING_ANIMATION, ATTACK_ANIMATION, DEATH_ANIMATION.

$ErrorActionPreference = "Stop"
Add-Type -AssemblyName System.IO.Compression.FileSystem

$Repo = Split-Path -Parent $PSScriptRoot
$Tmp = Join-Path $Repo "tools\_tmp_import\pixellab_heroes"
New-Item -ItemType Directory -Force -Path $Tmp | Out-Null

$NamedAnims = @{
    "IDLE_ANIMATION"    = "idle"
    "RUNNING_ANIMATION" = "run"
    "ATTACK_ANIMATION"  = "attack"
    "DEATH_ANIMATION"   = "death"
}

$Heroes = @(
    @{ class_id = "archer";    character_id = "5144da5d-ae83-40c2-b6e1-855f9debf9fe" },
    @{ class_id = "tank";      character_id = "8f846bdf-45ff-496a-8413-0892f865b715" },
    @{ class_id = "barbarian"; character_id = "5e279311-dd3b-405f-93e2-74aed522d30f" },
    @{ class_id = "priest";    character_id = "12bdf4f9-59fd-4d0c-8003-b74fe5ee77b2" },
    @{ class_id = "warrior";   character_id = "b4360101-4162-403a-af6b-31521fb0ea09" }
)

function Clear-FrameDir([string]$Path) {
    if (Test-Path $Path) {
        Get-ChildItem $Path -Filter "frame_*.png" | Remove-Item -Force
    } else {
        New-Item -ItemType Directory -Force -Path $Path | Out-Null
    }
}

function Import-HeroZip([hashtable]$Hero) {
    $classId = $Hero.class_id
    $charId = $Hero.character_id
    $zipPath = Join-Path $Tmp "$classId.zip"
    $url = "https://api.pixellab.ai/mcp/characters/$charId/download"

    Write-Host "Downloading $classId ..."
    curl.exe -sL -o $zipPath $url
    if (-not (Test-Path $zipPath) -or (Get-Item $zipPath).Length -lt 1024) {
        throw "Download failed for $classId"
    }

    $outBase = Join-Path $Repo "sprites\heroes\$classId"
    foreach ($sub in $NamedAnims.Values) {
        Clear-FrameDir (Join-Path $outBase $sub)
    }

    $zip = [System.IO.Compression.ZipFile]::OpenRead($zipPath)
    try {
        $counts = @{}
        foreach ($entry in $zip.Entries) {
            $name = $entry.FullName -replace "\\", "/"
            if ($name -notmatch "/animations/([^/]+)/east/frame_(\d+)\.png$") { continue }
            $animKey = $Matches[1].ToUpperInvariant()
            if (-not $NamedAnims.ContainsKey($animKey)) { continue }
            $destSub = $NamedAnims[$animKey]
            $frameIdx = [int]$Matches[2]
            $destDir = Join-Path $outBase $destSub
            New-Item -ItemType Directory -Force -Path $destDir | Out-Null
            $destPath = Join-Path $destDir ("frame_{0:D3}.png" -f $frameIdx)
            [System.IO.Compression.ZipFileExtensions]::ExtractToFile($entry, $destPath, $true)
            $counts[$destSub] = [Math]::Max($counts[$destSub], $frameIdx + 1)
        }

        # Fallback idle: duplicate east rotation when IDLE_ANIMATION missing (e.g. archer).
        $idleDir = Join-Path $outBase "idle"
        $idleCount = if ($counts.ContainsKey("idle")) { $counts["idle"] } else { 0 }
        if ($idleCount -eq 0) {
            $rotEntry = $zip.Entries | Where-Object { $_.FullName -match "rotations/east\.png$" } | Select-Object -First 1
            if ($null -ne $rotEntry) {
                New-Item -ItemType Directory -Force -Path $idleDir | Out-Null
                for ($i = 0; $i -lt 4; $i++) {
                    $destPath = Join-Path $idleDir ("frame_{0:D3}.png" -f $i)
                    [System.IO.Compression.ZipFileExtensions]::ExtractToFile($rotEntry, $destPath, $true)
                }
                $counts["idle"] = 4
            }
        }

        Write-Host ("  {0}: idle={1} run={2} attack={3} death={4}" -f $classId,
            $(if ($counts.ContainsKey("idle")) { $counts["idle"] } else { 0 }),
            $(if ($counts.ContainsKey("run")) { $counts["run"] } else { 0 }),
            $(if ($counts.ContainsKey("attack")) { $counts["attack"] } else { 0 }),
            $(if ($counts.ContainsKey("death")) { $counts["death"] } else { 0 }))
    } finally {
        $zip.Dispose()
    }
}

foreach ($hero in $Heroes) {
    Import-HeroZip $hero
}

Write-Host "Done. Imported $($Heroes.Count) heroes into sprites/heroes/<class_id>/"
