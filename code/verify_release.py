#!/usr/bin/env python3
"""Regenerate study results and validate the five-condition curated LPE MAT."""
from pathlib import Path
import subprocess
import sys

import numpy as np
import pandas as pd

ROOT = Path(__file__).resolve().parents[1]
subprocess.run([sys.executable, str(ROOT/'code'/'export_online_results.py')], check=True)
subprocess.run([sys.executable, str(ROOT/'code'/'export_dnn_lpe_results.py')], check=True)

raw = pd.read_csv(ROOT/'data'/'raw'/'kmg_raw_acquisition.csv', header=None)
assert raw.shape == (86079, 41), raw.shape
expected_counts = {1:17473,2:16232,3:15977,4:16305,5:20092}
counts = {int(k):int(v) for k,v in raw.iloc[:,40].value_counts().sort_index().items()}
assert counts == expected_counts, counts

online = pd.read_csv(ROOT/'data'/'processed'/'online_trials.csv')
assert len(online) == 400
assert online.groupby(['Protocol','Model']).size().eq(40).all()

metadata = pd.read_csv(ROOT/'data'/'lpe'/'condition_metadata.csv').sort_values('ConditionID')
expected_vars = ['DNN_LPE_0mm','DNN_LPE_1p5mm','DNN_LPE_3mm',
                 'DNN_LPE_4p5mm','DNN_LPE_6mm']
assert metadata.ConditionID.tolist() == [1,2,3,4,5]
assert metadata.MATVariable.tolist() == expected_vars
assert metadata.PhysicalDisplacement_mm.tolist() == [0,1.5,3,4.5,6]
from scipy.io import loadmat
mat = loadmat(ROOT/'data'/'lpe'/'dnn_lpe_pc_mainboard.mat', simplify_cells=True)
result_vars = [k for k in mat if k.startswith('DNN_LPE_')]
assert set(result_vars) == set(expected_vars)
assert np.allclose(mat['condition_shift_mm'],[0,1.5,3,4.5,6])
for name in expected_vars:
    block = mat[name]
    assert len(block['RTtest']['pc']) == 4
    assert len(block['RTtest']['mb']) == 4
    assert len(block['net_actual']) == len(block['net_pred']) == len(block['net_main_pred'])

lpe = pd.read_csv(ROOT/'data'/'processed'/'dnn_lpe_trials.csv')
assert len(lpe) == 400
assert lpe.groupby(['Hardware','GestureID']).size().eq(50).all()
assert set(lpe.SourceCondition.astype(str).unique()) == set(expected_vars)

v = pd.read_csv(ROOT/'data'/'processed'/'table_v_dnn_lpe_pc.csv')
expected_v = np.array([
    [0.064298,0.115898,1.038597,0.144170,96.616480,8.364536,88.0],
    [0.027210,0.006622,0.988236,0.031064,100.000000,0.000000,100.0],
    [0.062804,0.040919,1.042934,0.068900,94.685474,5.361145,82.0],
    [0.033233,0.015025,0.994839,0.055924,98.324637,2.946758,94.0],
])
cols = ['ST_mean_s','ST_sd_s','CT_mean_s','CT_sd_s','RTA_mean_pct','RTA_sd_pct','CR_pct']
assert np.allclose(v[cols].to_numpy(float), expected_v, atol=5e-7, rtol=0)
assert v.N_trials.tolist() == [50,50,50,50]

vi = pd.read_csv(ROOT/'data'/'processed'/'table_vi_dnn_pc_mainboard.csv').set_index('Hardware')
expected_vi = {
    'PC':[0.046886,0.063797,1.016152,0.088945,97.406648,5.510160,91.0],
    'MainBoard':[0.052298,0.077427,1.078489,0.084999,97.165280,5.850716,84.0],
}
for label,vals in expected_vi.items():
    assert np.allclose(vi.loc[label,cols].to_numpy(float), vals, atol=5e-7, rtol=0)
    assert vi.loc[label,'N_trials'] == 200

stats = pd.read_csv(ROOT/'data'/'processed'/'dnn_pc_mainboard_paired_statistics.csv').set_index('Metric')
assert np.isclose(stats.loc['ST_s','P_Holm'], .0194595508, atol=5e-10)
assert stats.loc['CT_s','P_Holm'] < .001
assert np.isclose(stats.loc['RTA_pct','P_Holm'], .122267776, atol=5e-9)
assert np.isclose(stats.loc['CR','P_Holm'], .00155639648, atol=5e-10)
assert int(stats.loc['CR','PC_only_successes']) == 15
assert int(stats.loc['CR','MainBoard_only_successes']) == 1

agree = pd.read_csv(ROOT/'data'/'processed'/'dnn_prediction_agreement.csv').iloc[0]
assert agree.N_synchronized_predictions == 69988
assert agree.PC_MB_agree == 68773
assert abs(agree.PC_vs_MainBoard_agreement_pct - 98.263988) < .000001


print('Verified: 5 LPE positions, 50 PC trials per gesture, 200 PC/MainBoard trial pairs')
print('Verified: 69,988 synchronized outputs, 98.264% agreement')
print('Verified: corrected five-condition MAT and metadata agree')
