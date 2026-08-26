# CalOS — Repo Index

> **Purpose of this folder:** durable, self-contained documentation of the entire
> repository so future sessions can orient instantly without re-reading every file.
> The `INDEX.md` is the entry point; detail docs live alongside it.

## Project at a Glance

- **What it is:** CalOS — a custom Fedora Atomic (bootc) desktop operating system
  image layered on top of [Bluefin](https://github.com/ublue-os/bluefin)
  (Universal Blue).
- **How it's distributed:** OCI container images pushed to GHCR
  (`ghcr.io/callenflynn/calos` and `:latest-nvidia`), consumed via
  `sudo bootc switch ghcr.io/callenflynn/calos:latest`.
- **How it's built:** a single `Containerfile` + `build_files/build.sh`, driven by
  `Justfile` recipes, built daily in GitHub Actions and signed with Cosign.
- **Disk images:** qcow2 + vmdk (VM) and anaconda-iso (installer) built daily
  via bootc-image-builder and published to SourceForge
  (https://sourceforge.net/projects/calos-linux/).
- **License:** Apache-2.0.
- **Repo size:** 54 tracked files (mostly text config + branding assets).

## The Build Chain (one paragraph)

GitHub Actions (`build.yml`) builds a matrix of two variants — **standard**
(base `ghcr.io/ublue-os/bluefin:stable`) and **nvidia** (base
`ghcr.io/ublue-os/bluefin-nvidia-open:stable`) — by passing `BASE_IMAGE` as a
build arg. `Containerfile` stages `build_files/` + `system_files/` into a `ctx`
stage, then runs `build.sh` inside the base image. `build.sh` uninstalls Bluefin
branding + VSCode/Firefox/GNOME Terminal, installs CalOS's app set (Zed, Brave,
Ghostty, Neovim+LazyVim, starship), and overlays `system_files/` onto `/` (the
CalOS brand layer: os-release, GRUB, Plymouth, GDM, wallpapers, dock, shell
prompt). Images are rechunked with rpm-ostree for smaller deltas, tagged, pushed
to GHCR, and signed. A second workflow (`build-disk.yml`) turns the container
images into qcow2/ISO artifacts with bootc-image-builder. On a `v*` tag push,
`build-disk.yml` first builds versioned container images
(`ghcr.io/<owner>/calos:v1.2.0[-nvidia]`) with the release codename (from
`build_files/codenames.sh`) stamped into os-release, then builds the disk
images from those same versioned images — so both bootc users and ISO/VM
releases get e.g. "CalOS Superior".

## Directory Map

```
.
├── Containerfile                  # Multi-stage build; ctx stage + base image + lint
├── Justfile                       # All local dev recipes (build, rechunk, VM, lint)
├── README.md                      # User-facing docs: variants, install, what's included
├── LICENSE                        # Apache-2.0
├── artifacthub-repo.yml           # ArtifactHub indexing (PLACEHOLDER values)
├── cosign.pub                     # Public key for verifying signed images
├── image-template.env             # Build config consumed by Justfile (dotenv)
├── .gitignore                     # cosign.key, _build_*, output, *_chunkah_*
├── .hadolint.yaml                 # Hadolint: only DL3006 ignored (ARG BASE_IMAGE)
│
├── .github/
│   ├── dependabot.yml             # Weekly github-actions updates
│   ├── renovate.json5             # Renovate best-practices; automerge pins
│   └── workflows/
│       ├── build.yml              # Main CI: build/push/sign both variants daily
│       ├── build-disk.yml         # qcow2/iso/vmdk via bootc-image-builder → SourceForge (+ GitHub Release on v* tags)
│       ├── codeql.yml             # CodeQL on actions language
│       ├── hadolint.yml           # Containerfile lint│   └── renovate-automerge.yml # Shared Renovate auto-merge trigger
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
        ├── lib/os-release         # CalOS identity (VERSION_ID=41, Bluefin)
        ├── share/
        │   ├── backgrounds/calos/       # Wallpaper copies installed to system
        │   ├── fastfetch/               # calos-logo.txt + presets/calos.jsonc
        │   ├── glib-2.0/schemas/90_calos.gschema.override  # dock, wallpaper, logo, terminal
        │   ├── pixmaps/                 # Logo copies (GDM login logo)
        │   └── plymouth/themes/calos/   # Boot splash (dark + #FF3B00 spinner)
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
| Variant parameterization | `ARG BASE_IMAGE` in `Containerfile` + CI matrix |

## Brand Quick Reference

- Primary accent `#FF3B00` · background `#050505` · text `#E0E0E0`
- Secondary logo colorways: teal `#71aab9`, slate `#7a899c`
- Brand surface everywhere: os-release, GRUB, Plymouth boot, GDM greeter,
  fastfetch/neofetch ASCII art, starship prompt, wallpapers, dock favorites.

## Gotchas & Inconsistencies (found during indexing)

1. **Owner references:** the build configuration and OS metadata use the real
   repository owner, **callenflynn (Callen Flynn)**. `Notsk` was removed as a
   stale Windows-machine username.
2. **`artifacthub-repo.yml` is placeholder** (`my-custom-id-here`, "My Name") —
   ArtifactHub indexing is not actually configured.
3. **ISO recipes use `disk_config/iso-gnome.toml`.** The KDE config remains
   available as an alternate, but the default local ISO path now matches CI.
4. **`iso-kde.toml` is unused by CI** — `build-disk.yml` only ever passes
   `iso-gnome.toml` for `anaconda-iso`.
5. **`renovate-automerge.yml` waits on a workflow named "PR Validation —
   testsuite"** that does not exist in this repo (leftover from the ublue
   template), so its automerge job never fires.
6. **`build.yml` concurrency group references `inputs.brand_name` /
   `inputs.stream_name`** which are not declared inputs (harmless, from template).
7. **`os-release` pins `VERSION_ID=41`** even though the base is `bluefin:stable`
   (rolling) — will go stale as Fedora bumps. `build.sh` deliberately removes
   Bluefin's os-release first so this override wins.
8. **`cosign.pub` is committed but `cosign.key` is gitignored** — signing key must
   live in the `SIGNING_SECRET` repo secret; public key in repo for verification.
9. **Starship only initializes for bash** (`/etc/profile.d/calos.sh`) — no zsh
   init despite README mention of bash *and* zsh.
10. **LazyVim is cloned at build time from `main`** (unpinned) into `/etc/skel`,
    so every new user gets the starter config; first launch installs plugins.

## Detail Docs

- [`BUILD_PIPELINE.md`](BUILD_PIPELINE.md) — Containerfile, build.sh, Justfile
  recipes, image-template.env, local dev loop.
- [`BRANDING_SYSTEM.md`](BRANDING_SYSTEM.md) — system_files overlay file-by-file,
  theme tokens, GSettings overrides, Plymouth, shell prompt.
- [`CI_WORKFLOWS.md`](CI_WORKFLOWS.md) — build.yml, build-disk.yml, CodeQL,
  Hadolint, Dependabot, Renovate, signing.
