#!/bin/bash
# usage example: ./pso_tuning.sh _v1
cd ../../
cargo build --release
set -eux
seq 100 | parallel -N0 ./target/release/phase-linearizer -n 0.1 -x 0.9 -p 150 -o 8 \
-a pso -i 300 -f "./experimental_results/pso_tuning/pso_tuning$1.csv transfer-function" --amp \
--num \'0.0015   -0.0020    0.0002   -0.0009 0.0028   -0.0009    0.0002   -0.0020    0.0015\' \
--den \'1.0000   -2.7355    5.9780   -7.8335    8.5654   -6.3463    3.9239   -1.4513 0.4299\'
