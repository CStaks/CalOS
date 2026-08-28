# Base Image
# Use --build-arg BASE_IMAGE=... to override for the NVIDIA variant when needed.
ARG BASE_IMAGE=ghcr.io/ublue-os/bluefin:stable

# Allow build scripts to be referenced without being copied into the final image
FROM scratch AS ctx
COPY build_files /
COPY system_files /system_files

FROM ${BASE_IMAGE}

# Optional release metadata stamped into os-release by build.sh on versioned
# builds (e.g. tag v1.2.0 -> VERSION="1.2 (Superior)"). Left empty on rolling
# builds, where the committed system_files/usr/lib/os-release is used as-is.
ARG CALOS_VERSION=""
ARG CALOS_CODENAME=""

## Other possible Fedora Atomic base images can be selected here when needed.
# Fedora base image: quay.io/fedora/fedora-bootc:44
# CentOS base images: quay.io/centos-bootc/centos-bootc:stream10

### [IM]MUTABLE /opt
## Some bootable images, like Fedora, have /opt symlinked to /var/opt, in order to
## make it mutable/writable for users. However, some packages write files to this directory,
## thus its contents might be wiped out when bootc deploys an image, making it troublesome for
## some packages. Eg, google-chrome, docker-desktop.
##
## Uncomment the following line if one desires to make /opt immutable and be able to be used
## by the package manager.

RUN rm -rf /opt && mkdir /opt

### MODIFICATIONS
## make modifications desired in your image and install packages by modifying the build.sh script
## the following RUN directive does all the things required to run "build.sh" as recommended.

RUN --mount=type=bind,from=ctx,source=/,target=/ctx \
    --mount=type=cache,dst=/var/cache \
    --mount=type=cache,dst=/var/log \
    --mount=type=tmpfs,dst=/tmp \
    /ctx/build.sh

### BRANDING METADATA
## Stamp CalOS's own OCI / Artifact Hub labels so the published image is
## branded as CalOS rather than inheriting the base image's labels (e.g.
## Bluefin / ublue-os). These override the base labels on the final image;
## the ARG defaults keep values correct even when not passed as build args.
ARG IMAGE_NAME="calos"
ARG REPO_ORGANIZATION="callenflynn"
ARG IMAGE_DESC="CalOS - A custom Fedora Atomic desktop"
ARG IMAGE_KEYWORDS="calos,bootc,oci,linux,atomic,gnome"
ARG IMAGE_LOGO_URL="https://raw.githubusercontent.com/callenflynn/CalOS/main/CalOS/CalOS.png"

LABEL org.opencontainers.image.title="${IMAGE_NAME}"
LABEL org.opencontainers.image.vendor="${REPO_ORGANIZATION}"
LABEL org.opencontainers.image.description="${IMAGE_DESC}"
LABEL org.opencontainers.image.url="https://github.com/${REPO_ORGANIZATION}/${IMAGE_NAME}"
LABEL org.opencontainers.image.source="https://raw.githubusercontent.com/${REPO_ORGANIZATION}/${IMAGE_NAME}/main/Containerfile"
LABEL org.opencontainers.image.licenses="Apache-2.0"
LABEL io.artifacthub.package.logo-url="${IMAGE_LOGO_URL}"
LABEL io.artifacthub.package.keywords="${IMAGE_KEYWORDS}"
LABEL io.artifacthub.package.maintainers="[{\"name\": \"callenflynn\"}]"
