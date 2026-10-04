import base64, csv, json, os, requests, sys
U = "http://127.0.0.1:9899/v1/chat/completions"; H = os.environ.get("WORK", "work")                                   # data, models and outputs (see ../agentic-quantization/loop/env.example.sh)
AQ = os.path.join(os.path.dirname(os.path.abspath(__file__)), "../agentic-quantization")   # manifest, prompt, harness
DATA = os.path.join(os.path.dirname(os.path.abspath(__file__)), "data")
txt = open(f"{AQ}/protocol/prompt_v1.txt").read(); sys_t = txt.split("### system\n")[1].split("### user\n")[0].strip(); usr_t = txt.split("### user\n")[1].split("### grammar")[0].strip()
NAMES = {"A": "healthy", "B": "coffee leaf rust", "C": "brown eye spot (Cercospora)", "D": "Phoma leaf spot", "E": "leaf miner", "F": "not sure"}
rows = [r for r in csv.DictReader(open(f"{DATA}/bracol_paper_sized_split.csv")) if r["split"] == "test"]
pick = []
for c in "ABCDE": pick += [r for r in rows if r["label_letter"] == c][:1]
for r in pick:
    b64 = base64.b64encode(open(f"{H}/bracol/cache512/{r['sha256']}.jpg", "rb").read()).decode(); img = {"type": "image_url", "image_url": {"url": "data:image/jpeg;base64," + b64}}
    body = {"messages": [{"role": "system", "content": sys_t}, {"role": "user", "content": [img, {"type": "text", "text": usr_t}]}], "max_tokens": 1, "temperature": 0, "grammar": "root ::= [A-F]",
            "chat_template_kwargs": {"enable_thinking": False}}
    ans = requests.post(U, json=body).json()["choices"][0]["message"]["content"].split("</think>")[-1].strip()
    q = (f"Diagnosis: {NAMES.get(ans, ans)}. In one sentence, describe only what you can see on this leaf (colour, shape and position of any spots or damage) that is consistent with this diagnosis.")
    for sc in (0.0, 1.0):
        b2 = {"messages": [{"role": "user", "content": [img, {"type": "text", "text": q}]}], "max_tokens": 90, "temperature": 0, "chat_template_kwargs": {"enable_thinking": False}, "lora": [{"id": 0, "scale": sc}]}
        out = requests.post(U, json=b2).json()["choices"][0]["message"]["content"].split("</think>")[-1].strip().replace("\n", " ")
        print(f"[true {r['label_letter']} | pred {ans}] adapter={sc}: {out}")
