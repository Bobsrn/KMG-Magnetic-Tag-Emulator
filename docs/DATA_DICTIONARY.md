# Data Dictionary

## Raw acquisition dataset

`data/raw/kmg_raw_acquisition.csv` is a headerless CSV with 40 scalar magnetic-field features and one label column.

Class labels: 1 = Grasp and Release, 2 = Wrist Flexion/Extension, 3 = Fourth and Fifth Fingers, 4 = Tripod Pinch, 5 = Rest.

## Static/Dynamic online result files

Each `data/online/<protocol>/<model>.mat` file contains a trained classifier object/structure and four online trial structures (`RTtest1`-`RTtest4`).

Each `RTtest` structure contains:

- `timeST`: Selection Time in seconds
- `timeCT`: Completion Time in seconds
- `ACC`: Real-Time Accuracy as a proportion

The online Completion Rate is computed from the task completion-time criterion (`CT <= 1.125 s`).

## Compact-DNN LPE result file

`data/lpe/dnn_lpe_pc_mainboard.mat` contains six recorded LPE result blocks. Historical internal variable names use the prefix `TestResults_mlp_*`; these structures correspond to the compact DNN used in the manuscript.

Each block contains:

- `net_actual`: requested/actual class stream
- `net_pred`: PC prediction stream
- `net_main_pred`: main-board prediction stream
- `RTtest.pc`: task-level PC results
- `RTtest.mb`: task-level main-board results

For each hardware implementation, four gesture entries are stored under `RTtest`. The public analysis uses the first 10 matched trials per gesture and condition, consistent with the recorded online protocol.

## Processed files

- `online_trials.csv`: Static/Dynamic online trials
- `static_summary.csv`: Static descriptive results
- `dynamic_summary.csv`: Dynamic descriptive results
- `dnn_lpe_trials.csv`: DNN LPE trials for PC and main board
- `table_v_dnn_lpe_pc.csv`: DNN PC LPE summary used for Table V
- `table_vi_dnn_pc_mainboard.csv`: pooled PC/MainBoard implementation summary
- `dnn_lpe_condition_summary.csv`: condition-level DNN descriptives
- `dnn_pc_mainboard_paired_statistics.csv`: paired implementation tests
- `dnn_prediction_agreement.csv`: synchronized prediction-stream agreement
