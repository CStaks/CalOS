# Build Pipeline

How a CalOS image goes from this repo to a bootable OS. See also
[`INDEX.md`](INDEX.md) for the big picture.

## 1. `image-template.env` — build configuration

Dotenv file loaded by the Justfile (`set dotenv-filename`, `set dotenv-load`).
Every `env_var(...)` in the Justfile reads from here.

| Variable | Value | Used for |
|---|---|---|
| `IMAGE_NAME` | `calos` | Image name / tags / labels |
| `REPO_ORGANIZATION` | `callenflynn` | OCI labels + README label URLs |
| `IMAGE_DESC` | `CalOS - A custom Fedora Atomic desktop built on Bluefin` | OCI `description` label |
| `IMAGE_KEYWORDS` | `calos,bluefin,bootc,oci,linux,atomic,gnome` | ArtifactHub keyword label |
| `IMAGE_LOGO_URL` | raw.githubusercontent `.../CalOS.png` | ArtifactHub logo label |
| `DEFAULT_TAG` | `latest` | Default tag used by all recipes |
| `BIB_IMAGE` | `quay.io/centos-bootc/bootc-image-builder:latest` | Container used by the BIB recipes |

## 2. `Containerfile` — multi-stage build

```dockerfile
ARG BASE_IMAGE=ghcr.io/ublue-os/bluefin:stable   # variant switch point (CI passes -nvidia)
FROM scratch AS ctx                               # context only, not shipped
COPY build_files /
COPY system_files /system_files
FROM ${BASE_IMAGE}
ARG CALOS_VERSION=""                              # optional release metadata (tag builds only)
ARG CALOS_CODENAME=""                             # e.g. v1.2.0 -> VERSION="1.2 (Superior)"
RUN rm -rf /opt && mkdir /opt                     # make /opt immutable (package safety)
RUN --mount=type=bind,from=ctx,source=/,target=/ctx \
    --mount=type=cache,dst=/var/cache \
    --mount=type=cache,dst=/var/log \
    --mount=type=tmpfs,dst=/tmp \
    /ctx/build.sh                                 # all real work happens here
RUN bootc container lint                          # verify image validity
```

- The `ctx` stage means `build_files/` and `system_files/` are never baked into
  the final image — only their contents via the bind mount.
- `/opt` is made immutable because bootc images symlink `/opt → /var/opt` and
  packages writing there (chrome, docker-desktop) would be wiped on deploy.
- Hadolint's `DL3006` is ignored (`.hadolint.yaml`) because the base image tag is
  parameterized via `ARG`; the default *is* pinned (`:stable`).

## 3. `build_files/build.sh` — the actual customization

Runs as root inside the base image. Order matters; summarized:

1. **Strip Bluefin branding + VSCode first** (while Fedora `os-release` intact —
   dnf5 needs correct `VERSION_ID`):
   `dnf5 remove bluefin-logos bluefin-release bluefin-gtk-theme code`
2. **Starship** — direct GitHub-release tarball → `/usr/bin/starship`
   (not in Fedora repos).
3. **Zed** (replaces VSCode) — tarball from zed.dev; copies binary to
   `/usr/bin/zed`, `.desktop` file to `/usr/share/applications`, icons to
   `/usr/share/icons/hicolor`; avoids the broken `/root` dir issue.
4. **Brave** (replaces Firefox) — imports Brave GPG key, adds official repo,
   installs, **disables the repo again**, removes Firefox.
5. **Ghostty** (replaces GNOME Terminal) — enables `scottames/ghostty` COPR,
   installs, disables COPR (so it doesn't linger enabled).
6. **Neovim + ripgrep + fd-find** via dnf5; clones
   `LazyVim/starter` into `/etc/skel/.config/nvim` (strips `.git`) so every new
   user gets LazyVim preloaded.
7. **Overlay branding:** `cp -avf /ctx/system_files/. /` then
   `glib-compile-schemas` (activates `90_calos.gschema.override`). On
   versioned builds (when the `CALOS_VERSION` / `CALOS_CODENAME` build args are
   set, e.g. from a `v1.2.0` tag) `build.sh` then overrides only `VERSION` and
   `PRETTY_NAME` in `/usr/lib/os-release` — `VERSION="1.2 (Superior)"`,
   `PRETTY_NAME="CalOS Superior"` — leaving `VERSION_ID` as Fedora's so
   bootc-image-builder keeps accepting the file. Rolling builds leave the
   committed os-release untouched.
8. **Plymouth:** `plymouth-set-default-theme calos`, with a
   `/etc/plymouth/plymouthd.conf` fallback.
9. **Starship init** for bash via `/etc/profile.d/calos.sh`.
10. `dconf update` (GDM login logo) and `systemctl enable podman.socket`.

## 4. `Justfile` — local development

Loads `image-template.env`; the main entry point for everything a maintainer does
locally. Public recipes:

| Recipe | Purpose |
|---|---|
| `just` / `just --list` | Show recipe list |
| `just check` / `fix` | Check / auto-fix Just syntax |
| `just clean` | Remove `_build*`, `output/`, manifests |
| `just build [image] [tag] [extra_args]` | podman build with OCI/ArtifactHub labels; `extra_args` = `--build-arg KEY=VALUE` pairs (CI passes `BASE_IMAGE=...`) |
| `just rechunk [image] [tag]` | **Chunkah** (new distro-agnostic) chunked OCI re-split for smaller deltas |
| `just ostree-rechunk [image] [tag]` | **rpm-ostree** chunked re-split (root required; what CI uses) |
| `just generate-default-tag` | Echo default tag (CI appends variant suffix) |
| `just generate-build-tags` | Emit `latest`, `latest-YYYYMMDD`, `latest-SHA`, `latest-DATE-SHA` |
| `just tag-images [image] [tag] [tags...]` | Re-tag a built image to all aliases |
| `just build-qcow2` / `build-raw` / `build-iso` | bootc-image-builder → `output/` |
| `just rebuild-qcow2` / `rebuild-raw` / `rebuild-iso` | Rebuild image, then disk image |
| `just run-vm-qcow2` / `run-vm-raw` / `run-vm-iso` | Run VM in qemux/qemu container, web UI on `localhost:8006+` |
| `just spawn-vm [rebuild] [type] [ram]` | `systemd-vmspawn` alternative (GUI console) |
| `just lint` / `format` | shellcheck / shfmt on all `*.sh` |

Private helpers: `sudoif` (root-or-sudo wrapper), `_rootful_load_image`
(rootful podman image transfer), `_build-bib` / `_rebuild-bib` (BIB plumbing),
`_run-vm`.

**Local dev loop:** `just build` → (optional `just ostree-rechunk`) →
`just build-qcow2` → `just run-vm-qcow2`. Disk images land in `output/`.

The ISO recipes use `disk_config/iso-gnome.toml` by default, matching the CI
workflow. `iso-kde.toml` remains available as an alternate configuration.

## 5. Disk image configs (`disk_config/`)

- `disk.toml` — qcow2/raw builds; root filesystem min size 20 GiB.
- `iso-gnome.toml` — installer kickstart runs
  `bootc switch --mutate-in-place --transport registry ghcr.io/callenflynn/calos:latest`
  post-install; Anaconda trimmed to Storage + Runtime modules only (no network /
  security / users / timezone prompts).
- `iso-kde.toml` — same kickstart but with the full Anaconda module set
  (network, security, users, timezone enabled); **not referenced by CI**.

## 6. Local build prerequisites

- `just`, `podman`, and root/sudo (for BIB + rechunk steps).
- Shell tooling used by recipes: `jq`, `numfmt` (spawn-vm), `shellcheck`/`shfmt`
  (lint/format), `ss` (port scan in `_run-vm`).
