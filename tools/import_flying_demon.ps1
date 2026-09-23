$root = Split-Path -Parent $PSScriptRoot
$sliceScript = Join-Path $PSScriptRoot "slice_flying_demon_sheets.ps1"

Write-Host "Flying Demon import: slicing source sheets..."
powershell -ExecutionPolicy Bypass -File $sliceScript

$godot = $env:GODOT
if (-not $godot) {
    $candidates = @(
        "C:\Users\LEONARDO\Downloads\Godot_v4.7.2-stable_win64.exe",
        "C:\Users\LEONARDO\Downloads\Godot_v4.7.1-stable_win64.exe",
        "godot"
    )
    foreach ($candidate in $candidates) {
        if ($candidate -eq "godot") {
            $cmd = Get-Command godot -ErrorAction SilentlyContinue
            if ($cmd) { $godot = $cmd.Source; break }
        } elseif (Test-Path $candidate) {
            $godot = $candidate
            break
        }
    }
}

if ($godot) {
    & $godot --headless --path $root --import
    Write-Host "Godot import finished."
} else {
    Write-Host "Godot not found; runtime slicing from source/ still works in-game."
}
