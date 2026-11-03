# Decisions

**One-line `irm | iex` and `curl | bash` commands.** This is how Claude Code itself installs, so students see the same pattern twice. Turned down: a downloadable .exe/.pkg (needs code signing, or Windows and macOS block it) and an npx command (needs Node first, which is what we're installing).

**Download the plugin ourselves instead of waiting for the server to do it.** The figma-console server copies the plugin to `~/.figma-console-mcp/plugin` only when it first starts, which happens after the student opens Claude Code. Doing it in the installer means the import path exists straight away.

**Official Node installers, not Homebrew, on Mac.** Most students won't have Homebrew, and installing it takes several minutes plus Xcode tools. The .pkg is checked against nodejs.org's published SHA-256.

**Skip Git for Windows.** Claude Code's docs say it's optional; without it Claude uses PowerShell.

**No Figma access token.** Ayodeji's working setup has none and the bridge plugin covers what students need.

**MCP config matches Ayodeji's working setup exactly:** `npx -y figma-console-mcp@latest`, user scope.

**Ask before installing Claude Code; if skipped, edit ~/.claude.json directly.** Some students already use Claude (often the desktop app, whose bundled claude is not on PATH). The terminal and the Code tab of the desktop app both read ~/.claude.json, so writing the server there works for both. Done with Node, not PowerShell 5.1, whose JSON round trip can damage a large config. Turned down: also writing the Claude desktop chat config (GUI apps get a short PATH and npx often fails there).
