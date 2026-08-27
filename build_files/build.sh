#!/bin/bash

set -ouex pipefail

### REBRAND: Remove Bluefin branding packages and VSCode
# Do removes first while Fedora os-release is still intact (dnf5 needs correct VERSION_ID)
dnf5 remove -y bluefin-logos bluefin-release bluefin-gtk-theme 2>/dev/null || true
dnf5 remove -y code 2>/dev/null || true

### Install packages (all done BEFORE overlaying CalOS os-release)

# Packages can be installed from any enabled yum repo on the image.
# RPMfusion repos are available by default in ublue main images
# List of rpmfusion packages can be found here:
# https://mirrors.rpmfusion.org/mirrorlist?path=free/fedora/updates/43/x86_64/repoview/index.html&protocol=https&redirect=1

### Starship prompt (direct binary — not in Fedora repos)
curl -fsSL https://github.com/starship/starship/releases/latest/download/starship-x86_64-unknown-linux-gnu.tar.gz | tar xz -C /usr/bin

### Zed Editor (replaces VSCode as primary IDE)
# Manual tarball install — avoids /root not being a directory in the container
curl -fsSL https://zed.dev/api/releases/stable/latest/zed-linux-x86_64.tar.gz -o /tmp/zed.tar.gz
mkdir -p /tmp/zed-install
tar xzf /tmp/zed.tar.gz -C /tmp/zed-install
cp /tmp/zed-install/zed.app/bin/zed /usr/bin/
cp /tmp/zed-install/zed.app/share/applications/dev.zed.Zed.desktop /usr/share/applications/ 2>/dev/null || true
# Install Zed icons so the .desktop file works
mkdir -p /usr/share/icons/hicolor
cp -r /tmp/zed-install/zed.app/share/icons/hicolor/* /usr/share/icons/hicolor/ 2>/dev/null || true
rm -rf /tmp/zed.tar.gz /tmp/zed-install

### Brave Browser (replaces Firefox)
# Import Brave's GPG key and add their official RPM repo
rpm --import https://brave-browser-rpm-release.s3.brave.com/brave-core.asc
dnf5 config-manager addrepo --from-repofile=https://brave-browser-rpm-release.s3.brave.com/brave-browser.repo 2>/dev/null || true
dnf5 install -y brave-browser
# Disable the Brave repo so it doesn't remain enabled on the final image
dnf5 config-manager --disable brave-browser 2>/dev/null || true
# Remove Firefox
dnf5 remove -y firefox 2>/dev/null || true

### Ghostty Terminal (replaces GNOME Terminal)
# Enable the scottames/ghostty COPR repository (has Fedora 44 builds)
dnf5 -y copr enable scottames/ghostty
dnf5 install -y ghostty
# Disable the COPR so it doesn't remain enabled on the final image
dnf5 -y copr disable scottames/ghostty

### Zoxide (smarter cd replacement)
dnf5 install -y zoxide --skip-unavailable

### Neovim + LazyVim (terminal IDE)
# Install neovim and its ecosystem dependencies (lazygit is preinstalled on Bluefin)
dnf5 install -y neovim ripgrep fd-find --skip-unavailable

# Preload LazyVim starter config for new users
# Cloned into /etc/skel/ so every new user gets LazyVim out of the box
LAZYVIM_SKEL="/etc/skel/.config/nvim"
mkdir -p "$(dirname "$LAZYVIM_SKEL")"
git clone https://github.com/LazyVim/starter.git "$LAZYVIM_SKEL"
rm -rf "$LAZYVIM_SKEL/.git"

### Install the CalOS convenience command set
# The source Justfile is a build/development task file, so ship a small
# end-user Justfile separately instead of exposing build recipes in releases.
dnf5 install -y just --skip-unavailable
mkdir -p /usr/share/calos
cat > /usr/share/calos/Justfile << 'CALOSJUSTEOF'
# CalOS user commands
update:
    sudo bootc update
    sudo reboot
CALOSJUSTEOF
# Make plain `just update` work from any directory on the installed system.
mkdir -p /etc/just
cp /usr/share/calos/Justfile /etc/just/Justfile

### Overlay CalOS branding files (after all installs — os-release must NOT override Fedora VERSION_ID yet)
# Copy the contents of system_files/ of the git repo to /
cp -avf "/ctx/system_files"/. /
# Make CalOS the default fastfetch config for every new user. Bluefin's
# profile may already contain FASTFETCH_CONFIG, so override it last.
mkdir -p /etc/skel/.config/fastfetch
cat > /etc/skel/.config/fastfetch/config.jsonc << 'CALOSFASTFETCHEOF'
{
    "$schema": "https://github.com/fastfetch-cli/fastfetch/raw/dev/doc/json_schema.json",
    "logo": {
        "source": "/usr/share/fastfetch/calos-logo.txt",
        "type": "file"
    }
}
CALOSFASTFETCHEOF
# Compile GSettings schemas so our wallpaper/favorites override takes effect
glib-compile-schemas /usr/share/glib-2.0/schemas/

### Stamp release version/codename into os-release (versioned builds only)
# Rolling builds keep the committed os-release as-is. Versioned builds pass
# CALOS_VERSION / CALOS_CODENAME (from a git tag like v1.2.0) and override only
# VERSION and PRETTY_NAME — VERSION_ID stays Fedora's so bootc-image-builder
# keeps accepting the file.
if [[ -n "${CALOS_VERSION:-}" && -n "${CALOS_CODENAME:-}" ]]; then
    sed -i "s/^VERSION=.*/VERSION=\"${CALOS_VERSION} (${CALOS_CODENAME})\"/" /usr/lib/os-release
    sed -i "s/^PRETTY_NAME=.*/PRETTY_NAME=\"CalOS ${CALOS_CODENAME}\"/" /usr/lib/os-release
fi

### Activate CalOS Plymouth boot theme
# Always overwrite plymouthd.conf — Bluefin's base image ships one with
# Theme=bluefin, and the conditional check (! -f) never fires.
plymouth-set-default-theme calos 2>/dev/null || true
mkdir -p /etc/plymouth
printf '[Daemon]\nTheme=calos\n' > /etc/plymouth/plymouthd.conf

### Shell prompt: enable starship for new users
# Profile.d script initializes starship for both bash and zsh
cat > /etc/profile.d/calos.sh << 'STARSHIPEOF'
# CalOS - terminal info defaults
export FASTFETCH_CONFIG=/usr/share/fastfetch/presets/calos.jsonc

# CalOS - Starship prompt
if command -v starship &> /dev/null; then
    eval "$(starship init bash)"
fi
# CalOS - Zoxide (smarter cd)
if command -v zoxide &> /dev/null; then
    eval "$(zoxide init bash)"
fi
STARSHIPEOF
chmod +x /etc/profile.d/calos.sh

### GDM: ensure CalOS dconf profile exists for login screen branding
# Bluefin may ship /etc/dconf/profile/gdm — if so, append our system-db;
# if not, create the standard profile from scratch.
if [ -f /etc/dconf/profile/gdm ]; then
    if ! grep -q 'system-db:calos' /etc/dconf/profile/gdm; then
        printf 'system-db:calos\n' >> /etc/dconf/profile/gdm
    fi
else
    mkdir -p /etc/dconf/profile
    printf 'user-db:user\nsystem-db:gdm\nfile-db:/usr/share/gdm/greeter-dconf-defaults\nsystem-db:calos\n' > /etc/dconf/profile/gdm
fi

# Ensure the site db (user session defaults) is also on the profile
if [ -f /etc/dconf/profile/user ]; then
    if ! grep -q 'system-db:calos' /etc/dconf/profile/user; then
        printf 'system-db:calos\n' >> /etc/dconf/profile/user
    fi
else
    mkdir -p /etc/dconf/profile
    printf 'user-db:user\nsystem-db:site\nsystem-db:local\nsystem-db:calos\n' > /etc/dconf/profile/user
fi

### Compile dconf databases
dconf update

# Use a COPR Example:
#
# dnf5 -y copr enable ublue-os/staging
# dnf5 -y install package
# Disable COPRs so they don't end up enabled on the final image:
# dnf5 -y copr disable ublue-os/staging

#### Example for enabling a System Unit File

systemctl enable podman.socket
