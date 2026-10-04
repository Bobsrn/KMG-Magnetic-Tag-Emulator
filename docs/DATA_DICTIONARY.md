# Data Dictionary

## Raw acquisition CSV

`data/raw/mmdreza.csv` is a headerless numeric CSV with 86,079 observations and 41 columns. Columns 1-40 are the scalar magnetic-field features used by the direct-classification framework and column 41 is the class label.

| Label | Class |
|---:|---|
| 1 | Grasp and Release |
| 2 | Wrist Flexion/Extension |
| 3 | Fourth and Fifth Fingers |
| 4 | Tripod Pinch |
| 5 | Rest |

## Acquisition protocols

### Static
The model-development acquisition represents final gesture positions.

### Dynamic
The model-development acquisition includes movement transitions between rest and the target gesture positions.

The online-result files contain separately acquired online evaluation results for the corresponding trained classifier.

## Gesture identifiers

| ID | Gesture |
|---:|---|
| 1 | Grasp and Release |
| 2 | Wrist Flexion/Extension |
| 3 | Fourth and Fifth Fingers |
| 4 | Tripod Pinch |

Rest is the fifth classifier class but is not one of the four requested functional gestures used to calculate ST, CT, RTA, and CR during the online test.

## Online MATLAB files

Each `data/online/<protocol>/<model>.mat` file contains a trained classifier object or structure and `RTtest1` through `RTtest4`.

Each `RTtestN` structure contains:

| Field | Description | Unit / scale |
|---|---|---|
| `timeST` | Selection Time | seconds |
| `timeCT` | Completion Time | seconds |
| `ACC` | Real-Time Accuracy | proportion in [0,1] |

`100 * ACC` gives RTA in percent.

## Completion Rate

For the released analyses, a trial is counted as completed when:

`CT <= 1.125 s`.

CR is the percentage of completed trials. RTA is reported as a separate online stability metric.

## Processed online CSV

`data/processed/online_trials.csv` contains:

| Column | Description |
|---|---|
| `Protocol` | Static or Dynamic |
| `Model` | QDA, SVM, kNN, NN, or DNN |
| `GestureID` | 1-4 |
| `Gesture` | Gesture name |
| `Trial` | Repetition number within the gesture |
| `ST_s` | Selection Time in seconds |
| `CT_s` | Completion Time in seconds |
| `RTA_pct` | Real-Time Accuracy in percent |
| `Completion` | 1 when `CT <= 1.125 s`, otherwise 0 |

## LPE data

`data/lpe/DNN_LPE.mat` contains six DNN result blocks under historical MATLAB variable names:

| Source variable | Nominal baseline-shift magnitude (mm) |
|---|---:|
| `TestResults_conv_0` | 0.0 |
| `TestResults_conv_15` | 1.5 |
| `TestResults_conv_25` | 2.5 |
| `TestResults_conv_5` | 5.0 |
| `TestResults_conv_6` | 6.0 |
| `TestResults_conv_75` | 7.5 |

The `conv` prefix is a historical working name; these result blocks correspond to the DNN used for the manuscript LPE experiment.

Each result block contains `RTtest.pc` and `RTtest.mb`. The manuscript LPE summary is based on `RTtest.pc`, pooled across the one nominal baseline condition and five controlled shifted-baseline conditions.

`data/processed/lpe_trials.csv` contains:

| Column | Description |
|---|---|
| `ConditionID` | Sequential condition identifier, 1-6 |
| `BaselineShift_mm` | Nominal baseline-shift magnitude |
| `SourceVariable` | Historical MATLAB result-block name |
| `GestureID` | 1-4 |
| `Gesture` | Gesture name |
| `Trial` | Repetition number, 1-10 |
| `ST_s` | Selection Time in seconds |
| `CT_s` | Completion Time in seconds |
| `RTA_pct` | Real-Time Accuracy in percent |
| `Completion` | 1 when `CT <= 1.125 s`, otherwise 0 |

## Trial counts

### Static / Dynamic online evaluation

- 10 trials per functional gesture
- 4 functional gestures per classifier
- 40 trials per classifier
- 5 classifiers per protocol
- 200 trials per protocol
- 400 online trials total

### LPE evaluation

- 6 recorded baseline-shift conditions
- 10 trials per gesture per condition
- 4 functional gestures
- 240 trial rows total
- 60 pooled trials per gesture
