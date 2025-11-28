#!/bin/bash
TESTFN="cheby_lp"
DISPNAME="Cheby LP"
ALGO="random-con"
echo "$TESTFN"
rm "./${TESTFN}.csv"
cd ../../
set -eux
cargo build --release
echo "$ALGO - $DISPNAME"
CMD="./target/release/phase-linearizer -n 0.0 -x 0.6 -p 150 -o 6 -a $ALGO -i 300 -f ./experimental_results/$ALGO/${TESTFN}.csv transfer-function --amp --num \"2.3447e-03   5.8262e-03   1.0160e-02   1.1842e-02   1.0160e-02   5.8262e-03   2.3447e-03\" --den \"1.000000  -3.207647 4.689690  -3.853772   1.857272  -0.493137   0.056098\""
hyperfine --warmup 0 --runs 1 --export-csv ./experimental_results/random-unc/${TESTFN}_timing.csv "$CMD"
seq 1 | parallel -N0 sh -c \'"$CMD"\'
