#!/bin/bash
TESTFN="cheby_hp"
DISPNAME="Cheby HP"
NUM="0.0014    0.0009    0.0023   -0.0005    0.0005   -0.0023   -0.0009   -0.0014"
DEN="1.0000    4.5142    9.0512   10.3576    7.2715    3.1213    0.7567    0.0798"
W_START="0.6"
W_END="1.0"
POINTS="100"
echo "$TESTFN"
rm "./${TESTFN}.csv"
cd ../../
set -eux
cargo build --release

WINDOW="rect"
ORDER="81"
echo "FIR $WINDOW - $DISPNAME"
CMD="./target/release/phase-linearizer -n $W_START -x $W_END -p $POINTS -o $ORDER -f ./experimental_results/fir/${TESTFN}.csv transfer-function-fir --window $WINDOW --amp --num \"$NUM\" --den \"$DEN\""
sh -c "$CMD"

WINDOW="hamming"
ORDER="81"
echo "FIR $WINDOW - $DISPNAME"
CMD="./target/release/phase-linearizer -n $W_START -x $W_END -p $POINTS -o $ORDER -f ./experimental_results/fir/${TESTFN}.csv transfer-function-fir --window $WINDOW --amp --num \"$NUM\" --den \"$DEN\""
sh -c "$CMD"