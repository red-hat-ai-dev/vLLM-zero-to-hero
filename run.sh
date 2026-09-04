#!/bin/sh
set -eu

name="vllm-zero-to-hero"
volume="vllm-models"

if [ "$#" -ne 1 ]; then
  echo "Usage: ./run.sh nvidia|amd|intel" >&2
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

if "$engine" container inspect "$name" >/dev/null 2>&1; then
  echo "$name already exists. Run ./stop.sh first." >&2
  exit 1
fi

case "$1" in
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
    echo "Unknown accelerator: $1" >&2
    echo "Usage: ./run.sh nvidia|amd|intel" >&2
    exit 1
    ;;
esac

"$engine" run -d --name "$name" "$@" --ipc=host -p 8000:8000 \
  -v "$volume:/root/.cache/huggingface" "$image"

echo "vLLM is starting. Run ./request.sh to wait for it and send a request."

