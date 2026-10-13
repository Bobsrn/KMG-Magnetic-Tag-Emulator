# File Provenance

The public filenames are simplified versions of the research working filenames. The released MAT files retain the original online measurements; the LPE file has been curated as described below. Processed CSV files are regenerated from the explicitly selected five-position analysis, and corrected physical-shift metadata are stored separately.

## Static online results

| Public file | Original working filename |
|---|---|
| `data/online/static/QDA.mat` | `simData_250426_5cls_realtimeresults_withData[2]_QDA.mat` |
| `data/online/static/SVM.mat` | `simData_250426_5cls_realtimeresults_withData[2]_SVM.mat` |
| `data/online/static/kNN.mat` | `simData_250426_5cls_realtimeresults_withData[2]_KNN.mat` |
| `data/online/static/NN.mat` | `simData_250426_5cls_realtimeresults_withData[2]_NN.mat` |
| `data/online/static/DNN.mat` | `simData_250426_5cls_realtimeresults_withData[2]_NN3.mat` |

## Dynamic online results

| Public file | Original working filename |
|---|---|
| `data/online/dynamic/QDA.mat` | `simData_250426_5cls_realtimeresults_withData[3]_QDA[2].mat` |
| `data/online/dynamic/SVM.mat` | `simData_250426_5cls_realtimeresults_withData[3]_SVM[2].mat` |
| `data/online/dynamic/kNN.mat` | `simData_250426_5cls_realtimeresults_withData[3]_KNN[2].mat` |
| `data/online/dynamic/NN.mat` | `simData_250426_5cls_realtimeresults_withData[3]_NN[2].mat` |
| `data/online/dynamic/DNN.mat` | `simData_250426_5cls_realtimeresults_withData[3]_NN3[2].mat` |

## Curated LPE source

The published `data/lpe/dnn_lpe_pc_mainboard.mat` is an analysis-ready five-condition extract from the recorded compact-DNN PC/main-board experiment. The original source file is retained by the investigators. The correspondence of source result blocks to corrected variables is:

| Original result variable | Published variable | Physical baseline shift (mm) |
|---|---|---:|
| `TestResults_mlp_0` | `DNN_LPE_0mm` | 0.0 |
| `TestResults_mlp_15` | `DNN_LPE_1p5mm` | 1.5 |
| `TestResults_mlp_25` | `DNN_LPE_3mm` | 3.0 |
| `TestResults_mlp_5` | `DNN_LPE_4p5mm` | 4.5 |
| `TestResults_mlp_6` | `DNN_LPE_6mm` | 6.0 |

The physical shifts were confirmed by the investigators. The original source had inaccurate nominal labels for the 3.0-mm and 4.5-mm conditions. The curated MAT includes only the five analyzed conditions. All retained task-level metrics and synchronized prediction streams were copied without numerical modification, and original trial structures remain intact. Source command templates were not redistributed in this curated results file because their stored nominal values were not the confirmed physical displacements. The mapping does not constitute a new calibration measurement.
