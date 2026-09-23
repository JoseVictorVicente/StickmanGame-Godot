# Slices Flying Demon source sheets into frame folders (idle/run/attack/death).

$ErrorActionPreference = "Stop"
$root = Split-Path -Parent $PSScriptRoot
$srcDir = Join-Path $root "sprites\enemies\flying_demon\source"
$outBase = Join-Path $root "sprites\enemies\flying_demon"

$jobs = @(
    @{ Key = "idle";   Out = "idle";   Aliases = @("idle.png", "BOSS_CORRENDO") },
    @{ Key = "run";    Out = "run";    Aliases = @("run.png", "ANDANDO", "VOANDO") },
    @{ Key = "attack"; Out = "attack"; Aliases = @("attack.png", "ATAQUE") },
    @{ Key = "death";  Out = "death";  Aliases = @("death.png", "MORRENDO") }
)

function Find-SourceSheet([string[]]$Aliases) {
    foreach ($alias in $Aliases) {
        $direct = Join-Path $srcDir $alias
        if (Test-Path -LiteralPath $direct) { return $direct }
    }
    if (-not (Test-Path -LiteralPath $srcDir)) { return $null }
    foreach ($file in Get-ChildItem -LiteralPath $srcDir -Filter "*.png" -File) {
        foreach ($alias in $Aliases) {
            if ($file.Name -like "*$alias*" -or $file.Name.Contains($alias)) {
                return $file.FullName
            }
        }
    }
    return $null
}

function Slice-Sheet([string]$SrcPath, [string]$OutDir) {
    Add-Type -AssemblyName System.Drawing
    $sheet = [System.Drawing.Bitmap]::FromFile($SrcPath)
    $sheetW = $sheet.Width
    $sheetH = $sheet.Height
    if ($sheetH -le 0 -or ($sheetW % $sheetH) -ne 0) {
        $sheet.Dispose()
        throw "Sheet is not a row of square cells: $SrcPath ($sheetW x $sheetH)"
    }

    $frameW = $sheetH
    $frameCount = [int]($sheetW / $frameW)

    New-Item -ItemType Directory -Force -Path $OutDir | Out-Null
    Get-ChildItem -LiteralPath $OutDir -Filter "frame_*.png" -File | Remove-Item -Force
    Get-ChildItem -LiteralPath $OutDir -Filter "*.import" -File |
        Where-Object { $_.Name -like "frame_*.png.import" } |
        ForEach-Object { Remove-Item -LiteralPath $_.FullName -Force }

    for ($i = 0; $i -lt $frameCount; $i++) {
        $frame = New-Object System.Drawing.Bitmap $frameW, $sheetH
        $gc = [System.Drawing.Graphics]::FromImage($frame)
        $gc.InterpolationMode = [System.Drawing.Drawing2D.InterpolationMode]::NearestNeighbor
        $gc.PixelOffsetMode = [System.Drawing.Drawing2D.PixelOffsetMode]::Half
        $srcRect = New-Object System.Drawing.Rectangle ($i * $frameW), 0, $frameW, $sheetH
        $dstRect = New-Object System.Drawing.Rectangle 0, 0, $frameW, $sheetH
        $gc.DrawImage($sheet, $dstRect, $srcRect, [System.Drawing.GraphicsUnit]::Pixel)
        $gc.Dispose()

        $outPath = Join-Path $OutDir ("frame_{0:d3}.png" -f $i)
        $frame.Save($outPath, [System.Drawing.Imaging.ImageFormat]::Png)
        $frame.Dispose()
    }
    $sheet.Dispose()
    return @{
        SheetW = $sheetW
        SheetH = $sheetH
        FrameW = $frameW
        OutH = $sheetH
        FrameCount = $frameCount
    }
}

$log = @()
foreach ($job in $jobs) {
    $src = Find-SourceSheet $job.Aliases
    if ($null -eq $src) {
        $log += "$($job.Key): MISSING source (aliases: $($job.Aliases -join ', '))"
        continue
    }
    $outDir = Join-Path $outBase $job.Out
    $info = Slice-Sheet -SrcPath $src -OutDir $outDir
    $log += (
        "$($job.Key): $($info.SheetW)x$($info.SheetH) frame=$($info.FrameW)x$($info.OutH) " +
        "count=$($info.FrameCount) from=$([System.IO.Path]::GetFileName($src))"
    )
}

$logPath = Join-Path $root "tools\slice_flying_demon_sheets_log.txt"
$log | Set-Content -Path $logPath -Encoding UTF8
$log | ForEach-Object { Write-Host $_ }
