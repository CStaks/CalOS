---
name: Installation
description: Installing CalOS
---

# Installing CalOS

Pick an image from the [image chooser](https://callenflynn.github.io/CalOS/)
or [SourceForge](https://sourceforge.net/projects/calos-linux/files/), then:

- **USB install:** flash the ISO with a tool like `dd` or a graphical flasher,
  then boot from the USB.
- **Virtual machine:** boot the QCOW2 image in QEMU / GNOME Boxes, or the VMDK
  in VMware.
- **Existing bootc system:** `sudo bootc switch ghcr.io/callenflynn/calos:latest`

Reboot into CalOS and run `ujust update` to make sure you're on the latest image.