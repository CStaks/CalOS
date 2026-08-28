# Contributing to CalOS

Thanks for your interest in contributing to CalOS! This document provides guidelines and information for contributors.

## Table of Contents

- [Code of Conduct](#code-of-conduct)
- [Getting Started](#getting-started)
- [Development Setup](#development-setup)
- [Making Changes](#making-changes)
- [Pull Request Process](#pull-request-process)
- [Style Guidelines](#style-guidelines)
- [Testing Your Changes](#testing-your-changes)
- [Reporting Bugs](#reporting-bugs)
- [Suggesting Features](#suggesting-features)
- [License](#license)

---

## Code of Conduct

Please be respectful and constructive in all interactions. We are building a welcoming community around a Linux desktop for everyone. Harassment, discrimination, or bad-faith behavior will not be tolerated.

---

## Getting Started

1. **Fork** the repository on GitHub.
2. **Clone** your fork locally:
   ```bash
   git clone https://github.com/<your-username>/CalOS.git
   cd CalOS
   ```
3. **Add the upstream remote**:
   ```bash
   git remote add upstream https://github.com/callenflynn/CalOS.git
   ```
4. **Create a branch** for your change:
   ```bash
   git checkout -b <branch-name>
   ```

---

## Development Setup

CalOS is a bootable Fedora Atomic image built with a `Containerfile` and shell scripts. To test changes locally you need:

- **Podman** (or Docker with appropriate flags)
- **[just](https://github.com/casey/just)** — task runner (`dnf install just` / `brew install just` / `cargo install just`)
- **[ShellCheck](https://www.shellcheck.net/)** — optional but recommended for linting scripts

### Local build

```bash
# Build the container image (standard variant)
just build

# Build a specific variant
just build calos latest "BASE_IMAGE=ghcr.io/ublue-os/bluefin-nvidia-open:stable"
```

### Lint and format

```bash
# Check shell script syntax
just lint

# Auto-format shell scripts
just format

# Check Justfile syntax
just check
```

### Boot a VM for testing

```bash
# Build a QCOW2 image and run it in a VM
just rebuild-qcow2

# Or use systemd-vmspawn (Fedora 40+)
just spawn-vm
```

---

## Making Changes

### What to change

| Area | Files | Notes |
|------|-------|-------|
| **Packages** | `build_files/build.sh` | Add/remove packages or change install logic |
| **Branding / config** | `system_files/` | Desktop settings, wallpapers, prompt themes, fastfetch config |
| **Container image** | `Containerfile` | Base image, build stages, linting |
| **Disk images** | `disk_config/` | BIB configuration for ISOs and VM disks |
| **CI/CD** | `.github/workflows/` | Build, release, or deploy pipelines |
| **Release names** | `build_files/codenames.sh` | Map minor versions to release codenames |
| **Docs site** | `docs/` | GitHub Pages landing page |
| **Documentation** | `README.md`, `*.md` | User-facing docs |

### Commit messages

Write clear, concise commit messages. Use the imperative mood ("Add feature" not "Added feature"). Keep the subject line under 72 characters. Use a body when the change needs context.

```
Add Ghostty as default terminal

- Replace GNOME Terminal with Ghostty via scottames/ghostty COPR
- Set Ghostty as default terminal in dconf and gschema overrides
- Disable COPR after install to avoid stale repos
```

---

## Pull Request Process

1. **Keep PRs focused.** One logical change per pull request.
2. **Update documentation** if your change affects user-facing behavior.
3. **Open the PR against `main`.**
4. **Describe what changed and why** in the PR description. Include screenshots for visual changes.
5. **CI must pass.** The following checks run automatically:
   - **Hadolint** — Containerfile linting
   - **CodeQL** — GitHub Actions security analysis
   - **Build** — Full container image build (standard x86_64 + ARM64, NVIDIA x86_64)
   - **Just check** — Justfile syntax validation
6. **Respond to review feedback** promptly. Push additional commits to your branch; they will be squashed on merge.

> [!NOTE]
> The maintainer may push commits directly to your PR branch to fix minor issues (typos, formatting) without requiring another review cycle.

---

## Style Guidelines

### Shell scripts

- Use `set -euo pipefail` (or `set -eoux pipefail` when verbose is helpful) at the top of every script.
- Quote all variable expansions: `"$VAR"`, not `$VAR`.
- Use `[[ ]]` for conditionals in Bash scripts.
- Run `just format` before committing to auto-format with [shfmt](https://github.com/mvdan/sh).
- Run `just lint` to catch issues with [ShellCheck](https://www.shellcheck.net/).

### YAML (GitHub Actions)

- Pin third-party actions to a specific commit SHA (Renovate keeps these up to date).
- Keep workflow files under `.github/workflows/`.
- Use concurrency groups to avoid duplicate runs.

### dconf / GSettings

- Use numeric prefixes on keyfile names for ordering (e.g. `01-calos`).
- After adding or modifying schema overrides, run `glib-compile-schemas` to verify.

### Containerfile

- Prefer editing `build_files/build.sh` over adding `RUN` directives to the `Containerfile` directly.
- Wrap package installs with `--skip-unavailable` for non-critical packages.

---

## Testing Your Changes

Before opening a PR, verify your changes work:

1. **Lint your changes:**
   ```bash
   just lint        # ShellCheck on all .sh files
   just check       # Justfile syntax
   ```

2. **Build the image locally:**
   ```bash
   just build localhost/calos
   ```

3. **Boot and inspect:**
   ```bash
   just rebuild-qcow2   # Builds + creates a bootable VM disk
   just run-vm          # Launches the VM (requires KVM)
   ```

4. **Check branding in the VM:**
   - GRUB menu shows "CalOS"
   - Plymouth boot splash shows CalOS theme
   - GDM login screen shows CalOS logo
   - Desktop wallpaper and dock match CalOS defaults
   - `fastfetch` shows CalOS ASCII art

---

## Reporting Bugs

Open an issue at [github.com/callenflynn/CalOS/issues](https://github.com/callenflynn/CalOS/issues) with:

- **A clear title** describing the problem.
- **Steps to reproduce** the issue.
- **Expected vs actual behavior.**
- **Hardware/software details:** GPU model, CPU, install method (bootc / ISO / VM), and CalOS version (`cat /etc/os-release`).

For security vulnerabilities, please use [GitHub Security Advisories](https://github.com/callenflynn/CalOS/security/advisories) instead of public issues. See [SECURITY.md](SECURITY.md) for details.

---

## Suggesting Features

Open a feature request issue and include:

- **The problem** your feature would solve.
- **Your proposed solution**, if you have one.
- **Alternatives** you considered.

Large changes (new packages, major rebranding, new disk image types) benefit from discussion in an issue before implementation.

---

## License

By contributing to CalOS, you agree that your contributions will be licensed under the [Apache License 2.0](LICENSE).

---

## Questions?

If you're unsure about anything, open a discussion issue or reach out — we're happy to help you get started.
