# Behind the scenes

The launcher runs an OpenAI-compatible vLLM server. Its core command is:

```bash
vllm serve Qwen/Qwen3.5-2B
```

The project image sets that command as its entry point and adds these defaults:

```bash
vllm serve Qwen/Qwen3.5-2B \
  --host 0.0.0.0 \
  --port 8000 \
  --served-model-name qwen3.5-2b \
  --max-model-len 8192
```

## Launcher

`run.sh` detects Podman or Docker. Set `ENGINE` to select one:

```bash
ENGINE=docker ./run.sh nvidia
```

```bash
ENGINE=podman ./run.sh amd
```

The launcher maps port 8000, shares host memory, and mounts the `vllm-models` volume at the Hugging Face cache path.

### NVIDIA

Docker passes the accelerator with:

```bash
--gpus all
```

Podman uses the NVIDIA Container Device Interface:

```bash
--device nvidia.com/gpu=all
```

### AMD

ROCm uses the Linux kernel device nodes and the video group:

```bash
--device /dev/kfd \
--device /dev/dri \
--group-add video \
--cap-add SYS_PTRACE \
--security-opt seccomp=unconfined
```

### Intel

XPU uses the Direct Rendering Infrastructure devices:

```bash
--device /dev/dri:/dev/dri \
-v /dev/dri/by-path:/dev/dri/by-path \
--privileged
```

Consult the [vLLM installation guide](https://docs.vllm.ai/en/latest/getting_started/installation/) for supported devices, Apple Silicon, Google TPU, CPU, and hardware plugins.

## Images

The GitHub Actions workflow publishes three image tags:

| Tag | vLLM base image |
| --- | --- |
| `cuda` | `vllm/vllm-openai:v0.28.0` |
| `rocm` | `vllm/vllm-openai-rocm:v0.28.0` |
| `xpu` | `vllm/vllm-openai-xpu:v0.28.0` |

Build a CUDA image:

```bash
docker build -t vllm-zero-to-hero:cuda .
```

Build a ROCm image:

```bash
docker build \
  --build-arg VLLM_IMAGE=docker.io/vllm/vllm-openai-rocm:v0.28.0 \
  -t vllm-zero-to-hero:rocm .
```

Build an XPU image:

```bash
docker build \
  --build-arg VLLM_IMAGE=docker.io/vllm/vllm-openai-xpu:v0.28.0 \
  -t vllm-zero-to-hero:xpu .
```

## Models

The image does not contain model weights. vLLM downloads the public example model on first use and stores it in the mounted cache.

Pass a model and its options after the image name to replace the defaults:

```bash
docker run --rm --gpus all --ipc=host -p 8000:8000 \
  -v vllm-models:/root/.cache/huggingface \
  ghcr.io/red-hat-ai-dev/vllm-zero-to-hero:cuda \
  Qwen/Qwen3.5-4B --served-model-name qwen3.5-4b
```

Set `HF_TOKEN` for a gated model. Review the model license before use. Qwen3.5-2B uses the Apache-2.0 license. Its details are in the [model card](https://huggingface.co/Qwen/Qwen3.5-2B).
