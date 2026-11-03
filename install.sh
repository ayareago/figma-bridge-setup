#!/usr/bin/env bash
# Figma Desktop Bridge setup for macOS.
# Checks for Node.js, Claude Code and Figma, installs what's missing,
# downloads the bridge plugin and connects it to Claude Code.
# Safe to run again: anything already set up is skipped.
#
# Run in Terminal:
#   curl -fsSL https://raw.githubusercontent.com/ayareago/figma-bridge-setup/main/install.sh | bash

set -u

PLUGIN_DIR="$HOME/.figma-console-mcp/plugin"
MANIFEST="$PLUGIN_DIR/manifest.json"
PROBLEMS=()
FIGMA_APP=""
CLAUDE=""

step()    { printf '\n\033[36m==> %s\033[0m\n' "$1"; }
ok()      { printf '    \033[32m[ok]\033[0m %s\n' "$1"; }
info()    { printf '    %s\n' "$1"; }
problem() { printf '    \033[33m[!]\033[0m %s\n' "$1"; PROBLEMS+=("$1"); }
has()     { command -v "$1" >/dev/null 2>&1; }

node_major() {
  if has node; then node -v | sed 's/^v//' | cut -d. -f1; else echo 0; fi
}

# The official LTS .pkg from nodejs.org, checked against its published checksum.
install_node_pkg() {
  local version pkg tmp expected actual
  version=$(curl -fsSL https://nodejs.org/dist/index.tab | awk -F'\t' 'NR>1 && $10!="-" {print $1; exit}')
  [ -n "$version" ] || return 1
  pkg="node-$version.pkg"
  tmp=$(mktemp -d)
  info "Downloading $pkg..."
  curl -fsSL "https://nodejs.org/dist/$version/$pkg" -o "$tmp/$pkg" || return 1
  expected=$(curl -fsSL "https://nodejs.org/dist/$version/SHASUMS256.txt" | awk -v f="$pkg" '$2==f {print $1}')
  actual=$(shasum -a 256 "$tmp/$pkg" | awk '{print $1}')
  if [ -z "$expected" ] || [ "$expected" != "$actual" ]; then
    info "Checksum didn't match for $pkg"
    rm -rf "$tmp"
    return 1
  fi
  info "Enter your Mac password if asked (nothing shows while you type)."
  sudo installer -pkg "$tmp/$pkg" -target / </dev/tty
  rm -rf "$tmp"
  hash -r
}

find_figma() {
  for app in "/Applications/Figma.app" "$HOME/Applications/Figma.app"; do
    if [ -d "$app" ]; then FIGMA_APP="$app"; return 0; fi
  done
  return 1
}

# Older installs and npm/Homebrew installs live outside ~/.local/bin, and shell aliases
# from ~/.zshrc aren't visible to this script, so check the usual places too.
find_claude() {
  if has claude; then CLAUDE=$(command -v claude); return 0; fi
  for c in "$HOME/.local/bin/claude" "$HOME/.claude/local/claude" "/opt/homebrew/bin/claude" \
           "/usr/local/bin/claude" "$HOME/.npm-global/bin/claude"; do
    if [ -x "$c" ]; then CLAUDE="$c"; return 0; fi
  done
  return 1
}

ask_yes() {
  local answer
  printf '    %s [Y/n] ' "$1"
  read -r answer </dev/tty || answer=""
  case "$answer" in [nN]*) return 1 ;; *) return 0 ;; esac
}

# Without the claude command, write the server straight into ~/.claude.json,
# which both the terminal and the Code tab of the Claude desktop app read.
add_to_claude_config() {
  node -e '
    const fs = require("fs");
    const file = process.argv[1];
    let config = {};
    if (fs.existsSync(file)) {
      const raw = fs.readFileSync(file, "utf8");
      config = JSON.parse(raw);
      fs.writeFileSync(file + ".backup", raw);
    }
    config.mcpServers = config.mcpServers || {};
    if (config.mcpServers["figma-console"]) { console.log("exists"); process.exit(0); }
    config.mcpServers["figma-console"] = { type: "stdio", command: "npx", args: ["-y", "figma-console-mcp@latest"], env: {} };
    fs.writeFileSync(file, JSON.stringify(config, null, 2));
    console.log("added");
  ' "$HOME/.claude.json"
}

# The Claude Code installer puts claude in ~/.local/bin; make sure new terminals can find it.
ensure_local_bin_on_path() {
  export PATH="$HOME/.local/bin:$PATH"
  local rc="$HOME/.zshrc"
  case "${SHELL:-}" in */bash) rc="$HOME/.bash_profile" ;; esac
  if ! grep -qs '.local/bin' "$rc"; then
    printf '\nexport PATH="$HOME/.local/bin:$PATH"\n' >> "$rc"
  fi
}

main() {
  printf '\nFigma Desktop Bridge setup\n'

  # 1. Node.js (runs the bridge server)
  step "Node.js"
  local major
  major=$(node_major)
  if [ "$major" -ge 18 ]; then
    ok "Node $(node -v) is installed"
  else
    if [ "$major" -gt 0 ]; then info "Node $(node -v) is too old. Installing the current LTS."
    else info "Not installed. Installing Node.js LTS..."; fi
    install_node_pkg
    if [ "$(node_major)" -ge 18 ]; then ok "Node $(node -v) installed"
    else problem "Node.js did not install. Get the LTS version from https://nodejs.org and run this again."; fi
  fi

  # 2. Claude Code
  step "Claude Code"
  if find_claude; then
    ok "Claude Code $("$CLAUDE" --version) is installed"
  elif ask_yes "Claude Code wasn't found. Install it now?"; then
    ensure_local_bin_on_path
    curl -fsSL https://claude.ai/install.sh | bash
    hash -r
    if find_claude; then ok "Claude Code $("$CLAUDE" --version) installed"
    else problem "Claude Code did not install. See https://code.claude.com/docs/en/setup and run this again."; fi
  else
    ok "Skipped. The bridge will go straight into your Claude settings."
  fi

  # 3. Figma desktop app (the browser version can't load local plugins)
  step "Figma desktop app"
  if find_figma; then
    ok "Figma desktop is installed"
  elif has brew; then
    info "Not installed. Installing Figma..."
    brew install --cask figma </dev/null
    if find_figma; then ok "Figma desktop installed"
    else problem "Figma did not install. Download it from https://www.figma.com/downloads/"; fi
  else
    open "https://www.figma.com/downloads/"
    problem "Install Figma desktop from the page that just opened, then drag it into Applications."
  fi

  # 4. The bridge plugin, copied to a fixed folder so the Figma import path never changes
  step "Figma Desktop Bridge plugin"
  if has npm; then
    local tmp tgz version="unknown"
    tmp=$(mktemp -d)
    npm pack figma-console-mcp@latest --pack-destination "$tmp" --silent </dev/null >/dev/null 2>&1
    tgz=$(ls "$tmp"/*.tgz 2>/dev/null | head -1)
    if [ -n "$tgz" ]; then
      tar -xzf "$tgz" -C "$tmp" package/figma-desktop-bridge package/package.json
      mkdir -p "$PLUGIN_DIR"
      cp "$tmp/package/figma-desktop-bridge/"{manifest.json,code.js,ui.html} "$PLUGIN_DIR/"
      version=$(sed -n 's/.*"version": *"\([^"]*\)".*/\1/p' "$tmp/package/package.json" | head -1)
      printf '%s' "$version" > "$PLUGIN_DIR/.version"
    fi
    rm -rf "$tmp"
    if [ -f "$MANIFEST" ]; then ok "Plugin version $version saved to $PLUGIN_DIR"
    else problem "Could not download the plugin. Check your internet connection and run this again."; fi
  else
    problem "Skipped the plugin because Node.js is missing."
  fi

  # 5. Tell Claude Code about the bridge server
  step "Connect Figma to Claude Code"
  if [ -n "$CLAUDE" ]; then
    if "$CLAUDE" mcp get figma-console </dev/null 2>&1 | grep -q 'No MCP server named'; then
      "$CLAUDE" mcp add figma-console -s user -- npx -y figma-console-mcp@latest </dev/null >/dev/null
      if "$CLAUDE" mcp get figma-console </dev/null 2>&1 | grep -q 'No MCP server named'; then
        problem "Could not add figma-console to Claude Code."
      else
        ok "Added figma-console to Claude Code (all projects)"
      fi
    else
      ok "figma-console is already set up in Claude Code"
    fi
  elif has node; then
    case "$(add_to_claude_config)" in
      added)  ok "Added figma-console to your Claude settings (~/.claude.json)" ;;
      exists) ok "figma-console is already in your Claude settings" ;;
      *)      problem "Could not update ~/.claude.json." ;;
    esac
  else
    problem "Skipped because Node.js is missing."
  fi

  # What's left is done by hand in Figma
  echo
  if [ ${#PROBLEMS[@]} -gt 0 ]; then
    printf '\033[33mAlmost there. Fix these, then run the same command again:\033[0m\n'
    for p in "${PROBLEMS[@]}"; do echo "  - $p"; done
    return
  fi

  printf '%s' "$MANIFEST" | pbcopy
  printf '\033[32mSetup finished. Last steps, in Figma:\033[0m\n\n'
  echo "  1. Open the Figma desktop app, sign in and open any design file."
  echo "  2. Menu > Plugins > Development > Import plugin from manifest..."
  echo "     In the file window press Cmd+Shift+G, paste this path (it is already copied) and press Enter:"
  echo "     $MANIFEST"
  echo "  3. Menu > Plugins > Development > Figma Desktop Bridge. Leave its window open."
  echo "  4. Open Claude Code: type  claude  in a NEW Terminal window, or use the Code tab in the Claude app."
  echo "     Then ask: \"Check the Figma connection and tell me which file is open.\""
  echo
  echo "Step 2 is only needed once. After that, just run the plugin (step 3) each time."

  [ -n "$FIGMA_APP" ] && open "$FIGMA_APP"
}

# Everything runs from main, so a half-downloaded script does nothing.
main "$@"
