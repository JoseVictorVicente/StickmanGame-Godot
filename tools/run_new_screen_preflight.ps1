# Preflight checks before visual capture for a UI panel script/scene.
param(
    [string]$PanelPath = ""
)

$ErrorActionPreference = "Stop"
$root = Split-Path -Parent $PSScriptRoot
$failed = $false

Write-Host "=== UI screen preflight ===" -ForegroundColor Cyan

# 1) Global layout + TSCN ownership guard
Write-Host "`n[1/4] run_ui_layout_check.ps1 (layout + ownership)"
& (Join-Path $PSScriptRoot "run_ui_layout_check.ps1")
if ($LASTEXITCODE -ne 0) {
    $failed = $true
}

# 2) Panel-specific anti-patterns
if ($PanelPath -ne "") {
    $resolved = Join-Path $root ($PanelPath -replace '/', '\')
    if (-not (Test-Path $resolved)) {
        Write-Host "WARN: PanelPath not found: $PanelPath" -ForegroundColor Yellow
    } else {
        Write-Host "`n[2/4] Anti-pattern scan: $PanelPath"
        $patterns = @(
            @{ Name = "position assignment"; Regex = '\bposition\s*=' },
            @{ Name = "offset_left"; Regex = '\boffset_(left|right|top|bottom)\s*=' },
            @{ Name = "custom_minimum_size in script"; Regex = '\bcustom_minimum_size\s*=' },
            @{ Name = "reparent()"; Regex = '\.reparent\(' },
            @{ Name = "StyleBoxFlat.new()"; Regex = 'StyleBoxFlat\.new\(' },
            @{ Name = "StyleBoxTexture.new()"; Regex = 'StyleBoxTexture\.new\(' }
        )
        $lines = Get-Content -Path $resolved -Encoding UTF8
        foreach ($pat in $patterns) {
            $hits = @()
            for ($i = 0; $i -lt $lines.Count; $i++) {
                $line = $lines[$i]
                if ($line -match '^\s*#') { continue }
                if ($line -match $pat.Regex) {
                    $hits += "{0}:{1}: {2}" -f ($i + 1), $pat.Name, $line.Trim()
                }
            }
            if ($hits.Count -gt 0) {
                Write-Host "  FAIL $($pat.Name):" -ForegroundColor Red
                $hits | ForEach-Object { Write-Host "    $_" }
                $failed = $true
            }
        }
        if (-not $failed) {
            Write-Host "  OK - no layout anti-patterns in panel script" -ForegroundColor Green
        }

        # Suggest related .tscn
        $tscn = [System.IO.Path]::ChangeExtension($resolved, ".tscn")
        if (Test-Path $tscn) {
            $rel = $tscn.Substring($root.Length).TrimStart('\', '/')
            Write-Host "  Scene: $rel"
            Write-Host "`n[3/4] TSCN ownership for scene"
            python (Join-Path $PSScriptRoot "check_tscn_ownership.py")
            if ($LASTEXITCODE -ne 0) { $failed = $true }
        }
    }
} else {
    Write-Host "`n[2/4] Skipped panel scan (pass -PanelPath presentation/inventory/my_panel.gd)"
}

# 4) Reminder for new capture states
Write-Host "`n[4/4] New menu-visible screen checklist"
Write-Host "  - tests/inventory_menu_layout_states.gd (STATE_IDS + apply_state)"
Write-Host "  - tools/run_inventory_menu_visual_capture.ps1 (`$stateIds)"
Write-Host "  - tests/inventory_menu_layout_audit.gd (optional invariants)"
Write-Host "  - See .cursor/skills/edit-ui-screens/references/new-screen-workflow.md"

if ($failed) {
    Write-Host "`nPREFLIGHT_FAILED" -ForegroundColor Red
    exit 1
}

Write-Host "`nPREFLIGHT_OK" -ForegroundColor Green
exit 0
