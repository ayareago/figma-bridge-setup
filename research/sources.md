# Sources (checked 2026-11-03)

- Claude Code install commands, Windows Git being optional, `~/.local/bin` location: https://code.claude.com/docs/en/setup
- Node release index (LTS column is the 10th field): https://nodejs.org/dist/index.tab
- winget IDs confirmed with `winget show`: `OpenJS.NodeJS.LTS`, `Figma.Figma`
- figma-console-mcp 1.46.0 on npm: the plugin ships in `figma-desktop-bridge/`; `dist/local.js` copies `manifest.json`, `code.js` and `ui.html` to `~/.figma-console-mcp/plugin` when the server starts. Repo: https://github.com/southleft/figma-console-mcp
