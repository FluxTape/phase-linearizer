#!/bin/bash
TESTFN="cheby_bp"
DISPNAME="Cheby BP"
ALGO="pso-m"
echo "$TESTFN"
rm "./${TESTFN}.csv"
cd ../../
set -eux
cargo build --release
echo "$ALGO - $DISPNAME"
CMD="./target/release/phase-linearizer -n 0.1 -x 0.9 -p 150 -o 8 -a $ALGO -i 300 -f ./experimental_results/$ALGO/${TESTFN}.csv transfer-function --amp --num \"1.5451e-03  -1.9713e-03   2.1760e-04  -9.3270e-04   2.7666e-03  -9.3270e-04   2.1760e-04  -1.9713e-03   1.5451e-03\" --den \"1.0000e+00  -2.7355e+00   5.9780e+00  -7.8335e+00   8.5654e+00  -6.3463e+00   3.9239e+00  -1.4513e+00   4.2989e-01\""
hyperfine --warmup 1 --runs 10 --show-output --export-csv ./experimental_results/$ALGO/${TESTFN}_timing.csv "$CMD"
seq 89 | parallel -N0 sh -c \'"$CMD"\'
