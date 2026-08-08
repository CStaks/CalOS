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

### Neovim + LazyVim (terminal IDE)
# Install neovim and its ecosystem dependencies (lazygit is preinstalled on Bluefin)
dnf5 install -y neovim ripgrep fd-find --skip-unavailable

# Preload LazyVim starter config for new users
# Cloned into /etc/skel/ so every new user gets LazyVim out of the box
LAZYVIM_SKEL="/etc/skel/.config/nvim"
mkdir -p "$(dirname "$LAZYVIM_SKEL")"
git clone https://github.com/LazyVim/starter.git "$LAZYVIM_SKEL"
rm -rf "$LAZYVIM_SKEL/.git"

### Overlay CalOS branding files (after all installs — os-release must NOT override Fedora VERSION_ID yet)
# Copy the contents of system_files/ of the git repo to /
cp -avf "/ctx/system_files"/. /
# Compile GSettings schemas so our wallpaper/favorites override takes effect
glib-compile-schemas /usr/share/glib-2.0/schemas/

### Activate CalOS Plymouth boot theme
# Set CalOS as the default Plymouth theme
plymouth-set-default-theme calos 2>/dev/null || true
# Fallback: set theme via config file if plymouth-set-default-theme not available
if [ ! -f /etc/plymouth/plymouthd.conf ]; then
    mkdir -p /etc/plymouth
    printf '[Daemon]\nTheme=calos\n' > /etc/plymouth/plymouthd.conf
fi

### Shell prompt: enable starship for new users
# Profile.d script initializes starship for both bash and zsh
cat > /etc/profile.d/calos.sh << 'STARSHIPEOF'
# CalOS - Starship prompt
if command -v starship &> /dev/null; then
    eval "$(starship init bash)"
fi
STARSHIPEOF
chmod +x /etc/profile.d/calos.sh

### GDM: compile dconf for login screen logo
dconf update

# Use a COPR Example:
#
# dnf5 -y copr enable ublue-os/staging
# dnf5 -y install package
# Disable COPRs so they don't end up enabled on the final image:
# dnf5 -y copr disable ublue-os/staging

#### Example for enabling a System Unit File

systemctl enable podman.socket
