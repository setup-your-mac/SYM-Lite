![GitHub release (latest by date)](https://img.shields.io/github/v/release/Setup-Your-Mac/SYM-Lite?display_name=tag) ![GitHub issues](https://img.shields.io/github/issues-raw/Setup-Your-Mac/SYM-Lite) ![GitHub closed issues](https://img.shields.io/github/issues-closed-raw/Setup-Your-Mac/SYM-Lite) ![GitHub pull requests](https://img.shields.io/github/issues-pr-raw/Setup-Your-Mac/SYM-Lite) ![GitHub closed pull requests](https://img.shields.io/github/issues-pr-closed-raw/Setup-Your-Mac/SYM-Lite) [![swiftDialog](https://img.shields.io/badge/swiftDialog-Enabled-blue)](https://swiftdialog.app) [![Semgrep Security Scan](https://img.shields.io/badge/security%20scanned%20by-Semgrep-00C7B7?style=flat&logo=semgrep&logoColor=white)](https://semgrep.dev)

# SYM-Lite (1.6.0)

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
✓ **Command Line Tools bootstrap** — Installs Apple's Command Line Tools when Homebrew has no `git`, so `brew update` and taps work  
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

At runtime, SYM-Lite validates each configured label against single-line and continued top-level alias arms in `organizationInstallomatorFile` before building the picker or accepting silent-mode CSV input. If a label is missing from that Installomator file, or if the Installomator file is unavailable, unreadable, or cannot be parsed, SYM-Lite logs a warning or error and removes Installomator labels from the current run while leaving other item types available.

Because root executes Installomator, `organizationInstallomatorFile` must be an absolute path that is not a symlink, and the file and every parent directory up to `/` must be owned by `root` with no group or other write bit. SYM-Lite checks this during pre-flight (hiding Installomator labels on failure) and again immediately before each label runs (failing that item). The default App Auto-Patch location meets this requirement.

**Notes on bundled labels:**
- `firefoxesr` installs `Firefox.app`, so it shares `/Applications/Firefox.app` with regular Firefox and shows as "Already installed" on Macs that already have Firefox
- `otter` requires an Installomator build that includes the `otter` label; older builds hide the item and log an error each run

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
- Third-party tap items use fully-qualified tokens (e.g., `formula:hashicorp/tap/terraform`); when `homebrewAutoTrustItems="true"`, SYM-Lite runs `brew trust` for that item before install (official taps are always trusted)
- If the logged-in user is not a local administrator, casks install to `~/Applications` (validation paths under `/Applications/` also match `~/Applications/`)
- Homebrew runs with `HOMEBREW_NO_SUDO=1`; casks needing `sudo` (e.g., `pkg`-based installers) fail fast and report "Requires administrator rights" rather than prompting for a password
- When `homebrewCreateCompletionDirectories="true"` (default), before the first Homebrew install of each run, SYM-Lite creates `share/zsh/site-functions` and `share/fish/vendor_completions.d` under the brew prefix as the Homebrew user (never `root`); brew's completion child process can write into these directories but can't create them, so cask shell completions would otherwise fail with `Operation not permitted`
- If `brew` exits `0` but its output reports a child-process exception, `Operation not permitted`, or `Permission denied` (e.g., cask shell completions under `${homebrewPrefix}/share` failing even though the Homebrew user owns the prefix), SYM-Lite logs a `[WARNING]` and reports "Ready to use; Homebrew reported warnings"; the installed command or app still works, only extras such as shell completions may be missing
- Validation paths use `${homebrewPrefix}` (`/opt/homebrew` on Apple silicon, `/usr/local` on Intel); pre-flight warns when the detected or configured `brew` lives under a different prefix, because skip and completion checks may then be wrong
- The Homebrew user is pinned during pre-flight; if the console user changes mid-run, remaining Homebrew items fail instead of running as the new user
- When `homebrewAutoInstallCommandLineTools="true"` (default) and no `git` is found, SYM-Lite installs Apple's Command Line Tools as `root` via `softwareupdate`, once per run: before the Installomator `homebrew` label installs Homebrew, after it skips an existing Homebrew, and before the first Homebrew item. Homebrew.pkg's postinstall resets its `git` checkout only when Command Line Tools `git` already exists; installed without it, `brew --version` reports `-dirty`. No logged-in user, admin rights, or prompts are needed. Logic is adapted from Rich Trouton's [`install_xcode_command_line_tools.sh`](https://github.com/rtrouton/rtrouton_scripts/tree/main/rtrouton_scripts/install_xcode_command_line_tools) and embedded in the script (never downloaded at runtime)
- `git` detection checks the active developer directory, `/Library/Developer/CommandLineTools`, `/Applications/Xcode.app`, and a brewed `git` under the brew prefix with `-x` tests only; it never runs `/usr/bin/git`, whose stub would show the "Install Command Line Tools" prompt to the user
- Command Line Tools need Apple's software update catalog and CDN; `softwareupdate --list` can take a minute or more and the download is large, so the first Homebrew step can add several minutes. Scan and install output stream to the log (`softwareupdate (CLT scan): …`, `softwareupdate (CLT): …`) with elapsed seconds for each step. Offline Macs, a blocked CDN, or MDM-deferred updates log a `[WARNING]` and the run continues; bottle and cask installs still work without `git`
- After the Installomator `homebrew` label (or a Command Line Tools install), SYM-Lite logs `brew --version` once per run; a `-dirty` checkout logs a `[WARNING]` suggesting `brew update-reset` as the logged-in user, because Command Line Tools alone don't clean an existing checkout
- If `git` is still missing, `homebrewUpdateBeforeInstall="true"` skips `brew update` with one `[WARNING]` instead of failing every Homebrew item, the Installomator `homebrew` completion row adds "git is missing, so brew update is unavailable", and third-party tap items (`user/tap/name`) fail because tapping needs `git`
- Interactive mode disables already-installed items, so to repair an existing Homebrew that lacks `git`, select a Homebrew item that isn't installed yet, or run silent mode with `homebrew` in Parameter 5
- An installed `Xcode.app` satisfies the `git` check even if its license hasn't been accepted; `git` then fails until the license is accepted (e.g., `xcodebuild -license accept` in the Xcode policy)

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

If Jamf policy items are enabled but the Jamf binary is missing at `jamfBinary`, pre-flight logs a warning and removes Jamf policy items from the run; silent mode warns and skips their IDs in the CSV input.

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
1. Selection dialog appears with all available items (or only the items listed in Parameter 5; see [Limit the Interactive Selection Dialog](#limit-the-interactive-selection-dialog)); selectable items start checked when `selectionDialogDefaultChecked="true"`
2. User selects one or more items using checkboxes
3. Inspect Mode dialog launches showing real-time progress
4. Completion report shows one row per selected item
5. Optional restart prompt

`selectionDialogDefaultChecked` affects interactive mode only. Users can deselect prechecked items before continuing, and already-installed items disabled by status sublabels remain unchecked. Silent mode does not show a selection dialog; it runs the items listed in `operationsCSV`.

If the user clicks `Cancel` in the selection dialog, interactive mode exits cleanly without launching Inspect Mode. If `selectionDialogStatusSublabelsEnabled="true"` and every remaining valid item is already installed, interactive mode shows an informational dialog and exits without launching Inspect Mode. If no valid items remain after configuration validation, interactive mode exits cleanly with a generic unavailable-items message.

**Interactive mode requirements:**
- Requires an active logged-in GUI user
- Waits up to 120 seconds for a valid console user before exiting
- If the Mac is at the login window or otherwise headless, use `silent` mode instead

### Limit the Interactive Selection Dialog

Parameter 5 (`operationsCSV`) is optional in interactive mode. When it's set, the selection dialog shows only the listed item IDs, so one copy of SYM-Lite can back several focused Self Service policies.

**Via Jamf Policy (e.g., "Developer Tools"):**
- Parameter 4: `interactive`
- Parameter 5: `homebrew,cask:1password-cli,cask:claude-code,cask:codex,formula:direnv`

**Direct execution:**
```bash
sudo /path/to/SYM-Lite.zsh "" "" "" interactive "cask:codex,formula:direnv"
```

- An empty Parameter 5 (including separator-only values such as `,`) shows all available items, as before
- Listed items are still sorted by display name; CSV order is ignored
- Item IDs are parsed and normalized exactly as in silent mode; unknown or unavailable IDs are warned and skipped
- Status sublabels and `selectionDialogDefaultChecked` work the same way for the listed items
- If Parameter 5 contains no valid item IDs, SYM-Lite logs the valid item IDs for the run, shows the "no selectable items" dialog, and exits without falling back to the full list
- Homebrew items are hidden when `brew` is not installed, so a Homebrew-focused list should also include the `homebrew` Installomator label; once Homebrew is installed, run the policy again to see the casks and formulae

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

Silent mode also normalizes surrounding straight quotes and common smart quotes copied from rich-text sources, including when the entire CSV is wrapped once or when individual item IDs are quoted. That normalization is safe even when Jamf launches the script under a non-UTF shell locale. Plain comma-separated item IDs are still the recommended input format.

If SYM-Lite reports an unknown item ID, compare Parameter 5 against the identifiers configured near the top of [SYM-Lite.zsh](SYM-Lite.zsh). For the current repo state, `googleChrome` is not a configured item ID, so silent mode will reject it until it is added to the appropriate item array.

**Silent mode behavior:**
- No selection dialog
- CSV list parsed directly
- No Inspect Mode or completion dialogs
- No restart prompt
- Same pre-flight checks still run, including `swiftDialog` validation / installation
- Installomator labels filtered out during pre-flight validation are warned and skipped in the CSV input
- If Jamf policy items are disabled or the Jamf binary is missing, Jamf item IDs in the CSV are warned and skipped
- If Homebrew items are disabled or unavailable for the current run, Homebrew item IDs in the CSV are warned and skipped
- Exits with an error if the CSV contains no valid item IDs
- Suitable for automated deployment

---

## Dependencies

### Required
- **macOS** 15+ (required by swiftDialog 3.x)
- **Root access** — Script must run as `root`
- **swiftDialog** 3.1.0.4994+ (auto-installed if missing)

### External Command Dependencies
- **Installomator** — Required only when Installomator labels are configured and available for the current run
  - Configured Installomator labels are validated early against the active `organizationInstallomatorFile`
  - If the Installomator file is unavailable or cannot be parsed, Installomator labels are hidden and skipped for that run
- **Homebrew Binary** — Required only when `enableHomebrewItems="true"` and Homebrew items are configured
- **Apple Command Line Tools** — Installed via `softwareupdate` only when `homebrewAutoInstallCommandLineTools="true"` and Homebrew has no `git`; needs Apple's software update catalog and CDN
- **Jamf Pro Binary** — Required only when `enableJamfPolicyItems="true"` and Jamf policy items are configured

---

## Execution Flow

```
PRE-FLIGHT CHECKS
  ├─ Verify root
  ├─ Check/install swiftDialog
  ├─ Normalize Installomator labels
  ├─ Normalize Homebrew item availability, detect brew path, and log git availability
  ├─ Normalize Jamf item availability from configuration
  ├─ Verify Jamf binary (if enabled and items configured; removes Jamf items when missing)
  ├─ Warn on item IDs configured in more than one item array
       ↓
SELECTION INTERFACE
  ├─ Show dialog (interactive; optional Parameter 5 allowlist) or parse CSV (silent)
  ├─ Validate at least one selection
  └─ Collect selected item IDs (interactive: display-name order; silent: CSV order)
       ↓
INSPECT MODE CONFIGURATION
  ├─ Interactive mode only
  ├─ Build unified JSON config
  ├─ Merge Installomator + Homebrew + Jamf items
  ├─ Add a Command Line Tools row when Homebrew work is selected and git is missing
  ├─ Add cachePaths for download detection
  └─ Validate JSON with plutil
       ↓
EXECUTION ENGINE
  ├─ Interactive mode launches Inspect Mode dialog (background)
  │   └─ Silent mode logs progress without UI
  ├─ Process items sequentially in selection order
  │   ├─ Installomator: executeInstallomatorLabel() (`homebrew` label: install Command Line Tools first if git is missing)
  │   ├─ Homebrew: executeHomebrewItem() (installs Command Line Tools first if git is missing)
  │   └─ Jamf: executeJamfPolicy()
  ├─ Interactive mode waits for Inspect Mode to close
  └─ Silent mode exits when execution completes
       ↓
COMPLETION & RESTART
  ├─ Interactive mode shows a completion report for selected items
  └─ Interactive mode prompts for restart (if enabled and something was newly installed); "Restart Now" asks `loginwindow` to restart as the logged-in user, so apps can prompt to save
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
- When Command Line Tools will be installed for Homebrew (setting enabled, Homebrew work selected, `git` missing), a "Command Line Tools (for Homebrew)" row appears where the install runs: right before the Installomator `homebrew` row or the first Homebrew item, whichever comes first. It shows "Waiting" → "Completed" (no percentage) and completes once `git` is available; if the install fails, it stays waiting like any other failed item. A side message notes it can take several minutes

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
2. Re-check Installomator ownership and permissions (fails the item if the check no longer passes)
3. Execute: `Installomator.sh <label>` with `DEBUG=0 NOTIFY=silent`
4. Inspect Mode: Log parsing + path monitoring
5. Post-check: Exit code determines success/failure
6. `homebrew` label only: when `enableHomebrewItems="true"`, install Command Line Tools if `git` is missing, before step 3 (so Homebrew.pkg's postinstall leaves a clean checkout) or after a skip; log `brew --version` (`[WARNING]` on `-dirty`); the row adds "git is missing, so brew update is unavailable" if it still is

### Homebrew Items
1. Pre-check: If validation path exists → skip
2. Command Line Tools: when `homebrewAutoInstallCommandLineTools="true"` and no `git` is found, once per run, install Command Line Tools as `root` via `softwareupdate`
3. Metadata (optional): when `homebrewUpdateBeforeInstall="true"`, once per run, run `brew update` as the logged-in user; skipped with a `[WARNING]` if `git` is still missing
4. Completion directories: when `homebrewCreateCompletionDirectories="true"`, once per run, create `share/zsh/site-functions` and `share/fish/vendor_completions.d` under the brew prefix as the logged-in user
5. Trust: `brew trust` for configured third-party tap items (`user/tap/name`) when `homebrewAutoTrustItems="true"`
6. Execute: `brew install` (or `--cask`; adds `--appdir=~/Applications` for non-admin users) as the logged-in user with `HOMEBREW_NO_SUDO=1`
7. Inspect Mode: Path monitoring only
8. Post-check: Exit code + path validation; a successful install whose output reports child-process or permission errors logs a `[WARNING]` and reports "Ready to use; Homebrew reported warnings"
9. Quarantine (optional): when `homebrewAutoRemoveQuarantine="true"` and the cask validation path is an `.app`, run `spctl --assess --type execute`; only if Gatekeeper accepts, remove `com.apple.quarantine` as the logged-in user (`xattr -drs`) so first launch skips the "downloaded from the Internet" prompt

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
| `organizationInstallomatorFile` | `/Library/Application Support/AppAutoPatch/Installomator/Installomator.sh` | Path to Installomator.sh |
| `installomatorLog` | `/var/log/Installomator.log` | Installomator log path for monitoring |
| `jamfBinary` | `/usr/local/jamf/bin/jamf` | Path to jamf binary |
| `enableJamfPolicyItems` | `"true"` | Show and execute Jamf policy items |
| `brewPath` | `""` | Optional Homebrew binary override |
| `enableHomebrewItems` | `"true"` | Show and execute Homebrew cask/formula items |
| `homebrewUpdateBeforeInstall` | `"false"` | Run `brew update` once before the first Homebrew package install |
| `homebrewCreateCompletionDirectories` | `"true"` | Before the first Homebrew install, create `share/zsh/site-functions` and `share/fish/vendor_completions.d` under the brew prefix as the logged-in user so cask shell completions can install |
| `homebrewAutoInstallCommandLineTools` | `"true"` | When no `git` is found, install Apple's Command Line Tools as `root` via `softwareupdate` before first Homebrew use, so `brew update` and taps work; `"false"` only logs a `[WARNING]` |
| `homebrewAutoTrustItems` | `"true"` | Run `brew trust` for configured third-party tap items (`user/tap/name`) before install |
| `homebrewAutoRemoveQuarantine` | `"false"` | After a cask install, remove `com.apple.quarantine` from its `.app` validation path, only when Gatekeeper accepts the app |
| `organizationOverlayiconURL` | swiftDialog logo | Overlay icon URL |
| `mainDialogIcon` | GitHub raw `SYM_icon.png` URL | Main dialog icon |
| `fontSize` | `"14"` | Dialog message font size |
| `selectionDialogDefaultChecked` | `"true"` | Start selectable interactive-mode items checked |
| `selectionDialogStatusSublabelsEnabled` | `"true"` | Show install-state sublabels, disable already-installed items, and exit cleanly if no selectable items remain |
| `restartPromptEnabled` | `"true"` | Show restart prompt after completion |
| `scriptLog` | `/var/log/...log` | Client-side log path (created `0640`; rotated at 10 MB, keeping the three newest `.old` files) |

Item IDs must be unique across `installomatorLabels`, `jamfPolicyItems`, and `homebrewItems`; pre-flight warns on duplicates, and the first match (Installomator, then Jamf, then Homebrew) wins.

---

**Version:** 1.6.0  
**Date:** 08-Oct-2026  
**Author:** Dan K. Snelson (@dan-snelson)
