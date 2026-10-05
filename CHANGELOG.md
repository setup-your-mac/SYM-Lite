# Changelog

All notable changes to this project are documented in this file.

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