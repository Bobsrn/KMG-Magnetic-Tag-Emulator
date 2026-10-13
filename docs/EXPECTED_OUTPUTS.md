# Expected outputs — five-point compact-DNN LPE evaluation

The curated MAT file contains five condition-labeled result blocks at physical shifts of 0, 1.5, 3.0, 4.5 and 6.0 mm. The reported summaries use 10 trials per gesture and condition on each hardware implementation. Class predictions and trial metrics were not changed.

## Table V: compact DNN on PC

| Gesture | ST (s) | CT (s) | RTA (%) | CR (%) |
|---|---:|---:|---:|---:|
| Grasp and Release | 0.064 ± 0.116 | 1.039 ± 0.144 | 96.62 ± 8.36 | 88.0 |
| Wrist Flexion/Extension | 0.027 ± 0.007 | 0.988 ± 0.031 | 100.00 ± 0.00 | 100.0 |
| Fourth and Fifth Fingers | 0.063 ± 0.041 | 1.043 ± 0.069 | 94.69 ± 5.36 | 82.0 |
| Tripod Pinch | 0.033 ± 0.015 | 0.995 ± 0.056 | 98.32 ± 2.95 | 94.0 |

All values are mean ± sample SD for ST, CT and RTA; CR follows `CT <= 1.125 s`.

## Table VI: compact-DNN PC vs main-board comparison

| Implementation | ST (s) | CT (s) | RTA (%) | CR (%) |
|---|---:|---:|---:|---:|
| PC | 0.047 ± 0.064 | 1.016 ± 0.089 | 97.41 ± 5.51 | 91.0 |
| Main board | 0.052 ± 0.077 | 1.078 ± 0.085 | 97.17 ± 5.85 | 84.0 |

There are **200 matched task trials** (5 positions × 4 gestures × 10 repetitions).

## Paired statistical comparisons

| Metric | Main board − PC | Holm-adjusted p |
|---|---:|---:|
| ST | +5.41 ms | 0.01946 |
| CT | +62.34 ms | <0.001 |
| RTA | −0.241 percentage points | 0.12227 |
| CR | −7.0 percentage points | 0.00156 |

PC and main-board predictions agree in **98.264% of 69,988 synchronized outputs**. Samplewise agreement is descriptive because observations within trial streams are temporally correlated.
