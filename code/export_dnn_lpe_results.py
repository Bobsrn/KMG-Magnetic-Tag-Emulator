#!/usr/bin/env python3
"""Export compact-DNN LPE trials, paired tests and prediction agreement.

The MAT file provides five labeled conditions and the corresponding PC
and main-board results. All displacements are in millimeters.
"""
from pathlib import Path

import numpy as np
import pandas as pd
from scipy.io import loadmat
from scipy.stats import binomtest, rankdata, wilcoxon

ROOT = Path(__file__).resolve().parents[1]
SOURCE = ROOT / "data" / "lpe" / "dnn_lpe_pc_mainboard.mat"
METADATA = ROOT / "data" / "lpe" / "condition_metadata.csv"
OUT = ROOT / "data" / "processed"
CT_THRESHOLD_S = 1.125
GESTURES = {
    1: "Grasp and Release",
    2: "Wrist Flexion/Extension",
    3: "Fourth and Fifth Fingers",
    4: "Tripod Pinch",
}


def holm_adjust(p_values):
    p_values = np.asarray(p_values, dtype=float)
    order = np.argsort(p_values)
    corrected = np.empty_like(p_values)
    running = 0.0
    for rank, ix in enumerate(order):
        running = max(running, (len(p_values) - rank) * p_values[ix])
        corrected[ix] = min(1.0, running)
    return corrected


def rank_biserial(diff):
    diff = np.asarray(diff, dtype=float)
    diff = diff[diff != 0]
    if not diff.size:
        return 0.0
    ranks = rankdata(np.abs(diff), method="average")
    return float((ranks[diff > 0].sum() - ranks[diff < 0].sum()) / ranks.sum())


def summarize(df, keys):
    summary = (
        df.groupby(keys, as_index=False, observed=True)
        .agg(
            N_trials=("Trial", "count"),
            ST_mean_s=("ST_s", "mean"),
            ST_sd_s=("ST_s", "std"),
            CT_mean_s=("CT_s", "mean"),
            CT_sd_s=("CT_s", "std"),
            RTA_mean_pct=("RTA_pct", "mean"),
            RTA_sd_pct=("RTA_pct", "std"),
            CR_pct=("Completion", lambda v: 100.0 * v.mean()),
        )
    )
    return summary


def main():
    OUT.mkdir(parents=True, exist_ok=True)
    mat = loadmat(SOURCE, squeeze_me=True, struct_as_record=False)
    metadata = pd.read_csv(METADATA).sort_values("ConditionID")
    expected_shifts = [0.0, 1.5, 3.0, 4.5, 6.0]
    if len(metadata) != 5 or not np.allclose(
        metadata["PhysicalDisplacement_mm"].to_numpy(float), expected_shifts
    ):
        raise ValueError("Condition metadata does not match the five-point LPE protocol")

    mat_vars = [name for name in mat if name.startswith("DNN_LPE_")]
    if set(mat_vars) != set(metadata["MATVariable"]):
        raise ValueError("Condition names in MAT and metadata do not match")
    if not np.allclose(np.ravel(mat["condition_shift_mm"]), expected_shifts):
        raise ValueError("Stored MAT condition shifts do not match experimental metadata")

    rows = []
    agreement_rows = []
    for _, cond in metadata.iterrows():
        varname = str(cond.MATVariable)
        block = mat[varname]
        condition_id = int(cond.ConditionID)
        physical_shift = float(cond.PhysicalDisplacement_mm)

        y = np.ravel(block.net_actual)
        pc_pred = np.ravel(block.net_pred)
        mb_pred = np.ravel(block.net_main_pred)
        if not (len(y) == len(pc_pred) == len(mb_pred)):
            raise ValueError(f"Synchronized prediction stream lengths differ for {varname}")
        agreement_rows.append({
            "ConditionID": condition_id,
            "PhysicalDisplacement_mm": physical_shift,
            "SourceCondition": varname,
            "N_synchronized_predictions": len(y),
            "PC_MB_agree": int(np.sum(pc_pred == mb_pred)),
            "PC_MB_agreement_pct": 100.0 * np.mean(pc_pred == mb_pred),
            "PC_vs_actual_pct": 100.0 * np.mean(pc_pred == y),
            "MainBoard_vs_actual_pct": 100.0 * np.mean(mb_pred == y),
        })
        for g, gesture in GESTURES.items():
            for hw, hw_label in (("pc", "PC"), ("mb", "MainBoard")):
                result = np.atleast_1d(getattr(block.RTtest, hw))[g - 1]
                st = np.ravel(result.timeST).astype(float)[:10]
                ct = np.ravel(result.timeCT).astype(float)[:10]
                rta = 100.0 * np.ravel(result.ACC).astype(float)[:10]
                if not (len(st) == len(ct) == len(rta) == 10):
                    raise ValueError(f"Expected 10 trials: {varname}/{hw}/gesture{g}")
                for trial_ix, (st_i, ct_i, rta_i) in enumerate(zip(st, ct, rta), start=1):
                    rows.append({
                        "ConditionID": condition_id,
                        "SourceCondition": varname,
                        "PhysicalDisplacement_mm": physical_shift,
                        "GestureID": g,
                        "Gesture": gesture,
                        "Trial": trial_ix,
                        "Hardware": hw_label,
                        "ST_s": st_i,
                        "CT_s": ct_i,
                        "RTA_pct": rta_i,
                        "Completion": int(ct_i <= CT_THRESHOLD_S),
                    })

    df = pd.DataFrame(rows)
    if len(df) != 400:
        raise ValueError(f"Expected 400 combined trial rows; found {len(df)}")
    df.to_csv(OUT / "dnn_lpe_trials.csv", index=False, float_format="%.9f")

    pc_df = df[df.Hardware == "PC"]
    table_v = summarize(pc_df, ["GestureID", "Gesture"])
    table_v.to_csv(OUT / "table_v_dnn_lpe_pc.csv", index=False, float_format="%.6f")

    table_vi = summarize(df, ["Hardware"])
    table_vi["Hardware"] = pd.Categorical(
        table_vi.Hardware, ["PC", "MainBoard"], ordered=True
    )
    table_vi.sort_values("Hardware", inplace=True)
    table_vi.Hardware = table_vi.Hardware.astype(str)
    table_vi.to_csv(OUT / "table_vi_dnn_pc_mainboard.csv", index=False, float_format="%.6f")

    per_condition = summarize(
        df, ["Hardware", "ConditionID", "PhysicalDisplacement_mm", "SourceCondition", "GestureID", "Gesture"]
    )
    per_condition.to_csv(OUT / "dnn_lpe_condition_summary.csv", index=False, float_format="%.6f")

    keys = ["ConditionID", "GestureID", "Trial"]
    pc = df[df.Hardware == "PC"].sort_values(keys).reset_index(drop=True)
    mb = df[df.Hardware == "MainBoard"].sort_values(keys).reset_index(drop=True)
    if not pc[keys].equals(mb[keys]):
        raise RuntimeError("PC/MainBoard condition/gesture/trial pairing does not match")

    stats = []
    raw_p = []
    for metric in ("ST_s", "CT_s", "RTA_pct"):
        difference = mb[metric].to_numpy(float) - pc[metric].to_numpy(float)
        res = wilcoxon(difference, zero_method="wilcox", alternative="two-sided", method="auto")
        raw_p.append(res.pvalue)
        stats.append({
            "Metric": metric,
            "Test": "Two-sided Wilcoxon signed-rank",
            "N_pairs": len(difference),
            "PC_mean": pc[metric].mean(),
            "MainBoard_mean": mb[metric].mean(),
            "Mean_difference_MainBoard_minus_PC": difference.mean(),
            "Median_difference_MainBoard_minus_PC": np.median(difference),
            "Statistic": res.statistic,
            "P_raw": res.pvalue,
            "Effect_size": rank_biserial(difference),
            "Effect_size_name": "Matched rank-biserial correlation",
        })

    pc_succ = pc.Completion.to_numpy(bool)
    mb_succ = mb.Completion.to_numpy(bool)
    pc_only = int(np.sum(pc_succ & ~mb_succ))
    mb_only = int(np.sum(~pc_succ & mb_succ))
    n_discordant = pc_only + mb_only
    mcnemar = 1.0 if n_discordant == 0 else binomtest(
        min(pc_only, mb_only), n_discordant, p=0.5, alternative="two-sided"
    ).pvalue
    raw_p.append(mcnemar)
    stats.append({
        "Metric": "CR",
        "Test": "Exact McNemar",
        "N_pairs": len(pc),
        "PC_mean": 100.0 * pc_succ.mean(),
        "MainBoard_mean": 100.0 * mb_succ.mean(),
        "Mean_difference_MainBoard_minus_PC": 100.0 * (mb_succ.mean() - pc_succ.mean()),
        "Median_difference_MainBoard_minus_PC": np.nan,
        "Statistic": n_discordant,
        "P_raw": mcnemar,
        "Effect_size": np.nan,
        "Effect_size_name": "",
        "PC_only_successes": pc_only,
        "MainBoard_only_successes": mb_only,
    })
    for row, adj in zip(stats, holm_adjust(raw_p)):
        row["P_Holm"] = adj
    pd.DataFrame(stats).to_csv(
        OUT / "dnn_pc_mainboard_paired_statistics.csv", index=False, float_format="%.9g"
    )

    stream = pd.DataFrame(agreement_rows)
    overall = pd.DataFrame([{
        "N_synchronized_predictions": int(stream.N_synchronized_predictions.sum()),
        "PC_MB_agree": int(stream.PC_MB_agree.sum()),
        "PC_vs_MainBoard_agreement_pct": 100.0 * stream.PC_MB_agree.sum() / stream.N_synchronized_predictions.sum(),
        "PC_vs_actual_pct": float(np.average(stream.PC_vs_actual_pct, weights=stream.N_synchronized_predictions)),
        "MainBoard_vs_actual_pct": float(np.average(stream.MainBoard_vs_actual_pct, weights=stream.N_synchronized_predictions)),
    }])
    overall.to_csv(OUT / "dnn_prediction_agreement.csv", index=False, float_format="%.6f")
    stream.to_csv(OUT / "dnn_prediction_agreement_by_condition.csv", index=False, float_format="%.6f")

    print(f"Five-condition LPE export: {len(df)} hardware-trial rows")
    print(f"PC/MainBoard matched trials: {len(pc)}")
    print(f"Prediction pairs: {int(overall.N_synchronized_predictions.iloc[0])}")
    print(f"Prediction agreement: {overall.PC_vs_MainBoard_agreement_pct.iloc[0]:.4f}%")


if __name__ == "__main__":
    main()
