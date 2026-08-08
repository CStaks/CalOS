# CalOS
<img height="150" src="CalOS/CalOS.png">

A custom Fedora Atomic desktop built on [Bluefin](https://github.com/ublue-os/bluefin).

> [!WARNING]
> This is a side project and may stop recieving updates at any time.

## Variants

| Tag | Base Image | GPU |
|-----|-----------|-----|
| `:latest` | `ghcr.io/ublue-os/bluefin:stable` | AMD / Intel |
| `:latest-nvidia` | `ghcr.io/ublue-os/bluefin-nvidia-open:stable` | NVIDIA (open drivers) |

Both variants are built daily via GitHub Actions and pushed to GHCR.

## Install

From any bootc-based system (Bluefin, Bazzite, Aurora, Fedora Atomic):

```bash
sudo bootc switch ghcr.io/callenflynn/calos:latest
```

For NVIDIA GPUs:

```bash
sudo bootc switch ghcr.io/callenflynn/calos:latest-nvidia
```

Reboot to apply. Updates are automatic — `bootc` checks for new images in the background and stages them for the next reboot.

## What's Included

### Preinstalled Apps

| App | Replaces | Notes |
|-----|----------|-------|
| [Zed](https://zed.dev) | VSCode | Primary IDE, GPU-accelerated |
| [Brave](https://brave.com) | Firefox | Privacy-focused browser |
| [Ghostty](https://ghostty.org) | GNOME Terminal | Modern GPU-accelerated terminal |
| [Neovim](https://neovim.io) + [LazyVim](https://www.lazyvim.org) | — | Terminal IDE, pre-configured for all users |
| [lazygit](https://github.com/jesseduffield/lazygit) | — | Git TUI |
| [Starship](https://starship.rs) | — | Shell prompt with CalOS branding |
| [tmux](https://github.com/tmux/tmux) | — | Terminal multiplexer |
| [fastfetch](https://github.com/fastfetch-cli/fastfetch) | — | System info with CalOS ASCII art |

### Visual Branding

- **OS identity** — "CalOS" everywhere (Settings → About, GRUB menu, fastfetch)
- **Plymouth boot screen** — Dark background with CalOS text and #FF3B00 accent spinner
- **GDM login screen** — CalOS logo on the greeter
- **Starship prompt** — CalOS-themed with #FF3B00 accent, git info, truncated paths
- **Wallpapers** — 4 custom wallpapers (mountains, night-iceberg, fuji, macOS-inspired)
- **Dock** — Files, Brave, Zed, Ghostty, Software, Settings

### Developer Tools

- **Neovim + LazyVim** — Preloaded starter config, first launch installs all plugins automatically
- **lazygit** — Terminal Git interface
- **ripgrep, fd-find** — Fast search tools
- **gcc, gcc-c++, make** — Build toolchain
- **unzip** — Archive extraction

## How It's Built

- **Containerfile** — ARG-based parameterization so one file builds both AMD and NVIDIA variants
- **build.yml** — Matrix CI builds both variants, pushes signed images to GHCR
- **build-disk.yml** — Produces qcow2 and ISO disk images for both variants
- **Daily rebuilds** — Cron schedule keeps packages fresh

## Colors

| Role | Hex |
|------|-----|
| Primary accent | `#FF3B00` |
| Background | `#050505` |
| Text | `#E0E0E0` |
