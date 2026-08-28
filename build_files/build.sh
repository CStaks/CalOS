#!/bin/bash

set -ouex pipefail

### Detect the base distro
# x86_64 CalOS builds on `bluefin:stable` (Fedora). The only ARM64 Bluefin
# tags are LTS builds on CentOS Stream 10, so the script must handle both.
if grep -qE '^ID=(")?centos' /usr/lib/os-release 2>/dev/null; then
    DISTRO="centos"
else
    DISTRO="fedora"
fi

### Package manager: dnf5 on Fedora, dnf4 on CentOS Stream
if [[ "${DISTRO}" == "centos" ]]; then
    DNF="dnf"
    # dnf-plugins-core provides `config-manager` for dnf4; bootstrap EPEL 10
    # (neovim, ripgrep, fd-find, fastfetch, just all come from there on CS10).
    dnf install -y dnf-plugins-core
    dnf install -y https://dl.fedoraproject.org/pub/epel/epel-release-latest-10.noarch.rpm
    # dnf4 doesn't understand --skip-unavailable; this setopt is its equivalent
    SKIP_MISSING="--setopt=skip_missing_names_on_install=True"
else
    DNF="dnf5"
    SKIP_MISSING="--skip-unavailable"
fi

### Rebrand: remove inherited vendor branding packages and VSCode
# Do removes first while the base os-release is still intact (dnf needs
# correct VERSION_ID).
"${DNF}" remove -y bluefin-logos bluefin-release bluefin-gtk-theme 2>/dev/null || true
"${DNF}" remove -y code 2>/dev/null || true

### Install packages (all done BEFORE overlaying CalOS os-release)

# Packages can be installed from any enabled yum repo on the image.
# RPMfusion repos are available by default in ublue main images
# List of rpmfusion packages can be found here:
# https://mirrors.rpmfusion.org/mirrorlist?path=free/fedora/updates/43/x86_64/repoview/index.html&protocol=https&redirect=1

### Starship prompt (direct binary — not in distro repos)
# Arch-aware: Starship publishes x86_64 as gnu but aarch64 only as musl
# (statically linked, runs fine on glibc). Verified against the v1.26.0
# release assets.
case "$(uname -m)" in
    aarch64) STARSHIP_TRIPLE="aarch64-unknown-linux-musl" ;;
    *)       STARSHIP_TRIPLE="x86_64-unknown-linux-gnu" ;;
esac
curl -fsSL "https://github.com/starship/starship/releases/latest/download/starship-${STARSHIP_TRIPLE}.tar.gz" | tar xz -C /usr/bin

### Zed Editor (replaces VSCode as primary IDE)
# Manual tarball install — avoids /root not being a directory in the container.
# Arch-aware: zed publishes zed-linux-aarch64.tar.gz for ARM64.
case "$(uname -m)" in
    aarch64) ZED_ARCH="aarch64" ;;
    *)       ZED_ARCH="x86_64" ;;
esac
curl -fsSL "https://zed.dev/api/releases/stable/latest/zed-linux-${ZED_ARCH}.tar.gz" -o /tmp/zed.tar.gz
mkdir -p /tmp/zed-install
tar xzf /tmp/zed.tar.gz -C /tmp/zed-install
cp /tmp/zed-install/zed.app/bin/zed /usr/bin/
cp /tmp/zed-install/zed.app/share/applications/dev.zed.Zed.desktop /usr/share/applications/ 2>/dev/null || true
# Install Zed icons so the .desktop file works
mkdir -p /usr/share/icons/hicolor
cp -r /tmp/zed-install/zed.app/share/icons/hicolor/* /usr/share/icons/hicolor/ 2>/dev/null || true
rm -rf /tmp/zed.tar.gz /tmp/zed-install

### Brave Browser (replaces Firefox)
# Import Brave's GPG key and add their official RPM repo (distro-agnostic:
# baseurl is $basearch only, so it serves both Fedora and CentOS Stream).
rpm --import https://brave-browser-rpm-release.s3.brave.com/brave-core.asc
if [[ "${DISTRO}" == "centos" ]]; then
    "${DNF}" config-manager --add-repo https://brave-browser-rpm-release.s3.brave.com/brave-browser.repo 2>/dev/null || true
else
    "${DNF}" config-manager addrepo --from-repofile=https://brave-browser-rpm-release.s3.brave.com/brave-browser.repo 2>/dev/null || true
fi
"${DNF}" install -y brave-browser
# Disable the Brave repo so it doesn't remain enabled on the final image
"${DNF}" config-manager --disable brave-browser 2>/dev/null || true
# Remove Firefox
"${DNF}" remove -y firefox 2>/dev/null || true

### Ghostty Terminal (replaces GNOME Terminal)
# Fedora: scottames/ghostty COPR (has Fedora 44+ builds). CentOS Stream has
# no ghostty package, COPR build, or official Linux binary, so it is skipped
# there and the base image's default terminal is kept instead (the ghostty
# dconf/gsettings defaults are stripped after the overlay below).
if [[ "${DISTRO}" == "fedora" ]]; then
    "${DNF}" -y copr enable scottames/ghostty
    "${DNF}" install -y ghostty
    # Disable the COPR so it doesn't remain enabled on the final image
    "${DNF}" -y copr disable scottames/ghostty
fi

### Zoxide (smarter cd replacement)
if [[ "${DISTRO}" == "centos" ]]; then
    # Not packaged for CentOS Stream — install the official static musl binary.
    case "$(uname -m)" in
        aarch64) ZOXIDE_TRIPLE="aarch64-unknown-linux-musl" ;;
        *)       ZOXIDE_TRIPLE="x86_64-unknown-linux-musl" ;;
    esac
    ZOXIDE_URL=$(curl -fsSL "https://api.github.com/repos/ajeetdsouza/zoxide/releases/latest" \
        | grep -oE '"browser_download_url": *"[^"]*'"${ZOXIDE_TRIPLE}"'[^"]*"' | head -n1 | cut -d'"' -f4)
    curl -fsSL "${ZOXIDE_URL}" -o /tmp/zoxide.tar.gz
    tar xzf /tmp/zoxide.tar.gz -C /usr/bin zoxide
    rm -f /tmp/zoxide.tar.gz
else
    "${DNF}" install -y zoxide "${SKIP_MISSING}"
fi

### tmux + build toolchain (developer tools)
"${DNF}" install -y tmux gcc gcc-c++ make unzip "${SKIP_MISSING}"

### lazygit (Git TUI)
if [[ "${DISTRO}" == "centos" ]]; then
    # Not packaged for CentOS Stream — install the official binary.
    case "$(uname -m)" in
        aarch64) LAZYGIT_ARCH="arm64" ;;
        *)       LAZYGIT_ARCH="x86_64" ;;
    esac
    LAZYGIT_URL=$(curl -fsSL "https://api.github.com/repos/jesseduffield/lazygit/releases/latest" \
        | grep -oE '"browser_download_url": *"[^"]*linux_'"${LAZYGIT_ARCH}"'[^"]*"' | head -n1 | cut -d'"' -f4)
    curl -fsSL "${LAZYGIT_URL}" -o /tmp/lazygit.tar.gz
    tar xzf /tmp/lazygit.tar.gz -C /usr/bin lazygit
    rm -f /tmp/lazygit.tar.gz
else
    # atim/lazygit COPR has multi-arch builds
    "${DNF}" -y copr enable atim/lazygit
    "${DNF}" install -y lazygit
    "${DNF}" -y copr disable atim/lazygit
fi

### Neovim + LazyVim (terminal IDE)
# Install neovim and its ecosystem dependencies (EPEL 10 on CentOS Stream)
"${DNF}" install -y neovim ripgrep fd-find fastfetch "${SKIP_MISSING}"

# Preload LazyVim starter config for new users
# Cloned into /etc/skel/ so every new user gets LazyVim out of the box
LAZYVIM_SKEL="/etc/skel/.config/nvim"
mkdir -p "$(dirname "$LAZYVIM_SKEL")"
git clone https://github.com/LazyVim/starter.git "$LAZYVIM_SKEL"
rm -rf "$LAZYVIM_SKEL/.git"

### Install the CalOS convenience command set
# The source Justfile is a build/development task file, so ship a small
# end-user Justfile separately instead of exposing build recipes in releases.
"${DNF}" install -y just "${SKIP_MISSING}"
mkdir -p /usr/share/calos
cat > /usr/share/calos/Justfile << 'CALOSJUSTEOF'
# CalOS user commands
# Run `just` (or `just --list`) to see everything. `just update` is the
# normal way to keep the system current.

default:
    @just --list

# Update CalOS to the latest version and reboot to apply it
update:
    sudo bootc update
    sudo reboot

# Check for updates without installing (safe to run any time)
check:
    sudo bootc update --check

# Roll back to the previous version and reboot
rollback:
    sudo bootc rollback
    sudo reboot

# Show the deployed image and version
status:
    sudo bootc status

# Switch to the rolling latest image (x86_64 standard)
switch-latest:
    sudo bootc switch ghcr.io/callenflynn/calos:latest
    sudo reboot

# Show system info with the CalOS ASCII logo
info:
    fastfetch

alias u := update
alias c := check
alias r := rollback
alias v := status
alias i := info
CALOSJUSTEOF
# Keep a copy under /etc/just as a stable system-wide path.
mkdir -p /etc/just
cp /usr/share/calos/Justfile /etc/just/Justfile

### Shell environment: starship, zoxide, just fallback, aliases
# Profile.d script initializes CalOS defaults for every new login shell.
cat > /etc/profile.d/calos.sh << 'CALOSPROFILEEOF'
# CalOS - terminal info defaults
export FASTFETCH_CONFIG=/usr/share/fastfetch/presets/calos.jsonc

# CalOS - Starship prompt
if command -v starship >/dev/null 2>&1; then
    eval "$(starship init bash)"
fi

# CalOS - Zoxide (smarter cd)
if command -v zoxide >/dev/null 2>&1; then
    eval "$(zoxide init bash)"
fi

# CalOS - `just`: use the system-wide Justfile when you aren't inside a
# project that has its own. This makes `just update` work from any directory.
if command -v just >/dev/null 2>&1; then
    just() {
        # `just --list` succeeds only when a local justfile exists; otherwise
        # fall back to the system-wide CalOS Justfile. (--working-directory
        # keeps recipes running in the user's cwd, not /usr/share/calos.)
        if command just --list >/dev/null 2>&1; then
            command just "$@"
        else
            command just --justfile /usr/share/calos/Justfile --working-directory "$PWD" "$@"
        fi
    }
    export -f just 2>/dev/null || true
fi

# CalOS - handy aliases (no sudo needed, bootc handles it)
alias calos-update='sudo bootc update && sudo reboot'
alias calos-rollback='sudo bootc rollback && sudo reboot'
alias calos-version='sudo bootc status'
alias calos-switch-latest='sudo bootc switch ghcr.io/callenflynn/calos:latest && sudo reboot'
CALOSPROFILEEOF
chmod +x /etc/profile.d/calos.sh
# Make the same defaults available in interactive (GUI terminal) bash shells,
# which read /etc/bashrc rather than the login profile.
if [ -f /etc/bashrc ]; then
    if ! grep -q 'calos.sh' /etc/bashrc; then
        printf '\n# CalOS terminal defaults (just fallback, aliases, prompt)\n[ -f /etc/profile.d/calos.sh ] && . /etc/profile.d/calos.sh\n' >> /etc/bashrc
    fi
fi

### Same defaults for zsh users (distros ship /etc/zshrc for interactive shells)
if [ -f /etc/zshrc ]; then
    if ! grep -q 'calos' /etc/zshrc; then
        cat >> /etc/zshrc << 'CALOSZSHEOF'
# CalOS terminal defaults (just fallback, aliases, prompt)
export FASTFETCH_CONFIG=/usr/share/fastfetch/presets/calos.jsonc

# CalOS - `just` fallback: system-wide Justfile outside project directories
if command -v just >/dev/null 2>&1; then
    just() {
        if command just --list >/dev/null 2>&1; then
            command just "$@"
        else
            command just --justfile /usr/share/calos/Justfile --working-directory "$PWD" "$@"
        fi
    }
fi

# CalOS - handy aliases (no sudo needed, bootc handles it)
alias calos-update='sudo bootc update && sudo reboot'
alias calos-rollback='sudo bootc rollback && sudo reboot'
alias calos-version='sudo bootc status'
alias calos-switch-latest='sudo bootc switch ghcr.io/callenflynn/calos:latest && sudo reboot'

# CalOS - Starship prompt (zsh)
if command -v starship >/dev/null 2>&1; then
    eval "$(starship init zsh)"
fi

# CalOS - Zoxide (zsh)
if command -v zoxide >/dev/null 2>&1; then
    eval "$(zoxide init zsh)"
fi
CALOSZSHEOF
    fi
fi

### Overlay CalOS branding files (after all installs — os-release must NOT override the base yet)
# Capture the base image's distro identity (ID / ID_LIKE / VERSION_ID) before
# the overlay replaces os-release. bootc-image-builder validates these, and
# the bases roll between releases (Fedora 43 on x86_64, CentOS Stream 10 on
# ARM64), so we restore them below instead of shipping hardcoded values that
# go stale.
BASE_OS_RELEASE=$(grep -E '^(ID|ID_LIKE|VERSION_ID)=' /usr/lib/os-release || true)

# Copy the contents of system_files/ of the git repo to /
cp -avf "/ctx/system_files"/. /

# Restore the base image's ID / ID_LIKE / VERSION_ID (bootc-image-builder
# rejects images whose os-release identity doesn't match the base distro).
if [[ -n "${BASE_OS_RELEASE}" ]]; then
    while IFS= read -r line; do
        key="${line%%=*}"
        sed -i "s|^${key}=.*|${line}|" /usr/lib/os-release
    done <<< "${BASE_OS_RELEASE}"
fi

# If Ghostty isn't available (CentOS Stream), keep the base default terminal:
# strip the ghostty entries from the dconf keyfile and the GSettings override
# so nothing points at a binary that doesn't exist.
if ! command -v ghostty >/dev/null 2>&1; then
    sed -i "/^\[org.gnome.desktop.default-applications.terminal\]/,+1d" /etc/dconf/db/site.d/01-calos 2>/dev/null || true
    sed -i "s/, 'com.mitchellh.ghostty.desktop'//" /etc/dconf/db/site.d/01-calos 2>/dev/null || true
    sed -i "/^\[org.gnome.desktop.default-applications.terminal\]/,+1d" /usr/share/glib-2.0/schemas/zz_calos.gschema.override 2>/dev/null || true
    sed -i "s/, 'com.mitchellh.ghostty.desktop'//" /usr/share/glib-2.0/schemas/zz_calos.gschema.override 2>/dev/null || true
fi

# Make CalOS the default fastfetch config for every user. Override the base
# image's profile and preset last so inherited Bluefin ASCII art cannot win.
mkdir -p /etc/skel/.config/fastfetch /usr/share/fastfetch/presets
cat > /etc/skel/.config/fastfetch/config.jsonc << 'CALOSFASTFETCHEOF'
{
    "$schema": "https://github.com/fastfetch-cli/fastfetch/raw/dev/doc/json_schema.json",
    "logo": {
        "source": "/usr/share/fastfetch/calos-logo.txt",
        "type": "file"
    }
}
CALOSFASTFETCHEOF
cp /etc/skel/.config/fastfetch/config.jsonc /usr/share/fastfetch/presets/calos.jsonc
# Replace the inherited global config if present; FASTFETCH_CONFIG points here.
mkdir -p /etc/fastfetch
cp /etc/skel/.config/fastfetch/config.jsonc /etc/fastfetch/config.jsonc 2>/dev/null || true
# Compile GSettings schemas so our wallpaper/favorites override takes effect
glib-compile-schemas /usr/share/glib-2.0/schemas/

### Stamp release version/codename into os-release (versioned builds only)
# Rolling builds keep the committed os-release as-is. Versioned builds pass
# CALOS_VERSION / CALOS_CODENAME (from a git tag like v1.2.0) and override only
# VERSION and PRETTY_NAME — ID/ID_LIKE/VERSION_ID stay the base's so
# bootc-image-builder keeps accepting the file.
if [[ -n "${CALOS_VERSION:-}" && -n "${CALOS_CODENAME:-}" ]]; then
    sed -i "s/^VERSION=.*/VERSION=\\\"${CALOS_VERSION} (${CALOS_CODENAME})\\\"/" /usr/lib/os-release
    sed -i "s/^PRETTY_NAME=.*/PRETTY_NAME=\\\"CalOS ${CALOS_CODENAME}\\\"/" /usr/lib/os-release
fi

### Activate CalOS Plymouth boot theme
# Always overwrite plymouthd.conf so the base image's theme cannot win.
plymouth-set-default-theme calos 2>/dev/null || true
mkdir -p /etc/plymouth
printf '[Daemon]\nTheme=calos\n' > /etc/plymouth/plymouthd.conf

### GDM: ensure dconf profiles include the CalOS databases
# CalOS dconf keyfiles live in /etc/dconf/db/gdm.d/ (login screen) and
# /etc/dconf/db/site.d/ (user session), which compile into the "gdm" and
# "site" databases. Make sure both dconf profiles reference them.
mkdir -p /etc/dconf/profile
if [ -f /etc/dconf/profile/gdm ]; then
    # Keep the base profile's databases, but make sure "gdm" is present so the
    # login-screen keyfiles are actually read.
    grep -q '^system-db:gdm$' /etc/dconf/profile/gdm || printf 'system-db:gdm\n' >> /etc/dconf/profile/gdm
else
    printf 'user-db:user\nsystem-db:gdm\nfile-db:/usr/share/gdm/greeter-dconf-defaults\n' > /etc/dconf/profile/gdm
fi

# Ensure the user-session profile includes the "site" database (dock, terminal,
# wallpaper defaults for every user).
if [ -f /etc/dconf/profile/user ]; then
    if ! grep -q 'system-db:site' /etc/dconf/profile/user; then
        printf 'system-db:site\n' >> /etc/dconf/profile/user
    fi
else
    mkdir -p /etc/dconf/profile
    printf 'user-db:user\nsystem-db:site\nsystem-db:local\n' > /etc/dconf/profile/user
fi

### Compile dconf databases
dconf update

#### Example for enabling a System Unit File

systemctl enable podman.socket