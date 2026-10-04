#!/usr/bin/env python3
"""Verify trial counts and manuscript-level summary values from the released files."""
from pathlib import Path
import subprocess
import sys
import pandas as pd
import numpy as np

ROOT = Path(__file__).resolve().parents[1]

subprocess.run([sys.executable, str(ROOT / 'code' / 'export_online_csv.py')], check=True)
subprocess.run([sys.executable, str(ROOT / 'code' / 'export_lpe_csv.py')], check=True)

processed = ROOT / 'data' / 'processed'

# Verify the released raw acquisition CSV.
raw = pd.read_csv(ROOT / 'data' / 'raw' / 'mmdreza.csv', header=None)
if raw.shape != (86079, 41):
    raise SystemExit(f'Expected raw acquisition shape (86079, 41); found {raw.shape}')
raw_counts = raw.iloc[:, 40].value_counts().sort_index().to_dict()
expected_raw_counts = {1: 17473, 2: 16232, 3: 15977, 4: 16305, 5: 20092}
if {int(k): int(v) for k, v in raw_counts.items()} != expected_raw_counts:
    raise SystemExit(f'Unexpected raw label counts: {raw_counts}')


expected_static = {
    'QDA':  [0.034998, 0.017722, 1.051199, 0.029388, 99.155052, 1.494095, 100.0, 40],
    'SVM':  [0.101244, 0.049982, 1.113073, 0.063795, 92.651924, 4.624623, 57.5, 40],
    'kNN':  [0.081871, 0.059102, 1.081187, 0.062697, 95.156060, 4.992100, 77.5, 40],
    'NN':   [0.099995, 0.087152, 1.109324, 0.095181, 93.768922, 6.987489, 62.5, 40],
    'DNN':  [0.061247, 0.059361, 1.076839, 0.077111, 96.935110, 4.924919, 75.0, 40],
}
expected_dynamic = {
    'QDA':  [0.060000, 0.037038, 1.069325, 0.046511, 96.919912, 3.507122, 90.0, 40],
    'SVM':  [0.082497, 0.036337, 1.155570, 0.046161, 94.065151, 2.390928, 40.0, 40],
    'kNN':  [0.047499, 0.036162, 1.063699, 0.043466, 98.089130, 3.260411, 95.0, 40],
    'NN':   [0.051246, 0.041193, 1.097448, 0.037464, 98.027584, 3.229909, 82.5, 40],
    'DNN':  [0.033748, 0.014489, 1.059324, 0.022423, 98.661440, 1.339564, 100.0, 40],
}
expected_lpe = {
    1: [60, 0.052381, 0.053666, 1.104850, 0.154625, 92.032604, 11.016625, 71.666667],
    2: [60, 0.117486, 0.196010, 1.154629, 0.242830, 89.668894, 14.758224, 65.000000],
    3: [60, 0.050623, 0.057366, 1.036977, 0.062745, 96.657395, 5.483898, 90.000000],
    4: [60, 0.038756, 0.029160, 1.008139, 0.045494, 97.584870, 4.752499, 98.333333],
}

cols = ['ST_mean_s','ST_sd_s','CT_mean_s','CT_sd_s','RTA_mean_pct','RTA_sd_pct','CR_pct','N_trials']

def check_protocol(filename, expected):
    df = pd.read_csv(filename).set_index('Model')
    for model, vals in expected.items():
        got = df.loc[model, cols].astype(float).to_numpy()
        if not np.allclose(got, np.asarray(vals, dtype=float), atol=5e-7, rtol=0):
            raise SystemExit(f'Validation failed for {filename.name}: {model}\nGot {got}\nExpected {vals}')

check_protocol(processed / 'static_summary.csv', expected_static)
check_protocol(processed / 'dynamic_summary.csv', expected_dynamic)

lpe = pd.read_csv(processed / 'lpe_summary.csv').set_index('GestureID')
lpe_cols = ['N_trials','ST_mean_s','ST_sd_s','CT_mean_s','CT_sd_s','RTA_mean_pct','RTA_sd_pct','CR_pct']
for gid, vals in expected_lpe.items():
    got = lpe.loc[gid, lpe_cols].astype(float).to_numpy()
    if not np.allclose(got, np.asarray(vals, dtype=float), atol=5e-7, rtol=0):
        raise SystemExit(f'LPE validation failed for gesture {gid}\nGot {got}\nExpected {vals}')

trials = pd.read_csv(processed / 'online_trials.csv')
lpe_trials = pd.read_csv(processed / 'lpe_trials.csv')
if len(trials) != 400:
    raise SystemExit(f'Expected 400 Static/Dynamic online trial rows; found {len(trials)}')
if len(lpe_trials) != 240:
    raise SystemExit(f'Expected 240 LPE trial rows; found {len(lpe_trials)}')

print('Release verification passed.')
print('Raw acquisition: 86,079 rows x 41 columns')
print('Static/Dynamic online trials: 400 rows')
print('LPE trials: 240 rows')
