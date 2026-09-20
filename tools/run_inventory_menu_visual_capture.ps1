# Visual layout capture for inventory_menu hub (requires display — not headless).
$ErrorActionPreference = "Stop"
$root = Split-Path -Parent $PSScriptRoot

$godot = $env:GODOT
if (-not $godot) {
    $godotCandidates = @(
        "$env:LOCALAPPDATA\Programs\Godot\Godot_v4.7.2-stable_win64.exe",
        "$env:USERPROFILE\Downloads\Godot_v4.7.2-stable_win64.exe"
    )
    foreach ($candidate in $godotCandidates) {
        if (Test-Path $candidate) {
            $godot = $candidate
            break
        }
    }
}
if (-not $godot) {
    $cmd = Get-Command godot -ErrorAction SilentlyContinue
    if ($cmd) { $godot = $cmd.Source }
}
if (-not $godot) {
    Write-Error "Godot executable not found. Set GODOT env var or install Godot 4.7."
}

$logOut = Join-Path $env:TEMP "stickman_inventory_visual_capture.out.log"
$logErr = Join-Path $env:TEMP "stickman_inventory_visual_capture.err.log"
if (Test-Path $logOut) { Remove-Item $logOut -Force }
if (Test-Path $logErr) { Remove-Item $logErr -Force }

$proc = Start-Process -FilePath $godot -ArgumentList @(
    "--path", $root, "-s", "res://tests/inventory_menu_visual_capture.gd"
) -Wait -PassThru -NoNewWindow -RedirectStandardOutput $logOut -RedirectStandardError $logErr

$output = ""
if (Test-Path $logOut) { $output += Get-Content $logOut -Raw }
if (Test-Path $logErr) { $output += Get-Content $logErr -Raw }
$output | Write-Output

if ($proc.ExitCode -ne 0) { exit $proc.ExitCode }
if ($output -match "INVENTORY_MENU_VISUAL_CAPTURE_FAILED") { exit 1 }
if ($output -notmatch "INVENTORY_MENU_VISUAL_CAPTURE_OK") { exit 1 }

$artifactDir = Join-Path $root "artifacts\inventory_layout"
$stateIds = @(
    "hub_combat_bottom",
    "hub_combat_top",
    "formation_open",
    "skills_open",
    "warehouse_open",
    "forge_open"
)
foreach ($stateId in $stateIds) {
    $png = Join-Path $artifactDir "$stateId.png"
    if (-not (Test-Path $png)) {
        Write-Error "Missing capture: $png"
        exit 1
    }
}

$manifest = Join-Path $artifactDir "manifest.json"
if (-not (Test-Path $manifest)) {
    Write-Error "Missing manifest: $manifest"
    exit 1
}

Write-Host "Visual captures ready in $artifactDir"
exit 0
