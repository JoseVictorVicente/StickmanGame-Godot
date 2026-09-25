# Deprecated: use tools/slice_flying_demon_sheets.ps1
$sliceScript = Join-Path $PSScriptRoot "slice_flying_demon_sheets.ps1"
powershell -ExecutionPolicy Bypass -File $sliceScript
