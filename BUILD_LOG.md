# Build log

## 2026-11-03 (evening)

**Done:** Added an optional step 6 to both scripts: if the Claude desktop app is installed, ask whether to connect Figma to its normal chat too, and write figma-console into claude_desktop_config.json. Tested the config writer on fake files (new file, existing file, already added) and the Windows app detection on this computer. Not tested: an actual chat in the Claude app using the bridge, on either system.

**Next:** Run the installer on a computer with the Claude app, say yes to step 6, restart the app and ask it to check the Figma connection.

## 2026-11-03 (later)

**Done:** First Mac try failed because only the URL was pasted, not the full curl command (user error, script fine). Ayodeji asked for students who already have Claude to be able to skip the Claude Code install. Both scripts now look for claude in more places (npm, Homebrew, old ~/.claude/local install), ask before installing it, and when skipped write figma-console straight into ~/.claude.json with Node (backup kept as .claude.json.backup). Tested the settings writer on fake config files on both scripts, and reran the full Windows script.

**Next:** Rerun on the Mac with the full command.

## 2026-11-03

**Done:** Wrote both installers. Ran `install.ps1` on Ayodeji's main computer (everything already installed): every step reported ok, and the plugin refreshed to 1.46.0. Checked `install.sh` syntax and tested its Node lookup and plugin download steps in Git Bash. Not run on a real Mac yet.

**Published:** public repo ayareago/figma-bridge-setup (Ayodeji approved making it public). Ran the live Windows one-liner from GitHub: every step ok. The live Mac script downloads with Unix line endings and parses.

**Next:** Test the Windows command on Ayodeji's new computer and find a Mac to test on.
