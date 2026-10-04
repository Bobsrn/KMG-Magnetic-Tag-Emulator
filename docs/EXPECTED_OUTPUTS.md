# Expected Outputs

The values below are obtained directly from the released trial data.

## Static online evaluation

| Model | ST (s) | CT (s) | RTA (%) | CR (%) |
|---|---:|---:|---:|---:|
| QDA | 0.035 ± 0.018 | 1.051 ± 0.029 | 99.16 ± 1.49 | 100.0 |
| SVM | 0.101 ± 0.050 | 1.113 ± 0.064 | 92.65 ± 4.62 | 57.5 |
| kNN | 0.082 ± 0.059 | 1.081 ± 0.063 | 95.16 ± 4.99 | 77.5 |
| NN | 0.100 ± 0.087 | 1.109 ± 0.095 | 93.77 ± 6.99 | 62.5 |
| DNN | 0.061 ± 0.059 | 1.077 ± 0.077 | 96.94 ± 4.92 | 75.0 |

## Dynamic online evaluation

| Model | ST (s) | CT (s) | RTA (%) | CR (%) |
|---|---:|---:|---:|---:|
| QDA | 0.060 ± 0.037 | 1.069 ± 0.047 | 96.92 ± 3.51 | 90.0 |
| SVM | 0.082 ± 0.036 | 1.156 ± 0.046 | 94.07 ± 2.39 | 40.0 |
| kNN | 0.047 ± 0.036 | 1.064 ± 0.043 | 98.09 ± 3.26 | 95.0 |
| NN | 0.051 ± 0.041 | 1.097 ± 0.037 | 98.03 ± 3.23 | 82.5 |
| DNN | 0.034 ± 0.014 | 1.059 ± 0.022 | 98.66 ± 1.34 | 100.0 |

## Pooled LPE evaluation

The LPE values below pool 60 trials per gesture across the one nominal baseline condition and five controlled shifted-baseline conditions.

| Gesture | ST (s) | CT (s) | RTA (%) | CR (%) |
|---|---:|---:|---:|---:|
| Grasp and Release | 0.052 ± 0.054 | 1.105 ± 0.155 | 92.03 ± 11.02 | 71.7 |
| Wrist Flexion/Extension | 0.117 ± 0.196 | 1.155 ± 0.243 | 89.67 ± 14.76 | 65.0 |
| Fourth and Fifth Fingers | 0.051 ± 0.057 | 1.037 ± 0.063 | 96.66 ± 5.48 | 90.0 |
| Tripod Pinch | 0.039 ± 0.029 | 1.008 ± 0.045 | 97.58 ± 4.75 | 98.3 |

Values are mean ± sample standard deviation. CR uses `CT <= 1.125 s`.
