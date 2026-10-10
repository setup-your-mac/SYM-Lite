# Changelog

All notable changes to this project are documented in this file.

## 1.6.0 - 10-Oct-2026
- When `git` is missing (no Xcode, Command Line Tools, or brewed `git`), SYM-Lite installs Apple's Command Line Tools as `root` via `softwareupdate` so Homebrew isn't left degraded; logic adapted from Rich Trouton's `install_xcode_command_line_tools.sh`; disable with `homebrewAutoInstallCommandLineTools="false"` (Issue #27)
- Command Line Tools install runs once per run, before the Installomator `homebrew` label installs Homebrew (Homebrew.pkg's postinstall resets its `git` checkout only when Command Line Tools `git` exists; otherwise `brew --version` reports `-dirty`), after the label skips an existing Homebrew, and before the first Homebrew item; it needs no logged-in user
- Pre-flight logs whether `git` is available for Homebrew
- With `homebrewUpdateBeforeInstall="true"`, a still-missing `git` skips `brew update` with one `[WARNING]` instead of failing every Homebrew item
- The Installomator `homebrew` completion row adds "git is missing, so brew update is unavailable" when Command Line Tools couldn't be installed
- Inspect Mode shows a "Command Line Tools (for Homebrew)" row where the install runs (before the `homebrew` label or the first Homebrew item); it completes once `git` is available, and its side message leads the list (Preset 3 shows only the first side message) noting it can take several minutes with no visible progress
- After the Installomator `homebrew` label (or a Command Line Tools install), `brew --version` is logged once per run; a `-dirty` checkout logs a `[WARNING]` suggesting `brew update-reset`
- Command Line Tools progress is logged: `softwareupdate` scan and install output stream to the log as `softwareupdate (CLT scan): …` and `softwareupdate (CLT): …`, with elapsed seconds for each step
- Selection and completion dialog height is now Parameter 6 (default: `675`), so a short `operationsCSV` list can use a smaller window
- When Parameter 6 is less than `500`, Inspect Mode uses Preset 3 (Compact) instead of `organizationPreset`, sized to match the selection and completion dialogs (900 x Parameter 6)
- Inspect Mode's completion button reads "Continue" (was "Review Results"); Preset 3 omits "Please wait..." because it ignores `autoEnableButtonText` when `button1text` is set
- Installomator `codex` validation path is now `/Applications/ChatGPT.app` (where the label installs), so Inspect Mode marks it complete and enables the button
- Added Installomator labels: Oracle MySQL Workbench CE (`mysqlworkbenchce`), OutSystems Service Studio (`outsystemsservicestudio`)

## 1.5.1 - 06-Oct-2026
- Homebrew installs that exit 0 but report child-process or permission errors (e.g., shell completions under `${homebrewPrefix}/share`) now log a `[WARNING]` and show "Ready to use; Homebrew reported warnings" (Issue #24)
- Before the first Homebrew install of each run, SYM-Lite creates `share/zsh/site-functions` and `share/fish/vendor_completions.d` under the brew prefix as the Homebrew user, because brew's completion child process can't create them; disable with `homebrewCreateCompletionDirectories="false"` (Issue #24)

## 1.5.0 - 06-Oct-2026
- Interactive mode honors a non-empty `operationsCSV` (Parameter 5) as a selection dialog allowlist; an empty value still shows all items (FR #23)
- Interactive mode shows the "No selectable items" dialog (after logging valid item IDs) when `operationsCSV` contains no valid item IDs

## 1.4.0 - 06-Oct-2026
- Added Homebrew casks: Claude CLI (`claude-code`), Mem AI (`mem`), Soulver AI (`soulver`), WPS Office (`wpsoffice`)
- Added Installomator labels: Firefox ESR (`firefoxesr`), Nova (`nova`), Otter AI (`otter`)
- Added Homebrew auto-trust: configured third-party tap items (`user/tap/name`) are trusted via `brew trust` before install (`homebrewAutoTrustItems`)
- Added optional Homebrew cask quarantine removal (`homebrewAutoRemoveQuarantine`, default `false`): after install, `com.apple.quarantine` is removed as the logged-in user only when Gatekeeper accepts the app
- Homebrew casks install to `~/Applications` when the logged-in user is not a local administrator; validation accepts `/Applications` or `~/Applications`
- Homebrew commands run with `HOMEBREW_NO_SUDO=1` so steps requiring `sudo` fail fast (reported as "Requires administrator rights") instead of hanging on a password prompt
- Consolidated Homebrew command environment into `setHomebrewCommandEnvironment()`
- Installomator ownership check now covers every parent directory, rejects symlinked or relative paths, and re-runs immediately before each label executes
- swiftDialog bootstrap requires Gatekeeper acceptance as a notarized Developer ID package before trusting the Team ID
- Jamf policy items are removed from the run when the Jamf binary is missing; silent mode reports "Jamf binary unavailable"
- Pre-flight warns when the Homebrew binary prefix does not match the validation prefix
- Homebrew user is pinned for the run; a mid-run console-user change fails remaining Homebrew items instead of installing as a different user
- Client log created `0640`; log rotation keeps only the three newest `.old` files
- Pre-flight warns when an item ID is configured in more than one item array
- Removed unreachable root `shutdown -r now` restart branch; "Restart Now" restarts only via `loginwindow` as the logged-in user and warns (instead of exiting) if no user is logged in

## 1.3.0 - 05-Oct-2026
- Updated icon for Visual Studio Code
- Validated with Monocle
- Moved swiftDialog hand-off files into a root-owned per-run directory under `/var/tmp`; `quit:` now sent as the logged-in user
- Removed `/usr/local/bin` from `PATH`; swiftDialog and `jamf` now run from root-owned paths
- Added Installomator ownership and permissions check before executing labels
- Exits non-zero when any item fails so Jamf Pro reports failed runs
- `runAsUser` no longer re-runs failed commands
- Made Homebrew validation paths architecture-aware (Intel: `/usr/local`; Apple silicon: `/opt/homebrew`)
- Normalized and validated `operationMode` (Parameter 4)
- Hardened swiftDialog install / update checks (empty version, `installer` exit status, post-install version)
- Fixed home directory parsing for paths containing spaces
- Excluded `_mbsetupuser` and `root` as valid logged-in users
- Inspect Mode window now moveable and can be minimized via JSON `options` (swiftDialog 3.1.1+; ignored on 3.1.0)
- Restart prompt hides default keyboard actions to prevent accidental restarts (swiftDialog 3.1.1+)

## 1.2.0 - 19-Aug-2026
- Fixed validation of Installomator labels declared in multiline alias arms (Bug Report #16)
- Added `selectionDialogDefaultChecked` to configure default selection for interactive-mode items (while keeping already-installed items disabled and unchecked; thanks for FR #14, @jeffmw777!)
- Updated `codex` Validation Path

## 1.1.0 - 04-Aug-2026
- Normalize surrounding straight and smart quotes in silent-mode CSV item IDs before lookup (thanks for the heads-up, @applegurutim!)
- Clarify that Silent Mode Parameter 5 expects configured item identifiers, not Jamf command strings.
- Fix silent-mode Parameter 5 parsing when Jamf passes multiple comma-separated item IDs wrapped in one quoted CSV string (thanks for another heads-up, @applegurutim!)
- Updates for OpenAI renaming "Codex.app" to "ChatGPT.app"
- Bumped minimum swiftDialog version to 3.1.0.4994 and updated default Installomator path to `/Library/Application Support/AppAutoPatch/Installomator/Installomator.sh`

## 1.0.0 - 12-Apr-2026
- Official 1.0.0 release