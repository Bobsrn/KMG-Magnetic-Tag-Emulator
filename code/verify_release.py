#!/usr/bin/env python3
"""Regenerate processed files and verify the public release."""
from pathlib import Path
import subprocess, sys
import numpy as np
import pandas as pd

ROOT = Path(__file__).resolve().parents[1]
subprocess.run([sys.executable, str(ROOT/'code'/'export_online_results.py')], check=True)
subprocess.run([sys.executable, str(ROOT/'code'/'export_dnn_lpe_results.py')], check=True)

# Raw acquisition data.
raw = pd.read_csv(ROOT/'data'/'raw'/'kmg_raw_acquisition.csv', header=None)
assert raw.shape == (86079, 41), raw.shape
expected_counts = {1:17473,2:16232,3:15977,4:16305,5:20092}
counts = {int(k):int(v) for k,v in raw.iloc[:,40].value_counts().sort_index().items()}
assert counts == expected_counts, counts

# Online trials.
online = pd.read_csv(ROOT/'data'/'processed'/'online_trials.csv')
assert len(online) == 400
assert online.groupby(['Protocol','Model']).size().eq(40).all()

# DNN LPE / implementation trials.
lpe = pd.read_csv(ROOT/'data'/'processed'/'dnn_lpe_trials.csv')
assert len(lpe) == 480
assert lpe.groupby(['Hardware','GestureID']).size().eq(60).all()

# Key manuscript-level summaries.
tv = pd.read_csv(ROOT/'data'/'processed'/'table_v_dnn_lpe_pc.csv')
expected_tv = np.array([
    [0.063625,0.113754,1.040221,0.141011,96.748301,8.273358,86.666667],
    [0.026843,0.006091,0.989740,0.033841,99.959350,0.314877,100.000000],
    [0.075392,0.048332,1.064093,0.081780,93.102079,6.146535,71.666667],
    [0.034474,0.020639,0.991010,0.052617,95.891401,6.360291,95.000000],
])
got_tv = tv[['ST_mean_s','ST_sd_s','CT_mean_s','CT_sd_s','RTA_mean_pct','RTA_sd_pct','CR_pct']].to_numpy()
assert np.allclose(got_tv, expected_tv, atol=5e-7, rtol=0)

tvi = pd.read_csv(ROOT/'data'/'processed'/'table_vi_dnn_pc_mainboard.csv')
expected_tvi = {
    'PC': [0.050084,0.065490,1.021266,0.092497,96.425283,6.499253,88.333333],
    'MainBoard': [0.056767,0.080708,1.083455,0.088288,96.210444,6.688067,81.666667],
}
for _,r in tvi.iterrows():
    got = r[['ST_mean_s','ST_sd_s','CT_mean_s','CT_sd_s','RTA_mean_pct','RTA_sd_pct','CR_pct']].astype(float).to_numpy()
    assert np.allclose(got, expected_tvi[r.Hardware], atol=5e-7, rtol=0)

agree = pd.read_csv(ROOT/'data'/'processed'/'dnn_prediction_agreement.csv').iloc[0]
assert int(agree.N_synchronized_predictions) == 84095
assert abs(agree.PC_vs_MainBoard_agreement_pct - 98.100957) < 5e-7

print('Release verification passed.')
print('Raw acquisition: 86,079 rows x 41 columns')
print('Static/Dynamic online trials: 400 rows')
print('DNN LPE PC/MainBoard trials: 480 rows')
print('Synchronized DNN predictions: 84,095')
