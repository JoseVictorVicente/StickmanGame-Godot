# Full /edit-ui-screens validation chain: layout guards + geometry audit + visual capture.
# After success, follow capture-menu-screens scoped workflow and read -ScopePng PNG(s).
param(
    [string]$PanelPath = "",
    [switch]$SkipCapture,
    [string[]]$ScopePng = @()
)

$ErrorActionPreference = "Stop"
$failed = $false

Write-Host "=== edit-ui-screens validation ===" -ForegroundColor Cyan

if ($PanelPath -ne "") {
    Write-Host "`n[1/4] run_new_screen_preflight.ps1 -PanelPath $PanelPath"
    & (Join-Path $PSScriptRoot "run_new_screen_preflight.ps1") -PanelPath $PanelPath
    if ($LASTEXITCODE -ne 0) { $failed = $true }
} else {
    Write-Host "`n[1/4] Skipped preflight (pass -PanelPath for new panels)"
}

Write-Host "`n[2/4] run_ui_layout_check.ps1"
& (Join-Path $PSScriptRoot "run_ui_layout_check.ps1")
if ($LASTEXITCODE -ne 0) { $failed = $true }

Write-Host "`n[3/4] run_inventory_menu_layout_audit.ps1"
& (Join-Path $PSScriptRoot "run_inventory_menu_layout_audit.ps1")
if ($LASTEXITCODE -ne 0) { $failed = $true }

if ($SkipCapture) {
    Write-Host "`n[4/4] Skipped visual capture (-SkipCapture)"
} else {
    Write-Host "`n[4/4] run_inventory_menu_visual_capture.ps1"
    & (Join-Path $PSScriptRoot "run_inventory_menu_visual_capture.ps1")
    if ($LASTEXITCODE -ne 0) { $failed = $true }
}

if ($failed) {
    Write-Host "`nEDIT_UI_VALIDATION_FAILED" -ForegroundColor Red
    exit 1
}

Write-Host "`nEDIT_UI_VALIDATION_OK" -ForegroundColor Green

if ($ScopePng.Count -gt 0) {
    Write-Host "`nCAPTURE_SCOPE_READ (capture-menu-screens scoped workflow):" -ForegroundColor Cyan
    foreach ($id in $ScopePng) {
        $png = "artifacts/inventory_layout/$id.png"
        Write-Host "  - $png"
    }
    Write-Host "  Checklist: .cursor/skills/capture-menu-screens/SKILL.md#visual-checklist" -ForegroundColor DarkGray
    Write-Host "  Loop: read PNG(s) -> if issue fix .tscn -> re-run this script" -ForegroundColor DarkGray
} else {
    Write-Host "`nNo -ScopePng passed. For single-screen edits, pass e.g. -ScopePng worlds_open" -ForegroundColor DarkYellow
    Write-Host "Full 12-PNG review: .cursor/skills/capture-menu-screens/SKILL.md (full workflow)" -ForegroundColor DarkGray
}

exit 0
