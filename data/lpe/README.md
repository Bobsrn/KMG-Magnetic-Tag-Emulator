# Compact-DNN limb-position-effect data

The MAT file `dnn_lpe_pc_mainboard.mat` provides five experimental baseline-shift conditions: **0, 1.5, 3.0, 4.5 and 6.0 mm**. The top-level result variables are:

| Shift (mm) | MATLAB variable |
|---:|---|
| 0.0 | `DNN_LPE_0mm` |
| 1.5 | `DNN_LPE_1p5mm` |
| 3.0 | `DNN_LPE_3mm` |
| 4.5 | `DNN_LPE_4p5mm` |
| 6.0 | `DNN_LPE_6mm` |

The MAT also contains `condition_shift_mm`, `condition_variable_names`, and `condition_ids`. Every result variable contains the original `net_actual`, `net_pred`, `net_main_pred` and `RTtest` records (PC and main board). The trial values and prediction streams are unmodified relative to the corresponding source blocks.

The data were curated using the investigator-confirmed physical shifts. The archived recording used outdated labels for the 3-mm and 4.5-mm conditions; the curated variable names and condition metadata are corrected. The source recording's numerical command templates were not used to infer physical travel and are not included in this analysis-ready file. Original source-to-output mappings are recorded in `docs/FILE_PROVENANCE.md`.

There are 10 matched trials per functional gesture and condition, resulting in 50 trials per gesture per implementation and 200 matched PC/main-board trial pairs. In one archived result, the `timeST` vector has extra entries; analyses use the first 10 entries consistently with the corresponding `timeCT` and `ACC` vectors. No measured metric or prediction value was overwritten.

To regenerate tables and tests:

```bash
python code/export_dnn_lpe_results.py
python code/verify_release.py
```

The MATLAB analysis script is `code/analyze_dnn_lpe_pc_mainboard.m`. The completion criterion is `CT <= 1.125 s` in the source LPE analysis.
