; Inno Setup recipe for FigmaBridgeSetup.exe.
; It installs nothing itself: it runs install.ps1 in a visible window
; so students can see each step and answer its questions.
; Built by .github/workflows/release.yml.

#ifndef AppVersion
  #define AppVersion "1.0.0"
#endif

[Setup]
AppName=Figma Bridge Setup
AppVersion={#AppVersion}
AppPublisher=Ayodeji Areago
AppPublisherURL=https://github.com/ayareago/figma-bridge-setup
VersionInfoDescription=Figma Bridge Setup
CreateAppDir=no
Uninstallable=no
PrivilegesRequired=lowest
DisableReadyPage=yes
WizardStyle=modern
OutputDir=..\dist
OutputBaseFilename=FigmaBridgeSetup

[Files]
Source: "..\install.ps1"; DestDir: "{tmp}"; Flags: deleteafterinstall

[Run]
Filename: "powershell.exe"; Parameters: "-NoProfile -ExecutionPolicy Bypass -Command ""$env:FIGMA_BRIDGE_PAUSE='1'; & '{tmp}\install.ps1'"""; StatusMsg: "Setting up. Follow the steps in the window that opened."; Flags: waituntilterminated

[Messages]
WelcomeLabel1=Set up Figma for Claude or ChatGPT
WelcomeLabel2=This gets your computer ready to use Claude or ChatGPT with Figma. It adds Node.js, Claude Code, Figma and the Figma Desktop Bridge plugin if they're missing, and can connect the Claude and ChatGPT desktop apps.%n%nA window will open and show each step. If Windows asks for permission, click Yes.
FinishedHeadingLabel=Almost done
FinishedLabelNoIcons=The last step is adding the plugin in Figma. The setup window showed how, and the plugin's path is already copied.%n%nIn Figma: Menu > Plugins > Development > Import plugin from manifest, then paste the path.
