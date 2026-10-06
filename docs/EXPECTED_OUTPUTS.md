# Expected Outputs

## Table V: compact DNN on PC under controlled LPE conditions

| Gesture | ST (s) | CT (s) | RTA (%) | CR (%) |
|---|---:|---:|---:|---:|
| Grasp and Release | 0.064 ± 0.114 | 1.040 ± 0.141 | 96.75 ± 8.27 | 86.7 |
| Wrist Flexion/Extension | 0.027 ± 0.006 | 0.990 ± 0.034 | 99.96 ± 0.31 | 100.0 |
| Fourth and Fifth Fingers | 0.075 ± 0.048 | 1.064 ± 0.082 | 93.10 ± 6.15 | 71.7 |
| Tripod Pinch | 0.034 ± 0.021 | 0.991 ± 0.053 | 95.89 ± 6.36 | 95.0 |

## Table VI: compact-DNN PC vs main-board implementation

| Implementation | ST (s) | CT (s) | RTA (%) | CR (%) |
|---|---:|---:|---:|---:|
| PC | 0.050 ± 0.065 | 1.021 ± 0.092 | 96.43 ± 6.50 | 88.3 |
| Main Board | 0.057 ± 0.081 | 1.083 ± 0.088 | 96.21 ± 6.69 | 81.7 |

Paired comparison (Holm-adjusted): ST `p = 0.00557`, CT `p < 0.001`, RTA `p = 0.158`, CR `p = 0.000435`.

Across 84,095 synchronized classifier outputs, PC and main-board class predictions agree in 98.10% of samples.
