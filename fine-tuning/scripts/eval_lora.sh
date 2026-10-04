#!/usr/bin/env bash
# usage: eval_lora.sh GPU PORT TAG BASE.gguf LORA.gguf MMPROJ.gguf [SPLIT dev|test|all] [MANIFEST DATA_ROOT]
# Harness run of a base GGUF + LoRA adapter (llama-server --lora), same prompt and scoring as the quantization benchmark.
# Default: BRACOL (manifest.csv). JMuBEN held-out: MANIFEST=fine-tuning/data/jmuben_grouped_split.csv DATA_ROOT=$WORK/jmuben (test = 240 originals).
set -uo pipefail; HERE=$(cd "$(dirname "$0")" && pwd); AQ=$HERE/../../agentic-quantization; source $AQ/loop/env.sh
GPU=$1; PORT=$2; TAG=$3; BASE=$(readlink -f $4); LORA=$(readlink -f $5); MMPROJ=$(readlink -f $6); SPLIT=${7:-all}
MAN=${8:-$AQ/manifest.csv}; ROOT=${9:-$BRACOL_ROOT}
export HN04B_SERVER_EXTRA="--lora $LORA"; cd $AQ
$PY benchmark/harness.py run --model Qwen3.5-2B --lm $BASE --mmproj $MMPROJ --prompt protocol/prompt_v1.txt \
    --manifest $(readlink -f $MAN) --data-root $ROOT --split $SPLIT --gpu $GPU --port $PORT --tag $TAG
