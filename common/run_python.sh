#!/bin/bash -l

module load xl
module load fftw
module load cuda/10.1.168

source ~/.bashrc
conda activate openmm_7.4_beta

python input.py $1 > python_run.log & 
