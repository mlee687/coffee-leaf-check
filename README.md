# Coffee Leaf Check

Offline coffee-leaf disease check on a budget Android phone. A small VLM (Qwen3.5-2B, llama.cpp) reads one leaf
photo and answers A healthy · B rust · C cercospora · D phoma · E leaf miner · F not sure.

Hack-Nation 7th Global AI Hackathon — World Bank challenge 04B.

The model was quantized by an **agentic pipeline**: give Claude Code one goal, and it plans, builds, evaluates and
iterates on its own until every size target is met. → [`agentic-quantization/`](agentic-quantization/)

| Path | What |
|---|---|
| [`agentic-quantization/`](agentic-quantization/) | agentic GGUF quantization pipeline, benchmark, results |
| [`app/`](app/) | Android app (to be added) |

## Model

[Qwen/Qwen3.5-2B](https://huggingface.co/Qwen/Qwen3.5-2B) quantized to 2.66 bpw GGUF, plus a coffee LoRA adapter and a fine-tuned
vision projector. Package **1.01 GB** (1.09 GB with the optional pt-BR translator).

| File | Size | bpw |
|---|---:|---:|
| `Qwen3.5-2B-coffee-base-Q2.gguf` (language model) | 0.638 GB | 2.66 |
| `mmproj-Qwen3.5-2B-coffee-Q8_0.gguf` (vision projector) | 0.362 GB | 8.73 |
| `Qwen3.5-2B-coffee-lora-Q8_0.gguf` (LoRA adapter) | 0.013 GB | 12.89 |

```
llama-server -m Qwen3.5-2B-coffee-base-Q2.gguf --mmproj mmproj-Qwen3.5-2B-coffee-Q8_0.gguf \
  --lora Qwen3.5-2B-coffee-lora-Q8_0.gguf --jinja -c 8192
```

## Results

Five classes (healthy, rust, brown eye spot, phoma, leaf miner); accuracy / macro-F1.

| Model | Package | LM bpw | BRACOL test (1,266) | JMuBEN held-out (240) |
|---|---:|---:|---|---|
| **This package** (base Q2 + LoRA + fine-tuned projector) | 1.01 GB | 2.66 | **90.8 % / 0.880** | **98.3 % / 0.984** |
| Qwen3.5-2B BF16, no fine-tuning | 4.26 GB | 16.0 | 60.9 % / 0.584 | |
| ResNet50, same training data | 0.09 GB | – | 88.5 % | 99.2 % |
| YOLO11m-cls, same training data | 0.02 GB | – | 88.5 % | 97.9 % |

**Quantization alone** (no adapter) vs the smallest Unsloth file:

| Benchmark | Ours, base Q2 (0.64 GB, 2.66 bpw) | Unsloth UD-IQ2_XXS (0.77 GB, 3.22 bpw) |
|---|---:|---:|
| BRACOL macro-F1 | **0.578** | 0.313 |
| MMStar | **0.439** | 0.256 |
| AI2D | **0.574** | 0.248 |
| MMLU-Redux | **0.340** | 0.292 |

- No BRACOL or JMuBEN test image was used for training or selection.
- JMuBEN held-out is in-domain (rotated / flipped copies grouped so they never cross train and test): read it as
  same-dataset performance.
- On an unseen photo domain, CNNs drop to about 15–28 % F1 and this model to about 47 %.
- Fine-tuning code is not part of this repository; this repository covers the quantization.

Training data: BRACOL dev (337 train, 82 for epoch choice) + 559 JMuBEN originals.

## Credits

- Base model: [Qwen/Qwen3.5-2B](https://huggingface.co/Qwen/Qwen3.5-2B), Apache 2.0.
- BRACOL: Krohling, Esgario, Ventura (2019), Mendeley Data, [doi:10.17632/yy2k5y8mxg.1](https://doi.org/10.17632/yy2k5y8mxg.1), CC BY 4.0.
- JMuBEN / JMuBEN2: Jepkoech et al. (2021), Mendeley Data, [doi:10.17632/t2r6rszp5c.1](https://doi.org/10.17632/t2r6rszp5c.1) /
  [doi:10.17632/tgv3zb82nd.1](https://doi.org/10.17632/tgv3zb82nd.1), CC BY 4.0.
- Translator: [Helsinki-NLP/opus-mt-en-ROMANCE](https://huggingface.co/Helsinki-NLP/opus-mt-en-ROMANCE), Apache 2.0.
- [llama.cpp](https://github.com/ggml-org/llama.cpp), MIT.

Images are not included; [`manifest.csv`](agentic-quantization/manifest.csv) lists them with SHA-256 and split.
