#!/bin/bash

set -ouex pipefail

### REBRAND: Replace Bluefin branding with CalOS
# Remove Bluefin-specific branding packages (ok if they don't exist)
dnf5 remove -y bluefin-logos bluefin-release bluefin-gtk-theme 2>/dev/null || true

# Remove VSCode (we use Zed instead)
dnf5 remove -y code 2>/dev/null || true

# Copy the contents of system_files/ of the git repo to /
# This overlays our CalOS os-release, wallpapers, logos, and gschema overrides
cp -avf "/ctx/system_files"/. /

# Compile GSettings schemas so our wallpaper/favorites override takes effect
glib-compile-schemas /usr/share/glib-2.0/schemas/

### Install packages

# Packages can be installed from any enabled yum repo on the image.
# RPMfusion repos are available by default in ublue main images
# List of rpmfusion packages can be found here:
# https://mirrors.rpmfusion.org/mirrorlist?path=free/fedora/updates/43/x86_64/repoview/index.html&protocol=https&redirect=1

### Starship prompt (direct binary — not in Fedora repos)
mkdir -p /usr/local/bin
curl -fsSL https://github.com/starship/starship/releases/latest/download/starship-x86_64-unknown-linux-gnu.tar.gz | tar xz -C /usr/local/bin

### Zed Editor (replaces VSCode as primary IDE)
curl -f https://zed.dev/install.sh | sh

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
# Enable the pgdev/ghostty COPR repository
dnf5 -y copr enable pgdev/ghostty
dnf5 install -y ghostty
# Disable the COPR so it doesn't remain enabled on the final image
dnf5 -y copr disable pgdev/ghostty

### Neovim + LazyVim (terminal IDE)
# Install neovim and its ecosystem dependencies
dnf5 install -y neovim ripgrep fd-find lazygit gcc gcc-c++ make unzip

# Preload LazyVim starter config for new users
# Cloned into /etc/skel/ so every new user gets LazyVim out of the box
LAZYVIM_SKEL="/etc/skel/.config/nvim"
mkdir -p "$(dirname "$LAZYVIM_SKEL")"
git clone https://github.com/LazyVim/starter.git "$LAZYVIM_SKEL"
rm -rf "$LAZYVIM_SKEL/.git"

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
