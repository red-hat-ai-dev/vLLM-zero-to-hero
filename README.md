# vLLM Zero to Hero

Start an OpenAI-compatible AI API on your accelerator. (Full details in [BEHIND_THE_SCENES](https://github.com/red-hat-ai-dev/vLLM-zero-to-hero/blob/main/BEHIND_THE_SCENES.md))

## Requirements

- Linux
- Docker or Podman
- A supported NVIDIA, AMD, or Intel accelerator
- 8 GB of free device memory
- Internet access for the first model download

## 1. Clone

```bash
git clone https://github.com/red-hat-ai-dev/vLLM-zero-to-hero.git
cd vLLM-zero-to-hero
```

## 2. Start vLLM

Choose your accelerator:

```bash
./run.sh nvidia
```

```bash
./run.sh amd
```

```bash
./run.sh intel
```

The first start downloads Qwen3.5-2B from Hugging Face. The script stores the model in a container volume for later runs.

## 3. Send a request

```bash
./request.sh
```

The response comes from an OpenAI-compatible endpoint at `http://localhost:8000/v1`.

## Stop

```bash
./stop.sh
```

Read [Behind the scenes](BEHIND_THE_SCENES.md) for the `vllm serve` command, container flags, image builds, and model options.
