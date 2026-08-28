# CalOS — Repo Index

> Durable orientation guide for agents working on CalOS. Start here, then read
> the detail document matching the task.

## Project at a Glance

- **What it is:** CalOS, a custom immutable Fedora/bootc desktop OS layered on Universal Blue/Bluefin.
- **Distribution:** OCI images at `ghcr.io/callenflynn/calos`, plus ISO, QCOW2, and VMDK artifacts on SourceForge.
- **Architectures:** x86_64 and ARM64. ARM64 uses Bluefin's CentOS Stream 10 base; NVIDIA is x86_64-only.
- **Build:** `Containerfile` + `build_files/build.sh`, driven locally by the developer `Justfile` and in GitHub Actions.
- **Website/wiki:** static GitHub Pages site under `docs/`; `scripts/build-wiki.py` generates wiki pages from `docs/wiki-src/`.
- **Quality automation:** Hadolint, CodeQL for JavaScript/Python/Actions, Dependabot, Renovate, and CodeRabbit configuration.
- **Branding:** CalOS logos, boot splash, GDM, GRUB, desktop defaults, fastfetch/neofetch, prompts, wallpapers, and OS metadata live in `CalOS/` and `system_files/`.

## Directory Map

```
.
├── Containerfile                  # Multi-stage bootc image build
├── Justfile                       # Maintainer-only local recipes
├── image-template.env             # Local build variables
├── build_files/
│   ├── build.sh                   # Package installation and OS branding
│   └── codenames.sh               # Release codename map
├── scripts/build-wiki.py          # Wiki generator; CodeQL Python target
├── system_files/                  # Files overlaid into the final image
├── CalOS/                         # Source logos, ASCII art, screenshots, wallpapers
├── disk_config/                   # bootc-image-builder configurations
├── docs/                           # GitHub Pages site and wiki output/source
├── freebuff/                      # Agent-facing architecture and workflow docs
├── .github/workflows/              # Build, release, lint, security, and notification workflows
├── .coderabbit.yaml                # CodeRabbit review policy
├── artifacthub-repo.yml            # Artifact Hub repository ownership metadata
└── .hadolint.yaml                 # Containerfile lint exceptions
```

## Key Facts

- User updates use Universal Blue's `ujust update`; no end-user Justfile is shipped.
- The repository-root `Justfile` is for maintainers and includes build, Chunkah rechunk, disk-image, VM, and lint recipes.
- CI builds native images on `ubuntu-24.04` and `ubuntu-24.04-arm`; it does not use QEMU emulation.
- Artifact names follow `calos-<version>_<arch>[<variant>].<ext>`.
- CalOS OCI labels are authored in `Containerfile` and the Justfile; base-image references to Bluefin are expected because Bluefin remains the build base, not the product identity.
- Release and deployment secrets are managed in GitHub repository settings; never commit secrets.

## Detail Docs

- [`BUILD_PIPELINE.md`](BUILD_PIPELINE.md) — image build, packages, architecture handling, Just recipes, and disk artifacts.
- [`BRANDING_SYSTEM.md`](BRANDING_SYSTEM.md) — CalOS brand layer and inherited-base overrides.
- [`CI_WORKFLOWS.md`](CI_WORKFLOWS.md) — workflow triggers, matrices, quality gates, releases, and security automation.
