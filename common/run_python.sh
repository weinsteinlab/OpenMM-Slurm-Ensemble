#!/bin/bash -l

module load xl
module load fftw
module load cuda/10.1.105

source ~/.bashrc
source activate openmmCuda101

python input.py $1 $2 $3 $4 > ./python_log.txt & 
