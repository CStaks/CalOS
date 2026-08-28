# CI / CD & Quality Gates

All automation lives in `.github/`. Two build workflows produce the container
images and the disk images; the rest are quality/lint bots.

## `.github/workflows/build.yml` — container image build, push, sign

Triggers: PR to `main` · daily cron `05 10 * * *` · push to `main`
(ignoring `**/README.md`) · `workflow_dispatch`.

**Matrix** (fail-fast off, `include` combos):

| Name | Platform | Runner | Suffix | Base image |
|---|---|---|---|---|
| standard | amd64 | `ubuntu-24.04` | *(none)* | `ghcr.io/ublue-os/bluefin:stable` |
| standard | arm64 | `ubuntu-24.04-arm` | `-arm64` | `ghcr.io/ublue-os/bluefin:lts-testing-arm64` |
| nvidia | amd64 | `ubuntu-24.04` | `-nvidia` | `ghcr.io/ublue-os/bluefin-nvidia-open:stable` |

ARM64 exists for the standard variant only (Bluefin's `stable` tag is x86_64
only; the arm64 tags are LTS testing; no arm64 NVIDIA base exists). Each combo
is built natively on its own runner — no QEMU emulation.

**The arm64 base is CentOS Stream 10**, not Fedora — Bluefin publishes no
Fedora-based ARM64 image. `build.sh` is distro-aware: on CentOS Stream it uses
dnf4 + EPEL 10 (neovim, ripgrep, fd-find, fastfetch, just), installs zoxide and
lazygit from official GitHub binaries, and skips Ghostty (no CentOS Stream
package or official Linux binary) — the ghostty dconf/gsettings defaults are
stripped and the base terminal is kept. os-release `ID`/`ID_LIKE`/`VERSION_ID`
are restored from the base so bootc-image-builder accepts the image.

Flow: checkout → free up space (runner cleanup action, arch-aware)
→ `just check` → resolve image name/tag → **`just build` with `BASE_IMAGE`
build-arg** → **`just ostree-rechunk`** (smaller delta updates) → generate
alias tags (`latest[-arm64]`, `latest[-arm64]-YYYYMMDD`, `latest[-arm64]-SHA`,
`latest[-arm64]-DATE-SHA`) → `just tag-images` → login GHCR + push each alias
(**only on default branch, never on PR**) → **Cosign sign** the pushed digest
with `SIGNING_SECRET` repo secret (skip on PR; pinned cosign v3.1.2;
`--new-bundle-format=false` for rpm-ostree compat).

Push/sign are guarded by:
`github.event_name != 'pull_request' && github.ref == refs/heads/<default>` —
PR builds validate but never publish.

## `.github/workflows/build-disk.yml` — qcow2 + anaconda-iso + release

Triggers: on completion of `Build container image` on `main` · daily cron
`15 11 * * *` (after the image build) · push of a `v*` tag (versioned
release, e.g. `v1.2.0`) · PR touching `disk_config/*` or the workflow itself ·
`workflow_dispatch` with `create-release` (bool). Both architectures always
build — there is no single-platform choice anymore.

**Matrix:** variant (standard / nvidia) × architecture (amd64 / arm64) ×
disk-type (`qcow2` / `anaconda-iso`, plus `vmdk` for the standard variant
only — VMware). NVIDIA is excluded for arm64 (no arm64 NVIDIA container
image) and vmdk. amd64 runs on `ubuntu-24.04`, arm64 on `ubuntu-24.04-arm`.

**Versioned container images job** (`build-versioned-images`, **tag runs
only**): before the disk matrix, builds the three image combos (standard
amd64/arm64 + nvidia amd64) with the release version + codename stamped into
`os-release` and pushes them to GHCR as
`ghcr.io/<owner>/calos:v1.2.0` / `:v1.2.0-arm64` / `:v1.2.0-nvidia`. The minor version →
codename map lives in `build_files/codenames.sh` (1→Huron, 2→Superior,
3→Eerie…); an unmapped minor fails the run with a clear error. The stamping
is done by `build.sh` (build args `CALOS_VERSION` / `CALOS_CODENAME` declared
in the Containerfile), overriding only `VERSION` and `PRETTY_NAME` —
`VERSION_ID` stays Fedora's so bootc-image-builder keeps accepting it. This
is what `bootc switch ghcr.io/callenflynn/calos:v1.2.0` users get.

Flow: prepare env → checkout → **`osbuild/bootc-image-builder-action`** with:
- `config-file`: `disk_config/iso-gnome.toml` for `anaconda-iso`, else
  `disk_config/disk.toml`
- `image`: `ghcr.io/<owner>/calos:latest` / `:latest-arm64` / `:latest-nvidia`
  on rolling runs, or `ghcr.io/<owner>/calos:v1.2.0` / `:v1.2.0-arm64` /
  `:v1.2.0-nvidia` on tag runs (the image pushed by the
  `build-versioned-images` job, gated via `needs`)
- `types`: the matrix disk type, `--use-librepo=True --rootfs btrfs`

→ delete the action's manifest `*.json` files from output (recent fix) → upload
artifacts (`disk-images-<variant>-<arch>-<type>`, no retention limit).

**Release job** (skipped on PR; gated on `create-release` for manual runs):
downloads all `disk-images-*` artifacts, copies real disk files into `dist/`
renamed to `calos-<version>_<arch>[<variant>].<ext>` — e.g.
`calos-v1.1.4_x86_64.qcow2`, `calos-v1.1.4_arm64.iso`,
`calos-v1.1.4_x86_64-nvidia.iso`; `latest` replaces the version on rolling
runs (`calos-latest_x86_64.qcow2`) — **skips `*.json`**, and writes a short
`README.txt` (shown on the files page) explaining what each of the eight
images is. Uploads via rsync to the
SourceForge project FRS dir (`/home/frs/project/calos-linux/` as user
`callenflynn`, key from the `SOURCEFORGE_SSH_KEY` repo secret). No checksum
file is uploaded — SourceForge's files page generates MD5/SHA1/SHA256
checksums per file. GitHub's 2 GiB per-asset release limit was the original
blocker; SourceForge FRS accepts files up to 10 GiB, so the multi-GB images
upload whole — no splitting needed.

**Two publish modes, one job:**

- **Tag run (`vX.Y.Z`)** → versioned release. After verifying all eight
  expected images exist in `dist/` (five x86_64 + three arm64 standard),
  they are rsynced to a per-version
  SourceForge directory (`/1.2.0/`, leading `v` stripped) with
  `--ignore-existing` and `--partial-dir` — versioned files are write-once,
  reruns fill gaps but never overwrite or delete a release's files, and no
  `--delete` is used. Only then is the GitHub Release for that tag
  created (or edited if it already exists) titled `CalOS Linux 1.2.0
  (Superior)` (codename from `build_files/codenames.sh`) with a notes
  section containing direct SourceForge download links for **this** version
  and the matching `bootc switch ghcr.io/callenflynn/calos:v1.2.0` image
  tag, clearly separating Standard (AMD/Intel) from NVIDIA. If any upload
  fails, `set -euo pipefail` fails the job before the release is published.
- **Non-tag run (schedule / dispatch)** → rolling "latest" channel: rsync
  `dist/` (including `README.txt`) to the SourceForge project root, and
  delete the stale `continuous` GitHub release.

## Quality & dependency bots

| File | What it does |
|---|---|
| `.github/workflows/hadolint.yml` | Hadolint on `Containerfile` (push/PR to main) |
| `.github/workflows/codeql.yml` | CodeQL analysis of `actions` language (push/PR + weekly Monday) |
| `.github/dependabot.yml` | Weekly updates for `github-actions` ecosystem |
| `.github/renovate.json5` | Renovate `config:best-practices`; `rebaseWhen: never`; auto-merges pin/pinDigest updates; **disables** digest/pin rules for container deps in workflows |
| `.github/workflows/renovate-automerge.yml` | Delegates automerge to the shared `projectbluefin/actions` reusable workflow after the **Hadolint** PR workflow succeeds (the old `PR Validation — testsuite` name from the ublue template never existed here, so it never fired; the reusable action re-checks all PR checks itself) |
| `.hadolint.yaml` | Only ignores `DL3006` (tagless `ARG BASE_IMAGE`, justified in-file) |

## Signing & verification

- **Private key:** repo secret `SIGNING_SECRET` (cosign key), consumed only in
  `build.yml`'s sign step. `cosign.key` is gitignored.
- **Public key:** `cosign.pub` committed for users to verify images:
  `cosign verify --key cosign.pub ghcr.io/callenflynn/calos@<digest>`.
- Uses old-format bundles for rpm-ostree compatibility
  (`--new-bundle-format=false`).

## Release cadence (summary)

Every day at ~10:05 UTC the container images rebuild (standard amd64+arm64,
nvidia amd64), get pushed and signed; at ~11:15 UTC disk images are built from
the fresh images for both architectures and published to the SourceForge
project files (https://sourceforge.net/projects/calos-linux/). Nothing about
this is manually operated in normal operation.
