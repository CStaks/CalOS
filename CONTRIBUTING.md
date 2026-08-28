# Contributing to CalOS

Thank you for your interest in contributing to CalOS. This document outlines the standard process for submitting changes.

## Code of Conduct
Please be respectful and constructive. Harassment or bad-faith behavior will not be tolerated. See our full [Code of Conduct](CODE_OF_CONDUCT.md) for details.

## Development Setup

**Dependencies:**
*   **Podman** (or Docker)
*   **[just](https://github.com/casey/just)** (Task runner)
*   **[ShellCheck](https://www.shellcheck.net/)** (Linting)

**Helpful Commands:**
*   **Build image:** `just build` (Standard) or `just build calos latest "BASE_IMAGE=..."` (Variant)
*   **Format & Lint:** `just format` and `just lint`
*   **Test in VM:** `just rebuild-qcow2` or `just spawn-vm` (Fedora 40+)

## Repository Structure

| Area | Location | Notes |
|------|-------|-------|
| **Packages** | `build_files/build.sh` | Add/remove packages or change install logic. |
| **Branding / Config** | `system_files/` | Settings, wallpapers, themes, fastfetch config. |
| **Container Image** | `Containerfile` | Base image, build stages. Avoid `RUN` if possible. |
| **Disk Images** | `disk_config/` | BIB configuration for ISOs and VM disks. |
| **Release Names** | `build_files/codenames.sh` | Map minor versions to release codenames. |

## Pull Request Workflow

1. **Fork and Branch:** Create a feature branch off of `main`. Keep your PR focused on a single logical change.
2. **Follow Guidelines:**
    *   **Shell:** Use `set -euo pipefail`, quote variable expansions (`"$VAR"`), and use `[[ ]]` for conditionals. 
    *   **Packages:** Wrap non-critical package installs with `--skip-unavailable`.
    *   **GSettings:** Use numeric prefixes on keyfiles (e.g., `01-calos`).
3. **Test:** Run `just lint` and test your build locally in a VM before submitting. Ensure branding and defaults load properly.
4. **Commit:** Write clear commit messages in the imperative mood (e.g., "Add Ghostty as default terminal"). Limit subject lines to 72 characters.
5. **Submit:** Open a PR against `main`. Ensure all CI checks (Hadolint, CodeQL, Build, Just check) pass. 

## Issues and Feature Requests

*   **Bugs:** Open an issue containing your hardware details, CalOS version (`cat /etc/os-release`), and exact steps to reproduce.
*   **Features:** For large changes, please open a discussion issue outlining the problem and proposed solution before writing code.
*   **Security:** Do not open public issues for vulnerabilities. Please refer to [SECURITY.md](SECURITY.md).

## License
By contributing to CalOS, you agree that your contributions will be licensed under the [Apache License 2.0](LICENSE).
