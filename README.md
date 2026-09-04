# vLLM Zero to Hero

Run an OpenAI-compatible vLLM API with one container. Qwen3.5-2B is the default example. The first run downloads its weights from Hugging Face.

## Requirements

- Linux
- 8 GB of free GPU memory
- Docker or Podman
- NVIDIA GPU with a working NVIDIA Container Toolkit, or AMD GPU with ROCm support
- Internet access and about 5 GB of free disk space for the model download

Windows users need a Linux environment with GPU passthrough. A Podman machine on WSL does not expose an AMD GPU. For AMD on Windows, use a supported WSL distribution and follow the [ROCm WSL container setup](https://rocm.docs.amd.com/projects/radeon-ryzen/en/latest/docs/install/installrad/wsl/legacywsl/install-pytorch.html).

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

The example uses Qwen3.5-2B under Apache-2.0. Review its [model card](https://huggingface.co/Qwen/Qwen3.5-2B) before use.
