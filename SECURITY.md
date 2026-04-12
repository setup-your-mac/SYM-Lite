# Security Policy

Thank you for helping keep **SYM-Lite** secure.

This project is a **macOS-only, root-run** workflow that can execute Installomator labels, Jamf Pro policy triggers, and approved Homebrew installs through a unified swiftDialog experience. Because it runs with elevated privileges and can change managed device state, security issues in this repo matter.

## Supported Versions

Only the **latest release** is actively supported for security updates.

- Current stable/beta reference: [v1.0.0b7](https://github.com/Setup-Your-Mac/SYM-Lite/releases) (and newer)
- Older releases receive no security patches

Use the newest release whenever possible, especially in Jamf Pro or other MDM-managed deployments.

## Reporting A Vulnerability

If you discover a security vulnerability in this project, report it **responsibly** and **privately**.

**Do not** open a public GitHub Issue or Pull Request that discloses the vulnerability.

### How To Report

Send an email to **security@snelson.us**

Include as much of the following as possible:

- Description of the vulnerability and its potential impact
- Exact steps to reproduce the issue
- Affected SYM-Lite version and macOS version
- Whether the run used `interactive` or `silent` mode
- Selected item IDs and any Jamf Parameter 4 / Parameter 5 values involved
- Whether the issue touches `swiftDialog`, `Installomator`, `Jamf`, or `Homebrew`
- Any suggested mitigation or fix
- Your name or handle, if you want credit

You should receive an acknowledgment within **48 hours**. We will work with you to reproduce the issue, prepare a fix, and coordinate disclosure once remediation is ready.

## Security Best Practices When Using SYM-Lite

- Test changes in a lab or VM before broad deployment
- Run the script only from trusted sources and within controlled management workflows
- Keep configured item lists intentionally scoped to approved software and actions
- In `silent` mode, double-check Parameter 5 or direct CSV input because there is no selection UI confirmation
- Validate the paths and ownership of downstream dependencies such as `organizationInstallomatorFile`, `jamfBinary`, and `brewPath`
- Prefer official or organization-controlled sources for `swiftDialog`, Installomator, Jamf content, Homebrew packages, and remote icons
- Scope Jamf policies carefully and communicate clearly with end users when installs or restarts may be disruptive
- Review `/var/log/org.churchofjesuschrist.log` and related downstream logs when investigating unexpected behavior

## Code Security Practices

- This repository is scanned with **Semgrep** using the `p/r2c-security-audit`, `p/ci`, and `p/secrets` rulesets
- **Gitleaks** is used to detect potential secrets in repository history and pull requests
- Tracked `*.zsh` files are syntax-checked with `zsh -n`
- Tracked `*.sh` and `*.bash` files are linted with **ShellCheck** when present
- Findings are surfaced through GitHub Actions summaries and GitHub code scanning where supported
- Contributions are reviewed for security impact before merging

## Disclosure Policy

- We follow **coordinated disclosure**
- Security fixes will be released as quickly as practical, typically with a tagged release and changelog entry
- We will credit the reporter unless anonymity is requested

## Questions Or General Security Concerns?

For non-vulnerability questions, open a regular GitHub Issue or Discussion.

Last updated: April 2026
