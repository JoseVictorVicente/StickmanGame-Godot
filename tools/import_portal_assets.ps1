# Import portal placeholder textures so Godot generates .import files.
$ErrorActionPreference = "Stop"
$root = Split-Path -Parent $PSScriptRoot
$godotCandidates = @(
    "$env:LOCALAPPDATA\Programs\Godot\Godot_v4.7.2-stable_win64.exe",
    "$env:USERPROFILE\Downloads\Godot_v4.7.2-stable_win64.exe",
    "godot"
)
$godot = $env:GODOT
if (-not $godot) {
    foreach ($candidate in $godotCandidates) {
        if ($candidate -eq "godot") {
            $cmd = Get-Command godot -ErrorAction SilentlyContinue
            if ($cmd) { $godot = $cmd.Source; break }
        }
        elseif (Test-Path $candidate) {
            $godot = $candidate
            break
        }
    }
}
if (-not $godot) {
    Write-Error "Godot executable not found. Install Godot 4.7 or set GODOT env var."
}

python (Join-Path $root "tools\gen_portal_placeholders.py")
if ($LASTEXITCODE -ne 0) { exit $LASTEXITCODE }

& $godot --headless --path $root --import
if ($LASTEXITCODE -ne 0) { exit $LASTEXITCODE }

Write-Output "Portal assets imported under sprites/ui/worlds/"
