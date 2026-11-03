# Figma Desktop Bridge setup

Gets a fresh computer ready to use Claude with Figma, through the figma-console MCP and its Figma Desktop Bridge plugin. Made for teaching students who have nothing installed yet. No Figma token needed.

## Start here

### Download and open

- **Windows:** [FigmaBridgeSetup.exe](https://github.com/ayareago/figma-bridge-setup/releases/latest/download/FigmaBridgeSetup.exe)
  If Windows says "Windows protected your PC", click **More info**, then **Run anyway**.
- **Mac:** [FigmaBridgeSetup-mac.zip](https://github.com/ayareago/figma-bridge-setup/releases/latest/download/FigmaBridgeSetup-mac.zip)
  Open the zip, then open **Figma Bridge Setup**. If the Mac says it can't check the app, open **System Settings > Privacy & Security**, scroll down and click **Open Anyway**. If it asks to control Terminal, click **OK**.

These warnings appear because the installers aren't paid-signed with Apple and Microsoft. They show once.

### Or paste one command

**Windows** (open PowerShell):

```powershell
irm https://raw.githubusercontent.com/ayareago/figma-bridge-setup/main/install.ps1 | iex
```

**Mac** (open Terminal):

```bash
curl -fsSL https://raw.githubusercontent.com/ayareago/figma-bridge-setup/main/install.sh | bash
```

Repo: https://github.com/ayareago/figma-bridge-setup (public).

## What it does

1. Checks for Node.js 18 or newer and installs the current LTS if needed (winget or the official MSI on Windows, the official .pkg on Mac).
2. Checks for Claude Code. If it is missing, asks before running the official installer; saying no skips it and the bridge goes straight into `~/.claude.json`.
3. Checks for the Figma desktop app and installs it (winget on Windows, Homebrew on Mac) or opens the download page.
4. Downloads the latest bridge plugin from npm into `~/.figma-console-mcp/plugin`.
5. Adds the `figma-console` MCP server to Claude Code for all projects.
6. If the Claude desktop app is installed, offers to connect its normal chat too (writes `claude_desktop_config.json`).
7. Copies the plugin's manifest path to the clipboard and prints the last steps, which have to be done by hand in Figma.

Running it again is safe. Anything already installed is skipped.

## Files

- `install.ps1`: Windows installer
- `install.sh`: Mac installer
- `PLAN.md`, `BUILD_LOG.md`, `DECISIONS.md`, `LESSONS.md`: project records
- `research/`: sources
