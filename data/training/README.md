# DNN model-development data format

`code/train_dnn.m` trains the compact five-class DNN using 40 scalar predictors.

The function expects one of the following protocol-specific files:

- `static_training.mat`
- `dynamic_training.mat`

Each MAT file must contain either:

1. `X`: an `N x 40` numeric predictor matrix and `Y`: the corresponding class labels; or
2. a MATLAB table `DATA_5cls` with exactly 40 predictor columns and a response column named `Label`.

The study configuration uses a one-time 80/20 sample-level split for model fitting and the internal model-development holdout.

The combined raw acquisition CSV is released in `data/raw/mmdreza.csv`. When a protocol-specific CSV subset has already been selected, it can be converted to the MAT format above with:

```matlab
csv_to_training_mat('protocol_subset.csv', 'static_training.mat')
```

or

```matlab
csv_to_training_mat('protocol_subset.csv', 'dynamic_training.mat')
```
