# Assisted check script for Cursor / CI — runs headless tests and validates structured logs.
$ErrorActionPreference = "Stop"
$ProjectRoot = Split-Path -Parent $PSScriptRoot
Set-Location $ProjectRoot

$godotCmd = $env:GODOT
if (-not $godotCmd) {
    $godotCmd = "C:\Users\Aleander\Downloads\Godot_v4.7.2-stable_win64.exe"
}
if (-not (Test-Path $godotCmd)) {
    $godot = Get-Command godot -ErrorAction SilentlyContinue
    if ($godot) { $godotCmd = $godot.Source }
}
if (-not (Test-Path $godotCmd)) {
    Write-Error "godot not found. Set GODOT env var or install Godot."
    exit 2
}
$godotArgs = @("--headless", "--path", $ProjectRoot)

$exitCode = 0

Write-Host "==> Unit: EnemyCatalog"
& $godotCmd @godotArgs -s res://tests/enemy_catalog_test.gd
if ($LASTEXITCODE -ne 0) { $exitCode = $LASTEXITCODE }

Write-Host "==> Unit: CombatResolver"
& $godotCmd @godotArgs -s res://tests/combat_resolver_test.gd
if ($LASTEXITCODE -ne 0) { $exitCode = $LASTEXITCODE }

Write-Host "==> Unit: StatCalculator"
& $godotCmd @godotArgs -s res://tests/stat_calculator_test.gd
if ($LASTEXITCODE -ne 0) { $exitCode = $LASTEXITCODE }

Write-Host "==> Smoke: idle combat (30s)"
$env:GAMELOG = "1"
$python = Get-Command python -ErrorAction SilentlyContinue
if (-not $python) {
    $python = Get-Command py -ErrorAction SilentlyContinue
}
$smokeLog = Join-Path $env:TEMP "stickman_smoke_events.log"
& $godotCmd @godotArgs -s res://tests/scenario_idle_smoke.gd 2>&1 | Tee-Object -FilePath $smokeLog
if ($LASTEXITCODE -ne 0) { $exitCode = $LASTEXITCODE }
if ($python) {
    try {
        Get-Content $smokeLog | & $python.Source tools/parse_game_log.py --stdin --expect-combat --expect-boot
        if ($LASTEXITCODE -ne 0) { $exitCode = $LASTEXITCODE }
    } catch {
        Write-Warning "python parser skipped: $_ (log saved at $smokeLog)"
    }
} else {
    Write-Warning "python not found; skipping log parser (check $smokeLog manually)"
}

exit $exitCode
