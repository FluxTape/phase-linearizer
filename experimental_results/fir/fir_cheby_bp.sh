#!/bin/bash
TESTFN="cheby_bp"
DISPNAME="Cheby BP"
NUM="1.5451e-03  -1.9713e-03   2.1760e-04  -9.3270e-04   2.7666e-03  -9.3270e-04   2.1760e-04  -1.9713e-03   1.5451e-03"
DEN="1.0000e+00  -2.7355e+00   5.9780e+00  -7.8335e+00   8.5654e+00  -6.3463e+00   3.9239e+00  -1.4513e+00   4.2989e-01"
W_START="0.1"
W_END="0.9"
POINTS="150"
echo "$TESTFN"
rm "./${TESTFN}.csv"
cd ../../
set -eux
cargo build --release

WINDOW="rect"
ORDER="56"
echo "FIR $WINDOW - $DISPNAME"
CMD="./target/release/phase-linearizer -n $W_START -x $W_END -p $POINTS -o $ORDER -f ./experimental_results/fir/${TESTFN}.csv transfer-function-fir --window $WINDOW --amp --num \"$NUM\" --den \"$DEN\""
sh -c "$CMD"

WINDOW="hamming"
ORDER="121"
echo "FIR $WINDOW - $DISPNAME"
CMD="./target/release/phase-linearizer -n $W_START -x $W_END -p $POINTS -o $ORDER -f ./experimental_results/fir/${TESTFN}.csv transfer-function-fir --window $WINDOW --amp --num \"$NUM\" --den \"$DEN\""
sh -c "$CMD"