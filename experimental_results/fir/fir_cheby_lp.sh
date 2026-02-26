#!/bin/bash
TESTFN="cheby_lp"
DISPNAME="Cheby LP"
NUM="2.3447e-03   5.8262e-03   1.0160e-02   1.1842e-02   1.0160e-02   5.8262e-03   2.3447e-03" 
DEN="1.000000  -3.207647 4.689690  -3.853772   1.857272  -0.493137   0.056098"
W_START="0.0"
W_END="0.6"
POINTS="150"
echo "$TESTFN"
rm "./${TESTFN}.csv"
cd ../../
set -eux
cargo build --release

WINDOW="rect"
ORDER="33"
echo "FIR $WINDOW - $DISPNAME"
CMD="./target/release/phase-linearizer -n $W_START -x $W_END -p $POINTS -o $ORDER -f ./experimental_results/fir/${TESTFN}.csv transfer-function-fir --window $WINDOW --amp --num \"$NUM\" --den \"$DEN\""
sh -c "$CMD"

WINDOW="hamming"
ORDER="50"
echo "FIR $WINDOW - $DISPNAME"
CMD="./target/release/phase-linearizer -n $W_START -x $W_END -p $POINTS -o $ORDER -f ./experimental_results/fir/${TESTFN}.csv transfer-function-fir --window $WINDOW --amp --num \"$NUM\" --den \"$DEN\""
sh -c "$CMD"