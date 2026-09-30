#!/bin/bash
set -Eeuo pipefail

ROOT=$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)
IMAGE=${IMAGE:-danos-buildiso:2608}
OUTPUT=${OUTPUT:-"$ROOT/container-output"}
DANOS_APT_URL=${DANOS_APT_URL:-https://r2.aikon.qzz.io/danos-apt/test/}

mkdir -p "$OUTPUT"

# The host reaches r2.aikon.qzz.io (and, some of the time, the Debian mirror)
# through a local proxy -- required, not optional, since both sit behind the
# GFW. dockerd does not inherit the shell's proxy env (see
# docker-daemon-proxy-and-restart-cost), and a container built from it
# inherits nothing either unless told to. --network host was chosen over
# passing --env http_proxy=http://host.docker.internal:<port> because the
# proxy here (xray/v2rayN) binds 127.0.0.1 only -- confirmed with `ss -tlnp`
# -- so it refuses connections arriving over the docker bridge from
# host.docker.internal regardless of --add-host=...:host-gateway. Sharing the
# host's network namespace makes the container's own 127.0.0.1 the same
# 127.0.0.1 the proxy is actually listening on, with no proxy reconfiguration
# needed. Without this, apt-get inside the container intermittently fails
# mid-build reaching r2.aikon.qzz.io -- it isn't flaky R2 or a flaky mirror,
# it's a container with no route to the proxy its host depends on.
#
# This has to cover the `docker build`/`buildx build` step too, not just
# `docker run` -- missed the first time, and it stayed invisible for a while
# because a cached image layer meant the image build step never actually ran
# apt-get. The moment that cache was pruned, rebuilding the image from
# scratch hit "Unable to locate package" for every package in the
# Dockerfile's RUN -- the image build has its own network context, entirely
# separate from the container the finished image later runs in.
proxy_args=()
build_proxy_args=()
if [ -n "${https_proxy:-${HTTPS_PROXY:-}}" ] || [ -n "${http_proxy:-${HTTP_PROXY:-}}" ]; then
  proxy_args+=(--network host)
  build_proxy_args+=(--network host)
  for var in http_proxy https_proxy HTTP_PROXY HTTPS_PROXY all_proxy ALL_PROXY; do
    val="${!var:-}"
    [ -n "$val" ] || continue
    proxy_args+=(--env "$var=$val")
    build_proxy_args+=(--build-arg "$var=$val")
  done
  # Exclude the domestic build-time mirrors (Aliyun, Huawei Cloud) from the
  # proxy -- they're fast and reliable reached directly, and were the
  # comment in config/apt/sources.list's whole reason for existing (68x
  # deb.debian.org's throughput from this host). Routing them through the
  # proxy anyway degraded them to the same congestion-prone path as the
  # genuinely GFW-blocked domains (r2.aikon.qzz.io, deb.debian.org) --
  # confirmed here: package fetches from mirrors.aliyun.com started failing
  # only after the proxy was made unconditional for all container traffic.
  no_proxy_list="localhost,127.0.0.0/8,::1,mirrors.aliyun.com,repo.huaweicloud.com"
  proxy_args+=(--env "no_proxy=$no_proxy_list" --env "NO_PROXY=$no_proxy_list")
  build_proxy_args+=(--build-arg "no_proxy=$no_proxy_list" --build-arg "NO_PROXY=$no_proxy_list")
fi

if docker buildx version >/dev/null 2>&1; then
  docker buildx build --load "${build_proxy_args[@]}" --tag "$IMAGE" "$ROOT"
else
  docker build "${build_proxy_args[@]}" --tag "$IMAGE" "$ROOT"
fi

docker run --rm --privileged \
  --env DANOS_APT_URL="$DANOS_APT_URL" \
  --env SOURCE_DATE_EPOCH="${SOURCE_DATE_EPOCH:-}" \
  --env ISO_VARIANT="${ISO_VARIANT:-product}" \
  "${proxy_args[@]}" \
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
