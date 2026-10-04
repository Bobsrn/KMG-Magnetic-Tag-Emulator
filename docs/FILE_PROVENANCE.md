# File Provenance

The research archive contained working copies, duplicate result files, MATLAB figures, and intermediate analysis scripts. This repository retains the files associated with the reported online and LPE results and uses concise public filenames.

## Static online results

| Public file | Original research filename |
|---|---|
| `data/online/static/QDA.mat` | `simData_250426_5cls_realtimeresults_withData[2]_QDA.mat` |
| `data/online/static/SVM.mat` | `simData_250426_5cls_realtimeresults_withData[2]_SVM.mat` |
| `data/online/static/kNN.mat` | `simData_250426_5cls_realtimeresults_withData[2]_KNN.mat` |
| `data/online/static/NN.mat` | `simData_250426_5cls_realtimeresults_withData[2]_NN.mat` |
| `data/online/static/DNN.mat` | `simData_250426_5cls_realtimeresults_withData[2]_NN3.mat` |

## Dynamic online results

| Public file | Original research filename |
|---|---|
| `data/online/dynamic/QDA.mat` | `Dynamic/simData_250426_5cls_realtimeresults_withData[3]_QDA[2].mat` |
| `data/online/dynamic/SVM.mat` | `Dynamic/simData_250426_5cls_realtimeresults_withData[3]_SVM[2].mat` |
| `data/online/dynamic/kNN.mat` | `Dynamic/simData_250426_5cls_realtimeresults_withData[3]_KNN[2].mat` |
| `data/online/dynamic/NN.mat` | `Dynamic/simData_250426_5cls_realtimeresults_withData[3]_NN[2].mat` |
| `data/online/dynamic/DNN.mat` | `Dynamic/simData_250426_5cls_realtimeresults_withData[3]_NN3[2].mat` |

## LPE results

`data/lpe/DNN_LPE.mat` is a public-facing copy of:

`result_ElbowMove6segment_mb_pc_Conv_40hz_ws8sample_31122025.mat`

The historical `Conv` naming predates the final model terminology. The file contains the DNN results used for the LPE analysis.

The historical LPE result-block suffixes encode the nominal baseline-shift magnitudes used in the recorded conditions: 0, 1.5, 2.5, 5.0, 6.0, and 7.5 mm.

## Analysis scripts

- `code/reproduce_statistical_analysis.m` is based on the final independent-run analysis for the Static and Dynamic online experiments.
- `code/plot_figure7_static_dynamic.m` is based on the integrated Static/Dynamic plotting script.
- `code/reproduce_lpe_table.m` reproduces the pooled LPE descriptive summary from the released DNN LPE result file.
- `code/train_dnn.m` implements the DNN architecture and training settings reported in the manuscript, based on the original DNN development script with the study-specific 40-feature, five-class configuration restored.

Redundant copies, superseded working scripts, MATLAB `.fig` files, and intermediate analyses are not included.

## Raw acquisition file

`data/raw/mmdreza.csv` is the original headerless raw acquisition CSV supplied with the study archive. The repository preserves the numeric values and original row order without modification.
