# KMG Magnetic-Tag Emulator: Data and Analysis Code

Data and code accompanying the manuscript:

**Real-Time KineticoMyoGraphy-Based Hand Gesture Recognition Using a Patient-Specific Magnetic-Tag Emulator**

Mohammad-R Gholami-Z, Babak Sarani, Hojjat Hosseini, A. Akbarzadeh, Mohammad-R. Akbarzadeh-T., and Ali Moradi.

## Overview

This repository contains experimental data, trained classifier files, and analysis code for the patient-specific KineticoMyoGraphy (KMG) magnetic-tag emulator study. All measurements were generated using the physical emulator; the repository does not contain human-subject KMG recordings.

The release includes:

- a raw 40-feature acquisition CSV with class labels;
- Static and Dynamic online evaluation results for QDA, SVM, kNN, NN, and DNN classifiers;
- the trained MATLAB classifier objects used in the online experiments;
- trial-level and summary CSV files for the online tests;
- DNN limb-position-effect (LPE) result data;
- statistical-analysis and plotting scripts;
- the compact DNN architecture and training configuration used in the study.

## Repository structure

```text
.
├── data/
│   ├── raw/                 # Raw 40-feature acquisition CSV
│   ├── online/
│   │   ├── static/          # Static-trained classifier objects and online trials
│   │   └── dynamic/         # Dynamic-trained classifier objects and online trials
│   ├── lpe/                 # DNN LPE result file
│   ├── processed/           # Trial-level and summary CSV files
│   └── training/            # DNN model-development data format
├── code/
│   ├── reproduce_statistical_analysis.m
│   ├── plot_figure7_static_dynamic.m
│   ├── reproduce_lpe_table.m
│   ├── predict_with_trained_dnn.m
│   ├── train_dnn.m
│   ├── train_all_dnn.m
│   ├── load_kmg_training_data.m
│   ├── load_raw_acquisition.m
│   ├── csv_to_training_mat.m
│   ├── export_online_csv.py
│   ├── export_lpe_csv.py
│   ├── inspect_raw_acquisition.py
│   └── verify_release.py
├── docs/
│   ├── DATA_DICTIONARY.md
│   ├── FILE_PROVENANCE.md
│   ├── EXPECTED_OUTPUTS.md
│   └── file_manifest_sha256.csv
├── reference_outputs/
└── outputs/
```

## Raw acquisition data

`data/raw/mmdreza.csv` is a headerless numeric CSV containing 40 scalar magnetic-field features and one class-label column. The original row order is preserved.

Columns 1-40 contain the scalar sensor features and column 41 contains the class label:

1. Grasp and Release
2. Wrist Flexion/Extension
3. Fourth and Fifth Fingers
4. Tripod Pinch
5. Rest

MATLAB:

```matlab
[X, Y, raw] = load_raw_acquisition;
```

Python integrity check:

```bash
python code/inspect_raw_acquisition.py
```

## Static and Dynamic online evaluation

Each protocol contains one MATLAB file per classifier:

- `QDA.mat`
- `SVM.mat`
- `kNN.mat`
- `NN.mat`
- `DNN.mat`

Each file contains four online trial structures:

- `RTtest1`: Grasp and Release
- `RTtest2`: Wrist Flexion/Extension
- `RTtest3`: Fourth and Fifth Fingers
- `RTtest4`: Tripod Pinch

Each structure contains Selection Time (`timeST`), Completion Time (`timeCT`), and Real-Time Accuracy (`ACC`). There are 10 trials per functional gesture and 40 online trials per classifier.

The corresponding long-format dataset is `data/processed/online_trials.csv`.

Completion Rate (CR) is calculated as the percentage of requested gesture trials with `CT <= 1.125 s`. RTA is reported separately.

## Statistical analysis

Run:

```matlab
run('code/reproduce_statistical_analysis.m')
```

The script performs the independent-run statistical analysis used for the Static and Dynamic online experiments, including Kruskal-Wallis tests, Holm-corrected Mann-Whitney U comparisons, effect sizes, Completion Rate comparisons, Wilson confidence intervals, and direct Static-versus-Dynamic comparisons.

Generated files are written to `outputs/analysis/`.

## Figure 7

Run:

```matlab
run('code/plot_figure7_static_dynamic.m')
```

Generated figure files are written to `outputs/figures/`.

## Limb-position-effect data

`data/lpe/DNN_LPE.mat` contains the archived DNN results used for the LPE analysis. Historical MATLAB variable names are retained in the file.

Processed LPE files are provided in `data/processed/`:

- `lpe_trials.csv`
- `lpe_condition_summary.csv`
- `lpe_summary.csv`

To reproduce the pooled LPE summary in MATLAB:

```matlab
run('code/reproduce_lpe_table.m')
```

To regenerate the processed CSV files in Python:

```bash
python code/export_lpe_csv.py
```

## DNN architecture and training configuration

The compact DNN configuration is implemented in `code/train_dnn.m`:

- 40 input features;
- hidden layers of 128, 64, and 32 ReLU units;
- five-class softmax output;
- Adam optimizer;
- 30 epochs;
- mini-batch size of 64;
- 80% model fitting and 20% internal model-development holdout;
- shuffling at every epoch.

The released online `DNN.mat` files contain the trained DNN models used in the online experiments. `code/predict_with_trained_dnn.m` loads these archived models for inference.

The DNN training function accepts protocol-specific model-development data in the format documented in `data/training/README.md`. The combined raw acquisition stream is released separately under `data/raw/` and is not automatically partitioned into protocol-specific training subsets by the repository scripts.

## Python access

Install the minimal Python dependencies with:

```bash
pip install -r requirements.txt
```

Regenerate processed datasets with:

```bash
python code/export_online_csv.py
python code/export_lpe_csv.py
```

Run the release consistency check with:

```bash
python code/verify_release.py
```

## Software

The experiments and MATLAB models were developed in MATLAB R2024b. The statistical-analysis scripts require the Statistics and Machine Learning Toolbox. DNN training requires Deep Learning Toolbox.

## Citation

Please cite the associated manuscript when using these data or scripts. Citation metadata are provided in `CITATION.cff`.
