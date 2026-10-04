#!/usr/bin/env python3
"""Export the DNN limb-position-effect trial data and pooled summaries."""
from pathlib import Path
import numpy as np
import pandas as pd
from scipy.io import loadmat

ROOT = Path(__file__).resolve().parents[1]
SOURCE = ROOT / "data" / "lpe" / "DNN_LPE.mat"
OUTPUT = ROOT / "data" / "processed"

# Historical MATLAB variable names encode the nominal baseline-shift magnitude.
CONDITIONS = [
    ("TestResults_conv_0", 0.0),
    ("TestResults_conv_15", 1.5),
    ("TestResults_conv_25", 2.5),
    ("TestResults_conv_5", 5.0),
    ("TestResults_conv_6", 6.0),
    ("TestResults_conv_75", 7.5),
]

GESTURES = {
    1: "Grasp and Release",
    2: "Wrist Flexion/Extension",
    3: "Fourth and Fifth Fingers",
    4: "Tripod Pinch",
}
CT_THRESHOLD_S = 1.125

mat = loadmat(SOURCE, simplify_cells=True)
rows = []

for condition_id, (block_name, shift_mm) in enumerate(CONDITIONS, start=1):
    result = mat[block_name]
    gesture_cells = result["RTtest"]["pc"]

    for gesture_id in range(1, 5):
        trial_data = gesture_cells[gesture_id - 1]
        st = np.asarray(trial_data["timeST"], dtype=float).reshape(-1)
        ct = np.asarray(trial_data["timeCT"], dtype=float).reshape(-1)
        rta = 100.0 * np.asarray(trial_data["ACC"], dtype=float).reshape(-1)
        if not (len(st) == len(ct) == len(rta) == 10):
            raise RuntimeError(
                f"Expected 10 trials in {block_name}, gesture {gesture_id}"
            )

        for trial, (st_i, ct_i, rta_i) in enumerate(zip(st, ct, rta), start=1):
            rows.append(
                {
                    "ConditionID": condition_id,
                    "BaselineShift_mm": shift_mm,
                    "SourceVariable": block_name,
                    "GestureID": gesture_id,
                    "Gesture": GESTURES[gesture_id],
                    "Trial": trial,
                    "ST_s": st_i,
                    "CT_s": ct_i,
                    "RTA_pct": rta_i,
                    "Completion": int(ct_i <= CT_THRESHOLD_S),
                }
            )

df = pd.DataFrame(rows)
OUTPUT.mkdir(parents=True, exist_ok=True)
df.to_csv(OUTPUT / "lpe_trials.csv", index=False, float_format="%.9f")

pooled = (
    df.groupby(["GestureID", "Gesture"], as_index=False)
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
pooled.to_csv(OUTPUT / "lpe_summary.csv", index=False, float_format="%.6f")

by_condition = (
    df.groupby(["ConditionID", "BaselineShift_mm", "GestureID", "Gesture"], as_index=False)
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
by_condition.to_csv(
    OUTPUT / "lpe_condition_summary.csv", index=False, float_format="%.6f"
)

print(f"Exported {len(df)} LPE trial rows to {OUTPUT}")
