# Lessons

- **`npm` fails in PowerShell on a fresh Windows computer.** The default execution policy blocks `npm.ps1`, so the script calls `npm.cmd`.
- **Installers update PATH in the registry, not in the open window.** The Windows script reloads PATH after each install, otherwise `node` and `claude` look missing right after installing them.
- **Node's LTS line moves.** In Nov 2026 the LTS was v26, not v24. The scripts read the current LTS from `nodejs.org/dist/index.tab` instead of hard-coding it.
- **`claude mcp get` exit codes aren't reliable for "does it exist".** The scripts look for the "No MCP server named" message instead.
- **Mac file pickers hide dot-folders.** Students need Cmd+Shift+G to paste the plugin path, so the script copies it to the clipboard.
- **Students paste only the URL.** The first Mac test pasted just the raw GitHub link and zsh said "no such file or directory". Handouts must show the command in a code box and say it starts with curl.
- **`has claude` misses real installs.** Shell aliases in ~/.zshrc (old local installs) are invisible to a curl | bash script, and the desktop app's claude is not on PATH.
