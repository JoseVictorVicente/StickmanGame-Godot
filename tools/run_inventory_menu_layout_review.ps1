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
Write-Host "Agent checklist — read artifacts/inventory_layout/*.png (10 screens):"
Write-Host "  hub_combat_bottom / hub_combat_top: combat band + hub placement"
Write-Host "  formation_open / skills_open / attributes_open: overlay full-bleed"
Write-Host "  skill_tree_open: skill tree replaces hub"
Write-Host "  warehouse_open / forge_open / worlds_open: side panels visible"
Write-Host "  settings_open: settings panel top-right"
exit $exitCode
