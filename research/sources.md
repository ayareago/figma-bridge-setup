# Sources (checked 2026-11-03)

- Claude Code install commands, Windows Git being optional, `~/.local/bin` location: https://code.claude.com/docs/en/setup
- Node release index (LTS column is the 10th field): https://nodejs.org/dist/index.tab
- winget IDs confirmed with `winget show`: `OpenJS.NodeJS.LTS`, `Figma.Figma`
- figma-console-mcp 1.46.0 on npm: the plugin ships in `figma-desktop-bridge/`; `dist/local.js` copies `manifest.json`, `code.js` and `ui.html` to `~/.figma-console-mcp/plugin` when the server starts. Repo: https://github.com/southleft/figma-console-mcp

## ChatGPT (checked 2026-11-04)

- ChatGPT on the web: "Can I connect to a local MCP server? Not directly. ChatGPT connects to remote MCP servers." Custom MCP is for Business and Enterprise/Edu on the web; Pro gets read/fetch only. https://help.openai.com/en/articles/12584461-connecting-custom-mcp-servers-in-chatgpt
- ChatGPT desktop app: shares MCP settings with Codex CLI and the IDE extension in ~/.codex/config.toml; supports STDIO and Streamable HTTP servers; also Settings > MCP servers > Add server, then Restart; `/mcp` in the composer lists connected servers; `startup_timeout_sec` defaults to 10. https://learn.chatgpt.com/docs/extend/mcp?surface=app
- Windows app uses %USERPROFILE%.codex; Store ID 9PLM9XGG6VKS (`winget install --id 9PLM9XGG6VKS -s msstore`). https://learn.chatgpt.com/docs/app/windows
- Plans: the feature table lists MCP for Plus, Pro, Business, Enterprise/Edu and API key; Free gets "GPT-6 Luna in the desktop app, subject to rollout" with no MCP detail. https://learn.chatgpt.com/docs/pricing
