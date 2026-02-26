#!/bin/bash
TESTFN="stop_lp"
DISPNAME="Stop & LP"
NUM="0.059720  -0.227672   0.360950  -0.130451  -0.415327   0.726934  -0.415327  -0.130451   0.360950  -0.227672   0.059720"
DEN="1.0000e+00  -3.9182e+00   7.9612e+00  -1.1212e+01   1.1767e+01  -9.4018e+00   5.8497e+00  -2.7816e+00   9.3618e-01  -2.0557e-01   2.6283e-02"
W_START="0.0"
W_END="1.0"
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
ORDER="85"
echo "FIR $WINDOW - $DISPNAME"
CMD="./target/release/phase-linearizer -n $W_START -x $W_END -p $POINTS -o $ORDER -f ./experimental_results/fir/${TESTFN}.csv transfer-function-fir --window $WINDOW --amp --num \"$NUM\" --den \"$DEN\""
sh -c "$CMD"