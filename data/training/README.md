# Protocol-specific DNN model-development data

`code/train_dnn.m` expects one of the following files when retraining the compact DNN:

- `static_training.mat`
- `dynamic_training.mat`

Each MAT file must contain either:

1. `X`: an `N x 40` numeric predictor matrix and `Y`: the corresponding class labels; or
2. a MATLAB table `DATA_5cls` with exactly 40 predictor columns and a response column named `Label`.

The combined acquisition CSV is released separately under `data/raw/`. The repository does not automatically infer protocol-specific model-development subsets from that combined stream.
