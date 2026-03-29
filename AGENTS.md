# SYM-Lite — Agent Instructions

> **Author**: Dan K. Snelson | **Version**: 1.0.0b1 | **Language**: zsh (Shell) | **Platform**: macOS only | **License**: MIT

## Big picture
- SYM-Lite is a macOS-only, root-run script that unifies Installomator label execution and Jamf Pro policy triggers behind a single swiftDialog-driven workflow.
- The repo is intentionally small. `SYM-Lite.zsh` contains the runtime logic, UI flow, logging, pre-flight checks, and execution engine. There is no build pipeline or assembled artifact layer in this repo.
- Default behavior is interactive: show a checkbox selection dialog, launch swiftDialog Inspect Mode, execute selected items sequentially, then show completion and optional restart prompts.
- Silent behavior is also supported through Jamf-style parameters: Parameter 4 sets `interactive` or `silent`, and Parameter 5 provides a comma-separated item ID list.
- This project does not manage enrollment, collect device metadata, or orchestrate arbitrary package workflows outside Jamf custom triggers and Installomator labels.

## Core components
1. **`SYM-Lite.zsh`** (CORE) — Single entrypoint and source of truth. Handles logging, pre-flight validation, selection parsing, Inspect Mode JSON generation, Installomator execution, Jamf execution, completion dialogs, and restart flow.
2. **`README.md`** (DOCS) — Operator-facing usage and behavior guide. Keep it aligned with user-visible workflow or configuration changes.
3. **`CHANGELOG.md`** (HISTORY) — Running history of all released versions. This is the canonical long-term change record for the repo.
4. **`.gitignore`** (HYGIENE) — Minimal macOS and zsh ignore rules. Do not expand it casually.

## Runtime model
- The script is designed to run as `root`. Logging, temp file creation, Installomator execution, and Jamf execution assume elevated privileges.
- UI actions require an active logged-in user. `requireLoggedInUser` and `runAsUser` gate interactive dialog launch and restart confirmation.
- Item definitions live in two arrays near the top of `SYM-Lite.zsh`:
  - `installomatorItems`
  - `jamfPolicyItems`
- Each item is defined as:
  - `"identifier | displayName | validationPath | iconURL"`
- `validationPath` is operationally important, not cosmetic. It drives pre-execution skip logic and Inspect Mode completion detection.
- The script processes selected items sequentially. There is no parallel execution layer.

## Dependencies and external contracts
- **swiftDialog** is required for all runs because pre-flight always calls `dialogCheck`, and it is auto-installed or updated if missing/outdated. Minimum required version is `3.0.1.4955`.
- Because this repo requires swiftDialog 3.x, the effective minimum supported OS is **macOS 15**.
- **Installomator** is expected at `/Library/Management/AppAutoPatch/Installomator/Installomator.sh` unless `organizationInstallomatorFile` is changed.
- **Jamf Pro Client** is expected at `/usr/local/bin/jamf` unless `jamfBinary` is changed.
- **Network access** may be required for:
  - swiftDialog bootstrap via GitHub API and GitHub release download
  - remote icon assets used in dialogs
- Inspect Mode configuration is written to a temp JSON file under `/var/tmp`.
- Logging writes to `/var/log/org.churchofjesuschrist.log` by default, and Installomator progress is read from `/var/log/Installomator.log`.

## Logging
- Log format is:
  - `${organizationScriptName} (${scriptVersion}): YYYY-MM-DD HH:MM:SS  [LEVEL] message`
- Active levels include:
  - `[PRE-FLIGHT]`
  - `[NOTICE]`
  - `[INFO]`
  - `[WARNING]`
  - `[ERROR]`
  - `[FATAL ERROR]`
- Installomator and Jamf `stdout` are piped back into the main script log via `logComment`.
- When adding or changing workflow branches, prefer:
  - `NOTICE` for phase transitions and important actions
  - `WARNING` for degraded-but-continuable states
  - `ERROR` or `FATAL ERROR` for failed execution paths

## Editing rules
- Always run `zsh -n` after modifying Zsh files.
- Ask for confirmation before adding new production dependencies.
- Preserve the current style unless there is a strong reason to refactor it:
  - lowerCamelCase variables and function names
  - `function name() {` declarations
  - braced variable expansion as the default style
  - large hash-wall section separators and generous spacing between top-level blocks
- Keep `installomatorItems` and `jamfPolicyItems` sorted by display name intent, because the UI merges and sorts both groups together for presentation.
- If you change user-visible behavior, configuration semantics, or required environment assumptions, update `README.md` in the same pass.
- `CHANGELOG.md` is the running history for all versions. Add each released version there.
- The `HISTORY` section in `SYM-Lite.zsh` should only describe changes for the current version under development, not retain the full historical archive.

## Known risks and technical debt
- `dialogInstall()` depends on GitHub API/release availability and Apple package signing validation. Blocked network access breaks automatic swiftDialog bootstrap.
- Inspect Mode uses the swiftDialog `"preset": "installomator"` log monitor behavior, which is convenient but not something this repo controls.
- Jamf policies do not have rich progress parsing. They are effectively binary from the UI perspective unless validation paths appear.
- Jamf success with a missing `validationPath` is logged as a warning but still treated as completed.
- Skip logic is entirely path-based. A stale file path can suppress needed execution.
- Interactive flows can fail on headless systems or at the login window; silent mode is the safer path when no user session is available.

## Key decisions

| Decision | Rationale |
|----------|-----------|
| Single-script architecture | Keeps deployment simple and avoids a build/assembly step |
| Sequential execution | Easier logging, UI tracking, and failure isolation |
| Unified selection UI for Jamf + Installomator items | Presents one operator-facing workflow instead of two separate tools |
| Path-based validation and skip logic | Simple and observable, even if imperfect |
| Interactive mode owns completion and restart dialogs | Silent mode remains automation-friendly and non-blocking |
| Auto-install/update swiftDialog | Reduces operator setup friction on managed Macs |

## Navigation
- Top of `SYM-Lite.zsh`: metadata, globals, runtime parameters, dependency paths, and item arrays.
- Early helper section: logging, cleanup, logged-in user detection, parsing helpers.
- Middle sections: swiftDialog bootstrap, pre-flight checks, Inspect Mode JSON generation, and selection parsing.
- Late sections: execution functions, interruption handling, completion dialog, restart flow, and main program.
- When debugging behavior, inspect in this order:
  1. Pre-flight logs
  2. Item parsing and selection state
  3. Validation paths
  4. Installomator or Jamf command output relayed into `scriptLog`
  5. Inspect Mode JSON generation and dialog launch conditions
