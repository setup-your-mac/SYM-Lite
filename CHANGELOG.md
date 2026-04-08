# Changelog

All notable changes to this project are documented in this file.

## 1.0.0b5 - 08-Apr-2026
- Added pre-flight validation for configured Installomator labels against the active Installomator file.
- Filtered unavailable Installomator labels out of the interactive picker, silent-mode CSV parsing, and runtime item lookups.
- Updated the no-selectable-items dialog so filtered labels do not appear as already installed.
- Changed Installomator dependency handling to fail fast when the configured file is missing, unreadable, non-executable, or zero bytes.
- Updated release documentation for early Installomator label validation.

## 1.0.0b4 - 08-Apr-2026
- Added validation-path status text to each interactive selection dialog row.
- Added an organization-level toggle to hide selection dialog status sublabels (i.e., `selectionDialogStatusSublabelsEnabled="false"`)
- Disabled already-installed items while preserving unified sorting, icons, and switch styling in the picker.
- Fixed interactive picker selection parsing by using stable checkbox names and exiting cleanly when all items are already installed.
- Updated release documentation for the new selection dialog feedback.

## 1.0.0b3 - 02-Apr-2026
- Added an organization-level switch to hide Jamf policy items from the UI and skip Jamf execution.
- Updated silent mode CSV parsing to warn and skip Jamf item IDs when Jamf policy items are disabled.
- Refined Inspect Mode messaging so it reflects the selected item types.

## 1.0.0b2 - 29-Mar-2026
- Replaced the plain completion dialog with a richer end-user completion report.
- Added per-item completion rows sorted alphabetically by display name.
- Interactive runs now show the completion report even when all selected items were already installed, while still skipping the restart prompt in that case.

## 1.0.0b1 - 28-Mar-2026
- Initial beta release
- Added interactive logged-in GUI user validation before dialog actions
- Added per-user handoff for the Inspect Mode JSON configuration
- Improved Inspect Mode JSON validation and refreshed project documentation

## 0.0.1a3 - 27-Mar-2026
- Added additional apps to Installomator labels.

## 0.0.1a2 - 26-Mar-2026
- Added per-item icons to selection dialog checkboxes.
- Changed item array delimiter from colon to space-padded pipe (` | `).
- Skip completion and restart dialogs when all selected items were already installed.
- Sort all checkboxes (Installomator and Jamf) together alphabetically by display name.

## 0.0.1a1 - 26-Mar-2026
- Initial alpha release.
- Unified Installomator label and Jamf Pro policy execution.
- swiftDialog Inspect Mode with dual log monitoring.
- Selection-based workflow with no additional user input.
