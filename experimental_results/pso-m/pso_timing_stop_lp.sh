#!/bin/bash
TESTFN="stop_lp"
DISPNAME="Stop & LP"
ALGO="pso-m"
echo "$TESTFN"
rm "./${TESTFN}.csv"
cd ../../
set -eux
cargo build --release
echo "$ALGO - $DISPNAME"
CMD="./target/release/phase-linearizer -n 0.0 -x 1.0 -p 150 -o 8 -a $ALGO -i 300 -f ./experimental_results/$ALGO/${TESTFN}.csv transfer-function --amp --num \"0.059720  -0.227672   0.360950  -0.130451  -0.415327   0.726934  -0.415327  -0.130451   0.360950  -0.227672   0.059720\" --den \"1.0000e+00  -3.9182e+00   7.9612e+00  -1.1212e+01   1.1767e+01  -9.4018e+00   5.8497e+00  -2.7816e+00   9.3618e-01  -2.0557e-01   2.6283e-02\""
hyperfine --warmup 1 --runs 10 --show-output --export-csv ./experimental_results/$ALGO/${TESTFN}_timing.csv "$CMD"
seq 89 | parallel -N0 sh -c \'"$CMD"\'
