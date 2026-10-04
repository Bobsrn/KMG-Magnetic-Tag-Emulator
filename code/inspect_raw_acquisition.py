#!/usr/bin/env python3
"""Check the released raw KMG acquisition CSV."""
from pathlib import Path
import pandas as pd

ROOT = Path(__file__).resolve().parents[1]
CSV = ROOT / "data" / "raw" / "mmdreza.csv"

LABELS = {
    1: "Grasp and Release",
    2: "Wrist Flexion/Extension",
    3: "Fourth and Fifth Fingers",
    4: "Tripod Pinch",
    5: "Rest",
}

df = pd.read_csv(CSV, header=None)
if df.shape[1] != 41:
    raise SystemExit(f"Expected 41 columns; found {df.shape[1]}")

counts = df.iloc[:, 40].value_counts().sort_index()
print(f"Rows: {len(df):,}")
print("Columns: 41 (40 features + label)")
print("Class counts:")
for label, count in counts.items():
    name = LABELS.get(int(label), "Unknown")
    print(f"  {int(label)} - {name}: {int(count):,}")
