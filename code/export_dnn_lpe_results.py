#!/usr/bin/env python3
"""Export compact-DNN LPE results for PC and main-board implementations."""
from pathlib import Path
import numpy as np
import pandas as pd
from scipy.io import loadmat
from scipy.stats import wilcoxon, binomtest, rankdata

ROOT = Path(__file__).resolve().parents[1]
SOURCE = ROOT / "data" / "lpe" / "dnn_lpe_pc_mainboard.mat"
OUT = ROOT / "data" / "processed"
OUT.mkdir(parents=True, exist_ok=True)

CONDITIONS = ["0", "15", "25", "5", "6", "75"]
GESTURES = {
    1: "Grasp and Release",
    2: "Wrist Flexion/Extension",
    3: "Fourth and Fifth Fingers",
    4: "Tripod Pinch",
}
CT_THRESHOLD_S = 1.125

mat = loadmat(SOURCE, squeeze_me=True, struct_as_record=False)
rows = []
for cid, code in enumerate(CONDITIONS, start=1):
    tr = mat[f"TestResults_mlp_{code}"]
    for gid, gesture in GESTURES.items():
        for hw in ("pc", "mb"):
            d = np.atleast_1d(getattr(tr.RTtest, hw))[gid - 1]
            st = np.ravel(d.timeST).astype(float)[:10]
            ct = np.ravel(d.timeCT).astype(float)[:10]
            rta = 100.0 * np.ravel(d.ACC).astype(float)[:10]
            if not (len(st) == len(ct) == len(rta) == 10):
                raise RuntimeError(f"Expected 10 trials: condition {code}, gesture {gid}, {hw}")
            for trial, (st_i, ct_i, rta_i) in enumerate(zip(st, ct, rta), start=1):
                rows.append({
                    "ConditionID": cid,
                    "SourceCondition": code,
                    "GestureID": gid,
                    "Gesture": gesture,
                    "Trial": trial,
                    "Hardware": "PC" if hw == "pc" else "MainBoard",
                    "ST_s": st_i,
                    "CT_s": ct_i,
                    "RTA_pct": rta_i,
                    "Completion": int(ct_i < CT_THRESHOLD_S),
                })

df = pd.DataFrame(rows)
df.to_csv(OUT / "dnn_lpe_trials.csv", index=False, float_format="%.9f")

# Table V: DNN on PC, pooled over recorded LPE conditions.
pc = df[df.Hardware == "PC"]
table_v = (
    pc.groupby(["GestureID", "Gesture"], as_index=False)
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
table_v.to_csv(OUT / "table_v_dnn_lpe_pc.csv", index=False, float_format="%.6f")

# Table VI: pooled PC/MainBoard implementation comparison.
table_vi = (
    df.groupby("Hardware", as_index=False)
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
table_vi["Hardware"] = pd.Categorical(table_vi["Hardware"], ["PC", "MainBoard"], ordered=True)
table_vi = table_vi.sort_values("Hardware").reset_index(drop=True)
table_vi["Hardware"] = table_vi["Hardware"].astype(str)
table_vi.to_csv(OUT / "table_vi_dnn_pc_mainboard.csv", index=False, float_format="%.6f")

# Condition-level descriptives.
condition_summary = (
    df.groupby(["Hardware", "ConditionID", "SourceCondition", "GestureID", "Gesture"], as_index=False)
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
condition_summary.to_csv(OUT / "dnn_lpe_condition_summary.csv", index=False, float_format="%.6f")

# Paired PC vs main-board tests.
keys = ["ConditionID", "GestureID", "Trial"]
p = df[df.Hardware == "PC"].sort_values(keys).reset_index(drop=True)
b = df[df.Hardware == "MainBoard"].sort_values(keys).reset_index(drop=True)
if not p[keys].equals(b[keys]):
    raise RuntimeError("PC and main-board trial keys do not align")

stats_rows = []
raw_p = []
for metric in ("ST_s", "CT_s", "RTA_pct"):
    x = p[metric].to_numpy(float)
    y = b[metric].to_numpy(float)
    res = wilcoxon(y, x, alternative="two-sided", zero_method="wilcox", method="auto")
    diff = y - x
    nz = diff != 0
    ranks = rankdata(np.abs(diff[nz]), method="average")
    w_plus = ranks[diff[nz] > 0].sum()
    w_minus = ranks[diff[nz] < 0].sum()
    rbc = (w_plus - w_minus) / (w_plus + w_minus)
    raw_p.append(res.pvalue)
    stats_rows.append({
        "Metric": metric,
        "Test": "Wilcoxon signed-rank",
        "N_pairs": len(x),
        "PC_mean": x.mean(),
        "MainBoard_mean": y.mean(),
        "Mean_difference_MainBoard_minus_PC": diff.mean(),
        "Median_difference_MainBoard_minus_PC": np.median(diff),
        "Statistic": res.statistic,
        "P_raw": res.pvalue,
        "Effect_size": rbc,
        "Effect_size_name": "matched rank-biserial correlation",
    })

pc_success = p.Completion.to_numpy(bool)
mb_success = b.Completion.to_numpy(bool)
pc_only = int(np.sum(pc_success & ~mb_success))
mb_only = int(np.sum(~pc_success & mb_success))
discordant = pc_only + mb_only
mcnemar_p = 1.0 if discordant == 0 else binomtest(
    min(pc_only, mb_only), n=discordant, p=0.5, alternative="two-sided"
).pvalue
raw_p.append(mcnemar_p)
stats_rows.append({
    "Metric": "CR",
    "Test": "Exact McNemar",
    "N_pairs": len(p),
    "PC_mean": 100.0 * pc_success.mean(),
    "MainBoard_mean": 100.0 * mb_success.mean(),
    "Mean_difference_MainBoard_minus_PC": 100.0 * (mb_success.mean() - pc_success.mean()),
    "Median_difference_MainBoard_minus_PC": np.nan,
    "Statistic": discordant,
    "P_raw": mcnemar_p,
    "Effect_size": np.nan,
    "Effect_size_name": "",
    "PC_only_successes": pc_only,
    "MainBoard_only_successes": mb_only,
})

# Holm adjustment across ST, CT, RTA, CR.
order = np.argsort(raw_p)
adj = np.empty(len(raw_p))
running = 0.0
for rank, idx in enumerate(order):
    val = (len(raw_p) - rank) * raw_p[idx]
    running = max(running, val)
    adj[idx] = min(running, 1.0)
for row, p_adj in zip(stats_rows, adj):
    row["P_Holm"] = p_adj
pd.DataFrame(stats_rows).to_csv(
    OUT / "dnn_pc_mainboard_paired_statistics.csv", index=False, float_format="%.9g"
)

# Synchronized prediction-stream agreement.
actual, pc_pred, mb_pred = [], [], []
for code in CONDITIONS:
    tr = mat[f"TestResults_mlp_{code}"]
    a = np.ravel(tr.net_actual)
    p0 = np.ravel(tr.net_pred)
    m0 = np.ravel(tr.net_main_pred)
    n = min(len(a), len(p0), len(m0))
    actual.append(a[:n]); pc_pred.append(p0[:n]); mb_pred.append(m0[:n])
actual = np.concatenate(actual)
pc_pred = np.concatenate(pc_pred)
mb_pred = np.concatenate(mb_pred)
agreement = pd.DataFrame([{
    "N_synchronized_predictions": len(actual),
    "PC_vs_actual_pct": 100.0 * np.mean(pc_pred == actual),
    "MainBoard_vs_actual_pct": 100.0 * np.mean(mb_pred == actual),
    "PC_vs_MainBoard_agreement_pct": 100.0 * np.mean(pc_pred == mb_pred),
}])
agreement.to_csv(OUT / "dnn_prediction_agreement.csv", index=False, float_format="%.6f")

print(f"Exported {len(df)} DNN LPE hardware-trial rows to {OUT}")
