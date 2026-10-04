#!/usr/bin/env python3
"""Export trial-level and summary CSV files for the Static/Dynamic online tests."""
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
            if not (len(st) == len(ct) == len(acc) == 10):
                raise RuntimeError(
                    f"Expected 10 trials: {protocol}, {model}, gesture {gid}"
                )
            for trial, (st_i, ct_i, acc_i) in enumerate(zip(st, ct, acc), start=1):
                rows.append(
                    {
                        "Protocol": protocol,
                        "Model": model,
                        "GestureID": gid,
                        "Gesture": gesture,
                        "Trial": trial,
                        "ST_s": st_i,
                        "CT_s": ct_i,
                        "RTA_pct": 100.0 * acc_i,
                        "Completion": int(ct_i <= CT_THRESHOLD_S),
                    }
                )

df = pd.DataFrame(rows)
out = ROOT / "data" / "processed"
out.mkdir(parents=True, exist_ok=True)
df.to_csv(out / "online_trials.csv", index=False, float_format="%.9f")

for protocol in ("Static", "Dynamic"):
    summary = []
    for model in MODELS:
        x = df[(df.Protocol == protocol) & (df.Model == model)]
        summary.append(
            {
                "Model": model,
                "ST_mean_s": x.ST_s.mean(),
                "ST_sd_s": x.ST_s.std(ddof=1),
                "CT_mean_s": x.CT_s.mean(),
                "CT_sd_s": x.CT_s.std(ddof=1),
                "RTA_mean_pct": x.RTA_pct.mean(),
                "RTA_sd_pct": x.RTA_pct.std(ddof=1),
                "CR_pct": 100.0 * x.Completion.mean(),
                "N_trials": len(x),
            }
        )
    pd.DataFrame(summary).to_csv(
        out / f"{protocol.lower()}_summary.csv", index=False, float_format="%.6f"
    )

# Gesture-level descriptive summary
gesture_summary = (
    df.groupby(["Protocol", "Model", "GestureID", "Gesture"], as_index=False)
    .agg(
        N_trials=("Trial", "count"),
        ST_mean_s=("ST_s", "mean"),
        ST_sd_s=("ST_s", "std"),
        CT_mean_s=("CT_s", "mean"),
        CT_sd_s=("CT_s", "std"),
        RTA_mean_pct=("RTA_pct", "mean"),
        RTA_sd_pct=("RTA_pct", "std"),
        CR_pct=("Completion", lambda x: 100.0 * x.mean()),
    )
)
gesture_summary.to_csv(
    out / "gesture_level_summary.csv", index=False, float_format="%.6f"
)

print(f"Exported {len(df)} online trial rows to {out}")
