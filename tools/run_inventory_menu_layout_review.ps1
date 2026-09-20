# Full inventory hub review: geometry audit (headless) + visual capture (display).
$ErrorActionPreference = "Stop"
$root = Split-Path -Parent $PSScriptRoot
$exitCode = 0

Write-Host "==> Geometry audit (headless)"
& (Join-Path $PSScriptRoot "run_inventory_menu_layout_audit.ps1")
if ($LASTEXITCODE -ne 0) {
    Write-Warning "Geometry audit failed — fix or continue to visual capture for agent review."
    $exitCode = $LASTEXITCODE
}

Write-Host "==> Visual capture (display required)"
& (Join-Path $PSScriptRoot "run_inventory_menu_visual_capture.ps1")
if ($LASTEXITCODE -ne 0) { exit $LASTEXITCODE }

Write-Host ""
Write-Host "Agent checklist — read artifacts/inventory_layout/*.png:"
Write-Host "  hub_combat_bottom: hub in lower half, top ~320px clear, 10x5 grid readable"
Write-Host "  hub_combat_top: hub below top combat band"
Write-Host "  formation_open / skills_open: overlay full-bleed on panel"
Write-Host "  warehouse_open / forge_open: side panels visible, margins ok"
exit $exitCode
