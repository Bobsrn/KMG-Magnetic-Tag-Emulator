# File Provenance

The public filenames are simplified versions of the research working filenames. Numerical contents of the released MAT and CSV data files are not modified.

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

## DNN LPE and embedded implementation

`data/lpe/dnn_lpe_pc_mainboard.mat` is a public-facing copy of:

`result_ElbowMove6segment_mb_pc_mlp3layer_40hz_ws1sample_31122025.mat`

The `mlp` prefix is a historical working name for the compact three-hidden-layer feedforward DNN. The released file contains matched PC and main-board results.

The separate experimental 1D-convolutional dataset is not included in this repository because it is not used for the manuscript results released here.
