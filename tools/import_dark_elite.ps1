# Slice Dark Elite sprite sheets into sprites/enemies/dark_elite/
$ErrorActionPreference = "Stop"
Add-Type -AssemblyName System.Drawing

$project = Split-Path -Parent $PSScriptRoot
$tmp = Join-Path $PSScriptRoot "_tmp_import"
$outBase = Join-Path $project "sprites\enemies\dark_elite"
$logPath = Join-Path $PSScriptRoot "import_dark_elite_log.txt"

function Slice-Horizontal {
    param(
        [string]$Name,
        [string]$Src,
        [string]$OutDir,
        [int]$FixedFrameCount = 0
    )
    $bmp = [System.Drawing.Bitmap]::FromFile($Src)
    $sheetW = $bmp.Width
    $sheetH = $bmp.Height
    $frameH = $sheetH
    if ($FixedFrameCount -gt 0) {
        $frameW = [int]($sheetW / $FixedFrameCount)
        $frameCount = $FixedFrameCount
    } else {
        $frameW = $frameH
        $frameCount = [int]($sheetW / $frameW)
    }
    New-Item -ItemType Directory -Force -Path $OutDir | Out-Null
    for ($i = 0; $i -lt $frameCount; $i++) {
        $rect = New-Object System.Drawing.Rectangle ($i * $frameW), 0, $frameW, $frameH
        $frame = $bmp.Clone($rect, $bmp.PixelFormat)
        $dest = Join-Path $OutDir ("frame_{0:D3}.png" -f $i)
        $frame.Save($dest, [System.Drawing.Imaging.ImageFormat]::Png)
        $frame.Dispose()
    }
    $bmp.Dispose()
    return "${Name}: sheet=${sheetW}x${sheetH} frame=${frameW}x${frameH} count=$frameCount out=$OutDir"
}

$log = @()
$log += Slice-Horizontal -Name "idle" -Src (Join-Path $tmp "idle.png") -OutDir (Join-Path $outBase "idle") -FixedFrameCount 8
$log += Slice-Horizontal -Name "run" -Src (Join-Path $tmp "run.png") -OutDir (Join-Path $outBase "run")
$log += Slice-Horizontal -Name "attack" -Src (Join-Path $tmp "attack.png") -OutDir (Join-Path $outBase "attack")
$log += Slice-Horizontal -Name "death" -Src (Join-Path $tmp "death.png") -OutDir (Join-Path $outBase "death")

$log | Set-Content -Path $logPath -Encoding UTF8
$log | ForEach-Object { Write-Output $_ }

# Frame counts per folder
foreach ($anim in @("idle", "run", "attack", "death")) {
    $dir = Join-Path $outBase $anim
    $count = (Get-ChildItem $dir -Filter "frame_*.png").Count
    $sample = Get-ChildItem $dir -Filter "frame_000.png" | Select-Object -First 1
    if ($sample) {
        $img = [System.Drawing.Image]::FromFile($sample.FullName)
        Write-Output "${anim}/: $count frames, ${img.Width}x${img.Height} each"
        $img.Dispose()
    }
}
