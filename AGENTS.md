# AGENTS.md

**Single source of truth for coding agents** (`Codex`, Claude Code, Cursor, Copilot, Aider, etc.).  
Takes precedence over `README.md`, `.github/copilot-instructions.md`, and similar instruction files.

## Orchestration Contract
This file codifies project rules, boundaries, workflows, and repeatable skills. If same correction repeats, formalize it here instead of re-prompting it.

## Project Overview
`SYM-Lite` is macOS-only, root-run zsh workflow for executing approved software and management actions through one swiftDialog-driven experience. Primary artifact: `SYM-Lite.zsh`. Supported operation modes: **interactive** (default) and **silent**. Scope limited to Installomator labels, Jamf policy triggers, and approved Homebrew items.

## Key Commands
- Validate syntax after every Zsh edit: `zsh -n SYM-Lite.zsh`
- Inspect current script version: `rg -n '^scriptVersion=' SYM-Lite.zsh`
- Inspect current item inventories: `rg -n '^(installomatorLabels|jamfPolicyItems|homebrewItems)=\\(' SYM-Lite.zsh`
- Review canonical runtime docs before behavior edits: `sed -n '1,240p' AGENTS.md`

## Agent Workflow
- Confirm this file is loaded before starting session.
- Default user-facing communication mode: `$caveman full`, except for security warnings, irreversible actions, or clear user confusion.
- Treat context like scalpel, not net; provide only files, lines, and examples needed.
- Use surgical edits; reference exact functions, arrays, or config blocks instead of pasting large sections.
- After any edit to `SYM-Lite.zsh`, run `zsh -n` immediately.
- For behavior changes, inspect affected paths end-to-end: pre-flight, selection parsing, execution, completion, restart.
- Keep interactive and silent behavior distinct; do not let GUI-only assumptions leak into silent flow.
- Use codified skills when they fit instead of re-describing workflow.
- Prefer batching related work into one well-scoped change.

## Skills
Invoke relevant skill name during planning.

### Add New Executable Item Skill
1. Start from matching array format in `installomatorLabels`, `jamfPolicyItems`, or `homebrewItems`.
2. Keep item list sorted by display-name intent because UI merges and sorts groups together.
3. Set real `validationPath`; skip logic and Inspect Mode completion depend on it.
4. Validate affected parsing and execution flow in `SYM-Lite.zsh`.
5. Update `README.md` if user-visible configuration or behavior changed.

### Runtime Flow Change Skill
1. Identify all touched functions with `rg`.
2. Make minimal surgical edits only.
3. Run `zsh -n SYM-Lite.zsh` immediately after edit.
4. Re-check pre-flight, selection, execution, and completion branches affected by change.
5. Update docs when runtime assumptions or operator workflow changed.

### Release Prep Skill
1. Keep `scriptVersion`, `CHANGELOG.md`, and released behavior aligned.
2. Update only files explicitly in scope.
3. Re-check syntax and release-facing docs.
4. Keep `SYM-Lite.zsh` `HISTORY` section limited to current in-development version only.

## Boundaries
**Always allowed without asking**
- Read any repository file.
- Run `zsh -n SYM-Lite.zsh`.
- Make small targeted doc or script edits that follow rules below.
- Inspect arrays, functions, and logs referenced in code without executing live install workflows.

**Ask before doing**
- Add new production dependencies.
- Run commands that can install software, trigger Jamf policies, update Homebrew metadata, or otherwise mutate host state outside repo.
- Change default operation mode, parameter semantics, logging contract, or restart behavior.
- Rebuild release notes or prepare release versioning not explicitly requested.

**Never do**
- Hardcode secrets, tokens, org-private endpoints, or credentials.
- Modify files outside current task scope without approval.
- Add arbitrary package workflows beyond Jamf triggers, Installomator labels, or explicitly configured Homebrew packages.
- Break macOS-only or root-run assumptions by accident.

## Source of Truth
When files disagree, prefer:
1. `SYM-Lite.zsh` for implemented behavior, defaults, dependencies, and runtime flow.
2. `AGENTS.md` for agent workflow, boundaries, and validation expectations.
3. `README.md`, `CHANGELOG.md`, and `SECURITY.md` for current operator and release documentation.
4. `.github/copilot-instructions.md` for supplemental agent guidance when consistent with this file.

## Mission and Scope
Mission: give operators one lean swiftDialog workflow to run approved developer setup and management actions on macOS with clear progress, logging, and completion status.

In scope:
- swiftDialog-driven selection and Inspect Mode execution UX
- Installomator label execution
- Jamf policy trigger execution
- approved Homebrew formula and cask execution
- path-based validation, logging, completion reporting, and restart prompts

Out of scope:
- non-macOS support
- non-root execution as primary runtime model
- enrollment, inventory collection strategy, or broad device orchestration
- arbitrary package pipelines outside configured Jamf, Installomator, and Homebrew items

## Implementation Priorities
1. Preserve single-script architecture in `SYM-Lite.zsh`.
2. Keep interactive workflow reliable for logged-in GUI users.
3. Keep silent workflow automation-friendly and non-blocking.
4. Favor safe incremental changes over broad refactors.
5. Keep docs aligned with user-visible behavior and environment assumptions.

## Key Files
- `SYM-Lite.zsh`: single entrypoint; runtime parameters, arrays, pre-flight, selection UI, Inspect Mode, execution engine, completion and restart flow
- `README.md`: operator-facing usage, configuration, and behavior guide
- `CHANGELOG.md`: canonical long-term release history
- `SECURITY.md`: security policy and reporting process
- `.github/workflows/security-scan.yml`: Semgrep, Gitleaks, `zsh -n`, and ShellCheck automation
- `.github/copilot-instructions.md`: secondary agent instructions; do not let it override this file

## Current Runtime Hotspots
- `dialogCheck()` always runs in pre-flight and can auto-install or update swiftDialog from GitHub; blocked network breaks bootstrap.
- Installomator availability is optional for each run; missing or unparsable Installomator filters those labels instead of aborting Jamf or Homebrew execution.
- `validationPath` drives both pre-execution skip logic and Inspect Mode completion detection; wrong path can suppress needed work or hide completion.
- Interactive mode needs active logged-in GUI user and exits after wait window if none appears.
- Homebrew execution runs in logged-in user context even though script itself runs as root.
- Jamf and Homebrew completion remain path-based, not rich progress parsed.

## Repository Rules
- Always run `zsh -n` after modifying Zsh files.
- Do not add new production dependencies without explicit approval.
- Keep durable repo rules near top of this file; avoid timestamps, counters, or ephemeral task notes in stable sections.
- Preserve existing script style unless strong reason exists to refactor.
- Keep `installomatorLabels`, `jamfPolicyItems`, and `homebrewItems` sorted by display-name intent.
- If behavior, configuration semantics, or environment assumptions change, update `README.md` in same pass.
- `CHANGELOG.md` is long-term history for released versions.
- `SYM-Lite.zsh` `HISTORY` section should describe current version under development only.
- Check `git status` before editing shared docs so unrelated local work is not overwritten.

## Scripting Style
Match established `SYM-Lite.zsh` style unless user explicitly asks otherwise.

1. Preserve sectioned structure and hash-wall separators.
2. Keep lowerCamelCase variables and functions.
3. Keep `function name() { ... }` declarations.
4. Prefer braced variable expansion and explicit quoting.
5. Route operational logging through `preFlight`, `logComment`, `notice`, `info`, `warning`, `errorOut`, and `fatal`.
6. Keep helper flow explicit; avoid hiding critical branching inside dense one-liners.
7. Preserve array item formats exactly:
   - Installomator: `"label | Display Name | Validation Path | Icon URL"`
   - Jamf: `"trigger | Display Name | Validation Path | Icon URL"`
   - Homebrew: `"formula:token"` or `"cask:token"` item id with same four-field layout
8. Keep silent-mode parsing tolerant of operator input normalization when touching CSV or item ID logic.
9. Prefer degraded-but-continuable warnings over fatal exits unless workflow truly cannot proceed.
10. Keep user-facing strings concise and operator-friendly.

## Dependency and Platform Expectations
- Platform is macOS only.
- Script is designed to run as `root`.
- Effective minimum OS support is macOS 15 because repo requires swiftDialog 3.x.
- Minimum swiftDialog version is `3.0.1.4955`.
- Default Installomator path: `/Library/Management/AppAutoPatch/Installomator/Installomator.sh`
- Default Jamf binary path: `/usr/local/bin/jamf`
- Homebrew detection prefers `/opt/homebrew/bin/brew`, then `/usr/local/bin/brew`
- Default logging paths: `/var/log/org.churchofjesuschrist.log` and `/var/log/Installomator.log`

## Quality Bar
- Keep pre-flight behavior reliable across missing GUI user, missing swiftDialog, missing Installomator, missing Jamf, and missing Homebrew cases.
- Keep interactive UX valid: selection dialog, Inspect Mode JSON, command file, completion dialog, restart prompt.
- Keep silent mode deterministic: parameter parsing, item lookup, skip logic, and completion reporting must stay clear.
- Logging must remain structured and useful for operators.
- Temporary file creation and cleanup must stay safe and bounded to expected temp locations.

## Required Validation
1. Run `zsh -n` on every modified Zsh script.
2. For script changes, review touched paths for obvious regressions in both `interactive` and `silent` flows.
3. For docs-only changes, review Markdown rendering, terminology, and cross-file consistency.
4. Update `README.md` when behavior, configuration, environment assumptions, or operator workflow changes.
5. Update `CHANGELOG.md` only for released-version history or when task explicitly includes release-note work.
6. Do not add new production dependencies without explicit approval.

## Release Checklist
Apply only for release prep.
1. Keep `scriptVersion`, top `CHANGELOG.md` entry, and shipped behavior aligned.
2. Ensure `README.md` matches current operation modes, dependencies, and item configuration semantics.
3. Confirm `SYM-Lite.zsh` `HISTORY` section reflects current in-development version only.
4. Verify security workflow and docs still reference current repository realities.
5. Remove or clarify stale version references when they would mislead contributors.

## Maintenance
This file is versioned with project. When core style rules, validation requirements, workflow boundaries, or agent expectations change, update `AGENTS.md`. Keep file concise enough for agent attention and specific enough to prevent repeated corrective prompting.
