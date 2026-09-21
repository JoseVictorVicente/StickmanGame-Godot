# Validates presentation .tscn files avoid manual layout_mode = 0 outside allowlist.
$ErrorActionPreference = "Stop"
$root = Split-Path -Parent $PSScriptRoot
python (Join-Path $PSScriptRoot "check_ui_layout.py")
if ($LASTEXITCODE -ne 0) { exit $LASTEXITCODE }
python (Join-Path $PSScriptRoot "check_tscn_ownership.py")
if ($LASTEXITCODE -ne 0) { exit $LASTEXITCODE }
