#!/bin/bash
TESTFN="cheby_hp"
DISPNAME="Cheby HP"
ALGO="pso-m"
echo "$TESTFN"
rm "./${TESTFN}.csv"
cd ../../
set -eux
cargo build --release
echo "$ALGO - $DISPNAME"
CMD="./target/release/phase-linearizer -n 0.6 -x 1.0 -p 100 -o 7 -a $ALGO -i 300 -f ./experimental_results/$ALGO/${TESTFN}.csv transfer-function --amp --num \"0.0014    0.0009    0.0023   -0.0005    0.0005   -0.0023   -0.0009   -0.0014\" --den \"1.0000    4.5142    9.0512   10.3576    7.2715    3.1213    0.7567    0.0798\""
hyperfine --warmup 1 --runs 10 --show-output --export-csv ./experimental_results/$ALGO/${TESTFN}_timing.csv "$CMD"
seq 89 | parallel -N0 sh -c \'"$CMD"\'
