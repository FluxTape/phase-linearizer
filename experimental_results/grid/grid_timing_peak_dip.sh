#!/bin/bash
rm ./peak_dip.csv
cd ../../
set -eux
cargo build --release
echo "grid - Peak & Dip"
hyperfine --warmup 1 --runs 10 --export-csv ./experimental_results/grid/peak_dip_timing.csv './target/release/phase-linearizer -n 0.0 -x 1.0 -p 100 -o 5 -a grid -i 300 -f ./experimental_results/grid/peak_dip.csv transfer-function --amp --num "1.071018  -1.895730   2.433447  -2.280328   1.683715  -0.931094   0.415294  -0.130253   0.024056" --den "1.000000  -1.976400   2.558539  -2.258532   1.651478  -0.884705   0.388817  -0.117767   0.028696"'

