# Figma Desktop Bridge setup

Gets a fresh computer ready to use Claude or ChatGPT with Figma, through the figma-console MCP and its Figma Desktop Bridge plugin. Made for teaching students who have nothing installed yet. No Figma token needed.

## Start here

### Claude or ChatGPT

The first thing the setup asks is which app you use: Claude, ChatGPT or both. It only sets up what you pick.

- **Claude:** it connects Claude Code. If the Claude desktop app is installed, it asks whether to connect its normal chat as well. The free plan works in the normal chat; Claude Code needs a paid plan.
- **ChatGPT:** it connects the ChatGPT desktop app, and opens the download page if the app isn't installed yet. Afterwards, quit ChatGPT fully and open it again, start a new chat in **Codex** and say "use figma-console". OpenAI lists this for paid plans (Plus and up). Whether it works on the free plan hasn't been checked.

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

First it asks which app you use with Figma: Claude, ChatGPT or both. Steps 2, 5 and 6 only run for Claude, and step 7 only for ChatGPT.

1. Checks for Node.js 18 or newer and installs the current LTS if needed (winget or the official MSI on Windows, the official .pkg on Mac).
2. Checks for Claude Code. If it is missing, asks before running the official installer; saying no skips it and the bridge goes straight into `~/.claude.json`.
3. Checks for the Figma desktop app and installs it (winget on Windows, Homebrew on Mac) or opens the download page.
4. Downloads the latest bridge plugin from npm into `~/.figma-console-mcp/plugin`.
5. Adds the `figma-console` MCP server to Claude Code for all projects.
6. If the Claude desktop app is installed, offers to connect its normal chat too (writes `claude_desktop_config.json`).
7. Connects the ChatGPT desktop app (adds `figma-console` to `~/.codex/config.toml`, the settings file ChatGPT shares with Codex).
8. Copies the plugin's manifest path to the clipboard and prints the last steps, which have to be done by hand in Figma.

Running it again is safe. Anything already installed is skipped.

## Files

- `install.ps1`: Windows installer
- `install.sh`: Mac installer
- `PLAN.md`, `BUILD_LOG.md`, `DECISIONS.md`, `LESSONS.md`: project records
- `research/`: sources

## If it doesn't connect (Windows)

Run this read-only check in PowerShell and send a screenshot of the result:

```powershell
irm https://raw.githubusercontent.com/ayareago/figma-bridge-setup/main/check.ps1 | iex
```
