# Raw acquisition data

`mmdreza.csv` is the combined raw acquisition file released with this repository.

The file is a headerless numeric CSV with 41 columns:

- columns 1-40: scalar magnetic-field features from the 40-sensor array;
- column 41: class label.

Class labels follow the study convention:

| Label | Class |
|---:|---|
| 1 | Grasp and Release |
| 2 | Wrist Flexion/Extension |
| 3 | Fourth and Fifth Fingers |
| 4 | Tripod Pinch |
| 5 | Rest |

The file contains 86,079 observations. The original row order is preserved.

For MATLAB, use `code/load_raw_acquisition.m`.
For Python, `code/inspect_raw_acquisition.py` provides a simple integrity check and class-count summary.
