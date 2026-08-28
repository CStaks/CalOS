# CalOS
<img height="150" src="CalOS/calos-github-social.png">

A custom Fedora Atomic desktop built on a Fedora Atomic base image.

> [!WARNING]
> This is a side project and may stop receiving updates at any time.

## Variants

| Tag | Architecture | Base Image | GPU |
|-----|--------------|-----------|-----|
| `:latest` | x86_64 | Fedora Atomic base | AMD / Intel |
| `:latest-arm64` | ARM64 | Bluefin LTS (CentOS Stream 10) | AMD / Intel |
| `:latest-nvidia` | x86_64 | Fedora Atomic base with NVIDIA drivers | NVIDIA (open drivers) |
| `:vX.Y.Z` / `:vX.Y.Z-arm64` / `:vX.Y.Z-nvidia` | released on each `v*` tag | matching variant |

> [!NOTE]
> NVIDIA builds are **x86_64 only** — there is no ARM64 NVIDIA base image.
> The ARM64 variant tracks the Bluefin LTS arm64 branch, which is based on
> **CentOS Stream 10** (Bluefin publishes no Fedora-based ARM64 image);
> x86_64 tracks Fedora. On ARM64, Ghostty is not available (no package or
> official Linux binary for CentOS Stream), so the base terminal is used
> instead — everything else is the same.


# Minimum Requirements
If you do not meet the minimum specs, the operating system may perform poorly and become unstable.


Minimum:


Memory:  6gb of ram

CPU (x86_64):  Intel Core i5-8400 or AMD Ryzen 5 2600 or equivalent 

CPU (ARM64): 4-core Cortex-A72-class or equivalent

Storage:  32 GB


Recommended:

Memory:  12gb of ram 

CPU (x86_64):  Intel Core i5-10400 or AMD Ryzen 5 3600 or equivalent

CPU (ARM64): 4-core Cortex-A76-class or equivalent

Storage:  64 GB+


Heavy Multitasking or Gaming:


Memory:  16gb of ram 

CPU (x86_64):  Intel Core i5-11400 or AMD Ryzen 5 5600 or equivalent

CPU (ARM64):  6+ core Cortex-A76-class or equivalent

Storage: 64 GB+


# Install

## Download

Each release tag (e.g. `v1.2.0`) is published to its own SourceForge folder (`/1.2.0/`) 


- **standard** — AMD / Intel GPUs (recommended)
- **nvidia** — NVIDIA GPUs only


## Bootc
From any bootc-based system (Bazzite, Aurora, Fedora Atomic, or another bootc image):

```bash
# Standard / AMD / Intel (x86_64)
sudo bootc switch ghcr.io/callenflynn/calos:latest

# ARM64 (Apple Silicon, Raspberry Pi-style boards)
sudo bootc switch ghcr.io/callenflynn/calos:latest-arm64

# NVIDIA GPUs (x86_64 only)
sudo bootc switch ghcr.io/callenflynn/calos:latest-nvidia
```

After either switch, update the installed system with:

```bash
sudo bootc update
sudo reboot
```

To pin a specific release instead of the rolling `latest` (replace v1.1.4 with the version you want to use):

```bash
# Standard / AMD / Intel (x86_64)
sudo bootc switch ghcr.io/callenflynn/calos:v1.1.4

# ARM64
sudo bootc switch ghcr.io/callenflynn/calos:v1.1.4-arm64

# NVIDIA hardware (x86_64)
sudo bootc switch ghcr.io/callenflynn/calos:v1.1.4-nvidia
```

Reboot to apply. For the rolling channel, `bootc update` checks the selected CalOS `:latest` image and stages updates for the next reboot. Versioned tags such as `:v1.1.1` are pinned and do not move automatically.

## Disk images

Prebuilt qcow2 + vmdk (VMs) and anaconda-iso (USB/installer) images are built daily for both **x86_64** and **ARM64** and published automatically to the [SourceForge project files](https://sourceforge.net/projects/calos-linux/):

- **standard x86_64** — AMD / Intel physical hardware (qcow2 for QEMU/Boxes, vmdk for VMware, installer ISO)
- **standard ARM64** — same set (Apple Silicon, Raspberry Pi-style boards)
- **nvidia x86_64** — NVIDIA physical hardware (qcow2, installer ISO); there is no NVIDIA VMDK because VMware virtualizes the GPU, and no ARM64 NVIDIA build

Files are named `calos-<version>_<arch>[<variant>].<ext>` — for example `calos-v1.1.4_x86_64.qcow2`, `calos-v1.1.4_arm64.iso`, `calos-v1.1.4_x86_64-nvidia.iso`. On the rolling channel the version token is `latest` (`calos-latest_x86_64.qcow2`); on tagged releases it is the tag (`calos-v1.1.4_x86_64.qcow2`).

Tagged releases (`vX.Y.Z`) are published to versioned SourceForge folders (e.g. `/1.2.0/`) and linked from [GitHub Releases](https://github.com/callenflynn/calos/releases). Use the latest GitHub Release to identify the current version; the actual files are linked from that release into its matching SourceForge folder (for example `/1.1.4/`). SourceForge generates MD5/SHA1/SHA256 checksums for every file on the files page.

## Updating

CalOS ships with [just](https://github.com/casey/just) preinstalled and a system-wide
Justfile, so updating is one command from any terminal:

```bash
just update    # check for updates, install them, and reboot to apply
```

Other useful commands (aliases in parentheses):

```bash
just check      # (just c)  check for updates without installing
just rollback   # (just r)  roll back to the previous version and reboot
just status     # (just v)  show the deployed image and version
just info       # (just i)  show system info with the CalOS ASCII logo
just switch-latest  # switch back to the rolling :latest image and reboot
```

`just` finds the CalOS Justfile automatically when you run it outside a project
directory (via `/etc/profile.d/calos.sh`), so `just update` works from anywhere.
There are also plain aliases if you prefer to skip `just`:

```bash
calos-update        # sudo bootc update && sudo reboot
calos-rollback      # sudo bootc rollback && sudo reboot
calos-version       # sudo bootc status
calos-switch-latest # sudo bootc switch ghcr.io/callenflynn/calos:latest && sudo reboot
```

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

### Developer Tools

- **Neovim + LazyVim** — Preloaded starter config, first launch installs all plugins automatically
- **lazygit** — Terminal Git interface
- **ripgrep, fd-find** — Fast search tools
- **gcc, gcc-c++, make** — Build toolchain
- **unzip** — Archive extraction

# Screenshots

v1.1.0 desktop

<img src="CalOS/v1.1.0-desktop-screenshot-1.webp" height=240>


# Branding

## Colors
| Role | Hex |
|------|-----|
| Primary accent | `#FF3B00` |
| Background | `#050505` |
| Background 2 | `#ffeee9` |
| Text | `#E0E0E0` |
| Text 2 | `#050505` |

## Logos

primary logo

<img src="CalOS/CalOS.png" height=120>



B&W

<img src="CalOS/CalOS-bw.png" height=120>
