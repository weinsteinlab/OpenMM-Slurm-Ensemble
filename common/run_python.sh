#!/bin/bash -l

module load xl
module load fftw
module load cuda/10.1.168

source ~/.bashrc
source activate openmm_7.4_beta

python input.py $1 & 
