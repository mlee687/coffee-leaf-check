# Commands

All paths are relative to `agentic-quantization/`; `source loop/env.sh` first.

## Loop control

| Command | What |
|---|---|
| `loop/start_workers.sh 0 1 2 3` | one worker per GPU (PIDs in `$WORK/workers.pid`) |
| `loop/enqueue.sh TAG TEMPLATE NSEQ "EXTRA"` | add a build job; TAG names `$WORK/gguf/ours/TAG.gguf` (put `0.8B` in the tag for the 0.8B model) |
| `loop/wait_event.sh [PATTERN] [TIMEOUT_S]` | block until new events match (default `^(DEV\|FAIL)`), print all new lines, exit; run in the background |
| `loop/status.sh [N]` | queue head, worker liveness, GPU memory, last N events |
| `loop/stop_workers.sh` / `--now` | stop after the current job / kill now by PID |

Event lines in `$WORK/logs/events.log`:
```
QUEUED <tag> template=<file> <time>
BUILD <tag> exit=<code> <seconds>s bytes=<out> template=<bytes>
FAIL <tag> build output missing or bytes != template
CHECK <tag> kld=<mean KLD vs BF16> same_top1=<%>
DEV [<tag>] dev n=419 forced_acc=… forced_macro_f1=… coarse_macro_f1=… agree_bf16=… letter_kld=… per_class=A:…,E:…
```

## Templates

```bash
export PYTHONPATH=$LLAMA_CPP_DIR/gguf-py:$PWD/quantizer
# BASE EMB BUDGET UP DOWN OUT: BASE's types, token_embd=EMB, then tensors toward UP (if under budget) or DOWN (if over)
python quantizer/plan_alloc.py $WORK/unsloth/Qwen3.5-2B-UD-IQ2_M.gguf Q2_K 638481344 \
    $WORK/unsloth/Qwen3.5-2B-UD-IQ3_XXS.gguf $WORK/unsloth/Qwen3.5-2B-UD-IQ2_XXS.gguf $WORK/plan-637-eQ2_K.txt
python quantizer/retype_template.py $WORK/unsloth/Qwen3.5-2B-UD-IQ2_M.gguf $WORK/tpl-637-eQ2_K.gguf $WORK/plan-637-eQ2_K.txt
```
`plan_alloc.py` prints the planned bytes; check them against the budget before queuing. It cannot go below DOWN's
types. Move order (up): full-attention q/k/v/o, ffn_down, ffn_gate, ffn_up, linear-attention qkv/gate/out.

## Build arguments (EXTRA)

| Variant | EXTRA |
|---|---|
| ours-general | `--tied-embd-gptq --calib-images $WORK/coco/generic_manifest.csv --image-dir $WORK/coco/gen512 --prompt-file $WORK/coco/prompt_generic_mcq.txt` |
| ours-task | `--tied-embd-gptq --calib-images manifest.csv --image-dir $WORK/bracol/dev512 --prompt-file protocol/prompt_v1.txt` |

`gptq_iq.py` reads only `split == dev` rows of the manifest. NSEQ 128 × seqlen 2048 of `$CALIB_TEXT` is the default.
A100: 2B 13–15 min and ~10 GB per build, 0.8B 5–11 min. Add `--offload-layers` on small GPUs.

## Files and numbers

```bash
python quantizer/fileinfo.py FILE.gguf          # name,bytes,bpw,tensors,sha256
python $LLAMA_CPP_DIR/gguf-py/gguf/scripts/gguf_dump.py FILE.gguf | head -40   # tensor types
```

## Test and collect (after selection only)

```bash
python benchmark/harness.py run --model Qwen3.5-2B --lm FILE --mmproj $WORK/gguf/mmproj-Qwen3.5-2B-Q8_0.gguf \
    --prompt protocol/prompt_v1.txt --split all --ref $HN04B_RUNS/bf16-2B-all/images.csv --gpu 0
python benchmark/collect.py --prompt prompt_v1 --jobs jobs.csv --out results/   # see benchmark/README.md
```
