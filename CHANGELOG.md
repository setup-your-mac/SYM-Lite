# Changelog

All notable changes to this project are documented in this file.

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