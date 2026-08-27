# CalOS
<img height="150" src="CalOS/calos-github-social.png">

A custom Fedora Atomic desktop built on a Fedora Atomic base image.

> [!WARNING]
> This is a side project and may stop recieving updates at any time.

## Variants

| Tag | Base Image | GPU |
|-----|-----------|-----|
| `:latest` | Fedora Atomic base | AMD / Intel |
| `:latest-nvidia` | Fedora Atomic base with NVIDIA drivers | NVIDIA (open drivers) |
| `:vX.Y.Z` / `:vX.Y.Z-nvidia` | released on each `v*` tag | matching variant |


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
sudo bootc switch ghcr.io/callenflynn/calos:latest
```

For NVIDIA GPUs:

```bash
sudo bootc switch ghcr.io/callenflynn/calos:latest-nvidia
```

After either switch, update the installed system with:

```bash
sudo bootc update
sudo reboot
```

To pin a specific release instead of the rolling `latest` (replace v1.1.3 with the version you want to use):

```bash
# Standard / AMD / Intel 
sudo bootc switch ghcr.io/callenflynn/calos:v1.1.1

# NVIDIA hardware
sudo bootc switch ghcr.io/callenflynn/calos:v1.1.1-nvidia
```

Reboot to apply. For the rolling channel, `bootc update` checks the selected CalOS `:latest` image and stages updates for the next reboot. Versioned tags such as `:v1.1.1` are pinned and do not move automatically.

## Disk images

Prebuilt qcow2 + vmdk (VMs) and anaconda-iso (USB/installer) images are built daily and published automatically to the [SourceForge project files](https://sourceforge.net/projects/calos-linux/):

- **standard** — AMD / Intel physical hardware (qcow2 for QEMU/Boxes, standard vmdk for VMware, installer ISO)
- **nvidia** — NVIDIA physical hardware (qcow2, installer ISO); there is no NVIDIA VMDK because VMware virtualizes the GPU

Tagged releases (`vX.Y.Z`) are published to versioned SourceForge folders (e.g. `/1.2.0/`) and linked from [GitHub Releases](https://github.com/callenflynn/calos/releases). Use the latest GitHub Release to identify the current version; the actual files are linked from that release into its matching SourceForge folder (for example `/1.1.3/`). The docs site points to the current release folder through the generated `docs/latest-release.js` file. The release workflow updates that file automatically whenever a version tag is published. SourceForge generates MD5/SHA1/SHA256 checksums for every file on the files page, so you can verify any download there.

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
