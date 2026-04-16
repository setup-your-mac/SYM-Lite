![GitHub release (latest by date)](https://img.shields.io/github/v/release/Setup-Your-Mac/SYM-Lite?display_name=tag) ![GitHub issues](https://img.shields.io/github/issues-raw/Setup-Your-Mac/SYM-Lite) ![GitHub closed issues](https://img.shields.io/github/issues-closed-raw/Setup-Your-Mac/SYM-Lite) ![GitHub pull requests](https://img.shields.io/github/issues-pr-raw/Setup-Your-Mac/SYM-Lite) ![GitHub closed pull requests](https://img.shields.io/github/issues-pr-closed-raw/Setup-Your-Mac/SYM-Lite) [![swiftDialog](https://img.shields.io/badge/swiftDialog-Enabled-blue)](https://swiftdialog.app) [![Semgrep Security Scan](https://img.shields.io/badge/security%20scanned%20by-Semgrep-00C7B7?style=flat&logo=semgrep&logoColor=white)](https://semgrep.dev)

# SYM-Lite (1.0.1b1)

> **SYM-Lite** is a lean, purpose-built script for executing MDM-agnostic [Installomator labels](https://github.com/Installomator/Installomator/tree/main/fragments/labels) and [Homebrew](https://brew.sh) casks / formulas, as well as Jamf Pro-specific [policy triggers](https://learn.jamf.com/r/en-US/jamf-pro-documentation-current/Triggers_for_Policies), all through a unified [swiftDialog](https://swiftdialog.app) selection and reporting interface.

## Screenshots

<table>
  <tr>
    <td align="center">
      <img src="images/SYML-00001.png" alt="SYM-Lite screenshot 1" width="300">
    </td>
    <td align="center">
      <img src="images/SYML-00002.png" alt="SYM-Lite screenshot 2" width="300">
    </td>
    <td align="center">
      <img src="images/SYML-00003.png" alt="SYM-Lite screenshot 3" width="300">
    </td>
  </tr>
  <tr>
    <td align="center">
      <img src="images/SYML-00004.png" alt="SYM-Lite screenshot 4" width="300">
    </td>
    <td align="center">
      <img src="images/SYML-00005.png" alt="SYM-Lite screenshot 5" width="300">
    </td>
    <td align="center">
      <img src="images/SYML-00006.png" alt="SYM-Lite screenshot 6" width="300">
    </td>
  </tr>
</table>

---

## Key Features

✓ **Unified execution support** — Installomator labels, Homebrew packages, and (optionally) Jamf Pro policies in a single session  
✓ **Interactive selection UI** — User-friendly checkbox dialog with per-item icons; optional install-state labels disable already-installed items and exit cleanly when nothing remains selectable  
✓ **Alphabetical sorting** — All items sorted together by display name in selection dialog  
✓ **Silent mode** — CSV-based automation support  
✓ **Early Installomator label validation** — Configured Installomator labels are verified against the active Installomator file before they can appear or run  
✓ **Homebrew package support** — Approved casks and formulas run in the logged-in user context when `brew` is available  
✓ **Inspect Mode monitoring** — Rich status updates for Installomator labels and path-based progress for Homebrew/Jamf items  
✓ **Log monitoring** — Parses Installomator.log for intermediate states and captures Homebrew/Jamf output into the main log  
✓ **Path-based validation** — Pre/post-execution checks via file system monitoring  
✓ **Cache monitoring** — Detects in-progress downloads  
✓ **Completion report** — Per-item results summary and optional restart prompt  
✓ **Graceful interruption** — Clean shutdown on SIGINT/SIGTERM with 30-second timeout  

---

## Quick Start Guide

### Adding Installomator Labels

Edit the `installomatorLabels` array near the top of `SYM-Lite.zsh`:

```zsh
installomatorLabels=(
    "label | Display Name | Validation Path | Icon URL"
)
```

**Example:**
```zsh
installomatorLabels=(
    "microsoftword | Microsoft Word | /Applications/Microsoft Word.app | https://icon.url"
    "googlechrome | Google Chrome | /Applications/Google Chrome.app | https://icon.url"
    "zoom | Zoom | /Applications/zoom.us.app | https://icon.url"
)
```

At runtime, SYM-Lite validates each configured label against `organizationInstallomatorFile` before building the picker or accepting silent-mode CSV input. If a label is missing from that Installomator file, or if the Installomator file is unavailable or unreadable, SYM-Lite logs a warning or error and removes Installomator labels from the current run while leaving other item types available.

### Adding Homebrew Items

Edit the `homebrewItems` array near the top of `SYM-Lite.zsh`:

```zsh
homebrewItems=(
    "cask:token | Display Name | Validation Path | Icon URL"
    "formula:token | Display Name | Validation Path | Icon URL"
)
```

**Example:**
```zsh
homebrewItems=(
    "cask:docker | Docker Desktop | /Applications/Docker.app | https://icon.url"
    "formula:node | Node.js | /opt/homebrew/bin/node | SF=terminal"
    "formula:python@3.12 | Python 3.12 | /opt/homebrew/bin/python3.12 | SF=terminal"
)
```

**Important:**
- Use `cask:` or `formula:` prefixes in the item ID
- Homebrew examples and default validation paths in this repo assume Apple silicon with Homebrew installed in `/opt/homebrew`
- Homebrew items are hidden for the current run if no working `brew` binary is available
- Homebrew items also require a valid logged-in user because package installs run in user context rather than as `root`

### Adding Jamf Policy Items

Edit the `jamfPolicyItems` array near the top of `SYM-Lite.zsh`:

```zsh
jamfPolicyItems=(
    "trigger | Display Name | Validation Path | Icon URL"
)
```

**Example:**
```zsh
jamfPolicyItems=(
    "installRosetta | Install Rosetta 2 | /usr/bin/arch | SF=cpu"
    "enableFileVault | Enable FileVault | /Library/Preferences/com.apple.fdesetup.plist | SF=lock.shield"
    "configureDock | Configure Dock | /usr/local/bin/dockutil | SF=dock.rectangle"
)
```

**Icon Options:**
- Full URL: `https://...`
- SF Symbol: `SF=symbolname,weight=semibold,colour1=auto,colour2=auto`

### Disabling Jamf Policy Items

If your environment does not use Jamf Pro, set `enableJamfPolicyItems="false"` near the top of `SYM-Lite.zsh`.

When Jamf policy items are disabled:
- Jamf policy items do not appear in the interactive selection UI
- Jamf policy items do not execute
- Jamf binary pre-flight validation is skipped
- Silent mode warns and skips Jamf item IDs in the CSV input

### Disabling Homebrew Items

If your environment does not use Homebrew packages through SYM-Lite, set `enableHomebrewItems="false"` near the top of `SYM-Lite.zsh`.

When Homebrew items are disabled:
- Homebrew items do not appear in the interactive selection UI
- Homebrew items do not execute
- Homebrew pre-flight detection is skipped
- Silent mode warns and skips Homebrew item IDs in the CSV input

---

## Usage

### Interactive Mode (Default)

Run the script as root with no parameters:

```bash
sudo ~/Downloads/SYM-Lite.zsh
```

**User experience:**
1. Selection dialog appears with all configured items
2. User selects one or more items using checkboxes
3. Inspect Mode dialog launches showing real-time progress
4. Completion report shows one row per selected item
5. Optional restart prompt

If the user clicks `Cancel` in the selection dialog, interactive mode exits cleanly without launching Inspect Mode. If `selectionDialogStatusSublabelsEnabled="true"` and every remaining valid item is already installed, interactive mode shows an informational dialog and exits without launching Inspect Mode. If no valid items remain after configuration validation, interactive mode exits cleanly with a generic unavailable-items message.

**Interactive mode requirements:**
- Requires an active logged-in GUI user
- Waits up to 120 seconds for a valid console user before exiting
- If the Mac is at the login window or otherwise headless, use `silent` mode instead

### Silent Mode

Run with Jamf parameters or direct positional arguments:

**Via Jamf Policy:**
- Parameter 4: `silent`
- Parameter 5: `androidstudio,appleXcode,cask:codex`

Parameter 5 must contain item identifiers exactly as they are defined in the configured item arrays. In this repo, that means values such as `androidstudio`, `appleXcode`, `homebrew`, `cask:1password-cli`, `cask:codex`, or `formula:direnv`, not a full Jamf command such as `jamf policy -event homebrew`.

**Direct execution:**
```bash
sudo /path/to/SYM-Lite.zsh "" "" "" silent "androidstudio,appleXcode,cask:codex"
```

Surrounding straight quotes and common smart quotes copied from rich-text sources are normalized in silent mode, but plain comma-separated item IDs are still the recommended input format.

If SYM-Lite reports an unknown item ID, compare Parameter 5 against the identifiers configured near the top of [SYM-Lite.zsh](SYM-Lite.zsh). For the current repo state, `googleChrome` is not a configured item ID, so silent mode will reject it until it is added to the appropriate item array.

**Silent mode behavior:**
- No selection dialog
- CSV list parsed directly
- No Inspect Mode or completion dialogs
- No restart prompt
- Same pre-flight checks still run, including `swiftDialog` validation / installation
- Installomator labels filtered out during pre-flight validation are warned and skipped in the CSV input
- If Jamf policy items are disabled, Jamf item IDs in the CSV are warned and skipped
- If Homebrew items are disabled or unavailable for the current run, Homebrew item IDs in the CSV are warned and skipped
- Exits with an error if the CSV contains no valid item IDs
- Suitable for automated deployment

---

## Dependencies

### Required
- **macOS** 15+ (required by swiftDialog 3.x)
- **Root access** — Script must run as `root`
- **swiftDialog** 3.0.1.4955+ (auto-installed if missing)

### External Command Dependencies
- **Installomator** — Required only when Installomator labels are configured and available for the current run
  - Configured Installomator labels are validated early against the active `organizationInstallomatorFile`
  - If the Installomator file is unavailable or cannot be parsed, Installomator labels are hidden and skipped for that run
- **Homebrew Binary** — Required only when `enableHomebrewItems="true"` and Homebrew items are configured
- **Jamf Pro Binary** — Required only when `enableJamfPolicyItems="true"` and Jamf policy items are configured

---

## Execution Flow

```
PRE-FLIGHT CHECKS
  ├─ Verify root
  ├─ Check/install swiftDialog
  ├─ Normalize Installomator labels
  ├─ Normalize Homebrew item availability and detect brew path
  ├─ Normalize Jamf item availability from configuration
  ├─ Verify Jamf binary (if enabled and items configured)
       ↓
SELECTION INTERFACE
  ├─ Show dialog (interactive) or parse CSV (silent)
  ├─ Validate at least one selection
  └─ Separate items by type (Installomator → Homebrew → Jamf)
       ↓
INSPECT MODE CONFIGURATION
  ├─ Interactive mode only
  ├─ Build unified JSON config
  ├─ Merge Installomator + Homebrew + Jamf items
  ├─ Add cachePaths for download detection
  └─ Validate JSON with plutil
       ↓
EXECUTION ENGINE
  ├─ Interactive mode launches Inspect Mode dialog (background)
  │   └─ Silent mode logs progress without UI
  ├─ Process items sequentially (Installomator → Homebrew → Jamf)
  │   ├─ Installomator: executeInstallomatorLabel()
  │   ├─ Homebrew: executeHomebrewItem()
  │   └─ Jamf: executeJamfPolicy()
  ├─ Interactive mode waits for Inspect Mode to close
  └─ Silent mode exits when execution completes
       ↓
COMPLETION & RESTART
  ├─ Interactive mode shows a completion report for selected items
  └─ Interactive mode prompts for restart (if enabled and something was newly installed)
```

---

## How Inspect Mode Works

swiftDialog's [Inspect Mode](https://swiftdialog.app/advanced/inspect-mode/) uses **dual monitoring** for comprehensive progress tracking:

### For Installomator Labels (Rich Status)

**Log Monitoring:**
- Parses `/var/log/Installomator.log` in real-time
- Uses undocumented `"preset": "installomator"` feature
- Shows intermediate states: "Downloading...", "Installing...", "Verifying...", "Completed"

**File System Monitoring:**
- Watches validation path via FSEvents API
- Item marks complete when app appears at specified path

### For Homebrew Items (Binary Status)

**File System Monitoring Only:**
- Shows binary states: "Waiting" → "Completed"
- Watches validation path (e.g., `/Applications/Docker.app` or `/opt/homebrew/bin/node`)

### For Jamf Pro Policies (Binary Status)

**File System Monitoring Only:**
- Shows binary states: "Waiting" → "Completed"
- Watches validation path (e.g., `/usr/bin/arch`)

### Common Features

- `cachePaths` monitoring for in-progress downloads
- `scanInterval: 2` — Checks every 2 seconds
- Auto-enable Close button when all items complete
- 30-second timeout if dialog doesn't close naturally

---

## Validation & Skip Logic

### Installomator Items
1. Pre-check: If validation path exists → skip
2. Execute: `Installomator.sh <label>` with `DEBUG=0 NOTIFY=silent`
3. Inspect Mode: Log parsing + path monitoring
4. Post-check: Exit code determines success/failure

### Homebrew Items
1. Pre-check: If validation path exists → skip
2. Execute: `brew install` (or `--cask`) as the logged-in user
3. Inspect Mode: Path monitoring only
4. Post-check: Exit code + path validation

### Jamf Policy Items
1. Pre-check: If validation path exists → skip
2. Execute: `jamf policy -event <trigger>`
3. Inspect Mode: Path monitoring only
4. Post-check: Exit code + path validation

---

## Customization Variables

| Variable | Default | Purpose |
|----------|---------|---------|
| `organizationPreset` | `"2"` | swiftDialog Inspect Mode preset (1-4) |
| `organizationInstallomatorFile` | `/Library/Management/...` | Path to Installomator.sh |
| `installomatorLog` | `/var/log/Installomator.log` | Installomator log path for monitoring |
| `jamfBinary` | `/usr/local/bin/jamf` | Path to jamf binary |
| `enableJamfPolicyItems` | `"true"` | Show and execute Jamf policy items |
| `brewPath` | `""` | Optional Homebrew binary override |
| `enableHomebrewItems` | `"true"` | Show and execute Homebrew cask/formula items |
| `homebrewUpdateBeforeInstall` | `"false"` | Run `brew update` once before the first Homebrew package install |
| `organizationOverlayiconURL` | swiftDialog logo | Overlay icon URL |
| `mainDialogIcon` | GitHub raw `SYM_icon.png` URL | Main dialog icon |
| `fontSize` | `"14"` | Dialog message font size |
| `selectionDialogStatusSublabelsEnabled` | `"true"` | Show install-state sublabels, disable already-installed items, and exit cleanly if no selectable items remain |
| `restartPromptEnabled` | `"true"` | Show restart prompt after completion |
| `scriptLog` | `/var/log/...log` | Client-side log path |

---

(The rest of the document — Logging, Troubleshooting, Testing Checklist, Next Steps, and Support — remains unchanged as the reordering was already applied where relevant.)

**Version:** 1.0.0  
**Date:** 12-Apr-2026  
**Author:** Dan K. Snelson (@dan-snelson)
