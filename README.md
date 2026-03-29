# SYM-Lite

> **SYM-Lite** is a lean, purpose-built script for executing Jamf Pro Policy [Custom Triggers](https://learn.jamf.com/r/en-US/jamf-pro-documentation-current/Triggers_for_Policies) _and / or_ [Installomator labels](https://github.com/Installomator/Installomator/tree/main/fragments/labels) through a unified [swiftDialog](https://swiftdialog.app) selection interface

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

✓ **Dual execution support** — Installomator labels AND Jamf Pro policies in single session  
✓ **Interactive selection UI** — User-friendly checkbox dialog with per-item icons  
✓ **Alphabetical sorting** — All items sorted together by display name in selection dialog  
✓ **Silent mode** — CSV-based automation support  
✓ **Inspect Mode monitoring** — Real-time progress with rich status updates for Installomator labels  
✓ **Log monitoring** — Parses Installomator.log for intermediate states (downloading, installing, verifying)  
✓ **Path-based validation** — Pre/post-execution checks via file system monitoring  
✓ **Cache monitoring** — Detects in-progress downloads  
✓ **Completion dialogs** — Success/failure summary and restart prompt (skipped when all items already installed)  
✓ **Graceful interruption** — Clean shutdown on SIGINT/SIGTERM with 30-second timeout  

---

## Quick Start Guide

### Adding Installomator Items

Edit the `installomatorItems` array near the top of `SYM-Lite.zsh`:

```zsh
installomatorItems=(
    "label | Display Name | Validation Path | Icon URL"
)
```

**Example:**
```zsh
installomatorItems=(
    "microsoftword | Microsoft Word | /Applications/Microsoft Word.app | https://icon.url"
    "googlechrome | Google Chrome | /Applications/Google Chrome.app | https://icon.url"
    "zoom | Zoom | /Applications/zoom.us.app | https://icon.url"
)
```

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
4. Completion dialog shows results
5. Optional restart prompt

### Silent Mode

Run with Jamf parameters or direct positional arguments:

**Via Jamf Policy:**
- Parameter 4: `silent`
- Parameter 5: `microsoftword,googlechrome,installRosetta`

**Direct execution:**
```bash
sudo /path/to/SYM-Lite.zsh "" "" "" silent "microsoftword,googlechrome"
```

**Silent mode behavior:**
- No selection dialog
- CSV list parsed directly
- No Inspect Mode or completion dialogs
- No restart prompt
- Same pre-flight checks still run, including `swiftDialog` validation / installation
- Exits with an error if the CSV contains no valid item IDs
- Suitable for automated deployment

---

## Dependencies

### Required
- **macOS** 15+ (required by swiftDialog 3.x)
- **Root access** — Script must run as `root`
- **swiftDialog** 3.0.1.4955+ (auto-installed if missing)

### External Command Dependencies
- **Installomator** — Required for selected Installomator items to succeed
  - Default path: `/Library/Management/AppAutoPatch/Installomator/Installomator.sh` [:link:](https://github.com/App-Auto-Patch/App-Auto-Patch/wiki)
    - Edit `organizationInstallomatorFile` variable to customize
  - If the configured file exists but is zero bytes, pre-flight exits with a fatal error
  - If the binary is missing, pre-flight logs warnings and selected Installomator items will fail at execution time
- **Jamf Pro Binary** — Required for selected Jamf policy items to succeed
  - Default path: `/usr/local/bin/jamf`
  - If the binary is missing, pre-flight logs warnings and selected Jamf policy items will fail at execution time

---

## Execution Flow

```
PRE-FLIGHT CHECKS
  ├─ Verify root
  ├─ Check/install swiftDialog
  ├─ Verify Installomator (if items configured; rejects zero-byte file)
  └─ Verify Jamf binary (if items configured)
       ↓
SELECTION INTERFACE
  ├─ Show dialog (interactive) or parse CSV (silent)
  ├─ Validate at least one selection
  └─ Separate items by type
       ↓
INSPECT MODE CONFIGURATION
  ├─ Interactive mode only
  ├─ Build unified JSON config
  ├─ Merge Installomator + Jamf items
  ├─ Add cachePaths for download detection
  └─ Validate JSON with plutil
       ↓
EXECUTION ENGINE
  ├─ Interactive mode launches Inspect Mode dialog (background)
  │   └─ Silent mode logs progress without UI
  ├─ Process items sequentially
  │   ├─ Installomator: executeInstallomatorLabel()
  │   └─ Jamf: executeJamfPolicy()
  ├─ Interactive mode waits for Inspect Mode to close
  └─ Silent mode exits when execution completes
       ↓
COMPLETION & RESTART
  ├─ Interactive mode shows completion dialog (success/errors)
  └─ Interactive mode prompts for restart (if enabled)
```

---

## How Inspect Mode Works

swiftDialog's [Inspect Mode](https://swiftdialog.app/advanced/inspect-mode/) uses **dual monitoring** for comprehensive progress tracking:

### For Installomator Labels (Rich Status)

**Log Monitoring:**
- Parses `/var/log/Installomator.log` in real-time
- Uses undocumented `"preset": "installomator"` feature
- Shows intermediate states:
  - "Downloading..." (with progress if available)
  - "Installing Microsoft Word..."
  - "Verifying..."
  - "Completed"

**File System Monitoring:**
- Watches validation path via FSEvents API
- Item marks complete when app appears at specified path
- Independent verification of installation success

### For Jamf Pro Policies (Binary Status)

**File System Monitoring Only:**
- No log parsing (no Jamf equivalent to Installomator preset)
- Shows binary states:
  - "Waiting" (policy executing)
  - "Completed" (validation path detected)

### Common Features

**Both types benefit from:**
- `cachePaths` monitoring — Detects `.pkg`, `.dmg`, `.download` files in progress
- `scanInterval: 2` — Checks for path changes every 2 seconds
- Auto-enable Close button when all items complete
- 30-second timeout if dialog doesn't close naturally

**Example Flow (Installomator):**
1. Script executes: `Installomator.sh microsoftword`
2. Log shows: "Downloading..." → User sees rich progress
3. Log shows: "Installing Microsoft Word..." → Status updates
4. Path appears: `/Applications/Microsoft Word.app` → Marks complete

**Example Flow (Jamf Policy):**
1. Script executes: `jamf policy -event installRosetta`
2. Dialog shows: "Waiting" → No intermediate updates
3. Path appears: `/usr/bin/arch` → Marks complete

---

## Restart Prompt Behavior

In interactive mode, after all items complete and the completion dialog closes, SYM-Lite prompts for a restart (if `restartPromptEnabled="true"`).

**Restart Prompt Dialog:**
- Title: "Restart Recommended"
- Message: "A restart is recommended to complete the installation. Would you like to restart now?"
- Button 1: "Restart Now"
- Button 2: "Later"

**User Clicks "Restart Now":**
1. Script sends AppleScript restart event to loginwindow
2. macOS shows its **standard restart confirmation dialog**
3. User confirms the restart (or cancels at macOS level)
4. This is a "polite" restart — gives user final control

**User Clicks "Later":**
1. Script logs "User chose to restart later"
2. Script exits normally
3. No restart occurs

**Silent Mode:**
- Restart prompt **never shows** in silent mode
- Script exits when item execution completes
- Suitable for unattended deployment

**Disable Restart Prompt:**
Set `restartPromptEnabled="false"` in the script to skip the prompt entirely in all modes.

**Technical Implementation:**
- Uses `executeRestartAction "Restart Confirm"` helper
- Sends `«event aevtrrst»` to loginwindow as logged-in user
- Runs via `runAsUser` to ensure proper user context
- Falls back gracefully if AppleScript command fails

---

## Validation & Skip Logic

### Installomator Items
1. **Pre-check:** If validation path exists → skip, log "already exists"
2. **Execute:** Run Installomator with `DEBUG=0 NOTIFY=silent`
3. **Inspect Mode:** Watches validation path, marks complete when app appears
4. **Post-check:** Exit code 0 = success, non-zero = failure

### Jamf Policy Items
1. **Pre-check:** If validation path exists → skip, log "already configured"
2. **Execute:** Run `jamf policy -event <trigger>`
3. **Inspect Mode:** Watches validation path, marks complete when file appears
4. **Post-check:** 
   - Exit code 0 + validation path exists = success
   - Exit code 0 + validation path missing = success (warn)
   - Non-zero exit code = failure

**Important:** Inspect Mode visual feedback is independent of script success/failure tracking. The dialog shows items as complete when paths appear, but the script tracks actual execution success separately.

---

## Customization Variables

| Variable | Default | Purpose |
|----------|---------|---------|
| `organizationPreset` | `"2"` | swiftDialog Inspect Mode preset (1-4) |
| `organizationInstallomatorFile` | `/Library/Management/...` | Path to Installomator.sh |
| `installomatorLog` | `/var/log/Installomator.log` | Installomator log path for monitoring |
| `jamfBinary` | `/usr/local/bin/jamf` | Path to jamf binary |
| `organizationOverlayiconURL` | swiftDialog logo | Overlay icon URL |
| `mainDialogIcon` | GitHub raw `SYM_icon.png` URL | Main dialog icon |
| `fontSize` | `"14"` | Dialog message font size |
| `restartPromptEnabled` | `"true"` | Show restart prompt after completion |
| `scriptLog` | `/var/log/...log` | Client-side log path |

---

## Logging

**Primary Log:** `/var/log/org.churchofjesuschrist.log`
- Set `scriptLog` to your organization's preferred log path

**Log Levels:**
- `[PRE-FLIGHT]` — Initial checks
- `[NOTICE]` — Major operations
- `[INFO]` — Detailed status updates
- `[WARNING]` — Non-fatal issues
- `[ERROR]` — Failures
- `[FATAL ERROR]` — Script termination

**Output Capture:**
- Installomator output: Captured and logged with `Installomator (label):` prefix
- Jamf policy output: Captured and logged with `Jamf (trigger):` prefix
- All output written to primary script log for troubleshooting

**Inspect Mode Monitoring:**
- **Installomator labels:** Log parsing (`/var/log/Installomator.log`) + file system monitoring
- **Jamf policies:** File system monitoring only (FSEvents)
- Items mark complete when validation paths appear
- Rich status updates shown for Installomator labels during execution

**Auto-rotation:** Log rotates when exceeds 10MB

---

## Troubleshooting

### swiftDialog not installing
- Check internet connectivity
- Verify GitHub access (not blocked by firewall)
- Manually download from: https://github.com/swiftDialog/swiftDialog/releases

### Items being skipped
- Check validation paths are correct
- Verify apps/files don't already exist
- Review pre-flight log messages

### Jamf policies failing
- Verify jamf binary exists: `ls -l /usr/local/bin/jamf`
- Test trigger manually: `sudo jamf policy -event <trigger>`
- Check policy exists in Jamf Pro and trigger name matches

### Installomator failures
- Verify Installomator path: `ls -lah /Library/Management/.../Installomator.sh`
- Verify file is non-zero bytes — a zero-byte Installomator file causes a fatal pre-flight error
- Test label manually: `sudo /path/to/Installomator.sh <label> DEBUG=1`
- Check label exists and is spelled correctly

### Missing dependencies
- If `swiftDialog` is unavailable and cannot be installed, the script exits during pre-flight
- If `Installomator.sh` is missing, pre-flight logs warnings but selected Installomator items fail when executed
- If the `jamf` binary is missing, pre-flight logs warnings but selected Jamf policy items fail when executed

### Selection dialog empty
- Verify items are configured in arrays
- Check array syntax (space-padded pipe-separated fields: `"id | Display Name | /validation/path | iconURL"`)
- Review pre-flight log for parsing errors

### Script hangs after clicking Close
- Script implements 30-second timeout for dialog close
- After timeout, dialog is force-terminated and script continues
- Check for debug output in terminal (may indicate dialog issue)
- Verify `dialogPID` was captured correctly in logs
- If consistently hanging, check for swiftDialog version issues

---

## Testing Checklist

### Before Production
- [ ] Edit `installomatorItems` array with organization's apps
- [ ] Edit `jamfPolicyItems` array with organization's policies
- [ ] Update icon URLs to organization's icons
- [ ] Verify Installomator path matches environment
- [ ] Verify Jamf binary path matches environment
- [ ] Test interactive mode with single item
- [ ] Test silent mode with CSV input
- [ ] Test mixed selection (Installomator + Jamf)
- [ ] Verify validation paths are correct
- [ ] Test failure handling (invalid label/trigger)
- [ ] Test skip logic (pre-installed items)
- [ ] Verify restart prompt behavior

### Functional Tests
1. **Interactive single item:** Select one Installomator label → verify install
2. **Interactive multiple:** Select 2+ items → verify sequential execution
3. **Silent mode:** Run with CSV → verify no dialogs, auto-execute
4. **Mixed execution:** Select both types → verify both execute correctly
5. **Skip logic:** Select already-installed item → verify skip
6. **Failure handling:** Select invalid item → verify error capture
7. **Completion dialog:** Verify success/failure counts accurate
8. **Restart prompt:** Test both "Restart Now" and "Later" buttons

---

## Next Steps

1. **Configure items** — Edit arrays with your organization's apps and policies
2. **Update paths** — Verify Installomator and Jamf paths match your environment
3. **Icon URLs** — Replace example URLs with your organization's icon URLs
4. **Test in VM** — Run through test checklist in non-production environment
5. **Deploy to Self Service** — Add as Jamf Self Service policy with appropriate scope
6. **Monitor logs** — Review `/var/log/org.churchofjesuschrist.log` for operational insights

---

## Support

> Community-supplied, best-effort support is available on the [Mac Admins Slack](https://www.macadmins.org/) (free, registration required) [#setup-your-mac](https://slack.com/app_redirect?channel=C04FRRN3281) channel, or you can open an [issue](https://github.com/setup-your-mac/SYM-Lite/issues).

### Troubleshooting:
- Review script logs: `/var/log/org.churchofjesuschrist.log`
- Check syntax: `zsh -n /path/to/SYM-Lite.zsh`
- Validate swiftDialog: `/usr/local/bin/dialog --version`
- Test Installomator: `sudo /path/to/Installomator.sh <label> DEBUG=1`
- Test Jamf trigger: `sudo jamf policy -event <trigger> -verbose`

---

**Version:** 1.0.0b1  
**Date:** 28-Mar-2026  
**Author:** Dan K. Snelson (@dan-snelson)
