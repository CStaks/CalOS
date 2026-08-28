# CalOS — Repo Index

> **Purpose of this folder:** durable, self-contained documentation of the entire
> repository so future sessions can orient instantly without re-reading every file.
> The `INDEX.md` is the entry point; detail docs live alongside it.

## Project at a Glance

- **What it is:** CalOS — a custom Fedora Atomic (bootc) desktop operating system
  image layered on top of a Fedora Atomic base image.
- **How it's distributed:** OCI container images pushed to GHCR
  (`ghcr.io/callenflynn/calos:latest`, `:latest-arm64`, `:latest-nvidia`),
  consumed via `sudo bootc switch ghcr.io/callenflynn/calos:latest`.
- **Architectures:** x86_64 (default) and ARM64. The ARM64 variant builds on
  the Bluefin LTS arm64 tag (`bluefin:lts-testing-arm64`) because Bluefin's
  `stable` tag is x86_64 only; the NVIDIA variant is x86_64 only (no arm64
  NVIDIA base exists from ublue-os). **The arm64 base is CentOS Stream 10**
  (Bluefin publishes no Fedora-based ARM64 image), so `build.sh` is
  distro-aware (dnf4 + EPEL 10, direct binaries for zoxide/lazygit, no
  Ghostty on arm64).
- **How it's built:** a single `Containerfile` + `build_files/build.sh`, driven by
  `Justfile` recipes, built daily in CI (on `ubuntu-24.04` for amd64 and
  `ubuntu-24.04-arm` for arm64) and signed with Cosign.
- **Disk images:** qcow2 + vmdk (VM) and anaconda-iso (installer) built daily
  for both archs via bootc-image-builder and published to SourceForge
  (https://sourceforge.net/projects/calos-linux/). Files are named
  `calos-<version>_<arch>[<variant>].<ext>` (e.g. `calos-v1.1.4_x86_64.qcow2`,
  `calos-v1.1.4_arm64.iso`, `calos-v1.1.4_x86_64-nvidia.iso`; `latest` on the
  rolling channel).
- **License:** Apache-2.0.
- **Repo size:** 54 tracked files (mostly text config + branding assets).

## The Build Chain (one paragraph)

GitHub Actions (`build.yml`) builds a matrix of three image combos —
**standard/amd64** (base `ghcr.io/ublue-os/bluefin:stable`), **standard/arm64**
(base `ghcr.io/ublue-os/bluefin:lts-testing-arm64`) and **nvidia/amd64** (base
`ghcr.io/ublue-os/bluefin-nvidia-open:stable`) — by passing `BASE_IMAGE` as a
build arg, on `ubuntu-24.04` (amd64) and `ubuntu-24.04-arm` (arm64) runners.
`Containerfile` stages `build_files/` + `system_files/` into a `ctx`
stage, then runs `build.sh` inside the base image. `build.sh` removes inherited
vendor branding + VSCode/Firefox/GNOME Terminal, installs CalOS's app set (Zed,
Brave, Ghostty, Neovim+LazyVim, starship), and overlays `system_files/` onto
`/` (the CalOS brand layer: os-release, GRUB, Plymouth, GDM, wallpapers, dock,
shell prompt). Images are rechunked with rpm-ostree for smaller deltas, tagged
(`latest`, `latest-arm64`, `latest-nvidia`), pushed to GHCR, and signed. A
second workflow (`build-disk.yml`) turns the container images into qcow2/ISO
artifacts with bootc-image-builder for both archs. On a `v*` tag push,
`build-disk.yml` first builds versioned container images
(`ghcr.io/<owner>/calos:v1.2.0[-arm64][-nvidia]`) with the release codename
(from `build_files/codenames.sh`) stamped into os-release, then builds the disk
images from those same versioned images — so both bootc users and ISO/VM
releases get e.g. "CalOS Superior".

## Directory Map

```
.
├── Containerfile                  # Multi-stage build; ctx stage + base image + lint
├── Justfile                       # All local dev recipes (build, rechunk, VM, lint)
├── README.md                      # User-facing docs: variants, install, what's included
├── CONTRIBUTING.md                # Contributor guide (fork, PR process, style)
├── SECURITY.md                    # Supported versions + advisory reporting
├── LICENSE                        # Apache-2.0
├── cosign.pub                     # Public key for verifying signed images
├── image-template.env             # Build config consumed by Justfile (dotenv)
├── .gitignore                     # cosign.key, _build_*, output, *_chunkah_*
├── .hadolint.yaml                 # Hadolint: only DL3006 ignored (ARG BASE_IMAGE)
│
├── .github/
│   ├── dependabot.yml             # Weekly github-actions updates
│   ├── renovate.json5             # Renovate best-practices; automerge pins
│   └── workflows/
│       ├── build.yml              # Main CI: build/push/sign standard (amd64+arm64) + nvidia (amd64) daily
│       ├── build-disk.yml         # qcow2/iso/vmdk (amd64+arm64) via bootc-image-builder → SourceForge (+ GitHub Release on v* tags)
│       ├── codeql.yml             # CodeQL on actions language
│       ├── hadolint.yml           # Containerfile lint
│       ├── renovate-automerge.yml # Renovate auto-merge (waits on Hadolint)
│       └── notify-discord.yml     # Shared Discord notifications
│
├── build_files/
│   ├── build.sh                   # THE install/branding script (runs in image build; stamps release codename when CALOS_VERSION/CODENAME args set)
│   └── codenames.sh               # minor version → release codename map (1=Huron, 2=Superior, 3=Eerie)
│
├── disk_config/
│   ├── disk.toml                  # qcow2/raw: / min 20 GiB
│   ├── iso-gnome.toml             # Minimal anaconda installer (GNOME)
│   └── iso-kde.toml               # Full anaconda installer (KDE, unused by CI)
│
├── CalOS/                         # Branding assets (logos, social image, ascii art)
│   ├── CalOS.png / CalOS.svg      # Primary logo (also 71aab9 & 7a899c colorways)
│   ├── calos-github-social.png    # README hero image
│   ├── ascii-art.txt              # CalOS ASCII logo (used by fastfetch/neofetch)
│   └── wallpapers/                # 4 wallpapers (mountains, night-iceberg, fuji, macOS)
│
└── system_files/                  # Overlay copied to / during build (brand layer)
    ├── etc/
    │   ├── default/grub           # GRUB: CalOS distributor + #FF3B00 highlight
    │   └── skel/.config/
    │       ├── fastfetch/config.jsonc   # fastfetch → calos-logo.txt
    │       ├── neofetch/config.conf     # neofetch → same ASCII art
    │       └── starship.toml            # CalOS-themed prompt (brand colors)
    └── usr/
        ├── lib/os-release         # CalOS identity (VERSION_ID restored from base at build)
        ├── share/
        │   ├── backgrounds/calos/       # Wallpaper copies installed to system
        │   ├── fastfetch/               # calos-logo.txt + presets/calos.jsonc
        │   ├── glib-2.0/schemas/zz_calos.gschema.override  # dock, wallpaper, logo, terminal (sorts after Bluefin's zz1-* so CalOS wins)
        │   ├── pixmaps/                 # Logo copies (GDM login logo)
        │   └── plymouth/themes/calos/   # Boot splash (dark + #FF3B00 pulsing dots, real script API)
```

## Key Facts & Connections

| Concern | Where it lives |
|---|---|
| What apps get installed / removed | `build_files/build.sh` |
| How the OS is branded | `system_files/` overlay (copied to `/`) |
| Local image build | `just build` (podman) |
| VM/ISO image build | `just build-qcow2` / `build-raw` / `build-iso` (bootc-image-builder) |
| Run a VM | `just run-vm-qcow2` / `spawn-vm` |
| CI container build + push + sign | `.github/workflows/build.yml` |
| CI disk image build + publish (SourceForge; GitHub Release on `v*` tags) | `.github/workflows/build-disk.yml` |
| Build config (image name, org, tags) | `image-template.env` |
| Variant/arch parameterization | `ARG BASE_IMAGE` in `Containerfile` + CI matrix (standard amd64/arm64, nvidia amd64) |

## Brand Quick Reference

- Primary accent `#FF3B00` · background `#050505` · text `#E0E0E0`
- Secondary logo colorways: teal `#71aab9`, slate `#7a899c`
- Brand surface everywhere: os-release, GRUB, Plymouth boot, GDM greeter,
  fastfetch/neofetch ASCII art, starship prompt, wallpapers, dock favorites.

## Gotchas & Inconsistencies (found during indexing)

1. **Owner references:** the build configuration and OS metadata use the real
   repository owner, **callenflynn (Callen Flynn)**. `Notsk` was removed as a
   stale Windows-machine username.
2. **`artifacthub-repo.yml` was removed** (it was 100% template placeholder).
   ArtifactHub metadata still ships as OCI labels from the Justfile build
   recipe; re-add the file only if ArtifactHub indexing is actually set up.
3. **ISO recipes use `disk_config/iso-gnome.toml`.** The KDE config remains
   available as an alternate, but the default local ISO path now matches CI.
4. **`iso-kde.toml` is unused by CI** — `build-disk.yml` only ever passes
   `iso-gnome.toml` for `anaconda-iso`.
5. **`renovate-automerge.yml` now waits on `Hadolint`** (a real PR workflow)
   — the previous "PR Validation — testsuite" name from the ublue template
   never existed here, so automerge never fired.
6. **`build.yml` concurrency group no longer references undeclared inputs**
   (`inputs.brand_name`/`inputs.stream_name` were template leftovers).
7. **`os-release` no longer pins a stale `VERSION_ID`** — `build.sh` captures
   the base image's `VERSION_ID` before overlaying `system_files/` and
   restores it after, so the committed file is a placeholder that never goes
   stale. Rolling builds keep the generic `VERSION`/`PRETTY_NAME`; versioned
   tag builds stamp codename values.
8. **`cosign.pub` is committed but `cosign.key` is gitignored** — signing key must
   live in the `SIGNING_SECRET` repo secret; public key in repo for verification.
9. **Starship only initializes for bash** (`/etc/profile.d/calos.sh`) — no zsh
   init despite README mention of bash *and* zsh.
10. **LazyVim is cloned at build time from `main`** (unpinned) into `/etc/skel`,
    so every new user gets the starter config; first launch installs plugins.
11. **ARM64 tracks the Bluefin LTS arm64 tag** (`bluefin:lts-testing-arm64`)
    and is published as `:latest-arm64` / `:vX.Y.Z-arm64` — it is NOT merged
    into the `:latest` tag because the amd64 and arm64 bases differ: **arm64
    is CentOS Stream 10** (Bluefin ships no Fedora-based ARM64 image), x86_64
    is Fedora. `build.sh` handles both: dnf4 + EPEL 10 on CS10, Ghostty
    skipped on arm64 (no package/binary — the ghostty dconf/gsettings
    defaults are stripped), zoxide/lazygit installed from official GitHub
    binaries, and os-release `ID`/`ID_LIKE`/`VERSION_ID` restored from the
    base so bootc-image-builder accepts the image. NVIDIA has no arm64 build
    (no ublue arm64 NVIDIA base).
12. **No custom end-user Justfile is shipped.** Updates use Universal Blue's
    `ujust update` (inherited from Bluefin — updates system image, flatpaks,
    and containers). `build.sh` only ensures the `just` binary is present
    (ujust needs it) and writes `/etc/profile.d/calos.sh` with the
    `calos-update` / `calos-rollback` / `calos-version` /
    `calos-switch-latest` aliases (sourced from `/etc/bashrc` + `/etc/zshrc`
    too). The repo-root `Justfile` is the *developer* task file and is not
    shipped to users.
    > **History:** an earlier build.sh shipped a custom end-user Justfile to
    > `/usr/share/calos/Justfile` + `/etc/just/` with a `just` shell-function
    > fallback so `just update` worked anywhere — removed as redundant once
    > Bluefin's `ujust` was confirmed to provide `ujust update` (it also had a
    > typo'd heredoc delimiter `CALOSPROFEOF` vs `CALOSPROFILEEOF` that
    > swallowed the rest of the script — fixed).
13. **Starship + Zed downloads in `build.sh` are arch-aware** (x86_64 vs
    aarch64 tarballs) so the ARM64 build works; `atim/lazygit` and
    `scottames/ghostty` COPRs both publish aarch64 builds (verified).

## Detail Docs

- [`BUILD_PIPELINE.md`](BUILD_PIPELINE.md) — Containerfile, build.sh, Justfile
  recipes, image-template.env, local dev loop.
- [`BRANDING_SYSTEM.md`](BRANDING_SYSTEM.md) — system_files overlay file-by-file,
  theme tokens, GSettings overrides, Plymouth, shell prompt.
- [`CI_WORKFLOWS.md`](CI_WORKFLOWS.md) — build.yml, build-disk.yml, CodeQL,
  Hadolint, Dependabot, Renovate, signing.
