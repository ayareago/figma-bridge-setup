-- The Mac app: opens Terminal and runs the install.sh bundled inside it,
-- so students can see each step and answer its questions.
on run
	set scriptPath to POSIX path of (path to resource "install.sh")
	tell application "Terminal"
		activate
		do script "bash " & quoted form of scriptPath
	end tell
end run
