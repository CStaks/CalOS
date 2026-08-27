# CI / CD & Quality Gates

All automation lives in `.github/`. Two build workflows produce the container
images and the disk images; the rest are quality/lint bots.

## `.github/workflows/build.yml` — container image build, push, sign

Triggers: PR to `main` · daily cron `05 10 * * *` · push to `main`
(ignoring `**/README.md`) · `workflow_dispatch`.

**Matrix** (fail-fast off):

| Variant | Suffix | Base image |
|---|---|---|
| standard | *(none)* | `ghcr.io/ublue-os/bluefin:stable` |
| nvidia | `-nvidia` | `ghcr.io/ublue-os/bluefin-nvidia-open:stable` |

Flow: checkout → free up space (runner cleanup action) → `just
check` → resolve image name/tag → **`just build` with `BASE_IMAGE` build-arg** →
**`just ostree-rechunk`** (smaller delta updates) → generate alias tags
(`latest`, `latest-YYYYMMDD`, `latest-SHA`, `latest-DATE-SHA`) → `just
tag-images` → login GHCR + push each alias (**only on default branch, never on
PR**) → **Cosign sign** the pushed digest with `SIGNING_SECRET` repo secret
(skip on PR; pinned cosign v3.1.2; `--new-bundle-format=false` for rpm-ostree
compat).

Push/sign are guarded by:
`github.event_name != 'pull_request' && github.ref == refs/heads/<default>` —
PR builds validate but never publish.

**Gotcha:** the `concurrency` group references `inputs.brand_name` /
`inputs.stream_name` which aren't declared inputs (harmless template leftover).

## `.github/workflows/build-disk.yml` — qcow2 + anaconda-iso + release

Triggers: on completion of `Build container image` on `main` · daily cron
`15 11 * * *` (after the image build) · push of a `v*` tag (versioned
release, e.g. `v1.2.0`) · PR touching `disk_config/*` or the workflow itself ·
`workflow_dispatch` with `create-release` (bool) and `platform`
(amd64/arm64, arm64 → `ubuntu-24.04-arm` runners).

**Matrix:** variant (standard / nvidia) × disk-type (`qcow2` / `anaconda-iso`,
plus `vmdk` for the standard variant only — VMware).

**Versioned container images job** (`build-versioned-images`, **tag runs
only**): before the disk matrix, builds both CalOS variants with the release
version + codename stamped into `os-release` and pushes them to GHCR as
`ghcr.io/<owner>/calos:v1.2.0` / `:v1.2.0-nvidia`. The minor version →
codename map lives in `build_files/codenames.sh` (1→Huron, 2→Superior,
3→Eerie…); an unmapped minor fails the run with a clear error. The stamping
is done by `build.sh` (build args `CALOS_VERSION` / `CALOS_CODENAME` declared
in the Containerfile), overriding only `VERSION` and `PRETTY_NAME` —
`VERSION_ID` stays Fedora's so bootc-image-builder keeps accepting it. This
is what `bootc switch ghcr.io/callenflynn/calos:v1.2.0` users get.

Flow: prepare env → checkout → **`osbuild/bootc-image-builder-action`** with:
- `config-file`: `disk_config/iso-gnome.toml` for `anaconda-iso`, else
  `disk_config/disk.toml`
- `image`: `ghcr.io/<owner>/calos:latest` / `:latest-nvidia` on rolling runs,
  or `ghcr.io/<owner>/calos:v1.2.0` / `:v1.2.0-nvidia` on tag runs (the image
  pushed by the `build-versioned-images` job, gated via `needs`)
- `types`: the matrix disk type, `--use-librepo=True --rootfs btrfs`

→ delete the action's manifest `*.json` files from output (recent fix) → upload
artifacts (`disk-images-<variant>-<type>`, no retention limit).

**Release job** (skipped on PR; gated on `create-release` for manual runs):
downloads all `disk-images-*` artifacts, copies real disk files into `dist/`
prefixed with variant (e.g. `standard-disk.qcow2`, `nvidia-install.iso`),
**skips `*.json`**, and writes a short `README.txt` (shown on the files page)
explaining what each of the five images is. Uploads via rsync to the
SourceForge project FRS dir (`/home/frs/project/calos-linux/` as user
`callenflynn`, key from the `SOURCEFORGE_SSH_KEY` repo secret). No checksum
file is uploaded — SourceForge's files page generates MD5/SHA1/SHA256
checksums per file. GitHub's 2 GiB per-asset release limit was the original
blocker; SourceForge FRS accepts files up to 10 GiB, so the multi-GB images
upload whole — no splitting needed.

**Two publish modes, one job:**

- **Tag run (`vX.Y.Z`)** → versioned release. After verifying all five
  expected images exist in `dist/`, they are rsynced to a per-version
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
| `.github/workflows/renovate-automerge.yml` | Delegates automerge to the shared `projectbluefin/actions` reusable workflow — but only after a workflow named `PR Validation — testsuite` succeeds, **which doesn't exist here** (stale template) → job never fires |
| `.hadolint.yaml` | Only ignores `DL3006` (tagless `ARG BASE_IMAGE`, justified in-file) |

## Signing & verification

- **Private key:** repo secret `SIGNING_SECRET` (cosign key), consumed only in
  `build.yml`'s sign step. `cosign.key` is gitignored.
- **Public key:** `cosign.pub` committed for users to verify images:
  `cosign verify --key cosign.pub ghcr.io/callenflynn/calos@<digest>`.
- Uses old-format bundles for rpm-ostree compatibility
  (`--new-bundle-format=false`).

## Release cadence (summary)

Every day at ~10:05 UTC the container images rebuild (both variants), get pushed
and signed; at ~11:15 UTC disk images are built from the fresh images and
published to the SourceForge project files
(https://sourceforge.net/projects/calos-linux/). Nothing about this is manually
operated in normal operation.
