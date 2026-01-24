#!/bin/bash
ALGOS=("random-unc" "random-con" "pso-m")
DATA_FILES=("cheby_lp.csv" "cheby_bp.csv")
DATA_NAMES=("Cheby LP" "Cheby BP")

for ALGO in "${ALGOS[@]}"; do
    for i in "${!DATA_FILES[@]}"; do
        echo "./$ALGO/${DATA_FILES[$i]};$ALGO, ${DATA_NAMES[$i]};" | octave ./plot_convergence.m
    done
done
