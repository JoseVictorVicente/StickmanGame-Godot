# Geometric layout audit for inventory_menu hub.
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

$logOut = Join-Path $env:TEMP "stickman_inventory_layout_audit.out.log"
$logErr = Join-Path $env:TEMP "stickman_inventory_layout_audit.err.log"
if (Test-Path $logOut) { Remove-Item $logOut -Force }
if (Test-Path $logErr) { Remove-Item $logErr -Force }

$proc = Start-Process -FilePath $godot -ArgumentList @(
    "--headless", "--path", $root, "-s", "res://tests/inventory_menu_layout_audit.gd"
) -Wait -PassThru -NoNewWindow -RedirectStandardOutput $logOut -RedirectStandardError $logErr

$output = ""
if (Test-Path $logOut) { $output += Get-Content $logOut -Raw }
if (Test-Path $logErr) { $output += Get-Content $logErr -Raw }
$output | Write-Output

if ($proc.ExitCode -ne 0) { exit $proc.ExitCode }
if ($output -match "INVENTORY_MENU_LAYOUT_AUDIT_FAILED") { exit 1 }
if ($output -notmatch "\[TEST PASS\] Inventory menu layout audit") { exit 1 }
exit 0
