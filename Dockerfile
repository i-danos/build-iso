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

# Survive a mirror gateway that answers a burst of parallel index fetches with
# HTTP 500. apt otherwise gives up on "Some index files failed to download" and
# live-build reports "An unexpected failure occurred" -- and which file fails
# changes run to run, so it reads like a broken mirror when it is not.
RUN echo 'Acquire::Retries "10";' > /etc/apt/apt.conf.d/99-danos-retries \
 && echo 'Acquire::http::Pipeline-Depth "0";' >> /etc/apt/apt.conf.d/99-danos-retries \
 && echo 'Acquire::http::Timeout "60";' >> /etc/apt/apt.conf.d/99-danos-retries

# Point this image's own apt at whatever mirror the build was given, so the
# binary stage does not go back to deb.debian.org behind the caller's back. On a
# host whose egress answers parallel fetches with 500s, DEBIAN_MIRROR can be a
# local serialising cache and this is what makes the build reproducible.
ARG DEBIAN_MIRROR=""
ARG DEBIAN_SECURITY_MIRROR=""
RUN set -eux; \
    f=/etc/apt/sources.list.d/debian.sources; \
    if [ -n "$DEBIAN_MIRROR" ]; then \
      sed -i "s#http://deb.debian.org/debian\b#$DEBIAN_MIRROR#g" "$f"; \
    fi; \
    if [ -n "$DEBIAN_SECURITY_MIRROR" ]; then \
      sed -i "s#http://deb.debian.org/debian-security\b#$DEBIAN_SECURITY_MIRROR#g" "$f"; \
    fi; \
    cat "$f"

COPY scripts/build-iso-in-container.sh /usr/local/bin/build-iso-in-container
RUN chmod 0755 /usr/local/bin/build-iso-in-container

ENTRYPOINT ["/usr/local/bin/build-iso-in-container"]
