# vLLM Zero to Hero

Run an OpenAI-compatible vLLM API on a supported accelerator. Qwen3.5-2B is the default example. The first run downloads its weights from Hugging Face.

At the center of this project is one command:

```bash
vllm serve Qwen/Qwen3.5-2B
```

The container supplies vLLM and the dependencies for your accelerator.

## Container requirements

- Linux
- 8 GB of free device memory
- Docker or Podman
- Supported NVIDIA, AMD, or Intel accelerator with its container runtime configured
- Internet access and about 5 GB of free disk space for the model download

Check the [vLLM hardware documentation](https://docs.vllm.ai/en/latest/getting_started/installation/) for device requirements. Windows users need a Linux environment with GPU passthrough.

## Clone

```bash
git clone https://github.com/red-hat-ai-dev/vLLM-zero-to-hero.git
cd vLLM-zero-to-hero
```

## NVIDIA

Docker:

```bash
docker run --rm --gpus all --ipc=host -p 8000:8000 \
  -v vllm-models:/root/.cache/huggingface \
  ghcr.io/red-hat-ai-dev/vllm-zero-to-hero:cuda
```

Podman:

```bash
podman run --rm --device nvidia.com/gpu=all --ipc=host -p 8000:8000 \
  -v vllm-models:/root/.cache/huggingface \
  ghcr.io/red-hat-ai-dev/vllm-zero-to-hero:cuda
```

## AMD ROCm

Docker or Podman:

```bash
podman run --rm --device /dev/kfd --device /dev/dri \
  --group-add video --cap-add SYS_PTRACE \
  --security-opt seccomp=unconfined --ipc=host -p 8000:8000 \
  -v vllm-models:/root/.cache/huggingface \
  ghcr.io/red-hat-ai-dev/vllm-zero-to-hero:rocm
```

Use `docker` in place of `podman` when needed.

## Intel XPU

Docker or Podman:

```bash
podman run --rm --device /dev/dri:/dev/dri \
  -v /dev/dri/by-path:/dev/dri/by-path \
  --privileged --ipc=host -p 8000:8000 \
  -v vllm-models:/root/.cache/huggingface \
  ghcr.io/red-hat-ai-dev/vllm-zero-to-hero:xpu
```

Use `docker` in place of `podman` when needed.

## Other hardware

Install the vLLM backend for your platform, then run:

```bash
vllm serve Qwen/Qwen3.5-2B \
  --served-model-name qwen3.5-2b \
  --max-model-len 8192
```

See the [vLLM installation guide](https://docs.vllm.ai/en/latest/getting_started/installation/) for Apple Silicon, Google TPU, CPU, and hardware plugins.

## Send a request

Wait for the server to report that startup is complete.

```bash
curl http://localhost:8000/v1/chat/completions \
  -H 'Content-Type: application/json' \
  -d '{
    "model": "qwen3.5-2b",
    "messages": [{"role": "user", "content": "Explain containers in three sentences."}]
  }'
```

List the available model:

```bash
curl http://localhost:8000/v1/models
```

Stop the foreground server with `Ctrl+C`.

## Build

CUDA:

```bash
docker build -t vllm-zero-to-hero:cuda .
```

ROCm:

```bash
docker build \
  --build-arg VLLM_IMAGE=docker.io/vllm/vllm-openai-rocm:v0.28.0 \
  -t vllm-zero-to-hero:rocm .
```

Intel XPU:

```bash
docker build \
  --build-arg VLLM_IMAGE=docker.io/vllm/vllm-openai-xpu:v0.28.0 \
  -t vllm-zero-to-hero:xpu .
```

Pass another model and its server options after the image name:

```bash
docker run --rm --gpus all --ipc=host -p 8000:8000 \
  -v vllm-models:/root/.cache/huggingface \
  ghcr.io/red-hat-ai-dev/vllm-zero-to-hero:cuda \
  Qwen/Qwen3.5-4B --served-model-name qwen3.5-4b
```

Set `HF_TOKEN` for a gated model. Review the model license before use.

## Image contents

- vLLM 0.28.0
- OpenAI-compatible API on port 8000
- CUDA, ROCm, and XPU image variants

The example uses Qwen3.5-2B under Apache-2.0. Review its [model card](https://huggingface.co/Qwen/Qwen3.5-2B) before use.
