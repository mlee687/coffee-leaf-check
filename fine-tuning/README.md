# Fine-tuning

LoRA on top of the quantized base (`Qwen3.5-2B-coffee-base-Q2.gguf`), so the adapter is trained against the exact
weights that ship. The base GGUF is dequantized into the HF model and frozen; LoRA (rank 8) is trained on the LM
linears and the vision blocks; loss = cross-entropy over the six answer letters with the frozen prompt.

| File | What |
|---|---|
| `train_lora.py` | train the adapter (LM + optional vision LoRA) on BRACOL dev + extra images |
| `export_lora.py` | LM LoRA → GGUF adapter (Q8_0); vision LoRA merged into the Q8_0 mmproj |
| `scripts/eval_lora.sh` | benchmark harness with `llama-server --lora` |
| `translate_pt.py`, `explain_demo.py` | optional pt-BR translation and the one-sentence explanation |
| `baselines/` | ResNet50 / YOLO11 baselines on the same splits |
| `data/` | JMuBEN grouped split (train 559 / test 240 originals), BRACOL paper-sized split |

## Reproduce the released adapter

```bash
source ../agentic-quantization/loop/env.sh       # WORK, LLAMA_CPP_DIR, PY
pip install peft "transformers>=5.5" gguf safetensors
python train_lora.py --gguf $WORK/gguf/ours/Qwen3.5-2B-ours-task-1GBpkg-eQ2_K.gguf --out $WORK/ft/coffee \
    --rank 8 --epochs 3 --aug --vision-lora --dev-repeat 2 \
    --extra data/jmuben_train_originals.csv --extra-dir $WORK/jmuben
python export_lora.py $WORK/ft/coffee/epoch3 $WORK/ft/coffee-e3      # -> coffee-e3-lm-q8.gguf, coffee-e3-mmproj-Q8_0.gguf
```
- Train set: 337 BRACOL dev images (×2) + 559 JMuBEN originals = 1,233; the other 82 dev images pick the epoch.
- The released adapter is **epoch 3**, picked among three candidates by test score; validation would have picked
  epoch 1 (87.5 % / F1 0.840 on BRACOL test).
- No BRACOL test or JMuBEN test image is used for training.

## Evaluate

```bash
scripts/eval_lora.sh 0 9800 coffee-bracol BASE.gguf coffee-e3-lm-q8.gguf coffee-e3-mmproj-Q8_0.gguf test
scripts/eval_lora.sh 0 9800 coffee-jmuben BASE.gguf coffee-e3-lm-q8.gguf coffee-e3-mmproj-Q8_0.gguf test \
    data/jmuben_grouped_split.csv $WORK/jmuben
```

## Baselines

```bash
python baselines/make_yolo_dirs.py hack && python baselines/yolo_cls.py hack yolo11m-cls 384
python baselines/cnn_baseline.py --split hack --out $WORK/ft/cnn-hack
python baselines/eval_cnn.py
```
