#!/bin/bash
rm ./cheby_hp.csv
cd ../../
set -eux
cargo build --release
echo "grid - Cheby HP"
hyperfine --warmup 1 --runs 10 --export-csv ./experimental_results/grid/cheby_hp_timing.csv './target/release/phase-linearizer -n 0.6 -x 1.0 -p 100 -o 7 -a grid -i 300 -f ./experimental_results/grid/cheby_hp.csv transfer-function --amp --num "0.0014    0.0009    0.0023   -0.0005    0.0005   -0.0023   -0.0009   -0.0014" --den "1.0000    4.5142    9.0512   10.3576    7.2715    3.1213    0.7567    0.0798"'

