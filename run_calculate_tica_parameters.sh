#!/bin/bash -l

module load xl
module load fftw
module load cuda/10.1.105

source ~/.bashrc
source activate tica_env

python calculate_tica_parameters.py > log_tica_parameters_calc.txt

exit
