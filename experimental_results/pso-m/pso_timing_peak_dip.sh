#!/bin/bash
TESTFN="peak_dip"
DISPNAME="Peak & Dip"
ALGO="pso-m"
echo "$TESTFN"
rm "./${TESTFN}.csv"
cd ../../
set -eux
cargo build --release
echo "$ALGO - $DISPNAME"
CMD="./target/release/phase-linearizer -n 0.0 -x 1.0 -p 100 -o 5 -a $ALGO -i 300 -f ./experimental_results/$ALGO/${TESTFN}.csv transfer-function --amp --num \"1.071018  -1.895730   2.433447  -2.280328   1.683715  -0.931094   0.415294  -0.130253   0.024056\" --den \"1.000000  -1.976400   2.558539  -2.258532   1.651478  -0.884705   0.388817  -0.117767   0.028696\""
hyperfine --warmup 1 --runs 10 --show-output --export-csv ./experimental_results/$ALGO/${TESTFN}_timing.csv "$CMD"
seq 89 | parallel -N0 sh -c \'"$CMD"\'
