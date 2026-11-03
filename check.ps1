# Figma Desktop Bridge check for Windows. Read-only: changes nothing.
# Shows where the Claude app keeps its settings, whether figma-console is in them,
# and what the app logged when it tried to start the bridge.
#
# Run in PowerShell:
#   irm https://raw.githubusercontent.com/ayareago/figma-bridge-setup/main/check.ps1 | iex

& {
$ErrorActionPreference = 'Continue'
function Head($t) { Write-Host ''; Write-Host "== $t" -ForegroundColor Cyan }
function Has($cmd) { [bool](Get-Command $cmd -ErrorAction SilentlyContinue) }

Head 'Claude app'
$procs = Get-Process Claude -ErrorAction SilentlyContinue | Where-Object { $_.Path } | Select-Object -ExpandProperty Path -Unique
if ($procs) { $procs | ForEach-Object { Write-Host "  running: $_" } } else { Write-Host '  not running' }
foreach ($p in "$env:LOCALAPPDATA\AnthropicClaude", "$env:LOCALAPPDATA\Programs\Claude") {
    if (Test-Path $p) { Write-Host "  installed at: $p" }
}
Get-ChildItem 'C:\Program Files\WindowsApps' -Directory -Filter 'Claude_*' -ErrorAction SilentlyContinue | ForEach-Object { Write-Host "  Store version: $($_.Name)" }

Head 'Settings files'
$dirs = @("$env:APPDATA\Claude")
$dirs += Get-ChildItem "$env:LOCALAPPDATA\Claude-Data" -Directory -Filter 'claude_*' -ErrorAction SilentlyContinue | Select-Object -ExpandProperty FullName
$dirs += Get-ChildItem "$env:LOCALAPPDATA\Packages" -Directory -Filter 'Claude_*' -ErrorAction SilentlyContinue | ForEach-Object { Join-Path $_.FullName 'LocalCache\Roaming\Claude' }
foreach ($d in $dirs) {
    $f = Join-Path $d 'claude_desktop_config.json'
    if (-not (Test-Path $f)) { Write-Host "  $f : missing"; continue }
    $raw = Get-Content $f -Raw
    $hasEntry = $raw -match '"figma-console"'
    Write-Host "  $f"
    Write-Host "     changed $((Get-Item $f).LastWriteTime), figma-console in it: $hasEntry"
    if ($hasEntry -and $raw -match '"figma-console"\s*:\s*(\{[^}]*\})') { Write-Host "     entry: $($Matches[1] -replace '\s+', ' ')" }
}

Head 'Node.js'
if (Has 'node') { Write-Host "  node $(& node -v), npx $(& npx.cmd -v)" } else { Write-Host '  node not found' }

Head 'Plugin'
$m = Join-Path $HOME '.figma-console-mcp\plugin\manifest.json'
Write-Host "  $m : $(if (Test-Path $m) { 'present' } else { 'missing' })"

Head 'Claude app logs for the bridge'
$found = $false
foreach ($d in $dirs) {
    Get-ChildItem (Join-Path $d 'logs') -Filter 'mcp*' -ErrorAction SilentlyContinue | Sort-Object LastWriteTime -Descending | Select-Object -First 3 | ForEach-Object {
        $found = $true
        Write-Host "  --- $($_.FullName) ($($_.LastWriteTime))"
        Get-Content $_.FullName -Tail 15 | ForEach-Object { Write-Host "  $_" }
    }
}
if (-not $found) { Write-Host '  no MCP logs found' }

Write-Host ''
Write-Host 'Take a screenshot of this whole window (or select all, copy and paste it).'
}
