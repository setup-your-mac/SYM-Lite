# Changelog

All notable changes to this project are documented in this file.

## 1.2.0b3 - 18-Aug-2026
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