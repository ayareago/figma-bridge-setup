# Figma Desktop Bridge setup

One command that gets a fresh computer ready to use Claude Code with Figma, through the figma-console MCP and its Figma Desktop Bridge plugin. Made for teaching students who have nothing installed yet.

## Start here

**Windows** (open PowerShell):

```powershell
irm https://raw.githubusercontent.com/ayareago/figma-bridge-setup/main/install.ps1 | iex
```

**Mac** (open Terminal):

```bash
curl -fsSL https://raw.githubusercontent.com/ayareago/figma-bridge-setup/main/install.sh | bash
```

These links only work once the repo is public on GitHub.

## What it does

1. Checks for Node.js 18 or newer and installs the current LTS if needed (winget or the official MSI on Windows, the official .pkg on Mac).
2. Checks for Claude Code and runs the official installer if needed.
3. Checks for the Figma desktop app and installs it (winget on Windows, Homebrew on Mac) or opens the download page.
4. Downloads the latest bridge plugin from npm into `~/.figma-console-mcp/plugin`.
5. Adds the `figma-console` MCP server to Claude Code for all projects.
6. Copies the plugin's manifest path to the clipboard and prints the last steps, which have to be done by hand in Figma.

Running it again is safe. Anything already installed is skipped.

## Files

- `install.ps1`: Windows installer
- `install.sh`: Mac installer
- `PLAN.md`, `BUILD_LOG.md`, `DECISIONS.md`, `LESSONS.md`: project records
- `research/`: sources
