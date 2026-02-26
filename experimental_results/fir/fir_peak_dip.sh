#!/bin/bash
TESTFN="peak_dip"
DISPNAME="Peak & Dip"
NUM="1.071018  -1.895730   2.433447  -2.280328   1.683715  -0.931094   0.415294  -0.130253   0.024056"
DEN="1.000000  -1.976400   2.558539  -2.258532   1.651478  -0.884705   0.388817  -0.117767   0.028696"
W_START="0.0"
W_END="1.0"
POINTS="100"
echo "$TESTFN"
rm "./${TESTFN}.csv"
cd ../../
set -eux
cargo build --release

WINDOW="rect"
ORDER="40"
echo "FIR $WINDOW - $DISPNAME"
CMD="./target/release/phase-linearizer -n $W_START -x $W_END -p $POINTS -o $ORDER -f ./experimental_results/fir/${TESTFN}.csv transfer-function-fir --window $WINDOW --amp --num \"$NUM\" --den \"$DEN\""
sh -c "$CMD"

WINDOW="hamming"
ORDER="53"
echo "FIR $WINDOW - $DISPNAME"
CMD="./target/release/phase-linearizer -n $W_START -x $W_END -p $POINTS -o $ORDER -f ./experimental_results/fir/${TESTFN}.csv transfer-function-fir --window $WINDOW --amp --num \"$NUM\" --den \"$DEN\""
sh -c "$CMD"