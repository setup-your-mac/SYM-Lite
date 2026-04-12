---
name: Bug Report
about: Submit a bug report for SYM-Lite
title: 'Bug Report: [Short description here]'
labels: bug
assignees: ''

---

> Before submitting a bug report, please reproduce the issue against the latest `main` branch version of `SYM-Lite.zsh` using the snippet below (unless directed otherwise by a project maintainer). If the issue cannot be reproduced against the latest `main` branch version, please update the "SYM-Lite version from `main`" field in the Environment section below to reflect the version you tested against.:
> 
> `timestamp=$( date '+%Y-%m-%d-%H%M%S' ) ; curl -L -o ~/Downloads/SYM-Lite-$timestamp.zsh https://raw.githubusercontent.com/setup-your-mac/SYM-Lite/main/SYM-Lite.zsh ; sudo zsh ~/Downloads/SYM-Lite-$timestamp.zsh`
> 
> If the issue appears to be in a dependency rather than SYM-Lite itself, please also review:
>
> - [open swiftDialog issues](https://github.com/swiftDialog/swiftDialog/issues)
> - [open Installomator issues](https://github.com/Installomator/Installomator/issues)

---

**Describe the bug**
A clear, concise description of the bug.

**To Reproduce**
- Please describe how the script was executed (for example: Terminal, Jamf Pro policy, or Self Service).
- Please specify whether the run was `interactive` or `silent`.
- Please include the selected item IDs or the `operationsCSV` value used.
- Please detail any modifications you made to `SYM-Lite.zsh`.
 
**Expected behavior**
A clear, concise description of what you expected to happen.

**Code/log output**
Please supply the full command used, and if applicable, add full output from Terminal. Either upload the log, or paste the output in a code block (triple backticks at the start and end of the code block, please!).

**Screenshots**
If applicable, add screenshots to help explain your problem.

**Environment (please complete the following information):**
- macOS version (for example: `26.4.1`)
- SYM-Lite version from `main` (for example: `1.0.0`) - please test the latest `main` branch version before filing (unless directed otherwise by a project maintainer).
- swiftDialog version
- Installomator version, if relevant
- Jamf Pro binary version, if relevant

**Additional context**
Add any other context about the problem here.
