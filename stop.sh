#!/bin/sh
set -eu

if [ -n "${ENGINE:-}" ]; then
  engine="$ENGINE"
elif command -v podman >/dev/null 2>&1; then
  engine="podman"
elif command -v docker >/dev/null 2>&1; then
  engine="docker"
else
  echo "Docker or Podman is required." >&2
  exit 1
fi

"$engine" rm --force vllm-zero-to-hero

