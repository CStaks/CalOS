# CalOS Agent Guide

CalOS is an immutable Linux desktop distribution built as a bootc OCI image on Universal Blue/Bluefin. The repository also contains a static GitHub Pages website and wiki tooling.

## Start here

Read [`freebuff/INDEX.md`](freebuff/INDEX.md) first. It is the durable repository index and links to the detailed operational documentation.

## Repository map

- `Containerfile` — multi-stage bootc/OCI image definition.
- `build_files/build.sh` — package installation, architecture handling, and system branding.
- `build_files/codenames.sh` — release codename mapping.
- `system_files/` — CalOS filesystem overlay: os-release, GRUB, Plymouth, GDM, desktop defaults, logos, wallpapers, and shell configuration.
- `CalOS/` — source logos, screenshots, ASCII art, and wallpapers.
- `Justfile` — maintainer-only local build, disk-image, VM, rechunk, and lint recipes.
- `docs/` — static website and generated wiki content.
- `scripts/build-wiki.py` — Python wiki builder.
- `.github/workflows/` — image builds, disk releases, deployment, linting, CodeQL, dependency automation, and notifications.
- `.coderabbit.yaml` — CodeRabbit pull-request review configuration.
- `artifacthub-repo.yml` — Artifact Hub repository ownership metadata.

## Documentation navigation

- [`freebuff/INDEX.md`](freebuff/INDEX.md) — complete overview and directory map.
- [`freebuff/BUILD_PIPELINE.md`](freebuff/BUILD_PIPELINE.md) — image build flow, packages, architecture differences, Just recipes, and disk artifacts.
- [`freebuff/BRANDING_SYSTEM.md`](freebuff/BRANDING_SYSTEM.md) — every CalOS branding surface and the inherited Bluefin override behavior.
- [`freebuff/CI_WORKFLOWS.md`](freebuff/CI_WORKFLOWS.md) — workflow triggers, build matrices, releases, CodeQL, Hadolint, Renovate, and signing.

## Contribution rules

- **Always open a pull request.** Never commit directly to `main`. Create a feature branch, push it, and open a PR against `main` so CI checks run and changes can be reviewed.
- Follow [CONTRIBUTING.md](CONTRIBUTING.md) for the full PR workflow, coding style (shell, GSettings, packages), testing steps, and commit message conventions.

## Important conventions

- Preserve existing user changes; do not reset or clean the working tree.
- Do not commit secrets. Repository secrets belong in GitHub settings.
- Keep x86_64 and ARM64 behavior explicit: ARM64 uses the Bluefin CentOS Stream 10 base and has no NVIDIA variant.
- User updates use Universal Blue's `ujust update`; the repository `Justfile` is not shipped to end users.
- Validate workflow YAML, shell syntax, and relevant scripts after changes.
- When changing branding, inspect both `system_files/` and the final OCI labels in `Containerfile`/`Justfile`.
