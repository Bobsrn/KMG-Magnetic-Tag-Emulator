#!/usr/bin/env python3
"""Export Static/Dynamic online trial data and descriptive summaries."""
from pathlib import Path
import numpy as np
import pandas as pd
from scipy.io import loadmat

ROOT = Path(__file__).resolve().parents[1]
MODELS = ["QDA", "SVM", "kNN", "NN", "DNN"]
GESTURES = {
    1: "Grasp and Release",
    2: "Wrist Flexion/Extension",
    3: "Fourth and Fifth Fingers",
    4: "Tripod Pinch",
}
CT_THRESHOLD_S = 1.125

rows = []
for protocol in ("Static", "Dynamic"):
    folder = ROOT / "data" / "online" / protocol.lower()
    for model in MODELS:
        mat = loadmat(folder / f"{model}.mat", squeeze_me=True, struct_as_record=False)
        for gid, gesture in GESTURES.items():
            rt = mat[f"RTtest{gid}"]
            st = np.ravel(rt.timeST).astype(float)
            ct = np.ravel(rt.timeCT).astype(float)
            acc = np.ravel(rt.ACC).astype(float)
            n = min(len(st), len(ct), len(acc), 10)
            if n != 10:
                raise RuntimeError(f"Expected 10 trials: {protocol}, {model}, gesture {gid}")
            for trial in range(n):
                rows.append({
                    "Protocol": protocol,
                    "Model": model,
                    "GestureID": gid,
                    "Gesture": gesture,
                    "Trial": trial + 1,
                    "ST_s": st[trial],
                    "CT_s": ct[trial],
                    "RTA_pct": 100.0 * acc[trial],
                    "Completion": int(ct[trial] <= CT_THRESHOLD_S),
                })

df = pd.DataFrame(rows)
out = ROOT / "data" / "processed"
out.mkdir(parents=True, exist_ok=True)
df.to_csv(out / "online_trials.csv", index=False, float_format="%.9f")

for protocol in ("Static", "Dynamic"):
    summary = []
    for model in MODELS:
        x = df[(df.Protocol == protocol) & (df.Model == model)]
        summary.append({
            "Model": model,
            "N_trials": len(x),
            "ST_mean_s": x.ST_s.mean(),
            "ST_sd_s": x.ST_s.std(ddof=1),
            "CT_mean_s": x.CT_s.mean(),
            "CT_sd_s": x.CT_s.std(ddof=1),
            "RTA_mean_pct": x.RTA_pct.mean(),
            "RTA_sd_pct": x.RTA_pct.std(ddof=1),
            "CR_pct": 100.0 * x.Completion.mean(),
        })
    pd.DataFrame(summary).to_csv(
        out / f"{protocol.lower()}_summary.csv", index=False, float_format="%.6f"
    )

print(f"Exported {len(df)} online trial rows to {out}")
