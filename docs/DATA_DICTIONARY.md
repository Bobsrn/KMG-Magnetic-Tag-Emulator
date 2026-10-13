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

`data/lpe/dnn_lpe_pc_mainboard.mat` contains exactly five result structures, labeled by physical baseline shift: `DNN_LPE_0mm`, `DNN_LPE_1p5mm`, `DNN_LPE_3mm`, `DNN_LPE_4p5mm` and `DNN_LPE_6mm`.

The shifts are also stored under `condition_shift_mm`, and the MATLAB variable names are listed in `condition_variable_names`. The investigator-confirmed displacements and original recording variable names are provided in `data/lpe/condition_metadata.csv`.

Each result structure contains:

- `net_actual`: requested/actual class stream
- `net_pred`: PC prediction stream
- `net_main_pred`: main-board prediction stream
- `RTtest.pc`: task-level PC results
- `RTtest.mb`: task-level main-board results

The analysis uses 10 matched trials per gesture and condition on each implementation, yielding 50 trials per gesture and 200 paired trials. The original prediction streams and trial outcomes are unchanged; only top-level condition names were corrected and non-study records omitted.

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
- `dnn_prediction_agreement_by_condition.csv`: agreement in each analyzed LPE condition
- `data/lpe/condition_metadata.csv`: condition order, corrected physical shift and MAT variable names
