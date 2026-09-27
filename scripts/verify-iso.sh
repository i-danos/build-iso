#!/bin/bash
set -Eeuo pipefail

ISO=${1:?usage: verify-iso.sh path/to/image.iso [expected-package]}
EXPECTED_PACKAGE=${2:-vyatta-version}

test -f "$ISO"
test -s "$ISO"

echo "Checking ISO format..."
file "$ISO" | grep -Eiq 'ISO 9660|boot sector'

CHECKSUM_FILE="${ISO}.sha256"
if [[ -f "$CHECKSUM_FILE" ]]; then
    expected=$(awk '{print $1}' "$CHECKSUM_FILE")
    actual=$(sha256sum "$ISO" | awk '{print $1}')
    test "$expected" = "$actual"
    echo "SHA256: $actual"
else
    echo "SHA256: $(sha256sum "$ISO" | awk '{print $1}')"
fi

if command -v isoinfo >/dev/null 2>&1; then
    echo "Checking ISO directory entries..."
    isoinfo -f -i "$ISO" | grep -q '/LIVE/FILESYSTEM.SQUASHFS'
    isoinfo -f -i "$ISO" | grep -q '/LIVE/VMLINUZ'
fi

echo "ISO verification passed: $ISO"
echo "Package-level verification requires booting the image or inspecting the extracted root filesystem."
echo "Expected package marker: $EXPECTED_PACKAGE"
