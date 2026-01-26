#!/bin/bash
ALGOS=("random-unc" "random-con" "pso-m")
DATA_FILES=("cheby_hp.csv" "cheby_bp.csv")
DATA_NAMES=("Cheby HP" "Cheby BP")

for i in "${!DATA_FILES[@]}"; do
    for ALGO in "${ALGOS[@]}"; do
        echo "./$ALGO/${DATA_FILES[$i]};$ALGO, ${DATA_NAMES[$i]};" | octave ./plot_convergence.m
    done
done
