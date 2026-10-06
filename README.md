# KMG Magnetic-Tag Emulator: Data and Analysis Code

Data and code accompanying the manuscript:

**Real-Time KineticoMyoGraphy-Based Hand Gesture Recognition Using a Patient-Specific Magnetic-Tag Emulator**

Mohammad-R Gholami-Z, Babak Sarani, Hojjat Hosseini, A. Akbarzadeh, Mohammad-R. Akbarzadeh-T., and Ali Moradi.

Repository: https://github.com/Bobsrn/KMG-Magnetic-Tag-Emulator

## Contents

This repository contains the experimental data, trained MATLAB classifier objects, and analysis code used for the magnetic-tag emulator study. The release includes:

- the raw 40-feature acquisition dataset;
- Static and Dynamic online evaluation results for QDA, SVM, kNN, NN, and DNN;
- the trained classifier objects used in the online experiments;
- compact-DNN limb-position-effect (LPE) data recorded on both the host PC and the system main board;
- trial-level and summary CSV files;
- statistical-analysis and plotting scripts;
- the compact DNN architecture and training configuration reported in the manuscript.

All measurements in this repository were generated using the physical magnetic-tag emulator. The repository does not contain human-subject KMG recordings.

## Repository structure

```text
.
├── data/
│   ├── raw/
│   │   └── kmg_raw_acquisition.csv
│   ├── online/
│   │   ├── static/          # QDA, SVM, kNN, NN, DNN
│   │   └── dynamic/         # QDA, SVM, kNN, NN, DNN
│   ├── lpe/
│   │   └── dnn_lpe_pc_mainboard.mat
│   ├── processed/
│   └── training/
├── code/
│   ├── reproduce_online_statistics.m
│   ├── plot_online_results.m
│   ├── analyze_dnn_lpe_pc_mainboard.m
│   ├── export_online_results.py
│   ├── export_dnn_lpe_results.py
│   ├── predict_with_trained_dnn.m
│   ├── train_dnn.m
│   ├── train_all_dnn.m
│   ├── load_training_data.m
│   ├── load_raw_acquisition.m
│   ├── csv_to_training_mat.m
│   └── verify_release.py
├── docs/
├── reference_outputs/
└── outputs/
```

## Raw acquisition data

`data/raw/kmg_raw_acquisition.csv` is a headerless numeric CSV. Columns 1-40 contain the scalar magnetic-field features used by the direct-classification framework, and column 41 contains the class label.

| Label | Class |
|---:|---|
| 1 | Grasp and Release |
| 2 | Wrist Flexion/Extension |
| 3 | Fourth and Fifth Fingers |
| 4 | Tripod Pinch |
| 5 | Rest |

MATLAB:

```matlab
[X,Y,raw] = load_raw_acquisition;
```

## Static and Dynamic online evaluation

Each protocol folder contains one MAT file per classifier:

`QDA.mat`, `SVM.mat`, `kNN.mat`, `NN.mat`, and `DNN.mat`.

Each file contains `RTtest1` through `RTtest4`, corresponding to the four functional gestures. The trial structures contain:

- `timeST`: Selection Time (s)
- `timeCT`: Completion Time (s)
- `ACC`: Real-Time Accuracy as a proportion

The processed long-format data are available in `data/processed/online_trials.csv`.

To regenerate the processed files:

```bash
python code/export_online_results.py
```

To reproduce the statistical analysis used for the Static/Dynamic comparison:

```matlab
run('code/reproduce_online_statistics.m')
```

To regenerate the integrated online-performance figure:

```matlab
run('code/plot_online_results.m')
```

## Compact-DNN LPE and main-board data

`data/lpe/dnn_lpe_pc_mainboard.mat` contains the compact-DNN results recorded for the controlled LPE experiment on both the host PC and the system main board.

The MAT file preserves the historical internal variable names `TestResults_mlp_*`; these structures correspond to the compact feedforward DNN used in the study.

For each recorded LPE condition and each of the four functional gestures, the file contains matched PC and main-board task metrics (`timeST`, `timeCT`, and `ACC`) together with synchronized PC and main-board prediction streams.

Processed outputs include:

- `dnn_lpe_trials.csv`
- `table_v_dnn_lpe_pc.csv`
- `table_vi_dnn_pc_mainboard.csv`
- `dnn_lpe_condition_summary.csv`
- `dnn_pc_mainboard_paired_statistics.csv`
- `dnn_prediction_agreement.csv`

To regenerate these files:

```bash
python code/export_dnn_lpe_results.py
```

MATLAB analysis:

```matlab
run('code/analyze_dnn_lpe_pc_mainboard.m')
```

The PC/MainBoard implementation comparison uses matched trials. ST, CT, and RTA are compared using two-sided Wilcoxon signed-rank tests; Completion Rate is compared using the exact McNemar test. Holm correction is applied across the four implementation comparisons.

## DNN architecture

The compact DNN configuration is implemented in `code/train_dnn.m`:

- 40 input features;
- hidden layers of 128, 64, and 32 ReLU units;
- five-class softmax output;
- cross-entropy loss;
- Adam optimizer;
- 30 epochs;
- mini-batch size 64;
- 80% model fitting and 20% internal model-development holdout;
- shuffling at every epoch.

The released `DNN.mat` files contain the trained Static and Dynamic models used in the online experiments. `code/predict_with_trained_dnn.m` provides a simple inference helper.

Protocol-specific model-development matrices can be supplied to `train_dnn.m` in the format described in `data/training/README.md`.

## Software

The MATLAB experiments were developed in MATLAB R2024b. The statistical scripts require Statistics and Machine Learning Toolbox, and DNN training requires Deep Learning Toolbox.

Python utilities require `numpy`, `pandas`, and `scipy`.

## Verification

Run:

```bash
python code/verify_release.py
```

The script regenerates the processed CSV files and checks the expected trial counts and key manuscript-level summaries.

## Citation

Please cite the associated manuscript when using these data or scripts. Citation metadata are provided in `CITATION.cff`.
