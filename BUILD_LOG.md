# Build log

## 2026-11-04

**Tested on a second Windows laptop** (new free Claude account, newer Store app 4.16336): FigmaBridgeSetup.exe installed Node and the plugin and wrote the settings correctly (confirmed with check.ps1), but the normal chat had no figma-console until Claude was ended in Task Manager and reopened. After that it showed under Settings > Customize > Connectors as "Desktop, Local dev" and named the open file. So **the free plan works for the normal chat**; only Claude Code needs a paid plan.

**Changed:** step 6 no longer asks students to quit Claude. A pop-up on top of everything asks first, then the setup closes Claude itself (close, then force after 10 s), writes the settings and reopens Claude. It restarts Claude even when the entry already exists, because the laptop showed an entry can be on disk but not loaded. Added check.ps1, a read-only diagnostic. Tagged v1.1.0.

**Not tested:** the close and reopen step itself. It can't run on Ayodeji's main computer without closing this Claude session; test it on the laptop.

## 2026-11-03 (late night)

**Done:** Ayodeji reports the earlier one-line Mac command worked on a Mac. He asked for a download-and-click installer instead of terminal commands. Added: windows/setup.iss (Inno Setup wizard that runs install.ps1 in a visible window and keeps it open at the end), mac/ (an AppleScript app that opens Terminal and runs the bundled install.sh), and a GitHub Actions workflow that builds both and publishes a release on each v* tag. Tagged v1.0.0.

**Next:** Ayodeji tests FigmaBridgeSetup.exe on another Windows computer; test the Mac app.

## 2026-11-03 (night)

**Verified:** the normal chat in Ayodeji's Claude app (Windows Store version) used figma-console and named the open file (Class Test). The first try failed: the app wrote its settings back from memory while running and wiped the entry. Added while the app ran, the entry survived 90 s; it also survived a full quit, and the app loaded it on start.

**Changed:** step 6 now waits (up to 3 min) for the student to quit the Claude app before writing its settings, on both systems. The closing message tells students to say "use figma-console", because the app otherwise picks the official Figma web connector, which can't see the open file.

**Next:** Same test on a Mac.

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
