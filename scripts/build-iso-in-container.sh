#!/bin/bash
set -Eeuo pipefail

: "${DANOS_APT_URL:?DANOS_APT_URL is required}"
: "${SOURCE_DATE_EPOCH:=}"
: "${ISO_VARIANT:=product}"

WORK=/build-iso
rm -rf "$WORK"
mkdir -p "$WORK" /output
rsync -a --delete \
  --exclude=.git \
  --exclude=.build \
  --exclude=binary \
  --exclude=cache \
  --exclude=chroot \
  --exclude='*.iso' \
  --exclude='*.log' \
  --exclude='*.files' \
  --exclude='*.packages' \
  --exclude='*.contents' \
  --exclude='*.hybrid.sha256' \
  --exclude='binary.modified_timestamps' \
  --exclude='chroot.*' \
  --exclude='mk-*.out' \
  /workspace/ "$WORK/"
cd "$WORK"

# The repository is intentionally configured with a local default for legacy
# builds. Replace it only in the container copy so the host checkout stays
# untouched and CI can inject an R2 snapshot URL.
tmp_sources=$(mktemp)
awk -v apt_url="${DANOS_APT_URL%/}/" '
  /^[[:space:]]*deb[[:space:]]+\[[^]]*\][[:space:]]+http:\/\/127\.0\.0\.1:8080\// {
    print "deb [trusted=yes] " apt_url " ./"
    next
  }
  { print }
' config/archives/danos.list.chroot > "$tmp_sources"
mv "$tmp_sources" config/archives/danos.list.chroot

# Keep the DANOS source in the build-time sources.list as well. This makes the
# package index available during live-build's early chroot apt pass; the
# archive hook still removes build-only sources from the final ISO.
printf 'deb [trusted=yes] %s ./\n' "${DANOS_APT_URL%/}/" >> config/apt/sources.list

# The test variant carries one content-only overlay: a preseeded dataplane
# exclude-interfaces entry plus a management interfaces.d file, so the test
# suites' "delete interfaces dataplane" doesn't cut their own connection. It
# never adds or removes a package -- only file content inside packages
# already selected -- so it must never show up as a package-set difference
# against the product variant. See test-overlay/ and
# toolkit/build/90-mk-test-iso.sh for the original (non-containerized)
# version of this same staging step.
if [ "$ISO_VARIANT" = "test" ]; then
  echo "I: staging test overlay (ISO_VARIANT=test)"
  ( cd test-overlay && find . -type f ) | while read -r f; do
    install -D -m644 "test-overlay/${f#./}" "config/includes.chroot_after_packages/${f#./}"
  done
elif [ "$ISO_VARIANT" != "product" ]; then
  echo "unknown ISO_VARIANT: $ISO_VARIANT (want product or test)" >&2
  exit 1
fi

export SOURCE_DATE_EPOCH
./auto/config
./auto/build

shopt -s nullglob
artifacts=( *.iso *.sha256 *.files *.packages *.contents *.log )
if ((${#artifacts[@]} == 0)); then
  echo "No build artifacts were produced" >&2
  exit 1
fi
cp -a "${artifacts[@]}" /output/

for iso in /output/*.iso; do
  sha256sum "$iso" > "$iso.sha256"
done

echo "Build artifacts:" >&2
ls -lh /output
