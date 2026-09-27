FROM debian:13-slim

ENV DEBIAN_FRONTEND=noninteractive

RUN apt-get update \
 && apt-get install -y --no-install-recommends \
      apt-utils ca-certificates cpio debootstrap \
      live-build xorriso squashfs-tools \
      grub-efi-amd64-bin grub-pc-bin isolinux \
      shim-signed shim-unsigned \
      dosfstools mtools rsync curl gzip xz-utils \
 && rm -rf /var/lib/apt/lists/*

COPY scripts/build-iso-in-container.sh /usr/local/bin/build-iso-in-container
RUN chmod 0755 /usr/local/bin/build-iso-in-container

ENTRYPOINT ["/usr/local/bin/build-iso-in-container"]
