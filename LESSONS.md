# Lessons

- **`npm` fails in PowerShell on a fresh Windows computer.** The default execution policy blocks `npm.ps1`, so the script calls `npm.cmd`.
- **Installers update PATH in the registry, not in the open window.** The Windows script reloads PATH after each install, otherwise `node` and `claude` look missing right after installing them.
- **Node's LTS line moves.** In Nov 2026 the LTS was v26, not v24. The scripts read the current LTS from `nodejs.org/dist/index.tab` instead of hard-coding it.
- **`claude mcp get` exit codes aren't reliable for "does it exist".** The scripts look for the "No MCP server named" message instead.
- **Mac file pickers hide dot-folders.** Students need Cmd+Shift+G to paste the plugin path, so the script copies it to the clipboard.
- **Students paste only the URL.** The first Mac test pasted just the raw GitHub link and zsh said "no such file or directory". Handouts must show the command in a code box and say it starts with curl.
- **`has claude` misses real installs.** Shell aliases in ~/.zshrc (old local installs) are invisible to a curl | bash script, and the desktop app's claude is not on PATH.
- **The Windows Store version of the Claude app keeps its config somewhere else:** %LOCALAPPDATA%Claude-Dataclaude_<id>claude_desktop_config.json, not %APPDATA%Claude. %APPDATA%Claude still exists but only holds a marker file, so the script checks Claude-Data first.
- **The Claude app overwrites its settings file from memory while it runs.** An entry added while the app is open can vanish on the next settings save, before any restart. Write it while the app is closed, so the installer waits for the student to quit.
- **Processes started from a Claude Code session die when the Claude app quits.** A helper meant to outlive the app had to be started through WMI (Win32_Process Create).
- **With the official Figma connector also on, the chat picks it first.** That connector only works from file links. Students should say "use figma-console".
- **First use of each figma-console tool asks for approval in the chat.** "Always allow" stops the prompts.
- **Quitting Claude by hand isn't reliable.** On the laptop it stayed running after the student thought it was closed, so it never loaded the new settings. The installer now closes and reopens it itself.
- **The Claude app has no Developer page any more.** Local servers show under Settings > Customize > Connectors, marked "Desktop, Local dev".
- **The free plan runs local servers in the normal chat.** Tested 2026-11-04.
