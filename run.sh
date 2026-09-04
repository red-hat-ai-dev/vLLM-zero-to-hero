#!/bin/sh
set -eu

name="vllm-zero-to-hero"
volume="vllm-models"

if [ "$#" -gt 1 ]; then
  echo "Usage: ./run.sh [nvidia|amd|intel]" >&2
  exit 1
fi

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

if ! command -v curl >/dev/null 2>&1; then
  echo "curl is required." >&2
  exit 1
fi

if "$engine" container inspect "$name" >/dev/null 2>&1; then
  echo "$name already exists. Run ./stop.sh first." >&2
  exit 1
fi

if [ "$#" -eq 1 ]; then
  accelerator="$1"
elif command -v nvidia-smi >/dev/null 2>&1 || [ -e /dev/nvidiactl ]; then
  accelerator="nvidia"
elif [ -e /dev/kfd ]; then
  accelerator="amd"
else
  accelerator=""
  for vendor_file in /sys/class/drm/card*/device/vendor; do
    [ -r "$vendor_file" ] || continue
    if [ "$(cat "$vendor_file")" = "0x8086" ]; then
      accelerator="intel"
      break
    fi
  done
fi

if [ -z "$accelerator" ]; then
  echo "No supported accelerator is visible." >&2
  echo "Configure accelerator passthrough for Docker or Podman, then try again." >&2
  echo "You can override detection with ./run.sh nvidia|amd|intel." >&2
  exit 1
fi

echo "Detected accelerator: $accelerator"

case "$accelerator" in
  nvidia)
    image="ghcr.io/red-hat-ai-dev/vllm-zero-to-hero:cuda"
    if [ "$engine" = "podman" ]; then
      set -- --device nvidia.com/gpu=all
    else
      set -- --gpus all
    fi
    ;;
  amd)
    image="ghcr.io/red-hat-ai-dev/vllm-zero-to-hero:rocm"
    set -- --device /dev/kfd --device /dev/dri --group-add video \
      --cap-add SYS_PTRACE --security-opt seccomp=unconfined
    ;;
  intel)
    image="ghcr.io/red-hat-ai-dev/vllm-zero-to-hero:xpu"
    set -- --device /dev/dri:/dev/dri \
      -v /dev/dri/by-path:/dev/dri/by-path --privileged
    ;;
  *)
    echo "Unknown accelerator: $accelerator" >&2
    echo "Usage: ./run.sh [nvidia|amd|intel]" >&2
    exit 1
    ;;
esac

"$engine" run -d --name "$name" "$@" --ipc=host -p 8000:8000 \
  -v "$volume:/root/.cache/huggingface" "$image"

attempt=0
printf "Waiting for vLLM"
until curl --fail --silent http://localhost:8000/v1/models >/dev/null 2>&1; do
  attempt=$((attempt + 1))
  if [ "$attempt" -ge 120 ]; then
    echo
    echo "vLLM did not become ready within 10 minutes." >&2
    echo "Read the logs with: $engine logs $name" >&2
    exit 1
  fi
  printf "."
  sleep 5
done
echo
echo "vLLM is ready at http://localhost:8000/v1"
