---
name: Installation
description: Installing CalOS
---

# Installing CalOS

Pick an image from the [image chooser](https://callenflynn.github.io/CalOS/)
or [SourceForge](https://sourceforge.net/projects/calos-linux/files/), then:

- **USB install:** [download balena Etcher](https://etcher.balena.io/) (the recommended graphical flasher), select the CalOS ISO, choose your USB drive, and flash it. Flashing erases the selected USB drive; then boot from it.
- **Virtual machine:** use [QEMU](https://www.qemu.org/) or [VirtualBox](https://www.virtualbox.org/) with the QCOW2 image, or [VMware](https://www.vmware.com/) with the VMDK image.
- **Existing bootc system:** `sudo bootc switch ghcr.io/callenflynn/calos:latest`

Reboot into CalOS and run `ujust update` to make sure you're on the latest image.
