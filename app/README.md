# App

Offline Android app for the coffee-leaf checker: llama.cpp `llama-server` in Termux, and one
static web page it serves (`--path`), so page and model share an origin and everything works in
airplane mode. No external scripts, fonts or styles.

| File | What |
|---|---|
| `index.html`, `app.js` | camera → resize → request → letter probabilities → decision → answer card |
| `config.json` | model, mmproj, LoRA, prompt path, tau, context, threads, languages. A model swap edits only this |
| `cards.json` | the six answer cards (A–E + not sure) in pt-BR, en, sw. The model never writes card text |
| `run_phone.sh` | Termux launcher; reads paths, `-c`, `-t` and port from `config.json` |
| `tools/make_voice.py` | records each card once with ElevenLabs into `audio/<lang>/<card>.mp3` |
| `manifest.json`, `icon-*.png` | "Add to Home screen" → opens full screen without the address bar |

## Run

    # model package (private HF repo) into app/models/coffee-leaf-check/
    hf download uchaan/coffee-leaf-check-qwen3.5-2b-gguf --local-dir app/models/coffee-leaf-check

    # desktop, any machine with llama.cpp:   bash app/run_phone.sh  →  http://127.0.0.1:8080/
    # desktop, no model:                     python3 -m http.server 8765 (in app/) → http://127.0.0.1:8765/?mock

Phone (Termux, from F-Droid or GitHub, not the Play Store):

    pkg upgrade            # required: without it llama-server fails to link (__hash_memory missing)
    pkg install llama-cpp jq
    termux-wake-lock       # and set Termux battery use to Unrestricted, or Android kills the server
    cd ~/app && bash run_phone.sh

Then open `http://127.0.0.1:8080/` in Chrome, ⋮ → Add to Home screen.

## Request (matches the package protocol)

- Prompt from `prompt.txt` (`### system`, `### user`, `### grammar`), word for word.
- Longest side 512 px, JPEG quality 0.9, base64 data URL; image before the user text.
- `POST /v1/chat/completions`, `max_tokens 1`, temperature 1.0, top_k 0, top_p 1.0, min_p 0,
  `logprobs`/`top_logprobs 6`, `n_probs 6`, `post_sampling_probs true`,
  `chat_template_kwargs: {enable_thinking: false}`.
- Answer = letter with the highest returned probability; the sampled token is ignored.
- Not sure = top letter F, or its probability < tau → card "not sure", photo saved to the queue.
- Result shows "provável" / "muito provável" (≥ `very_likely`, default 0.8), not a percentage.

Findings from running it (llama.cpp 0.5.0 / b11146, placeholder Unsloth 0.8B):

- **Thinking is ON by default** in the Qwen3.5 template; `enable_thinking: false` makes it pre-fill
  an empty `<think></think>`. The benchmark harness must send it too.
- **`top_probs` are not restricted to the grammar**: they include `<think>`, `G`, `**`, empty
  tokens. With 6 slots a low letter can drop out (reads as 0), and the letters sum to < 1. The top
  letter is unaffected; tau is applied to the raw probability. Harness and app must agree on this.
- The sampled token often differs from the top letter, so reading probabilities matters.

## Measured

| Where | Model | Per photo | Peak RSS |
|---|---|---|---|
| Mac M4 Pro (Metal) | placeholder 0.8B Q4_K_M + F16 mmproj | ~0.7 s | – |
| Android emulator, **3 GB RAM, 4 cores**, airplane mode | same | 2.9–4.7 s | **1.04 GB** (1.2 GB free) |
| Galaxy Z Flip5 (SM-F731U1, SD 8 Gen 2, 7 GB) | final package | to do | to do |

The emulator shows **fit in 3 GB**, not budget-phone speed: its cores are the host Mac's.

## Voice

Every possible answer is one of six fixed cards, so each is recorded once with ElevenLabs
(`tools/make_voice.py`, model `eleven_v4`) and shipped as ~1 MB of MP3s. The app never calls
ElevenLabs. Fallback, all offline: no clip → the phone's own text-to-speech (`pt-BR`/`en-US`)
→ if the phone has no voice for the language, a short message. Never an English voice reading
Portuguese.

## Not done

- Sending the queue (stub).
- The optional one-sentence explanation + translator (package `translate/`).
- Native-speaker check of the pt-BR cards (replace with the package's `translate_pt.py` CARDS).
