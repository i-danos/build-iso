#!/bin/bash
set -Eeuo pipefail

ROOT=$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)
IMAGE=${IMAGE:-danos-buildiso:2608}
OUTPUT=${OUTPUT:-"$ROOT/container-output"}
DANOS_APT_URL=${DANOS_APT_URL:-https://r2.aikon.qzz.io/danos-apt/test/}

mkdir -p "$OUTPUT"

if docker buildx version >/dev/null 2>&1; then
  docker buildx build --load --tag "$IMAGE" "$ROOT"
else
  docker build --tag "$IMAGE" "$ROOT"
fi
docker run --rm --privileged \
  --env DANOS_APT_URL="$DANOS_APT_URL" \
  --env SOURCE_DATE_EPOCH="${SOURCE_DATE_EPOCH:-}" \
  --volume "$ROOT:/workspace:ro" \
  --volume "$OUTPUT:/output" \
  "$IMAGE"

shopt -s nullglob
isos=("$OUTPUT"/*.iso)
if ((${#isos[@]} == 0)); then
  echo "Container build completed without producing an ISO" >&2
  exit 1
fi

for iso in "${isos[@]}"; do
  "$ROOT/scripts/verify-iso.sh" "$iso"
done
