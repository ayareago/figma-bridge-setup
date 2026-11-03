# Figma Desktop Bridge setup for Windows.
# Checks for Node.js, Claude Code and Figma, installs what's missing,
# downloads the bridge plugin and connects it to Claude Code.
# Safe to run again: anything already set up is skipped.
#
# Run in PowerShell:
#   irm https://raw.githubusercontent.com/ayareago/figma-bridge-setup/main/install.ps1 | iex

& {
$ErrorActionPreference = 'Continue'
$ProgressPreference = 'SilentlyContinue'
[Net.ServicePointManager]::SecurityProtocol = [Net.ServicePointManager]::SecurityProtocol -bor [Net.SecurityProtocolType]::Tls12

$PluginDir = Join-Path $HOME '.figma-console-mcp\plugin'
$Manifest = Join-Path $PluginDir 'manifest.json'
$Problems = New-Object System.Collections.ArrayList

function Step($text) { Write-Host ''; Write-Host "==> $text" -ForegroundColor Cyan }
function Ok($text) { Write-Host "    [ok] $text" -ForegroundColor Green }
function Info($text) { Write-Host "    $text" }
function Problem($text) { Write-Host "    [!] $text" -ForegroundColor Yellow; [void]$Problems.Add($text) }
function Has($cmd) { [bool](Get-Command $cmd -ErrorAction SilentlyContinue) }

# The .exe installer sets FIGMA_BRIDGE_PAUSE so its window stays open long enough to read.
function Wait-IfInstaller {
    if ($env:FIGMA_BRIDGE_PAUSE) { Write-Host ''; Read-Host 'Press Enter to close this window' | Out-Null }
}

# Installers change PATH in the registry, not in this window, so reload it.
function Update-SessionPath {
    $machine = [Environment]::GetEnvironmentVariable('Path', 'Machine')
    $user = [Environment]::GetEnvironmentVariable('Path', 'User')
    $env:Path = "$machine;$user;$HOME\.local\bin"
}

function Get-NodeMajor {
    if (-not (Has 'node')) { return 0 }
    $v = (& node -v) -replace '^v', ''
    return [int]($v.Split('.')[0])
}

# Fallback when winget isn't available: the official MSI, checked against nodejs.org's checksums.
function Install-NodeMsi {
    $index = (Invoke-WebRequest 'https://nodejs.org/dist/index.tab' -UseBasicParsing).Content -split "`n"
    $lts = $index | Select-Object -Skip 1 | Where-Object { ($_ -split "`t")[9] -ne '-' } | Select-Object -First 1
    $version = ($lts -split "`t")[0]
    $arch = if ($env:PROCESSOR_ARCHITECTURE -eq 'ARM64') { 'arm64' } else { 'x64' }
    $file = "node-$version-$arch.msi"
    $msi = Join-Path $env:TEMP $file
    Info "Downloading $file..."
    Invoke-WebRequest "https://nodejs.org/dist/$version/$file" -OutFile $msi -UseBasicParsing
    $sums = (Invoke-WebRequest "https://nodejs.org/dist/$version/SHASUMS256.txt" -UseBasicParsing).Content
    $expected = ($sums -split "`n" | Where-Object { $_ -match " $([regex]::Escape($file))$" }) -split '\s+' | Select-Object -First 1
    if ((Get-FileHash $msi -Algorithm SHA256).Hash -ne $expected.ToUpper()) {
        throw "Checksum didn't match for $file"
    }
    Start-Process msiexec.exe -ArgumentList "/i `"$msi`" /passive" -Wait
    Remove-Item $msi -Force
}

# npm installs and older installs live outside ~/.local/bin, so check those too.
function Find-Claude {
    $cmd = Get-Command claude -ErrorAction SilentlyContinue | Select-Object -First 1
    if ($cmd) { return $cmd.Source }
    $paths = @("$HOME\.local\bin\claude.exe", "$env:APPDATA\npm\claude.cmd", "$HOME\.claude\local\claude.exe")
    return $paths | Where-Object { Test-Path $_ } | Select-Object -First 1
}

function Ask-Yes($question) {
    $answer = Read-Host "    $question [Y/n]"
    return -not ($answer -match '^[nN]')
}

# Adds figma-console to the mcpServers of a JSON config file, keeping a backup.
# Returns "added" or "exists". Done in Node because PowerShell 5.1's JSON round trip
# can damage a large config; the entry goes in through an environment variable
# because PowerShell 5.1 mangles quotes in arguments to native programs.
function Add-McpServer($file, $entryJson) {
    $js = @'
const fs = require("fs");
const path = require("path");
const file = process.argv[2];
let config = {};
if (fs.existsSync(file)) {
  const raw = fs.readFileSync(file, "utf8");
  if (raw.trim()) config = JSON.parse(raw);
  fs.writeFileSync(file + ".backup", raw);
}
config.mcpServers = config.mcpServers || {};
if (config.mcpServers["figma-console"]) { console.log("exists"); process.exit(0); }
config.mcpServers["figma-console"] = JSON.parse(process.env.FIGMA_BRIDGE_ENTRY);
fs.mkdirSync(path.dirname(file), { recursive: true });
fs.writeFileSync(file, JSON.stringify(config, null, 2));
console.log("added");
'@
    $script = Join-Path $env:TEMP 'figma-bridge-config.js'
    Set-Content $script $js -Encoding ascii
    $env:FIGMA_BRIDGE_ENTRY = $entryJson
    $result = (& node $script $file 2>&1 | Out-String).Trim()
    Remove-Item Env:\FIGMA_BRIDGE_ENTRY
    Remove-Item $script -Force
    return $result
}

# The Store version of the Claude app keeps its config under Claude-Data;
# the classic installer uses %APPDATA%\Claude. Returns $null if the app isn't installed.
function Find-ClaudeAppConfig {
    $store = Get-ChildItem "$env:LOCALAPPDATA\Claude-Data" -Directory -Filter 'claude_*' -ErrorAction SilentlyContinue | Select-Object -First 1
    if ($store) { return Join-Path $store.FullName 'claude_desktop_config.json' }
    if ((Test-Path "$env:LOCALAPPDATA\AnthropicClaude") -or (Test-Path "$env:APPDATA\Claude\claude_desktop_config.json")) {
        return "$env:APPDATA\Claude\claude_desktop_config.json"
    }
    return $null
}

function Get-ClaudeAppProcesses {
    # Match the app's own folders only: Claude Code's claude.exe has the same process name.
    Get-Process Claude -ErrorAction SilentlyContinue | Where-Object { $_.Path -like '*\WindowsApps\Claude_*' -or $_.Path -like '*\AnthropicClaude\*' }
}

function Test-ClaudeAppRunning { [bool](Get-ClaudeAppProcesses) }

# A pop-up on top of every window, so nobody misses it. Returns $true for OK.
function Show-Dialog($text) {
    Add-Type -AssemblyName System.Windows.Forms
    $owner = New-Object System.Windows.Forms.Form -Property @{ TopMost = $true }
    $answer = [System.Windows.Forms.MessageBox]::Show($owner, $text, 'Figma Bridge Setup', 'OKCancel', 'Information')
    $owner.Dispose()
    return $answer -eq 'OK'
}

# The Claude app keeps its settings in memory, writes them back while it runs, and only
# reads them when it starts. Even "Quit" can leave it running in the tray. So the setup
# closes it itself (after asking), changes the settings, then opens it again.
function Close-ClaudeApp {
    if (-not (Test-ClaudeAppRunning)) { return $true }
    $ok = Show-Dialog "Claude needs to close for a moment so Figma can be connected to it.`n`nSave anything you're typing in Claude, then click OK. Claude will open again by itself."
    if (-not $ok) { return $false }
    Info 'Closing Claude...'
    Get-ClaudeAppProcesses | ForEach-Object { [void]$_.CloseMainWindow() }
    $deadline = (Get-Date).AddSeconds(10)
    while ((Test-ClaudeAppRunning) -and (Get-Date) -lt $deadline) { Start-Sleep -Milliseconds 500 }
    Get-ClaudeAppProcesses | Stop-Process -Force -ErrorAction SilentlyContinue
    Start-Sleep -Seconds 2
    return -not (Test-ClaudeAppRunning)
}

function Open-ClaudeApp {
    # The Store version can only be started through its app ID.
    $app = Get-StartApps -ErrorAction SilentlyContinue | Where-Object { $_.Name -eq 'Claude' } | Select-Object -First 1
    if ($app) { Start-Process "shell:AppsFolder\$($app.AppID)"; return }
    $exe = Get-ChildItem "$env:LOCALAPPDATA\AnthropicClaude" -Filter claude.exe -ErrorAction SilentlyContinue | Select-Object -First 1
    if ($exe) { Start-Process $exe.FullName }
}

function Find-Figma {
    $paths = @("$env:LOCALAPPDATA\Figma\Figma.exe", "$env:ProgramFiles\Figma\Figma.exe")
    return $paths | Where-Object { Test-Path $_ } | Select-Object -First 1
}

Write-Host ''
Write-Host 'Figma Desktop Bridge setup' -ForegroundColor White
Write-Host 'If Windows asks for permission while installing, click Yes.'

# 1. Node.js (runs the bridge server)
Step 'Node.js'
Update-SessionPath
$major = Get-NodeMajor
if ($major -ge 18) {
    Ok "Node $(& node -v) is installed"
} else {
    if ($major -gt 0) { Info "Node $(& node -v) is too old. Installing the current LTS." }
    else { Info 'Not installed. Installing Node.js LTS...' }
    try {
        if (Has 'winget') {
            winget install --id OpenJS.NodeJS.LTS -e --silent --accept-source-agreements --accept-package-agreements
        } else {
            Install-NodeMsi
        }
    } catch {
        Info $_.Exception.Message
    }
    Update-SessionPath
    if ((Get-NodeMajor) -ge 18) { Ok "Node $(& node -v) installed" }
    else { Problem 'Node.js did not install. Get the LTS version from https://nodejs.org and run this again.' }
}

# 2. Claude Code
Step 'Claude Code'
$claude = Find-Claude
if ($claude) {
    Ok "Claude Code $(& $claude --version) is installed"
} elseif (Ask-Yes "Claude Code wasn't found. Install it now?") {
    # Separate process, so the official installer can't close this window.
    powershell.exe -NoProfile -ExecutionPolicy Bypass -Command "irm https://claude.ai/install.ps1 | iex"
    Update-SessionPath
    $claude = Find-Claude
    if ($claude) { Ok "Claude Code $(& $claude --version) installed" }
    else { Problem 'Claude Code did not install. See https://code.claude.com/docs/en/setup and run this again.' }
} else {
    Ok 'Skipped. The bridge will go straight into your Claude settings.'
}

# 3. Figma desktop app (the browser version can't load local plugins)
Step 'Figma desktop app'
$figma = Find-Figma
if ($figma) {
    Ok 'Figma desktop is installed'
} elseif (Has 'winget') {
    Info 'Not installed. Installing Figma...'
    winget install --id Figma.Figma -e --silent --accept-source-agreements --accept-package-agreements
    $figma = Find-Figma
    if ($figma) { Ok 'Figma desktop installed' }
    else { Problem 'Figma did not install. Download it from https://www.figma.com/downloads/' }
} else {
    Start-Process 'https://www.figma.com/downloads/'
    Problem 'Install Figma desktop from the page that just opened.'
}

# 4. The bridge plugin, copied to a fixed folder so the Figma import path never changes
Step 'Figma Desktop Bridge plugin'
if (Has 'npm.cmd') {
    $version = 'unknown'
    $tmp = Join-Path $env:TEMP ('figma-bridge-' + [guid]::NewGuid())
    New-Item -ItemType Directory $tmp | Out-Null
    # npm.cmd, not npm: fresh Windows blocks npm.ps1 under the default execution policy.
    & npm.cmd pack figma-console-mcp@latest --pack-destination $tmp --silent | Out-Null
    $tgz = Get-ChildItem $tmp -Filter *.tgz | Select-Object -First 1
    if ($tgz) {
        tar -xzf $tgz.FullName -C $tmp package/figma-desktop-bridge package/package.json
        New-Item -ItemType Directory $PluginDir -Force | Out-Null
        foreach ($f in 'manifest.json', 'code.js', 'ui.html') {
            Copy-Item (Join-Path $tmp "package\figma-desktop-bridge\$f") $PluginDir -Force
        }
        $version = (Get-Content (Join-Path $tmp 'package\package.json') -Raw | ConvertFrom-Json).version
        Set-Content (Join-Path $PluginDir '.version') $version -Encoding ascii
    }
    Remove-Item $tmp -Recurse -Force -ErrorAction SilentlyContinue
    if (Test-Path $Manifest) { Ok "Plugin version $version saved to $PluginDir" }
    else { Problem 'Could not download the plugin. Check your internet connection and run this again.' }
} else {
    Problem 'Skipped the plugin because Node.js is missing.'
}

# 5. Tell Claude Code about the bridge server
Step 'Connect Figma to Claude Code'
if ($claude) {
    $existing = (& $claude mcp get figma-console 2>&1 | Out-String)
    if ($existing -match 'No MCP server named') {
        & $claude mcp add figma-console -s user -- npx -y figma-console-mcp@latest | Out-Null
        $check = (& $claude mcp get figma-console 2>&1 | Out-String)
        if ($check -match 'No MCP server named') { Problem 'Could not add figma-console to Claude Code.' }
        else { Ok 'Added figma-console to Claude Code (all projects)' }
    } else {
        Ok 'figma-console is already set up in Claude Code'
    }
} elseif (Has 'node') {
    # Without the claude command, write straight into .claude.json,
    # which both the terminal and the Code tab of the Claude app read.
    $entry = '{"type":"stdio","command":"npx","args":["-y","figma-console-mcp@latest"],"env":{}}'
    switch (Add-McpServer (Join-Path $HOME '.claude.json') $entry) {
        'added'  { Ok 'Added figma-console to your Claude Code settings (.claude.json)' }
        'exists' { Ok 'figma-console is already in your Claude Code settings' }
        default  { Problem 'Could not update .claude.json.' }
    }
} else {
    Problem 'Skipped because Node.js is missing.'
}

# 6. Optional: the normal chat in the Claude desktop app
$desktopAdded = $false
$desktopConfig = Find-ClaudeAppConfig
if ($desktopConfig -and (Has 'node')) {
    Step 'Claude desktop app (normal chat)'
    if (Ask-Yes 'Also connect Figma to the normal chat in the Claude app?') {
        $wasRunning = Test-ClaudeAppRunning
        if (Close-ClaudeApp) {
            # cmd /c, because apps can't start npx.cmd directly on Windows.
            $entry = '{"command":"cmd","args":["/c","npx","-y","figma-console-mcp@latest"]}'
            switch (Add-McpServer $desktopConfig $entry) {
                'added'  { Ok 'Connected Figma to the Claude app'; $desktopAdded = $true }
                'exists' { Ok 'figma-console is already in the Claude app'; $desktopAdded = $true }
                default  { Problem "Could not update the Claude app's settings." }
            }
            if ($wasRunning) { Info 'Opening Claude again...'; Open-ClaudeApp }
        } else {
            Problem 'Claude stayed open, so the normal chat was not connected. Run this again and click OK when asked.'
        }
    } else {
        Ok 'Skipped'
    }
}

# What's left is done by hand in Figma
Write-Host ''
if ($Problems.Count -gt 0) {
    Write-Host 'Almost there. Fix these, then run the same command again:' -ForegroundColor Yellow
    foreach ($p in $Problems) { Write-Host "  - $p" }
    Wait-IfInstaller
    return
}

if (Test-Path $Manifest) { Set-Clipboard -Value $Manifest }
Write-Host 'Setup finished. Last steps, in Figma:' -ForegroundColor Green
Write-Host ''
Write-Host '  1. Open the Figma desktop app, sign in and open any design file.'
Write-Host '  2. Menu > Plugins > Development > Import plugin from manifest...'
Write-Host '     Paste this path in the file name box (it is already copied) and press Enter:'
Write-Host "     $Manifest" -ForegroundColor White
Write-Host '  3. Menu > Plugins > Development > Figma Desktop Bridge. Leave its window open.'
Write-Host '  4. Open Claude Code: type  claude  in a NEW terminal, or use the Code tab in the Claude app.'
if ($desktopAdded) { Write-Host "     Or use a normal chat in the Claude app. Say 'use figma-console' so it doesn't pick the Figma web connector." }
Write-Host '     Then ask: "Check the Figma connection and tell me which file is open."'
Write-Host ''
Write-Host 'Step 2 is only needed once. After that, just run the plugin (step 3) each time.'

if ($figma) { Start-Process $figma }
Wait-IfInstaller
}
