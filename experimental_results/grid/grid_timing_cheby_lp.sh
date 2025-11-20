#!/bin/bash
rm ./cheby_lp.csv
cd ../../
set -eux
cargo build --release
echo "grid - Cheby LP"
hyperfine --warmup 1 --runs 10 --export-csv ./experimental_results/grid/cheby_lp_timing.csv './target/release/phase-linearizer -n 0.0 -x 0.6 -p 150 -o 6 -a grid -i 300 -f ./experimental_results/grid/cheby_lp.csv transfer-function --amp --num "2.3447e-03   5.8262e-03   1.0160e-02   1.1842e-02   1.0160e-02   5.8262e-03   2.3447e-03" --den "1.000000  -3.207647 4.689690  -3.853772   1.857272  -0.493137   0.056098"'

