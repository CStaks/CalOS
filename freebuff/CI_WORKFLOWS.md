# CI / CD & Quality Gates

Automation lives in `.github/`. CalOS has container-image, disk-image, website,
security, lint, dependency, and notification workflows.

## Build and release workflows

### `build.yml`

Builds three native container variants:

| Variant | Runner | Base | Published suffix |
|---|---|---|---|
| standard x86_64 | `ubuntu-24.04` | `bluefin:stable` | none |
| standard ARM64 | `ubuntu-24.04-arm` | `bluefin:lts-testing-arm64` (CentOS Stream 10) | `-arm64` |
| NVIDIA x86_64 | `ubuntu-24.04` | `bluefin-nvidia-open:stable` | `-nvidia` |

The workflow checks the Justfile, builds with `BASE_IMAGE`, rechunks with Chunkah,
creates aliases, pushes to GHCR only on the default branch, and signs the image
with Cosign. Pull requests build and validate without publishing.

### `build-disk.yml`

Builds QCOW2, Anaconda ISO, and standard VMDK artifacts with
`osbuild/bootc-image-builder-action`. ARM64 runs on the ARM64 runner and NVIDIA
is excluded from ARM64 because no compatible base image exists.

Release files are named `calos-<version>_<arch>[<variant>].<ext>` and published
to SourceForge. Tag builds also create/update the matching GitHub Release.

## Quality and dependency automation

| File | Purpose |
|---|---|
| `hadolint.yml` | Lints `Containerfile` with Hadolint |
| `codeql.yml` | CodeQL scans JavaScript, Python (`scripts/build-wiki.py`), and GitHub Actions |
| `../.coderabbit.yaml` | AI-assisted PR review guidance for shell, workflows, containers, and website code |
| `dependabot.yml` | Weekly GitHub Actions dependency updates |
| `renovate.json5` | Renovate configuration for pinned actions and dependencies |
| `renovate-automerge.yml` | Shared Renovate automerge workflow |
| `label.yml` | Applies labels based on changed paths |
| `deploy.yml` | Deploys the static `docs/` site to GitHub Pages |
| `notify-discord.yml` | Reusable Discord notification workflow |

CodeQL intentionally has no `autobuild`: CalOS is not a compiled application,
and JavaScript/Python/Actions are analyzed directly.

## Agent notes

- Read `freebuff/INDEX.md` first.
- Keep base-image references to Bluefin in build matrices; they are inputs, not
  CalOS branding shown by the final image metadata.
- Keep secrets in GitHub settings only (`SIGNING_SECRET`, SourceForge key, and
  notification credentials); never commit them.
- Validate YAML and embedded shell after workflow edits.
